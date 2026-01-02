import { Response } from 'express';
import { Op } from 'sequelize';
import { Product, User, Video, Review } from '../models';
import { AuthRequest } from '../middleware/auth';
import { UserRole } from '../types';

export const createProduct = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user || user.role !== UserRole.SELLER) {
      res.status(403).json({
        success: false,
        error: 'Only sellers can create products.',
      });
      return;
    }

    const {
      title,
      titleRu,
      titleUz,
      description,
      descriptionRu,
      descriptionUz,
      price,
      originalPrice,
      category,
      sizes,
      colors,
      stock,
      images,
    } = req.body;

    const product = await Product.create({
      sellerId: user.id,
      title,
      titleRu,
      titleUz,
      description,
      descriptionRu,
      descriptionUz,
      price,
      originalPrice,
      currency: 'UZS',
      category,
      sizes,
      colors,
      stock: stock || 0,
      images: images || [],
    });

    res.status(201).json({
      success: true,
      data: product,
    });
  } catch (error) {
    console.error('Create product error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create product',
    });
  }
};

export const getProducts = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const {
      page = 1,
      limit = 20,
      category,
      minPrice,
      maxPrice,
      search,
      sellerId,
      sortBy = 'createdAt',
      sortOrder = 'DESC',
    } = req.query;

    const offset = (Number(page) - 1) * Number(limit);

    const where: Record<string | symbol, unknown> = { isActive: true };

    if (category) {
      where.category = category;
    }

    if (minPrice || maxPrice) {
      where.price = {};
      if (minPrice) (where.price as Record<symbol, unknown>)[Op.gte] = Number(minPrice);
      if (maxPrice) (where.price as Record<symbol, unknown>)[Op.lte] = Number(maxPrice);
    }

    if (search) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } },
      ];
    }

    if (sellerId) {
      where.sellerId = sellerId;
    }

    const { count, rows: products } = await Product.findAndCountAll({
      where,
      include: [
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName', 'avatar'],
        },
      ],
      order: [[String(sortBy), String(sortOrder)]],
      limit: Number(limit),
      offset,
    });

    res.json({
      success: true,
      data: products,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: count,
        totalPages: Math.ceil(count / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Get products error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get products',
    });
  }
};

export const getProductById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const product = await Product.findByPk(id, {
      include: [
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName', 'avatar', 'phone'],
        },
        {
          model: Video,
          as: 'videos',
          where: { isActive: true },
          required: false,
        },
        {
          model: Review,
          as: 'reviews',
          include: [
            {
              model: User,
              as: 'buyer',
              attributes: ['id', 'firstName', 'lastName', 'avatar'],
            },
          ],
          limit: 10,
          order: [['createdAt', 'DESC']],
        },
      ],
    });

    if (!product) {
      res.status(404).json({
        success: false,
        error: 'Product not found.',
      });
      return;
    }

    res.json({
      success: true,
      data: product,
    });
  } catch (error) {
    console.error('Get product error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get product',
    });
  }
};

export const updateProduct = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;

    const product = await Product.findByPk(id);
    if (!product) {
      res.status(404).json({
        success: false,
        error: 'Product not found.',
      });
      return;
    }

    if (user?.role !== UserRole.ADMIN && product.sellerId !== user?.id) {
      res.status(403).json({
        success: false,
        error: 'You can only update your own products.',
      });
      return;
    }

    const {
      title,
      titleRu,
      titleUz,
      description,
      descriptionRu,
      descriptionUz,
      price,
      originalPrice,
      category,
      sizes,
      colors,
      stock,
      images,
      isActive,
    } = req.body;

    if (title !== undefined) product.title = title;
    if (titleRu !== undefined) product.titleRu = titleRu;
    if (titleUz !== undefined) product.titleUz = titleUz;
    if (description !== undefined) product.description = description;
    if (descriptionRu !== undefined) product.descriptionRu = descriptionRu;
    if (descriptionUz !== undefined) product.descriptionUz = descriptionUz;
    if (price !== undefined) product.price = price;
    if (originalPrice !== undefined) product.originalPrice = originalPrice;
    if (category !== undefined) product.category = category;
    if (sizes !== undefined) product.sizes = sizes;
    if (colors !== undefined) product.colors = colors;
    if (stock !== undefined) product.stock = stock;
    if (images !== undefined) product.images = images;
    if (isActive !== undefined) product.isActive = isActive;

    await product.save();

    res.json({
      success: true,
      data: product,
    });
  } catch (error) {
    console.error('Update product error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update product',
    });
  }
};

export const deleteProduct = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;

    const product = await Product.findByPk(id);
    if (!product) {
      res.status(404).json({
        success: false,
        error: 'Product not found.',
      });
      return;
    }

    if (user?.role !== UserRole.ADMIN && product.sellerId !== user?.id) {
      res.status(403).json({
        success: false,
        error: 'You can only delete your own products.',
      });
      return;
    }

    product.isActive = false;
    await product.save();

    res.json({
      success: true,
      message: 'Product deleted successfully.',
    });
  } catch (error) {
    console.error('Delete product error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete product',
    });
  }
};

export const getCategories = async (_req: AuthRequest, res: Response): Promise<void> => {
  try {
    const categories = await Product.findAll({
      attributes: ['category'],
      group: ['category'],
      where: { isActive: true },
    });

    res.json({
      success: true,
      data: categories.map((c) => c.category),
    });
  } catch (error) {
    console.error('Get categories error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get categories',
    });
  }
};

export const getSellerProducts = async (req: AuthRequest, res: Response): Promise<void> => {
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

    const { count, rows: products } = await Product.findAndCountAll({
      where: { sellerId: user.id },
      order: [['createdAt', 'DESC']],
      limit: Number(limit),
      offset,
    });

    res.json({
      success: true,
      data: products,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: count,
        totalPages: Math.ceil(count / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Get seller products error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get seller products',
    });
  }
};
