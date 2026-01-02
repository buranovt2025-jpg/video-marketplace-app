import { Router } from 'express';
import authRoutes from './authRoutes';
import productRoutes from './productRoutes';
import videoRoutes from './videoRoutes';
import orderRoutes from './orderRoutes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/products', productRoutes);
router.use('/videos', videoRoutes);
router.use('/orders', orderRoutes);

router.get('/health', (_req, res) => {
  res.json({
    success: true,
    message: 'GoGoMarket API is running',
    timestamp: new Date().toISOString(),
  });
});

export default router;
