from fastapi import FastAPI, HTTPException, Depends, UploadFile, File, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, EmailStr
from typing import Optional, List, Dict
from datetime import datetime, timedelta
import os
import jwt
import hashlib
from contextlib import asynccontextmanager
import asyncpg
import ssl
import logging
import uuid
import shutil
import json
from pathlib import Path

# Media upload directory
MEDIA_DIR = Path("/var/www/gogomarket/media")
MEDIA_DIR.mkdir(parents=True, exist_ok=True)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATABASE_URL = os.getenv("DATABASE_URL", "")
JWT_SECRET = os.getenv("JWT_SECRET", "change-me-in-production")
JWT_ALGORITHM = "HS256"

db_pool = None

async def get_db():
    global db_pool
    if db_pool is None:
        ssl_context = ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = ssl.CERT_NONE
        db_pool = await asyncpg.create_pool(DATABASE_URL, ssl=ssl_context, min_size=1, max_size=5)
        logger.info("Database pool created")
    return db_pool

async def init_db():
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS users (
                id SERIAL PRIMARY KEY,
                email VARCHAR(255) UNIQUE NOT NULL,
                password_hash VARCHAR(255) NOT NULL,
                name VARCHAR(255) NOT NULL,
                role VARCHAR(50) DEFAULT 'buyer',
                phone VARCHAR(50),
                address TEXT,
                latitude DOUBLE PRECISION,
                longitude DOUBLE PRECISION,
                avatar_url TEXT,
                is_verified BOOLEAN DEFAULT FALSE,
                is_active BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS products (
                id SERIAL PRIMARY KEY,
                seller_id INTEGER REFERENCES users(id),
                name VARCHAR(255) NOT NULL,
                description TEXT,
                price DOUBLE PRECISION NOT NULL,
                image_url TEXT,
                category VARCHAR(100),
                quantity INTEGER DEFAULT 1,
                in_stock BOOLEAN DEFAULT TRUE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS orders (
                id SERIAL PRIMARY KEY,
                buyer_id INTEGER REFERENCES users(id),
                seller_id INTEGER REFERENCES users(id),
                courier_id INTEGER REFERENCES users(id),
                status VARCHAR(50) DEFAULT 'pending',
                total_amount DOUBLE PRECISION,
                delivery_address TEXT,
                delivery_latitude DOUBLE PRECISION,
                delivery_longitude DOUBLE PRECISION,
                payment_method VARCHAR(50) DEFAULT 'cash',
                notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        # Add payment_method column if it doesn't exist (for existing databases)
        await conn.execute('''
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='orders' AND column_name='payment_method') THEN
                    ALTER TABLE orders ADD COLUMN payment_method VARCHAR(50) DEFAULT 'cash';
                END IF;
            END $$;
        ''')
        # Add multi-role support columns
        await conn.execute('''
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='roles') THEN
                    ALTER TABLE users ADD COLUMN roles TEXT[] DEFAULT ARRAY['buyer'];
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='active_role') THEN
                    ALTER TABLE users ADD COLUMN active_role VARCHAR(50);
                END IF;
            END $$;
        ''')
        # Migrate existing users: set roles array from current role, set active_role = role
        await conn.execute('''
            UPDATE users 
            SET roles = ARRAY[role], active_role = role 
            WHERE roles IS NULL OR active_role IS NULL
        ''')
        # Add admin user management columns
        await conn.execute('''
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='is_blocked') THEN
                    ALTER TABLE users ADD COLUMN is_blocked BOOLEAN DEFAULT FALSE;
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='block_reason') THEN
                    ALTER TABLE users ADD COLUMN block_reason TEXT;
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='admin_level') THEN
                    ALTER TABLE users ADD COLUMN admin_level INTEGER DEFAULT 0;
                END IF;
            END $$;
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS order_items (
                id SERIAL PRIMARY KEY,
                order_id INTEGER REFERENCES orders(id),
                product_id INTEGER REFERENCES products(id),
                quantity INTEGER NOT NULL,
                price DOUBLE PRECISION NOT NULL
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS content (
                id SERIAL PRIMARY KEY,
                author_id INTEGER REFERENCES users(id),
                content_type VARCHAR(50) NOT NULL,
                video_url TEXT,
                image_url TEXT,
                caption TEXT,
                product_id INTEGER REFERENCES products(id),
                views INTEGER DEFAULT 0,
                likes INTEGER DEFAULT 0,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        # Add is_admin_content column for admin-created content (non-purchasable)
        await conn.execute('''
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='content' AND column_name='is_admin_content') THEN
                    ALTER TABLE content ADD COLUMN is_admin_content BOOLEAN DEFAULT FALSE;
                END IF;
            END $$;
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS messages (
                id SERIAL PRIMARY KEY,
                sender_id INTEGER REFERENCES users(id),
                receiver_id INTEGER REFERENCES users(id),
                content TEXT NOT NULL,
                image_url TEXT,
                is_read BOOLEAN DEFAULT FALSE,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS product_likes (
                id SERIAL PRIMARY KEY,
                product_id INTEGER REFERENCES products(id),
                user_id INTEGER REFERENCES users(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(product_id, user_id)
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS product_comments (
                id SERIAL PRIMARY KEY,
                product_id INTEGER REFERENCES products(id),
                user_id INTEGER REFERENCES users(id),
                content TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        # Content comments (for reels and stories)
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS content_comments (
                id SERIAL PRIMARY KEY,
                content_id INTEGER REFERENCES content(id) ON DELETE CASCADE,
                user_id INTEGER REFERENCES users(id),
                text TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS reviews (
                id SERIAL PRIMARY KEY,
                product_id INTEGER REFERENCES products(id),
                user_id INTEGER REFERENCES users(id),
                rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
                comment TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(product_id, user_id)
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS favorites (
                id SERIAL PRIMARY KEY,
                product_id INTEGER REFERENCES products(id),
                user_id INTEGER REFERENCES users(id),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(product_id, user_id)
            )
        ''')
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS platform_settings (
                id SERIAL PRIMARY KEY,
                setting_key VARCHAR(100) UNIQUE NOT NULL,
                setting_value TEXT NOT NULL,
                description TEXT,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        # FCM tokens for push notifications
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS fcm_tokens (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                token TEXT NOT NULL,
                device_type VARCHAR(50),
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(user_id, token)
            )
        ''')
        # Courier locations for real-time tracking
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS courier_locations (
                id SERIAL PRIMARY KEY,
                courier_id INTEGER REFERENCES users(id) ON DELETE CASCADE UNIQUE,
                latitude DOUBLE PRECISION NOT NULL,
                longitude DOUBLE PRECISION NOT NULL,
                is_online BOOLEAN DEFAULT FALSE,
                last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        ''')
        # User verification documents
        await conn.execute('''
            CREATE TABLE IF NOT EXISTS user_verifications (
                id SERIAL PRIMARY KEY,
                user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
                document_type VARCHAR(100) NOT NULL,
                document_url TEXT NOT NULL,
                status VARCHAR(50) DEFAULT 'pending',
                admin_notes TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                reviewed_at TIMESTAMP
            )
        ''')
        # Insert default platform settings
        default_settings = [
            ('platform_commission', '10', 'Platform commission percentage from each sale'),
            ('courier_fee', '15000', 'Fixed delivery fee for couriers in sum'),
            ('min_order_amount', '50000', 'Minimum order amount in sum'),
        ]
        for key, value, desc in default_settings:
            exists = await conn.fetchval('SELECT id FROM platform_settings WHERE setting_key = $1', key)
            if not exists:
                await conn.execute(
                    'INSERT INTO platform_settings (setting_key, setting_value, description) VALUES ($1, $2, $3)',
                    key, value, desc
                )
        demo_users = [
            ('seller@demo.com', 'demo123', 'Demo Seller', 'seller'),
            ('buyer@demo.com', 'demo123', 'Demo Buyer', 'buyer'),
            ('courier@demo.com', 'demo123', 'Demo Courier', 'courier'),
            ('admin@demo.com', 'admin123', 'Demo Admin', 'admin'),
        ]
        for email, password, name, role in demo_users:
            exists = await conn.fetchval('SELECT id FROM users WHERE email = $1', email)
            if not exists:
                password_hash = hashlib.sha256(password.encode()).hexdigest()
                await conn.execute(
                    'INSERT INTO users (email, password_hash, name, role, is_verified) VALUES ($1, $2, $3, $4, TRUE)',
                    email, password_hash, name, role
                )
        logger.info("Database initialized")

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    if db_pool:
        await db_pool.close()

app = FastAPI(title="GoGoMarket API", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer(auto_error=False)

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    name: str
    role: str = "buyer"
    phone: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class ProductCreate(BaseModel):
    name: str
    price: float
    description: Optional[str] = None
    image_url: Optional[str] = None
    category: Optional[str] = None
    quantity: int = 1

class OrderCreate(BaseModel):
    seller_id: int
    items: List[dict]
    delivery_address: str
    delivery_latitude: float
    delivery_longitude: float
    payment_method: Optional[str] = 'cash'
    notes: Optional[str] = None

class ContentCreate(BaseModel):
    content_type: str
    video_url: Optional[str] = None
    image_url: Optional[str] = None
    caption: Optional[str] = None
    product_id: Optional[int] = None

class MessageCreate(BaseModel):
    receiver_id: int
    content: str

class ProductCommentCreate(BaseModel):
    product_id: int
    content: str

class ReviewCreate(BaseModel):
    product_id: int
    rating: int
    comment: Optional[str] = None

def create_token(user_id: int) -> str:
    payload = {"user_id": user_id, "exp": datetime.utcnow() + timedelta(days=30)}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def verify_token(token: str) -> Optional[int]:
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload.get("user_id")
    except:
        return None

async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if not credentials:
        raise HTTPException(status_code=401, detail="Not authenticated")
    user_id = verify_token(credentials.credentials)
    if not user_id:
        raise HTTPException(status_code=401, detail="Invalid token")
    pool = await get_db()
    async with pool.acquire() as conn:
        user = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        if not user:
            raise HTTPException(status_code=401, detail="User not found")
        return dict(user)

@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

@app.get("/")
async def root():
    return {"message": "GoGoMarket API", "version": "2.0", "database": "PostgreSQL"}

@app.post("/api/auth/register")
async def register(user: UserCreate):
    pool = await get_db()
    async with pool.acquire() as conn:
        exists = await conn.fetchval('SELECT id FROM users WHERE email = $1', user.email)
        if exists:
            raise HTTPException(status_code=400, detail="Email already registered")
        password_hash = hashlib.sha256(user.password.encode()).hexdigest()
        # Initialize roles array with selected role, set active_role = role
        user_id = await conn.fetchval(
            'INSERT INTO users (email, password_hash, name, role, roles, active_role, phone) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
            user.email, password_hash, user.name, user.role, [user.role], user.role, user.phone
        )
        token = create_token(user_id)
        return {"access_token": token, "user": {"id": user_id, "email": user.email, "name": user.name, "role": user.role, "roles": [user.role], "active_role": user.role}}

@app.post("/api/auth/login")
async def login(credentials: UserLogin):
    pool = await get_db()
    async with pool.acquire() as conn:
        password_hash = hashlib.sha256(credentials.password.encode()).hexdigest()
        user = await conn.fetchrow('SELECT * FROM users WHERE email = $1 AND password_hash = $2', credentials.email, password_hash)
        if not user:
            raise HTTPException(status_code=401, detail="Invalid credentials")
        token = create_token(user['id'])
        return {"access_token": token, "user": dict(user)}

@app.get("/api/auth/me")
async def get_me(user: dict = Depends(get_current_user)):
    return user

@app.put("/api/auth/me")
async def update_me(updates: dict, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        allowed = ['name', 'phone', 'address', 'latitude', 'longitude', 'avatar_url']
        set_parts, values, idx = [], [], 1
        for key, value in updates.items():
            if key in allowed:
                set_parts.append(f"{key} = ${idx}")
                values.append(value)
                idx += 1
        if set_parts:
            values.append(user['id'])
            await conn.execute(f"UPDATE users SET {', '.join(set_parts)} WHERE id = ${idx}", *values)
        updated = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user['id'])
        return dict(updated)

# ==================== MULTI-ROLE MANAGEMENT ====================

@app.post("/api/auth/switch-role")
async def switch_role(body: dict, user: dict = Depends(get_current_user)):
    """Switch active role for multi-role accounts"""
    new_role = body.get('role')
    if not new_role:
        raise HTTPException(status_code=400, detail="Role is required")
    
    valid_roles = ['buyer', 'seller', 'courier']
    if new_role not in valid_roles:
        raise HTTPException(status_code=400, detail=f"Invalid role. Must be one of: {valid_roles}")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        # Get user's available roles
        user_data = await conn.fetchrow('SELECT roles, active_role FROM users WHERE id = $1', user['id'])
        roles = user_data['roles'] or [user.get('role', 'buyer')]
        
        # Check if user has this role
        if new_role not in roles:
            raise HTTPException(status_code=403, detail=f"You don't have the '{new_role}' role. Add it first.")
        
        # If switching away from courier, set offline
        if user_data['active_role'] == 'courier' and new_role != 'courier':
            await conn.execute(
                'UPDATE courier_locations SET is_online = FALSE WHERE courier_id = $1',
                user['id']
            )
        
        # Update active role
        await conn.execute(
            'UPDATE users SET active_role = $1, role = $1 WHERE id = $2',
            new_role, user['id']
        )
        
        updated = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user['id'])
        return dict(updated)

@app.post("/api/auth/add-role")
async def add_role(body: dict, user: dict = Depends(get_current_user)):
    """Add a new role to user's account"""
    new_role = body.get('role')
    if not new_role:
        raise HTTPException(status_code=400, detail="Role is required")
    
    valid_roles = ['buyer', 'seller', 'courier']
    if new_role not in valid_roles:
        raise HTTPException(status_code=400, detail=f"Invalid role. Must be one of: {valid_roles}")
    
    # Admin role cannot be added this way
    if new_role == 'admin':
        raise HTTPException(status_code=403, detail="Admin role cannot be added")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        # Get user's current roles
        user_data = await conn.fetchrow('SELECT roles FROM users WHERE id = $1', user['id'])
        roles = list(user_data['roles'] or [user.get('role', 'buyer')])
        
        # Check if user already has this role
        if new_role in roles:
            raise HTTPException(status_code=400, detail=f"You already have the '{new_role}' role")
        
        # Add new role
        roles.append(new_role)
        await conn.execute(
            'UPDATE users SET roles = $1 WHERE id = $2',
            roles, user['id']
        )
        
        updated = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user['id'])
        return {"message": f"Role '{new_role}' added successfully", "user": dict(updated)}

@app.get("/api/auth/roles")
async def get_my_roles(user: dict = Depends(get_current_user)):
    """Get user's available roles and active role"""
    pool = await get_db()
    async with pool.acquire() as conn:
        user_data = await conn.fetchrow('SELECT roles, active_role, role FROM users WHERE id = $1', user['id'])
        roles = user_data['roles'] or [user_data['role']]
        active_role = user_data['active_role'] or user_data['role']
        return {
            "roles": roles,
            "active_role": active_role,
            "can_add_roles": [r for r in ['buyer', 'seller', 'courier'] if r not in roles]
        }

@app.get("/api/products")
async def get_products(seller_id: Optional[int] = None, category: Optional[str] = None, search: Optional[str] = None):
    pool = await get_db()
    async with pool.acquire() as conn:
        query = 'SELECT p.*, u.name as seller_name FROM products p JOIN users u ON p.seller_id = u.id WHERE 1=1'
        params, idx = [], 1
        if seller_id:
            query += f' AND p.seller_id = ${idx}'
            params.append(seller_id)
            idx += 1
        if category:
            query += f' AND p.category = ${idx}'
            params.append(category)
            idx += 1
        if search:
            query += f' AND (p.name ILIKE ${idx} OR p.description ILIKE ${idx})'
            params.append(f'%{search}%')
            idx += 1
        query += ' ORDER BY p.created_at DESC'
        rows = await conn.fetch(query, *params)
        return [dict(row) for row in rows]

@app.post("/api/products")
async def create_product(product: ProductCreate, user: dict = Depends(get_current_user)):
    if user['role'] not in ['seller', 'admin']:
        raise HTTPException(status_code=403, detail="Only sellers can create products")
    pool = await get_db()
    async with pool.acquire() as conn:
        product_id = await conn.fetchval(
            'INSERT INTO products (seller_id, name, description, price, image_url, category, quantity) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
            user['id'], product.name, product.description, product.price, product.image_url, product.category, product.quantity
        )
        row = await conn.fetchrow('SELECT * FROM products WHERE id = $1', product_id)
        return dict(row)

@app.get("/api/products/{product_id}")
async def get_product(product_id: int):
    pool = await get_db()
    async with pool.acquire() as conn:
        row = await conn.fetchrow('SELECT p.*, u.name as seller_name FROM products p JOIN users u ON p.seller_id = u.id WHERE p.id = $1', product_id)
        if not row:
            raise HTTPException(status_code=404, detail="Product not found")
        return dict(row)

@app.delete("/api/products/{product_id}")
async def delete_product(product_id: int, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        product = await conn.fetchrow('SELECT * FROM products WHERE id = $1', product_id)
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        if product['seller_id'] != user['id'] and user['role'] != 'admin':
            raise HTTPException(status_code=403, detail="Not authorized")
        await conn.execute('DELETE FROM products WHERE id = $1', product_id)
        return {"status": "deleted"}

@app.get("/api/content/reels")
async def get_reels(page: int = 1, per_page: int = 10):
    pool = await get_db()
    async with pool.acquire() as conn:
        offset = (page - 1) * per_page
        rows = await conn.fetch(
            "SELECT c.*, u.name as author_name FROM content c JOIN users u ON c.author_id = u.id WHERE c.content_type = 'reel' ORDER BY c.created_at DESC LIMIT $1 OFFSET $2",
            per_page, offset
        )
        return [dict(row) for row in rows]

@app.get("/api/content/stories")
async def get_stories():
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            "SELECT c.*, u.name as author_name FROM content c JOIN users u ON c.author_id = u.id WHERE c.content_type = 'story' AND c.created_at > NOW() - INTERVAL '24 hours' ORDER BY c.created_at DESC"
        )
        return [dict(row) for row in rows]

@app.post("/api/content")
async def create_content(content: ContentCreate, user: dict = Depends(get_current_user)):
    if user['role'] not in ['seller', 'admin']:
        raise HTTPException(status_code=403, detail="Only sellers can create content")
    pool = await get_db()
    async with pool.acquire() as conn:
        # Mark content as admin content if created by admin (non-purchasable)
        is_admin_content = user['role'] == 'admin'
        content_id = await conn.fetchval(
            'INSERT INTO content (author_id, content_type, video_url, image_url, caption, product_id, is_admin_content) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
            user['id'], content.content_type, content.video_url, content.image_url, content.caption, content.product_id, is_admin_content
        )
        row = await conn.fetchrow('SELECT * FROM content WHERE id = $1', content_id)
        return dict(row)

@app.post("/api/content/{content_id}/view")
async def view_content(content_id: int):
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute('UPDATE content SET views = views + 1 WHERE id = $1', content_id)
        return {"status": "viewed"}

@app.post("/api/content/{content_id}/like")
async def like_content(content_id: int):
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute('UPDATE content SET likes = likes + 1 WHERE id = $1', content_id)
        row = await conn.fetchrow('SELECT * FROM content WHERE id = $1', content_id)
        return dict(row)

@app.get("/api/orders")
async def get_orders(user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        if user['role'] == 'admin':
            rows = await conn.fetch('''
                SELECT o.*, 
                       b.name as buyer_name, b.email as buyer_email, b.phone as buyer_phone,
                       s.name as seller_name, s.email as seller_email,
                       c.name as courier_name
                FROM orders o
                LEFT JOIN users b ON o.buyer_id = b.id
                LEFT JOIN users s ON o.seller_id = s.id
                LEFT JOIN users c ON o.courier_id = c.id
                ORDER BY o.created_at DESC
            ''')
        elif user['role'] == 'seller':
            rows = await conn.fetch('''
                SELECT o.*, 
                       b.name as buyer_name, b.email as buyer_email, b.phone as buyer_phone,
                       c.name as courier_name
                FROM orders o
                LEFT JOIN users b ON o.buyer_id = b.id
                LEFT JOIN users c ON o.courier_id = c.id
                WHERE o.seller_id = $1 
                ORDER BY o.created_at DESC
            ''', user['id'])
        elif user['role'] == 'courier':
            rows = await conn.fetch('''
                SELECT o.*, 
                       b.name as buyer_name, b.phone as buyer_phone,
                       s.name as seller_name
                FROM orders o
                LEFT JOIN users b ON o.buyer_id = b.id
                LEFT JOIN users s ON o.seller_id = s.id
                WHERE o.courier_id = $1 OR (o.courier_id IS NULL AND o.status = 'ready') 
                ORDER BY o.created_at DESC
            ''', user['id'])
        else:
            rows = await conn.fetch('''
                SELECT o.*, 
                       s.name as seller_name,
                       c.name as courier_name
                FROM orders o
                LEFT JOIN users s ON o.seller_id = s.id
                LEFT JOIN users c ON o.courier_id = c.id
                WHERE o.buyer_id = $1 
                ORDER BY o.created_at DESC
            ''', user['id'])
        
        # Get order items for each order
        orders = []
        for row in rows:
            order = dict(row)
            items = await conn.fetch('''
                SELECT oi.*, p.name as product_name, p.image_url
                FROM order_items oi
                LEFT JOIN products p ON oi.product_id = p.id
                WHERE oi.order_id = $1
            ''', order['id'])
            order['items'] = [dict(item) for item in items]
            orders.append(order)
        
        return orders

@app.post("/api/orders")
async def create_order(order: OrderCreate, user: dict = Depends(get_current_user)):
    # Only users with active_role='buyer' can create orders
    active_role = user.get('active_role') or user.get('role')
    if active_role != 'buyer':
        raise HTTPException(status_code=403, detail="Only buyers can create orders. Switch to buyer role first.")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        # Check if user is trying to buy their own product
        for item in order.items:
            product = await conn.fetchrow('SELECT seller_id FROM products WHERE id = $1', item['product_id'])
            if product and product['seller_id'] == user['id']:
                raise HTTPException(status_code=400, detail="You cannot buy your own products")
        
        total = sum(item['price'] * item['quantity'] for item in order.items)
        order_id = await conn.fetchval(
            'INSERT INTO orders (buyer_id, seller_id, total_amount, delivery_address, delivery_latitude, delivery_longitude, payment_method, notes) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING id',
            user['id'], order.seller_id, total, order.delivery_address, order.delivery_latitude, order.delivery_longitude, order.payment_method, order.notes
        )
        for item in order.items:
            await conn.execute('INSERT INTO order_items (order_id, product_id, quantity, price) VALUES ($1, $2, $3, $4)', order_id, item['product_id'], item['quantity'], item['price'])
        row = await conn.fetchrow('SELECT * FROM orders WHERE id = $1', order_id)
        return dict(row)

@app.put("/api/orders/{order_id}/status")
async def update_order_status(order_id: int, body: dict, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        status = body.get('status')
        await conn.execute('UPDATE orders SET status = $1 WHERE id = $2', status, order_id)
        if status == 'delivering' and user['role'] == 'courier':
            await conn.execute('UPDATE orders SET courier_id = $1 WHERE id = $2', user['id'], order_id)
        row = await conn.fetchrow('SELECT * FROM orders WHERE id = $1', order_id)
        return dict(row)

@app.get("/api/chat/conversations")
async def get_conversations(user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            '''SELECT DISTINCT ON (other_id) 
                  CASE WHEN sender_id = $1 THEN receiver_id ELSE sender_id END as other_id,
                  u.name as other_name,
                  m.content as last_message,
                  m.created_at
               FROM messages m
               JOIN users u ON u.id = CASE WHEN m.sender_id = $1 THEN m.receiver_id ELSE m.sender_id END
               WHERE m.sender_id = $1 OR m.receiver_id = $1
               ORDER BY other_id, m.created_at DESC''',
            user['id']
        )
        return [dict(row) for row in rows]

@app.get("/api/chat/{user_id}")
async def get_chat_messages(user_id: int, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            'SELECT * FROM messages WHERE (sender_id = $1 AND receiver_id = $2) OR (sender_id = $2 AND receiver_id = $1) ORDER BY created_at ASC',
            user['id'], user_id
        )
        await conn.execute('UPDATE messages SET is_read = TRUE WHERE sender_id = $1 AND receiver_id = $2', user_id, user['id'])
        return [dict(row) for row in rows]

@app.post("/api/chat")
async def send_message(message: MessageCreate, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        msg_id = await conn.fetchval(
            'INSERT INTO messages (sender_id, receiver_id, content) VALUES ($1, $2, $3) RETURNING id',
            user['id'], message.receiver_id, message.content
        )
        row = await conn.fetchrow('SELECT * FROM messages WHERE id = $1', msg_id)
        return dict(row)

@app.get("/api/chat/unread/count")
async def get_unread_count(user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        count = await conn.fetchval('SELECT COUNT(*) FROM messages WHERE receiver_id = $1 AND is_read = FALSE', user['id'])
        return {"unread_count": count}

@app.get("/api/search")
async def search(q: str, type: Optional[str] = None):
    pool = await get_db()
    async with pool.acquire() as conn:
        results = {"products": [], "sellers": []}
        if not type or type == 'products':
            rows = await conn.fetch('SELECT p.*, u.name as seller_name FROM products p JOIN users u ON p.seller_id = u.id WHERE p.name ILIKE $1 OR p.description ILIKE $1', f'%{q}%')
            results["products"] = [dict(row) for row in rows]
        if not type or type == 'sellers':
            rows = await conn.fetch("SELECT * FROM users WHERE role = 'seller' AND name ILIKE $1", f'%{q}%')
            results["sellers"] = [dict(row) for row in rows]
        return results

@app.get("/api/explore")
async def get_explore(page: int = 1, per_page: int = 20):
    pool = await get_db()
    async with pool.acquire() as conn:
        offset = (page - 1) * per_page
        products = await conn.fetch('SELECT * FROM products ORDER BY created_at DESC LIMIT $1 OFFSET $2', per_page, offset)
        return {"products": [dict(row) for row in products]}

@app.get("/api/sellers")
async def get_sellers():
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch("SELECT * FROM users WHERE role = 'seller' AND is_active = TRUE")
        return [dict(row) for row in rows]

@app.get("/api/users")
async def get_users(user: dict = Depends(get_current_user)):
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin only")
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch('SELECT * FROM users ORDER BY created_at DESC')
        return [dict(row) for row in rows]

# ==================== ADMIN USER MANAGEMENT ====================

@app.get("/api/admin/users/{user_id}")
async def get_user_details(user_id: int, user: dict = Depends(get_current_user)):
    """Get detailed user information for admin"""
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin only")
    pool = await get_db()
    async with pool.acquire() as conn:
        user_data = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        if not user_data:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Get user's orders count
        orders_count = await conn.fetchval(
            'SELECT COUNT(*) FROM orders WHERE buyer_id = $1 OR seller_id = $1 OR courier_id = $1',
            user_id
        )
        
        # Get user's products count (if seller)
        products_count = await conn.fetchval(
            'SELECT COUNT(*) FROM products WHERE seller_id = $1',
            user_id
        )
        
        # Get user's verification status
        verification = await conn.fetchrow(
            'SELECT * FROM user_verifications WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1',
            user_id
        )
        
        result = dict(user_data)
        result['orders_count'] = orders_count
        result['products_count'] = products_count
        result['verification'] = dict(verification) if verification else None
        
        return result

@app.put("/api/admin/users/{user_id}")
async def admin_update_user(user_id: int, updates: dict, user: dict = Depends(get_current_user)):
    """Admin can update any user's data"""
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin only")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        # Check if user exists
        existing = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Allowed fields for admin to update
        allowed = ['name', 'phone', 'address', 'role', 'is_verified', 'is_blocked', 'admin_level']
        set_parts, values, idx = [], [], 1
        for key, value in updates.items():
            if key in allowed:
                set_parts.append(f"{key} = ${idx}")
                values.append(value)
                idx += 1
        
        if set_parts:
            values.append(user_id)
            await conn.execute(f"UPDATE users SET {', '.join(set_parts)} WHERE id = ${idx}", *values)
        
        updated = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        return dict(updated)

@app.post("/api/admin/users/{user_id}/block")
async def block_user(user_id: int, body: dict, user: dict = Depends(get_current_user)):
    """Block or unblock a user"""
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin only")
    
    is_blocked = body.get('is_blocked', True)
    reason = body.get('reason', '')
    
    pool = await get_db()
    async with pool.acquire() as conn:
        # Check if user exists
        existing = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Cannot block another admin
        if existing['role'] == 'admin' and user['id'] != user_id:
            raise HTTPException(status_code=403, detail="Cannot block another admin")
        
        await conn.execute(
            'UPDATE users SET is_blocked = $1, block_reason = $2 WHERE id = $3',
            is_blocked, reason, user_id
        )
        
        updated = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        return {"message": f"User {'blocked' if is_blocked else 'unblocked'}", "user": dict(updated)}

@app.post("/api/admin/users/{user_id}/approve")
async def approve_user(user_id: int, user: dict = Depends(get_current_user)):
    """Approve a user (set is_verified = true)"""
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin only")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        existing = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        if not existing:
            raise HTTPException(status_code=404, detail="User not found")
        
        await conn.execute('UPDATE users SET is_verified = TRUE WHERE id = $1', user_id)
        
        # Also update verification record if exists
        await conn.execute(
            "UPDATE user_verifications SET status = 'approved' WHERE user_id = $1 AND status = 'pending'",
            user_id
        )
        
        updated = await conn.fetchrow('SELECT * FROM users WHERE id = $1', user_id)
        return {"message": "User approved", "user": dict(updated)}

@app.get("/api/reviews/{product_id}")
async def get_product_reviews(product_id: int):
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            '''SELECT r.*, u.name as user_name, u.avatar_url as user_avatar
               FROM reviews r 
               JOIN users u ON r.user_id = u.id 
               WHERE r.product_id = $1 
               ORDER BY r.created_at DESC''',
            product_id
        )
        stats = await conn.fetchrow(
            '''SELECT COUNT(*) as count, COALESCE(AVG(rating), 0) as average
               FROM reviews WHERE product_id = $1''',
            product_id
        )
        return {
            "reviews": [dict(row) for row in rows],
            "stats": {
                "count": stats['count'],
                "average": round(float(stats['average']), 1)
            }
        }

@app.post("/api/reviews")
async def create_review(review: ReviewCreate, user: dict = Depends(get_current_user)):
    if review.rating < 1 or review.rating > 5:
        raise HTTPException(status_code=400, detail="Rating must be between 1 and 5")
    pool = await get_db()
    async with pool.acquire() as conn:
        existing = await conn.fetchrow(
            'SELECT id FROM reviews WHERE product_id = $1 AND user_id = $2',
            review.product_id, user['id']
        )
        if existing:
            await conn.execute(
                'UPDATE reviews SET rating = $1, comment = $2 WHERE product_id = $3 AND user_id = $4',
                review.rating, review.comment, review.product_id, user['id']
            )
        else:
            await conn.execute(
                'INSERT INTO reviews (product_id, user_id, rating, comment) VALUES ($1, $2, $3, $4)',
                review.product_id, user['id'], review.rating, review.comment
            )
        row = await conn.fetchrow(
            '''SELECT r.*, u.name as user_name FROM reviews r 
               JOIN users u ON r.user_id = u.id 
               WHERE r.product_id = $1 AND r.user_id = $2''',
            review.product_id, user['id']
        )
        return dict(row)

@app.delete("/api/reviews/{review_id}")
async def delete_review(review_id: int, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        review = await conn.fetchrow('SELECT * FROM reviews WHERE id = $1', review_id)
        if not review:
            raise HTTPException(status_code=404, detail="Review not found")
        if review['user_id'] != user['id'] and user['role'] != 'admin':
            raise HTTPException(status_code=403, detail="Not authorized")
        await conn.execute('DELETE FROM reviews WHERE id = $1', review_id)
        return {"status": "deleted"}

# Product Likes endpoints
@app.post("/api/products/{product_id}/like")
async def like_product(product_id: int, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        existing = await conn.fetchrow(
            'SELECT id FROM product_likes WHERE product_id = $1 AND user_id = $2',
            product_id, user['id']
        )
        if existing:
            await conn.execute(
                'DELETE FROM product_likes WHERE product_id = $1 AND user_id = $2',
                product_id, user['id']
            )
            liked = False
        else:
            await conn.execute(
                'INSERT INTO product_likes (product_id, user_id) VALUES ($1, $2)',
                product_id, user['id']
            )
            liked = True
        count = await conn.fetchval(
            'SELECT COUNT(*) FROM product_likes WHERE product_id = $1',
            product_id
        )
        return {"liked": liked, "likes_count": count}

@app.get("/api/products/{product_id}/likes")
async def get_product_likes(product_id: int, credentials: HTTPAuthorizationCredentials = Depends(security)):
    pool = await get_db()
    async with pool.acquire() as conn:
        count = await conn.fetchval(
            'SELECT COUNT(*) FROM product_likes WHERE product_id = $1',
            product_id
        )
        user_liked = False
        if credentials:
            user_id = verify_token(credentials.credentials)
            if user_id:
                existing = await conn.fetchrow(
                    'SELECT id FROM product_likes WHERE product_id = $1 AND user_id = $2',
                    product_id, user_id
                )
                user_liked = existing is not None
        return {"likes_count": count, "user_liked": user_liked}

# Product Comments endpoints
@app.get("/api/products/{product_id}/comments")
async def get_product_comments(product_id: int):
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch(
            '''SELECT c.*, u.name as user_name, u.avatar_url as user_avatar
               FROM product_comments c 
               JOIN users u ON c.user_id = u.id 
               WHERE c.product_id = $1 
               ORDER BY c.created_at DESC''',
            product_id
        )
        return [dict(row) for row in rows]

@app.post("/api/products/{product_id}/comments")
async def create_product_comment(product_id: int, comment: ProductCommentCreate, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        comment_id = await conn.fetchval(
            'INSERT INTO product_comments (product_id, user_id, content) VALUES ($1, $2, $3) RETURNING id',
            product_id, user['id'], comment.content
        )
        row = await conn.fetchrow(
            '''SELECT c.*, u.name as user_name, u.avatar_url as user_avatar
               FROM product_comments c 
               JOIN users u ON c.user_id = u.id 
               WHERE c.id = $1''',
            comment_id
        )
        return dict(row)

@app.delete("/api/products/comments/{comment_id}")
async def delete_product_comment(comment_id: int, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        comment = await conn.fetchrow('SELECT * FROM product_comments WHERE id = $1', comment_id)
        if not comment:
            raise HTTPException(status_code=404, detail="Comment not found")
        if comment['user_id'] != user['id'] and user['role'] != 'admin':
            raise HTTPException(status_code=403, detail="Not authorized")
        await conn.execute('DELETE FROM product_comments WHERE id = $1', comment_id)
        return {"status": "deleted"}

# Content comments endpoints (for reels and stories)
@app.get("/api/comments/{content_id}")
async def get_content_comments(content_id: int):
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch('''
            SELECT c.*, u.name as author_name
            FROM content_comments c
            JOIN users u ON c.user_id = u.id
            WHERE c.content_id = $1
            ORDER BY c.created_at DESC
        ''', content_id)
        return [dict(row) for row in rows]

class ContentCommentCreate(BaseModel):
    content_id: int
    text: str

@app.post("/api/comments")
async def create_content_comment(comment: ContentCommentCreate, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            'INSERT INTO content_comments (content_id, user_id, text) VALUES ($1, $2, $3) RETURNING id, created_at',
            comment.content_id, user['id'], comment.text
        )
        return {
            'id': row['id'],
            'content_id': comment.content_id,
            'user_id': user['id'],
            'author_name': user['name'],
            'text': comment.text,
            'created_at': row['created_at'].isoformat() if row['created_at'] else None
        }

# Favorites endpoints
@app.get("/api/favorites")
async def get_favorites(user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch('''
            SELECT p.*, u.name as seller_name, f.created_at as favorited_at
            FROM favorites f
            JOIN products p ON f.product_id = p.id
            JOIN users u ON p.seller_id = u.id
            WHERE f.user_id = $1
            ORDER BY f.created_at DESC
        ''', user['id'])
        return [dict(row) for row in rows]

@app.post("/api/favorites/{product_id}")
async def toggle_favorite(product_id: int, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        # Check if product exists
        product = await conn.fetchrow('SELECT id FROM products WHERE id = $1', product_id)
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Check if already favorited
        existing = await conn.fetchrow(
            'SELECT id FROM favorites WHERE product_id = $1 AND user_id = $2',
            product_id, user['id']
        )
        
        if existing:
            # Remove from favorites
            await conn.execute(
                'DELETE FROM favorites WHERE product_id = $1 AND user_id = $2',
                product_id, user['id']
            )
            return {"status": "removed", "is_favorite": False}
        else:
            # Add to favorites
            await conn.execute(
                'INSERT INTO favorites (product_id, user_id) VALUES ($1, $2)',
                product_id, user['id']
            )
            return {"status": "added", "is_favorite": True}

@app.get("/api/favorites/check/{product_id}")
async def check_favorite(product_id: int, user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        existing = await conn.fetchrow(
            'SELECT id FROM favorites WHERE product_id = $1 AND user_id = $2',
            product_id, user['id']
        )
        return {"is_favorite": existing is not None}

# Platform Settings endpoints (admin only)
@app.get("/api/settings")
async def get_settings(user: dict = Depends(get_current_user)):
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    pool = await get_db()
    async with pool.acquire() as conn:
        rows = await conn.fetch('SELECT * FROM platform_settings ORDER BY setting_key')
        return [dict(row) for row in rows]

@app.get("/api/settings/{key}")
async def get_setting(key: str):
    pool = await get_db()
    async with pool.acquire() as conn:
        row = await conn.fetchrow('SELECT * FROM platform_settings WHERE setting_key = $1', key)
        if not row:
            raise HTTPException(status_code=404, detail="Setting not found")
        return dict(row)

@app.put("/api/settings/{key}")
async def update_setting(key: str, body: dict, user: dict = Depends(get_current_user)):
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    pool = await get_db()
    async with pool.acquire() as conn:
        value = body.get('value')
        if value is None:
            raise HTTPException(status_code=400, detail="Value is required")
        await conn.execute(
            'UPDATE platform_settings SET setting_value = $1, updated_at = CURRENT_TIMESTAMP WHERE setting_key = $2',
            str(value), key
        )
        row = await conn.fetchrow('SELECT * FROM platform_settings WHERE setting_key = $1', key)
        if not row:
            raise HTTPException(status_code=404, detail="Setting not found")
        return dict(row)

# Admin statistics endpoint
@app.get("/api/admin/stats")
async def get_admin_stats(user: dict = Depends(get_current_user)):
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    pool = await get_db()
    async with pool.acquire() as conn:
        # Get total revenue
        total_revenue = await conn.fetchval(
            "SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status NOT IN ('cancelled')"
        )
        # Get commission rate
        commission_row = await conn.fetchrow(
            "SELECT setting_value FROM platform_settings WHERE setting_key = 'platform_commission'"
        )
        commission_rate = float(commission_row['setting_value']) if commission_row else 10.0
        platform_earnings = total_revenue * (commission_rate / 100)
        
        # Get order counts
        total_orders = await conn.fetchval('SELECT COUNT(*) FROM orders')
        completed_orders = await conn.fetchval(
            "SELECT COUNT(*) FROM orders WHERE status IN ('delivered', 'completed')"
        )
        pending_orders = await conn.fetchval(
            "SELECT COUNT(*) FROM orders WHERE status NOT IN ('delivered', 'completed', 'cancelled')"
        )
        cancelled_orders = await conn.fetchval(
            "SELECT COUNT(*) FROM orders WHERE status = 'cancelled'"
        )
        
        # Get user counts
        total_users = await conn.fetchval('SELECT COUNT(*) FROM users')
        buyers = await conn.fetchval("SELECT COUNT(*) FROM users WHERE role = 'buyer'")
        sellers = await conn.fetchval("SELECT COUNT(*) FROM users WHERE role = 'seller'")
        couriers = await conn.fetchval("SELECT COUNT(*) FROM users WHERE role = 'courier'")
        
        # Get product count
        total_products = await conn.fetchval('SELECT COUNT(*) FROM products')
        
        return {
            "revenue": {
                "total": total_revenue,
                "platform_earnings": platform_earnings,
                "commission_rate": commission_rate,
            },
            "orders": {
                "total": total_orders,
                "completed": completed_orders,
                "pending": pending_orders,
                "cancelled": cancelled_orders,
            },
            "users": {
                "total": total_users,
                "buyers": buyers,
                "sellers": sellers,
                "couriers": couriers,
            },
            "products": total_products,
        }

# User-specific statistics endpoints for personal reports
@app.get("/api/my/stats")
async def get_my_stats(user: dict = Depends(get_current_user)):
    pool = await get_db()
    async with pool.acquire() as conn:
        user_id = user['id']
        role = user['role']
        
        if role == 'seller':
            # Seller statistics
            total_products = await conn.fetchval(
                'SELECT COUNT(*) FROM products WHERE seller_id = $1', user_id
            )
            total_orders = await conn.fetchval(
                'SELECT COUNT(*) FROM orders WHERE seller_id = $1', user_id
            )
            completed_orders = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE seller_id = $1 AND status IN ('delivered', 'completed')", user_id
            )
            pending_orders = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE seller_id = $1 AND status NOT IN ('delivered', 'completed', 'cancelled')", user_id
            )
            cancelled_orders = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE seller_id = $1 AND status = 'cancelled'", user_id
            )
            total_revenue = await conn.fetchval(
                "SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE seller_id = $1 AND status NOT IN ('cancelled')", user_id
            )
            # Get commission rate
            commission_row = await conn.fetchrow(
                "SELECT setting_value FROM platform_settings WHERE setting_key = 'platform_commission'"
            )
            commission_rate = float(commission_row['setting_value']) if commission_row else 10.0
            commission_amount = total_revenue * (commission_rate / 100)
            net_earnings = total_revenue - commission_amount
            
            # Get average rating
            avg_rating = await conn.fetchval(
                '''SELECT AVG(r.rating) FROM reviews r 
                   JOIN products p ON r.product_id = p.id 
                   WHERE p.seller_id = $1''', user_id
            )
            total_reviews = await conn.fetchval(
                '''SELECT COUNT(*) FROM reviews r 
                   JOIN products p ON r.product_id = p.id 
                   WHERE p.seller_id = $1''', user_id
            )
            
            return {
                "role": "seller",
                "products": total_products,
                "orders": {
                    "total": total_orders,
                    "completed": completed_orders,
                    "pending": pending_orders,
                    "cancelled": cancelled_orders,
                },
                "revenue": {
                    "total": total_revenue,
                    "commission_rate": commission_rate,
                    "commission_amount": commission_amount,
                    "net_earnings": net_earnings,
                },
                "rating": {
                    "average": float(avg_rating) if avg_rating else 0.0,
                    "total_reviews": total_reviews,
                },
            }
        
        elif role == 'courier':
            # Courier statistics
            total_deliveries = await conn.fetchval(
                'SELECT COUNT(*) FROM orders WHERE courier_id = $1', user_id
            )
            completed_deliveries = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE courier_id = $1 AND status IN ('delivered', 'completed')", user_id
            )
            in_progress = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE courier_id = $1 AND status = 'in_transit'", user_id
            )
            # Get courier fee
            fee_row = await conn.fetchrow(
                "SELECT setting_value FROM platform_settings WHERE setting_key = 'courier_fee'"
            )
            courier_fee = float(fee_row['setting_value']) if fee_row else 15000.0
            total_earnings = completed_deliveries * courier_fee
            
            return {
                "role": "courier",
                "deliveries": {
                    "total": total_deliveries,
                    "completed": completed_deliveries,
                    "in_progress": in_progress,
                },
                "earnings": {
                    "fee_per_delivery": courier_fee,
                    "total_earnings": total_earnings,
                },
            }
        
        elif role == 'buyer':
            # Buyer statistics
            total_orders = await conn.fetchval(
                'SELECT COUNT(*) FROM orders WHERE buyer_id = $1', user_id
            )
            completed_orders = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE buyer_id = $1 AND status IN ('delivered', 'completed')", user_id
            )
            pending_orders = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE buyer_id = $1 AND status NOT IN ('delivered', 'completed', 'cancelled')", user_id
            )
            cancelled_orders = await conn.fetchval(
                "SELECT COUNT(*) FROM orders WHERE buyer_id = $1 AND status = 'cancelled'", user_id
            )
            total_spent = await conn.fetchval(
                "SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE buyer_id = $1 AND status NOT IN ('cancelled')", user_id
            )
            favorites_count = await conn.fetchval(
                'SELECT COUNT(*) FROM favorites WHERE user_id = $1', user_id
            )
            reviews_count = await conn.fetchval(
                'SELECT COUNT(*) FROM reviews WHERE user_id = $1', user_id
            )
            
            return {
                "role": "buyer",
                "orders": {
                    "total": total_orders,
                    "completed": completed_orders,
                    "pending": pending_orders,
                    "cancelled": cancelled_orders,
                },
                "spending": {
                    "total_spent": total_spent,
                },
                "activity": {
                    "favorites": favorites_count,
                    "reviews": reviews_count,
                },
            }
        
        else:
            # Admin or unknown role
            return {
                "role": role,
                "message": "Use /api/admin/stats for admin statistics",
            }

# Export user statistics as CSV
@app.get("/api/my/stats/export")
async def export_my_stats(user: dict = Depends(get_current_user)):
    from fastapi.responses import Response
    import csv
    import io
    
    pool = await get_db()
    async with pool.acquire() as conn:
        user_id = user['id']
        role = user['role']
        
        output = io.StringIO()
        writer = csv.writer(output)
        
        if role == 'seller':
            # Export seller orders
            orders = await conn.fetch(
                '''SELECT o.id, o.status, o.total_amount, o.payment_method, o.created_at,
                          b.name as buyer_name, b.email as buyer_email
                   FROM orders o
                   LEFT JOIN users b ON o.buyer_id = b.id
                   WHERE o.seller_id = $1
                   ORDER BY o.created_at DESC''', user_id
            )
            writer.writerow(['Order ID', 'Status', 'Amount', 'Payment Method', 'Date', 'Buyer Name', 'Buyer Email'])
            for order in orders:
                writer.writerow([
                    order['id'], order['status'], order['total_amount'],
                    order['payment_method'], str(order['created_at']),
                    order['buyer_name'], order['buyer_email']
                ])
        
        elif role == 'courier':
            # Export courier deliveries
            deliveries = await conn.fetch(
                '''SELECT o.id, o.status, o.delivery_address, o.created_at,
                          b.name as buyer_name, s.name as seller_name
                   FROM orders o
                   LEFT JOIN users b ON o.buyer_id = b.id
                   LEFT JOIN users s ON o.seller_id = s.id
                   WHERE o.courier_id = $1
                   ORDER BY o.created_at DESC''', user_id
            )
            writer.writerow(['Delivery ID', 'Status', 'Address', 'Date', 'Buyer', 'Seller'])
            for d in deliveries:
                writer.writerow([
                    d['id'], d['status'], d['delivery_address'],
                    str(d['created_at']), d['buyer_name'], d['seller_name']
                ])
        
        elif role == 'buyer':
            # Export buyer orders
            orders = await conn.fetch(
                '''SELECT o.id, o.status, o.total_amount, o.payment_method, o.created_at,
                          s.name as seller_name
                   FROM orders o
                   LEFT JOIN users s ON o.seller_id = s.id
                   WHERE o.buyer_id = $1
                   ORDER BY o.created_at DESC''', user_id
            )
            writer.writerow(['Order ID', 'Status', 'Amount', 'Payment Method', 'Date', 'Seller'])
            for order in orders:
                writer.writerow([
                    order['id'], order['status'], order['total_amount'],
                    order['payment_method'], str(order['created_at']),
                    order['seller_name']
                ])
        
        csv_content = output.getvalue()
        output.close()
        
        return Response(
            content=csv_content,
            media_type="text/csv",
            headers={
                "Content-Disposition": f"attachment; filename={role}_report.csv"
            }
        )

# Admin export all transactions
@app.get("/api/admin/export")
async def export_admin_stats(user: dict = Depends(get_current_user)):
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    from fastapi.responses import Response
    import csv
    import io
    
    pool = await get_db()
    async with pool.acquire() as conn:
        output = io.StringIO()
        writer = csv.writer(output)
        
        orders = await conn.fetch(
            '''SELECT o.id, o.status, o.total_amount, o.payment_method, o.delivery_address, o.created_at,
                      b.name as buyer_name, b.email as buyer_email, b.phone as buyer_phone,
                      s.name as seller_name, s.email as seller_email,
                      c.name as courier_name
               FROM orders o
               LEFT JOIN users b ON o.buyer_id = b.id
               LEFT JOIN users s ON o.seller_id = s.id
               LEFT JOIN users c ON o.courier_id = c.id
               ORDER BY o.created_at DESC'''
        )
        
        writer.writerow([
            'Order ID', 'Status', 'Amount', 'Payment Method', 'Delivery Address', 'Date',
            'Buyer Name', 'Buyer Email', 'Buyer Phone',
            'Seller Name', 'Seller Email', 'Courier Name'
        ])
        for order in orders:
            writer.writerow([
                order['id'], order['status'], order['total_amount'],
                order['payment_method'], order['delivery_address'], str(order['created_at']),
                order['buyer_name'], order['buyer_email'], order['buyer_phone'],
                order['seller_name'], order['seller_email'], order['courier_name']
            ])
        
        csv_content = output.getvalue()
        output.close()
        
        return Response(
            content=csv_content,
            media_type="text/csv",
            headers={
                "Content-Disposition": "attachment; filename=all_transactions.csv"
            }
        )

# ==================== FCM PUSH NOTIFICATIONS ====================

class FCMTokenRegister(BaseModel):
    token: str
    device_type: Optional[str] = 'android'

@app.post("/api/fcm/register")
async def register_fcm_token(data: FCMTokenRegister, user: dict = Depends(get_current_user)):
    """Register or update FCM token for push notifications"""
    pool = await get_db()
    async with pool.acquire() as conn:
        # Upsert FCM token
        await conn.execute('''
            INSERT INTO fcm_tokens (user_id, token, device_type, updated_at)
            VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
            ON CONFLICT (user_id, token) DO UPDATE SET updated_at = CURRENT_TIMESTAMP
        ''', user['id'], data.token, data.device_type)
        return {"status": "registered"}

@app.delete("/api/fcm/unregister")
async def unregister_fcm_token(token: str, user: dict = Depends(get_current_user)):
    """Remove FCM token when user logs out"""
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute('DELETE FROM fcm_tokens WHERE user_id = $1 AND token = $2', user['id'], token)
        return {"status": "unregistered"}

async def send_push_notification(user_id: int, title: str, body: str, data: dict = None):
    """Send push notification to user (placeholder - requires Firebase Admin SDK)"""
    # Note: This is a placeholder. In production, you would use Firebase Admin SDK
    # to send actual push notifications. For now, we just log the notification.
    logger.info(f"Push notification to user {user_id}: {title} - {body}")
    # Store notification in database for in-app display
    pool = await get_db()
    async with pool.acquire() as conn:
        # Get user's FCM tokens
        tokens = await conn.fetch('SELECT token FROM fcm_tokens WHERE user_id = $1', user_id)
        # In production, send to each token using Firebase Admin SDK
        return len(tokens)

# ==================== COURIER LOCATION TRACKING ====================

class CourierLocationUpdate(BaseModel):
    latitude: float
    longitude: float

@app.post("/api/courier/location")
async def update_courier_location(location: CourierLocationUpdate, user: dict = Depends(get_current_user)):
    """Update courier's current location"""
    if user['role'] != 'courier':
        raise HTTPException(status_code=403, detail="Only couriers can update location")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute('''
            INSERT INTO courier_locations (courier_id, latitude, longitude, is_online, last_updated)
            VALUES ($1, $2, $3, TRUE, CURRENT_TIMESTAMP)
            ON CONFLICT (courier_id) DO UPDATE SET 
                latitude = $2, longitude = $3, is_online = TRUE, last_updated = CURRENT_TIMESTAMP
        ''', user['id'], location.latitude, location.longitude)
        return {"status": "updated"}

@app.post("/api/courier/online")
async def set_courier_online(is_online: bool, user: dict = Depends(get_current_user)):
    """Set courier online/offline status"""
    if user['role'] != 'courier':
        raise HTTPException(status_code=403, detail="Only couriers can update status")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        await conn.execute('''
            UPDATE courier_locations SET is_online = $1, last_updated = CURRENT_TIMESTAMP
            WHERE courier_id = $2
        ''', is_online, user['id'])
        return {"status": "updated", "is_online": is_online}

@app.get("/api/courier/{courier_id}/location")
async def get_courier_location(courier_id: int, user: dict = Depends(get_current_user)):
    """Get courier's current location (for buyers tracking their delivery)"""
    pool = await get_db()
    async with pool.acquire() as conn:
        # Verify user has an active order with this courier
        has_order = await conn.fetchval('''
            SELECT id FROM orders WHERE courier_id = $1 AND buyer_id = $2 
            AND status IN ('picked_up', 'in_transit')
        ''', courier_id, user['id'])
        
        if not has_order and user['role'] not in ['admin', 'seller']:
            raise HTTPException(status_code=403, detail="Not authorized to track this courier")
        
        location = await conn.fetchrow('''
            SELECT latitude, longitude, is_online, last_updated 
            FROM courier_locations WHERE courier_id = $1
        ''', courier_id)
        
        if not location:
            raise HTTPException(status_code=404, detail="Courier location not found")
        
        return dict(location)

@app.get("/api/couriers/online")
async def get_online_couriers(user: dict = Depends(get_current_user)):
    """Get all online couriers (for admin/auto-assignment)"""
    if user['role'] not in ['admin', 'seller']:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        couriers = await conn.fetch('''
            SELECT cl.*, u.name, u.phone 
            FROM courier_locations cl
            JOIN users u ON cl.courier_id = u.id
            WHERE cl.is_online = TRUE 
            AND cl.last_updated > NOW() - INTERVAL '10 minutes'
        ''')
        return [dict(c) for c in couriers]

# ==================== USER VERIFICATION ====================

class VerificationSubmit(BaseModel):
    document_type: str  # 'passport', 'driver_license', 'business_license'
    document_url: str

@app.post("/api/verification/submit")
async def submit_verification(data: VerificationSubmit, user: dict = Depends(get_current_user)):
    """Submit verification document"""
    if user['role'] not in ['seller', 'courier']:
        raise HTTPException(status_code=403, detail="Only sellers and couriers need verification")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        # Check if already has pending verification
        existing = await conn.fetchval('''
            SELECT id FROM user_verifications 
            WHERE user_id = $1 AND document_type = $2 AND status = 'pending'
        ''', user['id'], data.document_type)
        
        if existing:
            raise HTTPException(status_code=400, detail="Already have pending verification for this document type")
        
        verification_id = await conn.fetchval('''
            INSERT INTO user_verifications (user_id, document_type, document_url, status)
            VALUES ($1, $2, $3, 'pending') RETURNING id
        ''', user['id'], data.document_type, data.document_url)
        
        return {"id": verification_id, "status": "pending"}

@app.get("/api/verification/status")
async def get_verification_status(user: dict = Depends(get_current_user)):
    """Get user's verification status"""
    pool = await get_db()
    async with pool.acquire() as conn:
        verifications = await conn.fetch('''
            SELECT id, document_type, status, admin_notes, created_at, reviewed_at
            FROM user_verifications WHERE user_id = $1
            ORDER BY created_at DESC
        ''', user['id'])
        return [dict(v) for v in verifications]

@app.get("/api/admin/verifications")
async def get_pending_verifications(user: dict = Depends(get_current_user)):
    """Get all pending verifications (admin only)"""
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        verifications = await conn.fetch('''
            SELECT v.*, u.name, u.email, u.role, u.phone
            FROM user_verifications v
            JOIN users u ON v.user_id = u.id
            WHERE v.status = 'pending'
            ORDER BY v.created_at ASC
        ''')
        return [dict(v) for v in verifications]

@app.put("/api/admin/verifications/{verification_id}")
async def review_verification(verification_id: int, status: str, notes: Optional[str] = None, user: dict = Depends(get_current_user)):
    """Approve or reject verification (admin only)"""
    if user['role'] != 'admin':
        raise HTTPException(status_code=403, detail="Admin access required")
    
    if status not in ['approved', 'rejected']:
        raise HTTPException(status_code=400, detail="Status must be 'approved' or 'rejected'")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        verification = await conn.fetchrow('SELECT * FROM user_verifications WHERE id = $1', verification_id)
        if not verification:
            raise HTTPException(status_code=404, detail="Verification not found")
        
        await conn.execute('''
            UPDATE user_verifications 
            SET status = $1, admin_notes = $2, reviewed_at = CURRENT_TIMESTAMP
            WHERE id = $3
        ''', status, notes, verification_id)
        
        # If approved, update user's is_verified status
        if status == 'approved':
            await conn.execute('UPDATE users SET is_verified = TRUE WHERE id = $1', verification['user_id'])
            # Send push notification
            await send_push_notification(
                verification['user_id'],
                'Верификация одобрена!',
                'Ваши документы проверены и одобрены.'
            )
        else:
            await send_push_notification(
                verification['user_id'],
                'Верификация отклонена',
                notes or 'Пожалуйста, загрузите документы повторно.'
            )
        
        return {"status": status}

# ==================== DELIVERY FEE CALCULATION ====================

import math

def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance between two points using Haversine formula (in km)"""
    R = 6371  # Earth's radius in km
    
    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)
    
    a = math.sin(delta_lat/2)**2 + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon/2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a))
    
    return R * c

@app.get("/api/delivery/calculate")
async def calculate_delivery_fee(
    seller_lat: float, seller_lon: float,
    buyer_lat: float, buyer_lon: float
):
    """Calculate delivery fee based on distance"""
    pool = await get_db()
    async with pool.acquire() as conn:
        # Get base fee and per-km rate from settings
        base_fee_row = await conn.fetchrow("SELECT setting_value FROM platform_settings WHERE setting_key = 'courier_fee'")
        base_fee = float(base_fee_row['setting_value']) if base_fee_row else 15000
        
        # Calculate distance
        distance = calculate_distance(seller_lat, seller_lon, buyer_lat, buyer_lon)
        
        # Fee calculation: base fee + 2000 sum per km after first 3km
        if distance <= 3:
            delivery_fee = base_fee
        else:
            extra_km = distance - 3
            delivery_fee = base_fee + (extra_km * 2000)
        
        # Round to nearest 500
        delivery_fee = round(delivery_fee / 500) * 500
        
        return {
            "distance_km": round(distance, 2),
            "delivery_fee": delivery_fee,
            "base_fee": base_fee,
            "extra_km_rate": 2000
        }

# ==================== AUTO-ASSIGNMENT OF COURIERS ====================

@app.post("/api/orders/{order_id}/auto-assign")
async def auto_assign_courier(order_id: int, user: dict = Depends(get_current_user)):
    """Auto-assign nearest available courier to order"""
    if user['role'] not in ['admin', 'seller']:
        raise HTTPException(status_code=403, detail="Not authorized")
    
    pool = await get_db()
    async with pool.acquire() as conn:
        # Get order details
        order = await conn.fetchrow('SELECT * FROM orders WHERE id = $1', order_id)
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        
        if order['status'] != 'ready':
            raise HTTPException(status_code=400, detail="Order must be in 'ready' status for courier assignment")
        
        if order['courier_id']:
            raise HTTPException(status_code=400, detail="Order already has a courier assigned")
        
        # Get seller location
        seller = await conn.fetchrow('SELECT latitude, longitude FROM users WHERE id = $1', order['seller_id'])
        if not seller or not seller['latitude']:
            raise HTTPException(status_code=400, detail="Seller location not set")
        
        # Find nearest online courier
        couriers = await conn.fetch('''
            SELECT cl.courier_id, cl.latitude, cl.longitude, u.name
            FROM courier_locations cl
            JOIN users u ON cl.courier_id = u.id
            WHERE cl.is_online = TRUE 
            AND cl.last_updated > NOW() - INTERVAL '10 minutes'
            AND u.is_verified = TRUE
        ''')
        
        if not couriers:
            return {"status": "no_couriers", "message": "No available couriers online"}
        
        # Calculate distances and find nearest
        nearest_courier = None
        min_distance = float('inf')
        
        for courier in couriers:
            distance = calculate_distance(
                seller['latitude'], seller['longitude'],
                courier['latitude'], courier['longitude']
            )
            if distance < min_distance:
                min_distance = distance
                nearest_courier = courier
        
        if nearest_courier:
            # Assign courier to order
            await conn.execute('''
                UPDATE orders SET courier_id = $1, status = 'assigned'
                WHERE id = $2
            ''', nearest_courier['courier_id'], order_id)
            
            # Send push notification to courier
            await send_push_notification(
                nearest_courier['courier_id'],
                'Новая доставка!',
                f'Вам назначен заказ #{order_id}. Расстояние: {min_distance:.1f} км'
            )
            
            return {
                "status": "assigned",
                "courier_id": nearest_courier['courier_id'],
                "courier_name": nearest_courier['name'],
                "distance_km": round(min_distance, 2)
            }
        
        return {"status": "no_couriers", "message": "No suitable couriers found"}

# ==================== MEDIA UPLOAD ====================

@app.post("/api/upload/image")
async def upload_image(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    """Upload an image file and return public URL"""
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="File must be an image")
    
    # Generate unique filename
    ext = file.filename.split('.')[-1] if '.' in file.filename else 'jpg'
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = MEDIA_DIR / "images" / filename
    filepath.parent.mkdir(parents=True, exist_ok=True)
    
    # Save file
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Return public URL
    public_url = f"https://165.232.81.31/media/images/{filename}"
    return {"url": public_url, "filename": filename}

@app.post("/api/upload/video")
async def upload_video(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    """Upload a video file and return public URL"""
    if not file.content_type.startswith('video/'):
        raise HTTPException(status_code=400, detail="File must be a video")
    
    # Generate unique filename
    ext = file.filename.split('.')[-1] if '.' in file.filename else 'mp4'
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = MEDIA_DIR / "videos" / filename
    filepath.parent.mkdir(parents=True, exist_ok=True)
    
    # Save file
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Return public URL
    public_url = f"https://165.232.81.31/media/videos/{filename}"
    return {"url": public_url, "filename": filename}

@app.post("/api/upload/document")
async def upload_document(file: UploadFile = File(...), user: dict = Depends(get_current_user)):
    """Upload a document file (for verification) and return public URL"""
    # Generate unique filename
    ext = file.filename.split('.')[-1] if '.' in file.filename else 'pdf'
    filename = f"{uuid.uuid4()}.{ext}"
    filepath = MEDIA_DIR / "documents" / filename
    filepath.parent.mkdir(parents=True, exist_ok=True)
    
    # Save file
    with open(filepath, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    
    # Return public URL
    public_url = f"https://165.232.81.31/media/documents/{filename}"
    return {"url": public_url, "filename": filename}

# ==================== REAL WEBSOCKET CHAT ====================

# Store active WebSocket connections
active_connections: Dict[int, WebSocket] = {}

@app.websocket("/ws/chat/{user_id}")
async def websocket_chat(websocket: WebSocket, user_id: int):
    """WebSocket endpoint for real-time chat"""
    await websocket.accept()
    active_connections[user_id] = websocket
    logger.info(f"WebSocket connected: user {user_id}")
    
    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Save message to database
            pool = await get_db()
            async with pool.acquire() as conn:
                message_id = await conn.fetchval('''
                    INSERT INTO messages (sender_id, receiver_id, content, image_url)
                    VALUES ($1, $2, $3, $4) RETURNING id
                ''', user_id, message_data.get('receiver_id'), 
                    message_data.get('content'), message_data.get('image_url'))
                
                # Get full message with sender info
                message = await conn.fetchrow('''
                    SELECT m.*, u.name as sender_name 
                    FROM messages m JOIN users u ON m.sender_id = u.id
                    WHERE m.id = $1
                ''', message_id)
                
                response = {
                    "type": "message",
                    "data": {
                        "id": message['id'],
                        "sender_id": message['sender_id'],
                        "sender_name": message['sender_name'],
                        "receiver_id": message['receiver_id'],
                        "content": message['content'],
                        "image_url": message['image_url'],
                        "created_at": str(message['created_at'])
                    }
                }
                
                # Send to receiver if online
                receiver_id = message_data.get('receiver_id')
                if receiver_id in active_connections:
                    await active_connections[receiver_id].send_text(json.dumps(response))
                
                # Send confirmation to sender
                await websocket.send_text(json.dumps(response))
                
    except WebSocketDisconnect:
        logger.info(f"WebSocket disconnected: user {user_id}")
        if user_id in active_connections:
            del active_connections[user_id]
    except Exception as e:
        logger.error(f"WebSocket error for user {user_id}: {e}")
        if user_id in active_connections:
            del active_connections[user_id]

@app.get("/api/chat/online")
async def get_online_users(user: dict = Depends(get_current_user)):
    """Get list of online users for chat"""
    return {"online_users": list(active_connections.keys())}

# ==================== ENHANCED ORDER STATUS WITH NOTIFICATIONS ====================

@app.put("/api/orders/{order_id}/status")
async def update_order_status_with_notification(order_id: int, status: str, user: dict = Depends(get_current_user)):
    """Update order status and send push notifications"""
    pool = await get_db()
    async with pool.acquire() as conn:
        order = await conn.fetchrow('SELECT * FROM orders WHERE id = $1', order_id)
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        
        # Verify authorization
        if user['role'] == 'seller' and order['seller_id'] != user['id']:
            raise HTTPException(status_code=403, detail="Not authorized")
        if user['role'] == 'courier' and order['courier_id'] != user['id']:
            raise HTTPException(status_code=403, detail="Not authorized")
        
        # Update status
        if user['role'] == 'courier':
            await conn.execute('UPDATE orders SET status = $1, courier_id = $2 WHERE id = $3', status, user['id'], order_id)
        else:
            await conn.execute('UPDATE orders SET status = $1 WHERE id = $2', status, order_id)
        
        # Send push notifications based on status
        notification_map = {
            'accepted': ('Заказ принят!', 'Продавец принял ваш заказ', order['buyer_id']),
            'ready': ('Заказ готов!', 'Ваш заказ готов к выдаче', order['buyer_id']),
            'picked_up': ('Курьер забрал заказ', 'Ваш заказ в пути', order['buyer_id']),
            'in_transit': ('Заказ в пути', 'Курьер везёт ваш заказ', order['buyer_id']),
            'delivered': ('Заказ доставлен!', 'Спасибо за покупку!', order['buyer_id']),
            'rejected': ('Заказ отклонён', 'К сожалению, продавец отклонил заказ', order['buyer_id']),
        }
        
        if status in notification_map:
            title, body, recipient_id = notification_map[status]
            await send_push_notification(recipient_id, title, body)
        
        # Notify seller when courier picks up
        if status == 'picked_up':
            await send_push_notification(
                order['seller_id'],
                'Курьер забрал заказ',
                f'Заказ #{order_id} передан курьеру'
            )
        
        return {"status": status}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
