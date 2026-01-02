import { config } from '../config';

interface SmsResponse {
  success: boolean;
  messageId?: string;
  error?: string;
}

class SmsService {
  private token: string | null = null;
  private tokenExpiry: Date | null = null;

  private async getToken(): Promise<string> {
    if (this.token && this.tokenExpiry && this.tokenExpiry > new Date()) {
      return this.token;
    }

    try {
      const response = await fetch(`${config.sms.eskizBaseUrl}/auth/login`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: config.sms.eskizEmail,
          password: config.sms.eskizPassword,
        }),
      });

      const data = await response.json() as { data?: { token: string } };
      
      if (data.data?.token) {
        this.token = data.data.token;
        this.tokenExpiry = new Date(Date.now() + 29 * 24 * 60 * 60 * 1000);
        return this.token;
      }

      throw new Error('Failed to get SMS token');
    } catch (error) {
      console.error('SMS auth error:', error);
      throw error;
    }
  }

  async sendOtp(phone: string, code: string): Promise<SmsResponse> {
    try {
      const token = await this.getToken();
      const message = `GoGoMarket: Ваш код подтверждения: ${code}. Не сообщайте его никому.`;

      const response = await fetch(`${config.sms.eskizBaseUrl}/message/sms/send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          mobile_phone: phone.replace('+', ''),
          message,
          from: '4546',
        }),
      });

      const data = await response.json() as { id?: string; status?: string };

      if (data.id) {
        return { success: true, messageId: data.id };
      }

      return { success: false, error: 'Failed to send SMS' };
    } catch (error) {
      console.error('SMS send error:', error);
      return { success: false, error: 'SMS service unavailable' };
    }
  }

  async sendDeliveryCode(phone: string, code: string, orderNumber: string): Promise<SmsResponse> {
    try {
      const token = await this.getToken();
      const message = `GoGoMarket: Код для получения заказа ${orderNumber}: ${code}`;

      const response = await fetch(`${config.sms.eskizBaseUrl}/message/sms/send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        body: JSON.stringify({
          mobile_phone: phone.replace('+', ''),
          message,
          from: '4546',
        }),
      });

      const data = await response.json() as { id?: string };

      if (data.id) {
        return { success: true, messageId: data.id };
      }

      return { success: false, error: 'Failed to send SMS' };
    } catch (error) {
      console.error('SMS send error:', error);
      return { success: false, error: 'SMS service unavailable' };
    }
  }

  generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  generateDeliveryCode(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }
}

export const smsService = new SmsService();
export default smsService;
