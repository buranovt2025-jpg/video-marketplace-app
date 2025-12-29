import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:tiktok_tutorial/constants.dart';

enum PaymentMethod { cash, card, click, payme }

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;
  final Function(bool success, String? transactionId) onPaymentComplete;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.orderId,
    required this.onPaymentComplete,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.card;
  bool _isProcessing = false;
  
  // Card form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: const Text(
          'Оплата',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount to pay
            _buildAmountCard(),
            const SizedBox(height: 24),
            
            // Payment methods
            const Text(
              'Способ оплаты',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentMethods(),
            const SizedBox(height: 24),
            
            // Payment form based on selected method
            if (_selectedMethod == PaymentMethod.card) _buildCardForm(),
            if (_selectedMethod == PaymentMethod.click) _buildClickInfo(),
            if (_selectedMethod == PaymentMethod.payme) _buildPaymeInfo(),
            if (_selectedMethod == PaymentMethod.cash) _buildCashInfo(),
          ],
        ),
      ),
      bottomNavigationBar: _buildPayButton(),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'К оплате',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_formatPrice(widget.amount)} сум',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Заказ #${widget.orderId}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    return Column(
      children: [
        _buildPaymentMethodTile(
          PaymentMethod.card,
          'Банковская карта',
          'Visa, Mastercard, Uzcard, Humo',
          Icons.credit_card,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          PaymentMethod.click,
          'Click',
          'Оплата через Click',
          Icons.touch_app,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          PaymentMethod.payme,
          'Payme',
          'Оплата через Payme',
          Icons.account_balance_wallet,
          Colors.cyan,
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodTile(
          PaymentMethod.cash,
          'Наличными',
          'Оплата при получении',
          Icons.money,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildPaymentMethodTile(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[800]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: primaryColor)
            else
              Icon(Icons.circle_outlined, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Данные карты',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Card number
          TextFormField(
            controller: _cardNumberController,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(16),
              _CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              labelText: 'Номер карты',
              labelStyle: TextStyle(color: Colors.grey[500]),
              hintText: '0000 0000 0000 0000',
              hintStyle: TextStyle(color: Colors.grey[700]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(Icons.credit_card, color: Colors.grey[500]),
            ),
            validator: (value) {
              if (value == null || value.replaceAll(' ', '').length < 16) {
                return 'Введите корректный номер карты';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Expiry and CVV row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(4),
                    _ExpiryDateFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Срок',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    hintText: 'MM/YY',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 5) {
                      return 'MM/YY';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    labelStyle: TextStyle(color: Colors.grey[500]),
                    hintText: '***',
                    hintStyle: TextStyle(color: Colors.grey[700]),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.length < 3) {
                      return 'CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Card holder name
          TextFormField(
            controller: _cardHolderController,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'Имя владельца',
              labelStyle: TextStyle(color: Colors.grey[500]),
              hintText: 'IVAN IVANOV',
              hintStyle: TextStyle(color: Colors.grey[700]),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите имя владельца';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Security info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ваши данные защищены SSL шифрованием',
                    style: TextStyle(color: Colors.green[300], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.touch_app, color: Colors.green, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Оплата через Click',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'После нажатия "Оплатить" вы будете перенаправлены в приложение Click для подтверждения платежа',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymeInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.cyan.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.account_balance_wallet, color: Colors.cyan, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Оплата через Payme',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'После нажатия "Оплатить" вы будете перенаправлены в приложение Payme для подтверждения платежа',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCashInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.money, color: Colors.orange, size: 40),
          ),
          const SizedBox(height: 16),
          const Text(
            'Оплата наличными',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Оплатите заказ курьеру при получении. Пожалуйста, подготовьте точную сумму.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    String buttonText;
    switch (_selectedMethod) {
      case PaymentMethod.card:
        buttonText = 'Оплатить ${_formatPrice(widget.amount)} сум';
        break;
      case PaymentMethod.click:
        buttonText = 'Перейти в Click';
        break;
      case PaymentMethod.payme:
        buttonText = 'Перейти в Payme';
        break;
      case PaymentMethod.cash:
        buttonText = 'Подтвердить заказ';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey[700],
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    buttonText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    // Validate card form if card payment
    if (_selectedMethod == PaymentMethod.card) {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, you would call the payment API here
      // For demo, we'll simulate a successful payment
      final transactionId = 'TXN${DateTime.now().millisecondsSinceEpoch}';
      
      // Show success
      Get.snackbar(
        'Успешно!',
        _selectedMethod == PaymentMethod.cash 
            ? 'Заказ подтверждён' 
            : 'Оплата прошла успешно',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      
      // Return success
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onPaymentComplete(true, transactionId);
      Get.back();
      
    } catch (e) {
      Get.snackbar(
        'Ошибка',
        'Не удалось обработать платёж: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  String _formatPrice(double price) {
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      final thousands = (price / 1000).toStringAsFixed(0);
      return '$thousands 000';
    }
    return price.toStringAsFixed(0);
  }
}

// Card number formatter (adds spaces every 4 digits)
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i + 1 != text.length) {
        buffer.write(' ');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Expiry date formatter (adds / after MM)
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 1 && text.length > 2) {
        buffer.write('/');
      }
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
