import QRCode from 'qrcode';
import { v4 as uuidv4 } from 'uuid';

interface QrData {
  orderId: string;
  type: 'seller_pickup' | 'courier_delivery';
  code: string;
  timestamp: number;
}

class QrService {
  async generateSellerQr(orderId: string): Promise<{ qrCode: string; code: string }> {
    const code = uuidv4().substring(0, 8).toUpperCase();
    
    const qrData: QrData = {
      orderId,
      type: 'seller_pickup',
      code,
      timestamp: Date.now(),
    };

    const qrCode = await QRCode.toDataURL(JSON.stringify(qrData), {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    return { qrCode, code };
  }

  async generateCourierQr(orderId: string): Promise<{ qrCode: string; code: string }> {
    const code = uuidv4().substring(0, 8).toUpperCase();
    
    const qrData: QrData = {
      orderId,
      type: 'courier_delivery',
      code,
      timestamp: Date.now(),
    };

    const qrCode = await QRCode.toDataURL(JSON.stringify(qrData), {
      width: 300,
      margin: 2,
      color: {
        dark: '#000000',
        light: '#FFFFFF',
      },
    });

    return { qrCode, code };
  }

  parseQrCode(qrString: string): QrData | null {
    try {
      const data = JSON.parse(qrString) as QrData;
      
      if (!data.orderId || !data.type || !data.code) {
        return null;
      }

      return data;
    } catch {
      return null;
    }
  }

  validateQrCode(qrData: QrData, expectedOrderId: string, expectedType: 'seller_pickup' | 'courier_delivery'): boolean {
    if (qrData.orderId !== expectedOrderId) {
      return false;
    }

    if (qrData.type !== expectedType) {
      return false;
    }

    const maxAge = 24 * 60 * 60 * 1000;
    if (Date.now() - qrData.timestamp > maxAge) {
      return false;
    }

    return true;
  }
}

export const qrService = new QrService();
export default qrService;
