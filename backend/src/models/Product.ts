import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';

interface ProductAttributes {
  id: string;
  sellerId: string;
  title: string;
  titleRu?: string;
  titleUz?: string;
  description: string;
  descriptionRu?: string;
  descriptionUz?: string;
  price: number;
  originalPrice?: number;
  currency: string;
  category: string;
  sizes?: string[];
  colors?: string[];
  stock: number;
  images: string[];
  isActive: boolean;
  rating: number;
  reviewCount: number;
  createdAt?: Date;
  updatedAt?: Date;
}

interface ProductCreationAttributes extends Optional<ProductAttributes, 'id' | 'titleRu' | 'titleUz' | 'descriptionRu' | 'descriptionUz' | 'originalPrice' | 'sizes' | 'colors' | 'isActive' | 'rating' | 'reviewCount' | 'createdAt' | 'updatedAt'> {}

class Product extends Model<ProductAttributes, ProductCreationAttributes> implements ProductAttributes {
  public id!: string;
  public sellerId!: string;
  public title!: string;
  public titleRu?: string;
  public titleUz?: string;
  public description!: string;
  public descriptionRu?: string;
  public descriptionUz?: string;
  public price!: number;
  public originalPrice?: number;
  public currency!: string;
  public category!: string;
  public sizes?: string[];
  public colors?: string[];
  public stock!: number;
  public images!: string[];
  public isActive!: boolean;
  public rating!: number;
  public reviewCount!: number;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

Product.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    sellerId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    title: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    titleRu: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    titleUz: {
      type: DataTypes.STRING(255),
      allowNull: true,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    descriptionRu: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    descriptionUz: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    price: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: false,
    },
    originalPrice: {
      type: DataTypes.DECIMAL(12, 2),
      allowNull: true,
    },
    currency: {
      type: DataTypes.STRING(3),
      defaultValue: 'UZS',
    },
    category: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    sizes: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: [],
    },
    colors: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: [],
    },
    stock: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
    images: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: [],
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    rating: {
      type: DataTypes.DECIMAL(2, 1),
      defaultValue: 0,
    },
    reviewCount: {
      type: DataTypes.INTEGER,
      defaultValue: 0,
    },
  },
  {
    sequelize,
    tableName: 'products',
    modelName: 'Product',
  }
);

export default Product;
