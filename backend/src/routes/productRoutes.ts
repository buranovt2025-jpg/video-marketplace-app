import { Router } from 'express';
import {
  createProduct,
  getProducts,
  getProductById,
  updateProduct,
  deleteProduct,
  getCategories,
  getSellerProducts,
} from '../controllers/productController';
import { authenticate, authorize, optionalAuth } from '../middleware/auth';
import { validateProduct } from '../middleware/validation';
import { UserRole } from '../types';

const router = Router();

router.get('/', optionalAuth, getProducts);
router.get('/categories', getCategories);
router.get('/seller', authenticate, authorize(UserRole.SELLER), getSellerProducts);
router.get('/:id', optionalAuth, getProductById);
router.post('/', authenticate, authorize(UserRole.SELLER), validateProduct, createProduct);
router.put('/:id', authenticate, authorize(UserRole.SELLER, UserRole.ADMIN), updateProduct);
router.delete('/:id', authenticate, authorize(UserRole.SELLER, UserRole.ADMIN), deleteProduct);

export default router;
