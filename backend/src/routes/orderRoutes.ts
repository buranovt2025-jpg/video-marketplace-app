import { Router } from 'express';
import {
  createOrder,
  getOrders,
  getOrderById,
  confirmOrder,
  assignCourier,
  scanPickupQr,
  confirmDelivery,
  cancelOrder,
  getAvailableOrdersForCourier,
  acceptOrderAsCourier,
} from '../controllers/orderController';
import { authenticate, authorize } from '../middleware/auth';
import { validateOrder } from '../middleware/validation';
import { UserRole } from '../types';

const router = Router();

router.get('/', authenticate, getOrders);
router.get('/available', authenticate, authorize(UserRole.COURIER), getAvailableOrdersForCourier);
router.get('/:id', authenticate, getOrderById);
router.post('/', authenticate, authorize(UserRole.BUYER), validateOrder, createOrder);
router.post('/:id/confirm', authenticate, authorize(UserRole.SELLER, UserRole.ADMIN), confirmOrder);
router.post('/:id/assign-courier', authenticate, authorize(UserRole.SELLER, UserRole.ADMIN), assignCourier);
router.post('/:id/accept', authenticate, authorize(UserRole.COURIER), acceptOrderAsCourier);
router.post('/:id/pickup', authenticate, authorize(UserRole.COURIER), scanPickupQr);
router.post('/:id/deliver', authenticate, authorize(UserRole.COURIER), confirmDelivery);
router.post('/:id/cancel', authenticate, cancelOrder);

export default router;
