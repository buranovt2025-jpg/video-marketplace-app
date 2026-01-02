import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt, { SignOptions } from 'jsonwebtoken';
import { User } from '../models';
import { config } from '../config';
import { UserRole, Language } from '../types';
import { AuthRequest } from '../middleware/auth';
import smsService from '../services/smsService';

const otpStore = new Map<string, { code: string; expiry: Date }>();

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { phone, email, password, firstName, lastName, role, language, acceptedTerms, acceptedPrivacy } = req.body;

    const existingUser = await User.findOne({ where: { phone } });
    if (existingUser) {
      res.status(409).json({
        success: false,
        error: 'User with this phone number already exists',
      });
      return;
    }

    if (email) {
      const existingEmail = await User.findOne({ where: { email } });
      if (existingEmail) {
        res.status(409).json({
          success: false,
          error: 'User with this email already exists',
        });
        return;
      }
    }

    const passwordHash = await bcrypt.hash(password, 12);

    const user = await User.create({
      phone,
      email,
      passwordHash,
      firstName,
      lastName,
      role: role || UserRole.BUYER,
      language: language || Language.RU,
      acceptedTerms,
      acceptedPrivacy,
    });

    const otp = smsService.generateOtp();
    otpStore.set(phone, {
      code: otp,
      expiry: new Date(Date.now() + 5 * 60 * 1000),
    });

    await smsService.sendOtp(phone, otp);

    res.status(201).json({
      success: true,
      data: {
        userId: user.id,
        phone: user.phone,
        message: 'Registration successful. Please verify your phone number.',
      },
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      error: 'Registration failed',
    });
  }
};

export const verifyOtp = async (req: Request, res: Response): Promise<void> => {
  try {
    const { phone, code } = req.body;

    const storedOtp = otpStore.get(phone);
    if (!storedOtp) {
      res.status(400).json({
        success: false,
        error: 'OTP not found. Please request a new one.',
      });
      return;
    }

    if (storedOtp.expiry < new Date()) {
      otpStore.delete(phone);
      res.status(400).json({
        success: false,
        error: 'OTP expired. Please request a new one.',
      });
      return;
    }

    if (storedOtp.code !== code) {
      res.status(400).json({
        success: false,
        error: 'Invalid OTP code.',
      });
      return;
    }

    otpStore.delete(phone);

    const user = await User.findOne({ where: { phone } });
    if (!user) {
      res.status(404).json({
        success: false,
        error: 'User not found.',
      });
      return;
    }

    user.isVerified = true;
    await user.save();

    const signOptions: SignOptions = { expiresIn: '7d' };
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      config.jwtSecret,
      signOptions
    );

    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          phone: user.phone,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          role: user.role,
          isVerified: user.isVerified,
        },
      },
    });
  } catch (error) {
    console.error('OTP verification error:', error);
    res.status(500).json({
      success: false,
      error: 'Verification failed',
    });
  }
};

export const resendOtp = async (req: Request, res: Response): Promise<void> => {
  try {
    const { phone } = req.body;

    const user = await User.findOne({ where: { phone } });
    if (!user) {
      res.status(404).json({
        success: false,
        error: 'User not found.',
      });
      return;
    }

    const otp = smsService.generateOtp();
    otpStore.set(phone, {
      code: otp,
      expiry: new Date(Date.now() + 5 * 60 * 1000),
    });

    await smsService.sendOtp(phone, otp);

    res.json({
      success: true,
      message: 'OTP sent successfully.',
    });
  } catch (error) {
    console.error('Resend OTP error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to resend OTP',
    });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { phone, password } = req.body;

    const user = await User.findOne({ where: { phone } });
    if (!user) {
      res.status(401).json({
        success: false,
        error: 'Invalid credentials.',
      });
      return;
    }

    if (!user.isActive) {
      res.status(401).json({
        success: false,
        error: 'Account is deactivated.',
      });
      return;
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
      res.status(401).json({
        success: false,
        error: 'Invalid credentials.',
      });
      return;
    }

    user.lastLoginAt = new Date();
    await user.save();

    const signOptions: SignOptions = { expiresIn: '7d' };
    const token = jwt.sign(
      { userId: user.id, role: user.role },
      config.jwtSecret,
      signOptions
    );

    res.json({
      success: true,
      data: {
        token,
        user: {
          id: user.id,
          phone: user.phone,
          email: user.email,
          firstName: user.firstName,
          lastName: user.lastName,
          role: user.role,
          avatar: user.avatar,
          isVerified: user.isVerified,
          language: user.language,
        },
      },
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      error: 'Login failed',
    });
  }
};

export const getProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user) {
      res.status(404).json({
        success: false,
        error: 'User not found.',
      });
      return;
    }

    res.json({
      success: true,
      data: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        avatar: user.avatar,
        isVerified: user.isVerified,
        language: user.language,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get profile',
    });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user) {
      res.status(404).json({
        success: false,
        error: 'User not found.',
      });
      return;
    }

    const { firstName, lastName, email, avatar, language } = req.body;

    if (firstName) user.firstName = firstName;
    if (lastName) user.lastName = lastName;
    if (email) user.email = email;
    if (avatar) user.avatar = avatar;
    if (language) user.language = language;

    await user.save();

    res.json({
      success: true,
      data: {
        id: user.id,
        phone: user.phone,
        email: user.email,
        firstName: user.firstName,
        lastName: user.lastName,
        role: user.role,
        avatar: user.avatar,
        language: user.language,
      },
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update profile',
    });
  }
};

export const changePassword = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const user = req.currentUser;
    if (!user) {
      res.status(404).json({
        success: false,
        error: 'User not found.',
      });
      return;
    }

    const { currentPassword, newPassword } = req.body;

    const isPasswordValid = await bcrypt.compare(currentPassword, user.passwordHash);
    if (!isPasswordValid) {
      res.status(401).json({
        success: false,
        error: 'Current password is incorrect.',
      });
      return;
    }

    user.passwordHash = await bcrypt.hash(newPassword, 12);
    await user.save();

    res.json({
      success: true,
      message: 'Password changed successfully.',
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to change password',
    });
  }
};
