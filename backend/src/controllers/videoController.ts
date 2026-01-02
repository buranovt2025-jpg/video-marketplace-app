import { Response } from 'express';
import { Op } from 'sequelize';
import { Video, User, Product } from '../models';
import { AuthRequest } from '../middleware/auth';
import { UserRole } from '../types';

export const createVideo = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user || user.role !== UserRole.SELLER) {
      res.status(403).json({
        success: false,
        error: 'Only sellers can upload videos.',
      });
      return;
    }

    const {
      productId,
      videoUrl,
      thumbnailUrl,
      title,
      titleRu,
      titleUz,
      description,
      descriptionRu,
      descriptionUz,
      duration,
      isLive,
    } = req.body;

    if (productId) {
      const product = await Product.findByPk(productId);
      if (!product || product.sellerId !== user.id) {
        res.status(404).json({
          success: false,
          error: 'Product not found or does not belong to you.',
        });
        return;
      }
    }

    const video = await Video.create({
      sellerId: user.id,
      productId,
      videoUrl,
      thumbnailUrl,
      title,
      titleRu,
      titleUz,
      description,
      descriptionRu,
      descriptionUz,
      duration: duration || 0,
      isLive: isLive || false,
    });

    res.status(201).json({
      success: true,
      data: video,
    });
  } catch (error) {
    console.error('Create video error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create video',
    });
  }
};

export const getVideoFeed = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { page = 1, limit = 10, category } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const where: Record<string, unknown> = { isActive: true };

    let productWhere: Record<string, unknown> | undefined;
    if (category) {
      productWhere = { category, isActive: true };
    }

    const { count, rows: videos } = await Video.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName', 'avatar'],
        },
        {
          model: Product,
          as: 'product',
          where: productWhere,
          required: !!category,
        },
      ],
      order: [
        ['isLive', 'DESC'],
        ['createdAt', 'DESC'],
      ],
      limit: Number(limit),
      offset,
    });

    res.json({
      success: true,
      data: videos,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: count,
        totalPages: Math.ceil(count / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Get video feed error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get video feed',
    });
  }
};

export const getVideoById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const video = await Video.findByPk(id, {
      include: [
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName', 'avatar', 'phone'],
        },
        {
          model: Product,
          as: 'product',
        },
      ],
    });

    if (!video) {
      res.status(404).json({
        success: false,
        error: 'Video not found.',
      });
      return;
    }

    video.viewCount += 1;
    await video.save();

    res.json({
      success: true,
      data: video,
    });
  } catch (error) {
    console.error('Get video error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get video',
    });
  }
};

export const updateVideo = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;

    const video = await Video.findByPk(id);
    if (!video) {
      res.status(404).json({
        success: false,
        error: 'Video not found.',
      });
      return;
    }

    if (user?.role !== UserRole.ADMIN && video.sellerId !== user?.id) {
      res.status(403).json({
        success: false,
        error: 'You can only update your own videos.',
      });
      return;
    }

    const {
      productId,
      title,
      titleRu,
      titleUz,
      description,
      descriptionRu,
      descriptionUz,
      thumbnailUrl,
      isLive,
      isActive,
    } = req.body;

    if (productId !== undefined) video.productId = productId;
    if (title !== undefined) video.title = title;
    if (titleRu !== undefined) video.titleRu = titleRu;
    if (titleUz !== undefined) video.titleUz = titleUz;
    if (description !== undefined) video.description = description;
    if (descriptionRu !== undefined) video.descriptionRu = descriptionRu;
    if (descriptionUz !== undefined) video.descriptionUz = descriptionUz;
    if (thumbnailUrl !== undefined) video.thumbnailUrl = thumbnailUrl;
    if (isLive !== undefined) video.isLive = isLive;
    if (isActive !== undefined) video.isActive = isActive;

    await video.save();

    res.json({
      success: true,
      data: video,
    });
  } catch (error) {
    console.error('Update video error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update video',
    });
  }
};

export const deleteVideo = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;

    const video = await Video.findByPk(id);
    if (!video) {
      res.status(404).json({
        success: false,
        error: 'Video not found.',
      });
      return;
    }

    if (user?.role !== UserRole.ADMIN && video.sellerId !== user?.id) {
      res.status(403).json({
        success: false,
        error: 'You can only delete your own videos.',
      });
      return;
    }

    video.isActive = false;
    await video.save();

    res.json({
      success: true,
      message: 'Video deleted successfully.',
    });
  } catch (error) {
    console.error('Delete video error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete video',
    });
  }
};

export const likeVideo = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const video = await Video.findByPk(id);
    if (!video) {
      res.status(404).json({
        success: false,
        error: 'Video not found.',
      });
      return;
    }

    video.likeCount += 1;
    await video.save();

    res.json({
      success: true,
      data: { likeCount: video.likeCount },
    });
  } catch (error) {
    console.error('Like video error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to like video',
    });
  }
};

export const getLiveVideos = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    const videos = await Video.findAll({
      where: { isLive: true, isActive: true },
      include: [
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName', 'avatar'],
        },
        {
          model: Product,
          as: 'product',
        },
      ],
      order: [['viewCount', 'DESC']],
      limit: 20,
    });

    res.json({
      success: true,
      data: videos,
    });
  } catch (error) {
    console.error('Get live videos error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get live videos',
    });
  }
};

export const getSellerVideos = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user) {
      res.status(401).json({
        success: false,
        error: 'Authentication required.',
      });
      return;
    }

    const { page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const { count, rows: videos } = await Video.findAndCountAll({
      where: { sellerId: user.id },
      include: [
        {
          model: Product,
          as: 'product',
        },
      ],
      order: [['createdAt', 'DESC']],
      limit: Number(limit),
      offset,
    });

    res.json({
      success: true,
      data: videos,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: count,
        totalPages: Math.ceil(count / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Get seller videos error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get seller videos',
    });
  }
};
