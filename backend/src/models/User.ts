import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import { UserRole, Language } from '../types';

interface UserAttributes {
  id: string;
  phone: string;
  email?: string;
  passwordHash: string;
  firstName: string;
  lastName: string;
  role: UserRole;
  avatar?: string;
  isVerified: boolean;
  isActive: boolean;
  language: Language;
  oneIdVerified: boolean;
  acceptedTerms: boolean;
  acceptedPrivacy: boolean;
  lastLoginAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

interface UserCreationAttributes extends Optional<UserAttributes, 'id' | 'email' | 'avatar' | 'isVerified' | 'isActive' | 'oneIdVerified' | 'acceptedTerms' | 'acceptedPrivacy' | 'lastLoginAt' | 'createdAt' | 'updatedAt'> {}

class User extends Model<UserAttributes, UserCreationAttributes> implements UserAttributes {
  public id!: string;
  public phone!: string;
  public email?: string;
  public passwordHash!: string;
  public firstName!: string;
  public lastName!: string;
  public role!: UserRole;
  public avatar?: string;
  public isVerified!: boolean;
  public isActive!: boolean;
  public language!: Language;
  public oneIdVerified!: boolean;
  public acceptedTerms!: boolean;
  public acceptedPrivacy!: boolean;
  public lastLoginAt?: Date;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

User.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    phone: {
      type: DataTypes.STRING(20),
      allowNull: false,
      unique: true,
    },
    email: {
      type: DataTypes.STRING(255),
      allowNull: true,
      unique: true,
    },
    passwordHash: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    firstName: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    lastName: {
      type: DataTypes.STRING(100),
      allowNull: false,
    },
    role: {
      type: DataTypes.ENUM(...Object.values(UserRole)),
      allowNull: false,
      defaultValue: UserRole.BUYER,
    },
    avatar: {
      type: DataTypes.STRING(500),
      allowNull: true,
    },
    isVerified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    isActive: {
      type: DataTypes.BOOLEAN,
      defaultValue: true,
    },
    language: {
      type: DataTypes.ENUM(...Object.values(Language)),
      defaultValue: Language.RU,
    },
    oneIdVerified: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    acceptedTerms: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    acceptedPrivacy: {
      type: DataTypes.BOOLEAN,
      defaultValue: false,
    },
    lastLoginAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  },
  {
    sequelize,
    tableName: 'users',
    modelName: 'User',
  }
);

export default User;
