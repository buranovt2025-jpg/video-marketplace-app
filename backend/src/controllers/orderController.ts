import { Response } from 'express';
import { Order, Product, User, Transaction, Video } from '../models';
import { AuthRequest } from '../middleware/auth';
import { OrderStatus, PaymentStatus, TransactionType, UserRole } from '../types';
import { config } from '../config';
import qrService from '../services/qrService';
import smsService from '../services/smsService';

export const createOrder = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user) {
      res.status(401).json({
        success: false,
        error: 'Authentication required.',
      });
      return;
    }

    const {
      productId,
      videoId,
      quantity,
      paymentMethod,
      shippingAddress,
      shippingCity,
      shippingPhone,
      buyerNote,
    } = req.body;

    const product = await Product.findByPk(productId);
    if (!product || !product.isActive) {
      res.status(404).json({
        success: false,
        error: 'Product not found or unavailable.',
      });
      return;
    }

    if (product.stock < quantity) {
      res.status(400).json({
        success: false,
        error: 'Insufficient stock.',
      });
      return;
    }

    const unitPrice = Number(product.price);
    const totalAmount = unitPrice * quantity;
    const courierFee = config.courierFeeDefault;
    const platformCommission = totalAmount * config.platformCommission;
    const sellerAmount = totalAmount - platformCommission;

    const { qrCode: sellerQrCode } = await qrService.generateSellerQr('temp');

    const order = await Order.create({
      buyerId: user.id,
      sellerId: product.sellerId,
      productId,
      videoId,
      quantity,
      unitPrice,
      totalAmount: totalAmount + courierFee,
      courierFee,
      platformCommission,
      sellerAmount,
      currency: 'UZS',
      status: OrderStatus.PENDING,
      paymentMethod,
      paymentStatus: PaymentStatus.PENDING,
      shippingAddress,
      shippingCity,
      shippingPhone,
      buyerNote,
      sellerQrCode,
    });

    const { qrCode: updatedSellerQr } = await qrService.generateSellerQr(order.id);
    order.sellerQrCode = updatedSellerQr;
    await order.save();

    product.stock -= quantity;
    await product.save();

    await Transaction.create({
      orderId: order.id,
      userId: user.id,
      type: TransactionType.PAYMENT,
      amount: totalAmount + courierFee,
      currency: 'UZS',
      status: PaymentStatus.PENDING,
      description: `Payment for order ${order.orderNumber}`,
    });

    res.status(201).json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Create order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create order',
    });
  }
};

export const getOrders = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user) {
      res.status(401).json({
        success: false,
        error: 'Authentication required.',
      });
      return;
    }

    const { page = 1, limit = 20, status } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const where: Record<string, unknown> = {};

    if (user.role === UserRole.BUYER) {
      where.buyerId = user.id;
    } else if (user.role === UserRole.SELLER) {
      where.sellerId = user.id;
    } else if (user.role === UserRole.COURIER) {
      where.courierId = user.id;
    }

    if (status) {
      where.status = status;
    }

    const { count, rows: orders } = await Order.findAndCountAll({
      where,
      include: [
        {
          model: Product,
          as: 'product',
          attributes: ['id', 'title', 'images', 'price'],
        },
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'firstName', 'lastName', 'phone'],
        },
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName', 'phone'],
        },
        {
          model: User,
          as: 'courier',
          attributes: ['id', 'firstName', 'lastName', 'phone'],
        },
      ],
      order: [['createdAt', 'DESC']],
      limit: Number(limit),
      offset,
    });

    res.json({
      success: true,
      data: orders,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: count,
        totalPages: Math.ceil(count / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Get orders error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get orders',
    });
  }
};

export const getOrderById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;

    const order = await Order.findByPk(id, {
      include: [
        {
          model: Product,
          as: 'product',
        },
        {
          model: Video,
          as: 'video',
        },
        {
          model: User,
          as: 'buyer',
          attributes: ['id', 'firstName', 'lastName', 'phone', 'avatar'],
        },
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName', 'phone', 'avatar'],
        },
        {
          model: User,
          as: 'courier',
          attributes: ['id', 'firstName', 'lastName', 'phone', 'avatar'],
        },
        {
          model: Transaction,
          as: 'transactions',
        },
      ],
    });

    if (!order) {
      res.status(404).json({
        success: false,
        error: 'Order not found.',
      });
      return;
    }

    if (
      user?.role !== UserRole.ADMIN &&
      order.buyerId !== user?.id &&
      order.sellerId !== user?.id &&
      order.courierId !== user?.id
    ) {
      res.status(403).json({
        success: false,
        error: 'Access denied.',
      });
      return;
    }

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Get order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get order',
    });
  }
};

export const confirmOrder = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;

    const order = await Order.findByPk(id);
    if (!order) {
      res.status(404).json({
        success: false,
        error: 'Order not found.',
      });
      return;
    }

    if (order.sellerId !== user?.id && user?.role !== UserRole.ADMIN) {
      res.status(403).json({
        success: false,
        error: 'Only the seller can confirm this order.',
      });
      return;
    }

    if (order.status !== OrderStatus.PENDING) {
      res.status(400).json({
        success: false,
        error: 'Order cannot be confirmed in current status.',
      });
      return;
    }

    order.status = OrderStatus.CONFIRMED;
    await order.save();

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Confirm order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to confirm order',
    });
  }
};

export const assignCourier = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;
    const { courierId } = req.body;

    const order = await Order.findByPk(id);
    if (!order) {
      res.status(404).json({
        success: false,
        error: 'Order not found.',
      });
      return;
    }

    if (order.sellerId !== user?.id && user?.role !== UserRole.ADMIN) {
      res.status(403).json({
        success: false,
        error: 'Only the seller or admin can assign a courier.',
      });
      return;
    }

    const courier = await User.findByPk(courierId);
    if (!courier || courier.role !== UserRole.COURIER) {
      res.status(404).json({
        success: false,
        error: 'Courier not found.',
      });
      return;
    }

    const { qrCode: courierQrCode } = await qrService.generateCourierQr(order.id);
    const deliveryCode = smsService.generateDeliveryCode();

    order.courierId = courierId;
    order.courierQrCode = courierQrCode;
    order.deliveryCode = deliveryCode;
    await order.save();

    await smsService.sendDeliveryCode(order.shippingPhone, deliveryCode, order.orderNumber);

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Assign courier error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to assign courier',
    });
  }
};

export const scanPickupQr = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;
    const { qrData } = req.body;

    if (user?.role !== UserRole.COURIER) {
      res.status(403).json({
        success: false,
        error: 'Only couriers can scan pickup QR codes.',
      });
      return;
    }

    const order = await Order.findByPk(id);
    if (!order) {
      res.status(404).json({
        success: false,
        error: 'Order not found.',
      });
      return;
    }

    if (order.courierId !== user.id) {
      res.status(403).json({
        success: false,
        error: 'This order is not assigned to you.',
      });
      return;
    }

    const parsedQr = qrService.parseQrCode(qrData);
    if (!parsedQr || !qrService.validateQrCode(parsedQr, order.id, 'seller_pickup')) {
      res.status(400).json({
        success: false,
        error: 'Invalid QR code.',
      });
      return;
    }

    order.status = OrderStatus.PICKED_UP;
    order.pickedUpAt = new Date();
    await order.save();

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Scan pickup QR error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to process QR scan',
    });
  }
};

export const confirmDelivery = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;
    const { qrData, deliveryCode } = req.body;

    if (user?.role !== UserRole.COURIER) {
      res.status(403).json({
        success: false,
        error: 'Only couriers can confirm delivery.',
      });
      return;
    }

    const order = await Order.findByPk(id);
    if (!order) {
      res.status(404).json({
        success: false,
        error: 'Order not found.',
      });
      return;
    }

    if (order.courierId !== user.id) {
      res.status(403).json({
        success: false,
        error: 'This order is not assigned to you.',
      });
      return;
    }

    if (order.status !== OrderStatus.PICKED_UP && order.status !== OrderStatus.IN_TRANSIT) {
      res.status(400).json({
        success: false,
        error: 'Order must be picked up before delivery.',
      });
      return;
    }

    let isValid = false;

    if (qrData) {
      const parsedQr = qrService.parseQrCode(qrData);
      isValid = !!parsedQr && qrService.validateQrCode(parsedQr, order.id, 'courier_delivery');
    }

    if (!isValid && deliveryCode) {
      isValid = order.deliveryCode === deliveryCode;
    }

    if (!isValid) {
      res.status(400).json({
        success: false,
        error: 'Invalid QR code or delivery code.',
      });
      return;
    }

    order.status = OrderStatus.DELIVERED;
    order.deliveredAt = new Date();
    order.paymentStatus = PaymentStatus.COMPLETED;
    await order.save();

    await Transaction.create({
      orderId: order.id,
      userId: order.sellerId,
      type: TransactionType.SELLER_PAYOUT,
      amount: Number(order.sellerAmount),
      currency: 'UZS',
      status: PaymentStatus.COMPLETED,
      description: `Seller payout for order ${order.orderNumber}`,
    });

    await Transaction.create({
      orderId: order.id,
      userId: order.courierId,
      type: TransactionType.COURIER_PAYOUT,
      amount: Number(order.courierFee),
      currency: 'UZS',
      status: PaymentStatus.COMPLETED,
      description: `Courier fee for order ${order.orderNumber}`,
    });

    await Transaction.create({
      orderId: order.id,
      type: TransactionType.PLATFORM_COMMISSION,
      amount: Number(order.platformCommission),
      currency: 'UZS',
      status: PaymentStatus.COMPLETED,
      description: `Platform commission for order ${order.orderNumber}`,
    });

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Confirm delivery error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to confirm delivery',
    });
  }
};

export const cancelOrder = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;
    const { reason } = req.body;

    const order = await Order.findByPk(id);
    if (!order) {
      res.status(404).json({
        success: false,
        error: 'Order not found.',
      });
      return;
    }

    if (
      order.buyerId !== user?.id &&
      order.sellerId !== user?.id &&
      user?.role !== UserRole.ADMIN
    ) {
      res.status(403).json({
        success: false,
        error: 'Access denied.',
      });
      return;
    }

    if (order.status === OrderStatus.DELIVERED || order.status === OrderStatus.CANCELLED) {
      res.status(400).json({
        success: false,
        error: 'Order cannot be cancelled.',
      });
      return;
    }

    const product = await Product.findByPk(order.productId);
    if (product) {
      product.stock += order.quantity;
      await product.save();
    }

    order.status = OrderStatus.CANCELLED;
    order.cancelledAt = new Date();
    order.cancelReason = reason;
    order.paymentStatus = PaymentStatus.REFUNDED;
    await order.save();

    await Transaction.create({
      orderId: order.id,
      userId: order.buyerId,
      type: TransactionType.REFUND,
      amount: Number(order.totalAmount),
      currency: 'UZS',
      status: PaymentStatus.COMPLETED,
      description: `Refund for cancelled order ${order.orderNumber}`,
    });

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Cancel order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to cancel order',
    });
  }
};

export const getAvailableOrdersForCourier = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (user?.role !== UserRole.COURIER) {
      res.status(403).json({
        success: false,
        error: 'Only couriers can view available orders.',
      });
      return;
    }

    const { page = 1, limit = 20, city } = req.query;
    const offset = (Number(page) - 1) * Number(limit);

    const where: Record<string, unknown> = {
      status: OrderStatus.CONFIRMED,
      courierId: null,
    };

    if (city) {
      where.shippingCity = city;
    }

    const { count, rows: orders } = await Order.findAndCountAll({
      where,
      include: [
        {
          model: Product,
          as: 'product',
          attributes: ['id', 'title', 'images'],
        },
        {
          model: User,
          as: 'seller',
          attributes: ['id', 'firstName', 'lastName'],
        },
      ],
      order: [['createdAt', 'ASC']],
      limit: Number(limit),
      offset,
    });

    res.json({
      success: true,
      data: orders,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total: count,
        totalPages: Math.ceil(count / Number(limit)),
      },
    });
  } catch (error) {
    console.error('Get available orders error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get available orders',
    });
  }
};

export const acceptOrderAsCourier = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    const { id } = req.params;

    if (user?.role !== UserRole.COURIER) {
      res.status(403).json({
        success: false,
        error: 'Only couriers can accept orders.',
      });
      return;
    }

    const order = await Order.findByPk(id);
    if (!order) {
      res.status(404).json({
        success: false,
        error: 'Order not found.',
      });
      return;
    }

    if (order.status !== OrderStatus.CONFIRMED || order.courierId) {
      res.status(400).json({
        success: false,
        error: 'Order is not available for pickup.',
      });
      return;
    }

    const { qrCode: courierQrCode } = await qrService.generateCourierQr(order.id);
    const deliveryCode = smsService.generateDeliveryCode();

    order.courierId = user.id;
    order.courierQrCode = courierQrCode;
    order.deliveryCode = deliveryCode;
    await order.save();

    await smsService.sendDeliveryCode(order.shippingPhone, deliveryCode, order.orderNumber);

    res.json({
      success: true,
      data: order,
    });
  } catch (error) {
    console.error('Accept order error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to accept order',
    });
  }
};
