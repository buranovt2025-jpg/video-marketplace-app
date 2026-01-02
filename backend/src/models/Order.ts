import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import { OrderStatus, PaymentMethod, PaymentStatus } from '../types';

interface OrderAttributes {
  id: string;
  orderNumber: string;
  buyerId: string;
  sellerId: string;
  courierId?: string;
  productId: string;
  videoId?: string;
  quantity: number;
  unitPrice: number;
  totalAmount: number;
  courierFee: number;
  platformCommission: number;
  sellerAmount: number;
  currency: string;
  status: OrderStatus;
  paymentMethod: PaymentMethod;
  paymentStatus: PaymentStatus;
  shippingAddress: string;
  shippingCity: string;
  shippingPhone: string;
  buyerNote?: string;
  sellerQrCode?: string;
  courierQrCode?: string;
  deliveryCode?: string;
  pickedUpAt?: Date;
  deliveredAt?: Date;
  cancelledAt?: Date;
  cancelReason?: string;
  createdAt?: Date;
  updatedAt?: Date;
}

interface OrderCreationAttributes extends Optional<OrderAttributes, 'id' | 'orderNumber' | 'courierId' | 'videoId' | 'buyerNote' | 'sellerQrCode' | 'courierQrCode' | 'deliveryCode' | 'pickedUpAt' | 'deliveredAt' | 'cancelledAt' | 'cancelReason' | 'createdAt' | 'updatedAt'> {}

class Order extends Model<OrderAttributes, OrderCreationAttributes> implements OrderAttributes {
  public id!: string;
  public orderNumber!: string;
  public buyerId!: string;
  public sellerId!: string;
  public courierId?: string;
  public productId!: string;
  public videoId?: string;
  public quantity!: number;
  public unitPrice!: number;
  public totalAmount!: number;
  public courierFee!: number;
  public platformCommission!: number;
  public sellerAmount!: number;
  public currency!: string;
  public status!: OrderStatus;
  public paymentMethod!: PaymentMethod;
  public paymentStatus!: PaymentStatus;
  public shippingAddress!: string;
  public shippingCity!: string;
  public shippingPhone!: string;
  public buyerNote?: string;
  public sellerQrCode?: string;
  public courierQrCode?: string;
  public deliveryCode?: string;
  public pickedUpAt?: Date;
  public deliveredAt?: Date;
  public cancelledAt?: Date;
  public cancelReason?: string;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

Order.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    orderNumber: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true,
    },
    buyerId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    sellerId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    courierId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    productId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'products',
        key: 'id',
      },
    },
    videoId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'videos',
        key: 'id',
      },
    },
    quantity: {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 1,
    },
    unitPrice: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: false,
    },
    totalAmount: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: false,
    },
    courierFee: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: false,
      defaultValue: 0,
    },
    platformCommission: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: false,
      defaultValue: 0,
    },
    sellerAmount: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: false,
    },
    currency: {
      type: DataTypes.STRING(3),
      defaultValue: 'UZS',
    },
    status: {
      type: DataTypes.ENUM(...Object.values(OrderStatus)),
      defaultValue: OrderStatus.PENDING,
    },
    paymentMethod: {
      type: DataTypes.ENUM(...Object.values(PaymentMethod)),
      allowNull: false,
    },
    paymentStatus: {
      type: DataTypes.ENUM(...Object.values(PaymentStatus)),
      defaultValue: PaymentStatus.PENDING,
    },
    shippingAddress: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    shippingCity: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    shippingPhone: {
      type: DataTypes.STRING(20),
      allowNull: false,
    },
    buyerNote: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    sellerQrCode: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    courierQrCode: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    deliveryCode: {
      type: DataTypes.STRING(6),
      allowNull: true,
    },
    pickedUpAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    deliveredAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    cancelledAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
    cancelReason: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
  },
  {
    sequelize,
    tableName: 'orders',
    modelName: 'Order',
    hooks: {
      beforeCreate: (order) => {
        const timestamp = Date.now().toString(36).toUpperCase();
        const random = Math.random().toString(36).substring(2, 6).toUpperCase();
        order.orderNumber = `GGM-${timestamp}-${random}`;
      },
    },
  }
);

export default Order;
