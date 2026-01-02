import { Request, Response, NextFunction } from 'express';

export const validatePhone = (phone: string): boolean => {
  const phoneRegex = /^\+998[0-9]{9}$/;
  return phoneRegex.test(phone);
};

export const validateEmail = (email: string): boolean => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

export const validatePassword = (password: string): { valid: boolean; message?: string } => {
  if (password.length < 8) {
    return { valid: false, message: 'Password must be at least 8 characters long' };
  }
  if (!/[A-Z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one uppercase letter' };
  }
  if (!/[a-z]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one lowercase letter' };
  }
  if (!/[0-9]/.test(password)) {
    return { valid: false, message: 'Password must contain at least one number' };
  }
  return { valid: true };
};

export const validateRegistration = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const { phone, email, password, firstName, lastName, acceptedTerms, acceptedPrivacy } = req.body;

  if (!phone || !validatePhone(phone)) {
    res.status(400).json({
      success: false,
      error: 'Valid Uzbekistan phone number is required (+998XXXXXXXXX)',
    });
    return;
  }

  if (email && !validateEmail(email)) {
    res.status(400).json({
      success: false,
      error: 'Invalid email format',
    });
    return;
  }

  if (!password) {
    res.status(400).json({
      success: false,
      error: 'Password is required',
    });
    return;
  }

  const passwordValidation = validatePassword(password);
  if (!passwordValidation.valid) {
    res.status(400).json({
      success: false,
      error: passwordValidation.message,
    });
    return;
  }

  if (!firstName || firstName.trim().length < 2) {
    res.status(400).json({
      success: false,
      error: 'First name is required (minimum 2 characters)',
    });
    return;
  }

  if (!lastName || lastName.trim().length < 2) {
    res.status(400).json({
      success: false,
      error: 'Last name is required (minimum 2 characters)',
    });
    return;
  }

  if (!acceptedTerms) {
    res.status(400).json({
      success: false,
      error: 'You must accept the terms and conditions',
    });
    return;
  }

  if (!acceptedPrivacy) {
    res.status(400).json({
      success: false,
      error: 'You must accept the privacy policy',
    });
    return;
  }

  next();
};

export const validateLogin = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const { phone, password } = req.body;

  if (!phone || !validatePhone(phone)) {
    res.status(400).json({
      success: false,
      error: 'Valid Uzbekistan phone number is required (+998XXXXXXXXX)',
    });
    return;
  }

  if (!password) {
    res.status(400).json({
      success: false,
      error: 'Password is required',
    });
    return;
  }

  next();
};

export const validateProduct = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const { title, description, price, category, stock } = req.body;

  if (!title || title.trim().length < 3) {
    res.status(400).json({
      success: false,
      error: 'Product title is required (minimum 3 characters)',
    });
    return;
  }

  if (!description || description.trim().length < 10) {
    res.status(400).json({
      success: false,
      error: 'Product description is required (minimum 10 characters)',
    });
    return;
  }

  if (!price || price <= 0) {
    res.status(400).json({
      success: false,
      error: 'Valid price is required',
    });
    return;
  }

  if (!category || category.trim().length < 2) {
    res.status(400).json({
      success: false,
      error: 'Product category is required',
    });
    return;
  }

  if (stock !== undefined && stock < 0) {
    res.status(400).json({
      success: false,
      error: 'Stock cannot be negative',
    });
    return;
  }

  next();
};

export const validateOrder = (
  req: Request,
  res: Response,
  next: NextFunction
): void => {
  const { productId, quantity, paymentMethod, shippingAddress, shippingCity, shippingPhone } = req.body;

  if (!productId) {
    res.status(400).json({
      success: false,
      error: 'Product ID is required',
    });
    return;
  }

  if (!quantity || quantity < 1) {
    res.status(400).json({
      success: false,
      error: 'Valid quantity is required (minimum 1)',
    });
    return;
  }

  if (!paymentMethod) {
    res.status(400).json({
      success: false,
      error: 'Payment method is required',
    });
    return;
  }

  if (!shippingAddress || shippingAddress.trim().length < 10) {
    res.status(400).json({
      success: false,
      error: 'Shipping address is required (minimum 10 characters)',
    });
    return;
  }

  if (!shippingCity || shippingCity.trim().length < 2) {
    res.status(400).json({
      success: false,
      error: 'Shipping city is required',
    });
    return;
  }

  if (!shippingPhone || !validatePhone(shippingPhone)) {
    res.status(400).json({
      success: false,
      error: 'Valid shipping phone number is required (+998XXXXXXXXX)',
    });
    return;
  }

  next();
};
