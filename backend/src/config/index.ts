import dotenv from 'dotenv';

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '3000'),
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'your-super-secret-jwt-key',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  
  aws: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID || '',
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY || '',
    region: process.env.AWS_REGION || 'us-east-1',
    s3Bucket: process.env.AWS_S3_BUCKET || 'gogomarket-media',
  },
  
  sms: {
    eskizEmail: process.env.ESKIZ_EMAIL || '',
    eskizPassword: process.env.ESKIZ_PASSWORD || '',
    eskizBaseUrl: 'https://notify.eskiz.uz/api',
  },
  
  payment: {
    paymeId: process.env.PAYME_ID || '',
    paymeKey: process.env.PAYME_KEY || '',
    clickServiceId: process.env.CLICK_SERVICE_ID || '',
    clickMerchantId: process.env.CLICK_MERCHANT_ID || '',
  },
  
  platformCommission: parseFloat(process.env.PLATFORM_COMMISSION || '0.10'),
  courierFeeDefault: parseFloat(process.env.COURIER_FEE_DEFAULT || '15000'),
};

export default config;
