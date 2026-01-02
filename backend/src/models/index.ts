import sequelize from '../config/database';
import User from './User';
import Product from './Product';
import Video from './Video';
import Order from './Order';
import Transaction from './Transaction';
import Dispute from './Dispute';
import Review from './Review';
import Address from './Address';

// Define associations
User.hasMany(Product, { foreignKey: 'sellerId', as: 'products' });
Product.belongsTo(User, { foreignKey: 'sellerId', as: 'seller' });

User.hasMany(Video, { foreignKey: 'sellerId', as: 'videos' });
Video.belongsTo(User, { foreignKey: 'sellerId', as: 'seller' });

Product.hasMany(Video, { foreignKey: 'productId', as: 'videos' });
Video.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

User.hasMany(Order, { foreignKey: 'buyerId', as: 'purchases' });
User.hasMany(Order, { foreignKey: 'sellerId', as: 'sales' });
User.hasMany(Order, { foreignKey: 'courierId', as: 'deliveries' });
Order.belongsTo(User, { foreignKey: 'buyerId', as: 'buyer' });
Order.belongsTo(User, { foreignKey: 'sellerId', as: 'seller' });
Order.belongsTo(User, { foreignKey: 'courierId', as: 'courier' });

Order.belongsTo(Product, { foreignKey: 'productId', as: 'product' });
Product.hasMany(Order, { foreignKey: 'productId', as: 'orders' });

Order.belongsTo(Video, { foreignKey: 'videoId', as: 'video' });
Video.hasMany(Order, { foreignKey: 'videoId', as: 'orders' });

Order.hasMany(Transaction, { foreignKey: 'orderId', as: 'transactions' });
Transaction.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });

User.hasMany(Transaction, { foreignKey: 'userId', as: 'transactions' });
Transaction.belongsTo(User, { foreignKey: 'userId', as: 'user' });

Order.hasOne(Dispute, { foreignKey: 'orderId', as: 'dispute' });
Dispute.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });

User.hasMany(Dispute, { foreignKey: 'reporterId', as: 'reportedDisputes' });
Dispute.belongsTo(User, { foreignKey: 'reporterId', as: 'reporter' });

User.hasMany(Dispute, { foreignKey: 'assignedAdminId', as: 'assignedDisputes' });
Dispute.belongsTo(User, { foreignKey: 'assignedAdminId', as: 'assignedAdmin' });

Order.hasOne(Review, { foreignKey: 'orderId', as: 'review' });
Review.belongsTo(Order, { foreignKey: 'orderId', as: 'order' });

Product.hasMany(Review, { foreignKey: 'productId', as: 'reviews' });
Review.belongsTo(Product, { foreignKey: 'productId', as: 'product' });

User.hasMany(Review, { foreignKey: 'buyerId', as: 'givenReviews' });
Review.belongsTo(User, { foreignKey: 'buyerId', as: 'buyer' });

User.hasMany(Review, { foreignKey: 'sellerId', as: 'receivedReviews' });
Review.belongsTo(User, { foreignKey: 'sellerId', as: 'seller' });

User.hasMany(Address, { foreignKey: 'userId', as: 'addresses' });
Address.belongsTo(User, { foreignKey: 'userId', as: 'user' });

export {
  sequelize,
  User,
  Product,
  Video,
  Order,
  Transaction,
  Dispute,
  Review,
  Address,
};

export const initializeDatabase = async (force = false) => {
  try {
    await sequelize.authenticate();
    console.log('Database connection established successfully.');
    
    await sequelize.sync({ force });
    console.log('Database synchronized successfully.');
  } catch (error) {
    console.error('Unable to connect to the database:', error);
    throw error;
  }
};
