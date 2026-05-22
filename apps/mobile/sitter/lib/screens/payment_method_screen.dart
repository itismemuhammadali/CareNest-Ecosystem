import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  bool _showAddForm = false;

  final _cardNumberController = TextEditingController();
  final _cardholderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final List<Map<String, dynamic>> _cards = [];

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardholderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _setDefault(int index) {
    setState(() {
      for (int i = 0; i < _cards.length; i++) {
        _cards[i]['isDefault'] = i == index;
      }
    });
  }

  void _removeCard(int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2235),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title + subtitle
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                child: Column(
                  children: [
                    const Text(
                      'Are you sure!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Are you sure you want to remove payment method',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              ),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  children: [
                    // Yes, Remove
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        setState(() => _cards.removeAt(index));
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF3B3B),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Yes, Remove',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Cancel
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitCard() {
    final number = _cardNumberController.text.replaceAll(' ', '');
    final name = _cardholderController.text.trim();
    final expiry = _expiryController.text;
    final cvv = _cvvController.text;

    if (number.length < 16 || name.isEmpty || expiry.length < 5 || cvv.length < 3) {
      return;
    }

    final last4 = number.substring(number.length - 4);
    String brand = 'Card';
    if (number.startsWith('4')) brand = 'Visa';
    if (number.startsWith('5')) brand = 'Mastercard';
    if (number.startsWith('3')) brand = 'Amex';
    if (number.startsWith('6')) brand = 'Discover';

    setState(() {
      _cards.add({
        'brand': brand,
        'last4': last4,
        'expiry': expiry,
        'isDefault': false,
      });
      _showAddForm = false;
      _cardNumberController.clear();
      _cardholderController.clear();
      _expiryController.clear();
      _cvvController.clear();
    });
  }

  void _cancelForm() {
    setState(() {
      _showAddForm = false;
      _cardNumberController.clear();
      _cardholderController.clear();
      _expiryController.clear();
      _cvvController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/screen-bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient overlay
          IgnorePointer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xB30F172A), Color(0xFF0F172A)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── Pinned header ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                            SizedBox(width: 6),
                            Text('Back', style: TextStyle(fontSize: 14, color: Colors.white70)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Payment Method',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage your payment cards',
                        style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
                // ── Scrollable body ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),

                  // Add New Card button (hidden when form is open)
                  if (!_showAddForm)
                    GestureDetector(
                      onTap: () => setState(() => _showAddForm = true),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFB8E8F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Color(0xFF0F172A), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Add New Card',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Inline Add Card form
                  if (_showAddForm)
                    _AddCardForm(
                      cardNumberController: _cardNumberController,
                      cardholderController: _cardholderController,
                      expiryController: _expiryController,
                      cvvController: _cvvController,
                      onAdd: _submitCard,
                      onCancel: _cancelForm,
                    ),

                  const SizedBox(height: 28),

                  // Saved Cards label
                  const Text(
                    'Saved Cards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Card list
                  ..._cards.asMap().entries.map((entry) {
                    final index = entry.key;
                    final card = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _CardTile(
                        brand: card['brand'] as String,
                        last4: card['last4'] as String,
                        expiry: card['expiry'] as String,
                        isDefault: card['isDefault'] as bool,
                        onSetDefault: () => _setDefault(index),
                        onRemove: () => _removeCard(index),
                      ),
                    );
                  }),

                  const SizedBox(height: 8),

                  // Security notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0x1AD4B5FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0x4DD4B5FF), width: 1.09),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/lock-icon.svg',
                              width: 14,
                              height: 14,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFD4B5FF),
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Your payment information is secure',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFD4B5FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'We use industry-standard encryption to protect your card details. Your information is never stored on our servers.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xB3D4B5FF),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline Add Card Form ──────────────────────────────────────────────────────

class _AddCardForm extends StatefulWidget {
  final TextEditingController cardNumberController;
  final TextEditingController cardholderController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final VoidCallback onAdd;
  final VoidCallback onCancel;

  const _AddCardForm({
    required this.cardNumberController,
    required this.cardholderController,
    required this.expiryController,
    required this.cvvController,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  State<_AddCardForm> createState() => _AddCardFormState();
}

class _AddCardFormState extends State<_AddCardForm> {
  bool _cvvVisible = false;

  bool get _isValid {
    final number = widget.cardNumberController.text.replaceAll(' ', '');
    return number.length >= 16 &&
        widget.cardholderController.text.trim().isNotEmpty &&
        widget.expiryController.text.length >= 5 &&
        widget.cvvController.text.length >= 3;
  }

  String _detectBrand(String number) {
    final digits = number.replaceAll(' ', '');
    if (digits.startsWith('4')) return 'Visa';
    if (digits.startsWith('5')) return 'Mastercard';
    if (digits.startsWith('3')) return 'Amex';
    if (digits.startsWith('6')) return 'Discover';
    return '';
  }

  @override
  void initState() {
    super.initState();
    widget.cardNumberController.addListener(() => setState(() {}));
    widget.cardholderController.addListener(() => setState(() {}));
    widget.expiryController.addListener(() => setState(() {}));
    widget.cvvController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final brand = _detectBrand(widget.cardNumberController.text);
    final canSubmit = _isValid;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Add New Card',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // ── Card Number ──
          _FieldLabel('Card Number'),
          const SizedBox(height: 6),
          TextField(
            controller: widget.cardNumberController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            maxLength: 19,
            decoration: _inputDecoration(
              hint: '1234 5678 9012 3456',
              suffix: brand.isNotEmpty
                  ? _BrandBadge(brand: brand)
                  : SvgPicture.asset(
                      'assets/card_icon.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                    ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Cardholder Name ──
          _FieldLabel('Cardholder Name'),
          const SizedBox(height: 6),
          TextField(
            controller: widget.cardholderController,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: _inputDecoration(hint: 'John Doe'),
          ),
          const SizedBox(height: 14),

          // ── Expiry + CVV ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('Expiry Date'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: widget.expiryController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _ExpiryFormatter(),
                      ],
                      maxLength: 5,
                      decoration: _inputDecoration(hint: 'MM/YY'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FieldLabel('CVV'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: widget.cvvController,
                      keyboardType: TextInputType.number,
                      obscureText: !_cvvVisible,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      maxLength: 4,
                      decoration: _inputDecoration(
                        hint: '•••',
                        suffix: GestureDetector(
                          onTap: () =>
                              setState(() => _cvvVisible = !_cvvVisible),
                          child: Icon(
                            _cvvVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white38,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Helper text ──
          Row(
            children: [
              SvgPicture.asset(
                'assets/lock-icon.svg',
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(
                  Colors.white24,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Your card details are encrypted and secure',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Buttons ──
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: canSubmit ? widget.onAdd : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: canSubmit
                          ? const Color(0xFFA8D8EA)
                          : const Color(0x33A8D8EA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Add Card',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: canSubmit
                            ? const Color(0x991E293B)
                            : Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x991E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0x33A8D8EA), width: 1.09),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFA8D8EA),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.25),
        fontSize: 14,
      ),
      counterText: '',
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 12),
              child: suffix,
            )
          : null,
      suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: const Color(0x4D262626),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0x33A8D8EA), width: 1.09),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0x33A8D8EA), width: 1.09),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFA8D8EA), width: 1.09),
      ),
    );
  }
}

// ── Brand Badge ───────────────────────────────────────────────────────────────

class _BrandBadge extends StatelessWidget {
  final String brand;
  const _BrandBadge({required this.brand});

  Color get _color {
    switch (brand) {
      case 'Visa':
        return const Color(0xFF1A1F71);
      case 'Mastercard':
        return const Color(0xFFEB001B);
      case 'Amex':
        return const Color(0xFF007BC1);
      case 'Discover':
        return const Color(0xFFFF6600);
      default:
        return Colors.white24;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        brand,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: brand == 'Visa'
              ? const Color(0xFF7B9FFF)
              : brand == 'Mastercard'
                  ? const Color(0xFFFF8080)
                  : brand == 'Amex'
                      ? const Color(0xFF80C8FF)
                      : const Color(0xFFFFAA66),
        ),
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.6),
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Input Formatters ──────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ── Card Tile ─────────────────────────────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final String brand;
  final String last4;
  final String expiry;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _CardTile({
    required this.brand,
    required this.last4,
    required this.expiry,
    required this.isDefault,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x991E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x4DA8D8EA), width: 1.09),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card info row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'assets/card_icon.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$brand •••• $last4',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Expires $expiry',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0x99A8D8EA),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x1AB5FFD9),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0x4DB5FFD9), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Color(0xFFB5FFD9), size: 13),
                      SizedBox(width: 4),
                      Text(
                        'Default',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFFB5FFD9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              if (!isDefault) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: onSetDefault,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0x1AB5FFD9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0x4DB5FFD9), width: 1.09),
                      ),
                      child: const Text(
                        'Set as Default',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB5FFD9),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0x1AFF6467),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0x4DFF6467), width: 1),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline,
                            color: Color(0xFFFF6467), size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Remove',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF6467),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
