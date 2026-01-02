import { DataTypes, Model, Optional } from 'sequelize';
import sequelize from '../config/database';
import { DisputeStatus } from '../types';

interface DisputeAttributes {
  id: string;
  orderId: string;
  reporterId: string;
  assignedAdminId?: string;
  status: DisputeStatus;
  reason: string;
  description: string;
  evidence?: string[];
  resolution?: string;
  resolvedAt?: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

interface DisputeCreationAttributes extends Optional<DisputeAttributes, 'id' | 'assignedAdminId' | 'evidence' | 'resolution' | 'resolvedAt' | 'createdAt' | 'updatedAt'> {}

class Dispute extends Model<DisputeAttributes, DisputeCreationAttributes> implements DisputeAttributes {
  public id!: string;
  public orderId!: string;
  public reporterId!: string;
  public assignedAdminId?: string;
  public status!: DisputeStatus;
  public reason!: string;
  public description!: string;
  public evidence?: string[];
  public resolution?: string;
  public resolvedAt?: Date;
  public readonly createdAt!: Date;
  public readonly updatedAt!: Date;
}

Dispute.init(
  {
    id: {
      type: DataTypes.UUID,
      defaultValue: DataTypes.UUIDV4,
      primaryKey: true,
    },
    orderId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'orders',
        key: 'id',
      },
    },
    reporterId: {
      type: DataTypes.UUID,
      allowNull: false,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    assignedAdminId: {
      type: DataTypes.UUID,
      allowNull: true,
      references: {
        model: 'users',
        key: 'id',
      },
    },
    status: {
      type: DataTypes.ENUM(...Object.values(DisputeStatus)),
      defaultValue: DisputeStatus.OPEN,
    },
    reason: {
      type: DataTypes.STRING(255),
      allowNull: false,
    },
    description: {
      type: DataTypes.TEXT,
      allowNull: false,
    },
    evidence: {
      type: DataTypes.ARRAY(DataTypes.STRING),
      defaultValue: [],
    },
    resolution: {
      type: DataTypes.TEXT,
      allowNull: true,
    },
    resolvedAt: {
      type: DataTypes.DATE,
      allowNull: true,
    },
  },
  {
    sequelize,
    tableName: 'disputes',
    modelName: 'Dispute',
  }
);

export default Dispute;
