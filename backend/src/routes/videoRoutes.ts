import { Router } from 'express';
import {
  createVideo,
  getVideoFeed,
  getVideoById,
  updateVideo,
  deleteVideo,
  likeVideo,
  getLiveVideos,
  getSellerVideos,
} from '../controllers/videoController';
import { authenticate, authorize, optionalAuth } from '../middleware/auth';
import { UserRole } from '../types';

const router = Router();

router.get('/feed', optionalAuth, getVideoFeed);
router.get('/live', getLiveVideos);
router.get('/seller', authenticate, authorize(UserRole.SELLER), getSellerVideos);
router.get('/:id', optionalAuth, getVideoById);
router.post('/', authenticate, authorize(UserRole.SELLER), createVideo);
router.put('/:id', authenticate, authorize(UserRole.SELLER, UserRole.ADMIN), updateVideo);
router.delete('/:id', authenticate, authorize(UserRole.SELLER, UserRole.ADMIN), deleteVideo);
router.post('/:id/like', optionalAuth, likeVideo);

export default router;
