import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/order/order_bloc.dart';
import '../core/theme.dart';
import '../models/order.dart';
import '../services/cart_service.dart';
import '../widgets/shared_widgets.dart';

class CheckoutScreen extends StatefulWidget {
  final CartService cart;
  const CheckoutScreen({super.key, required this.cart});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey    = GlobalKey<FormState>();
  int _currentStep  = 0;

  final _nameCtrl   = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl   = TextEditingController();
  final _zipCtrl    = TextEditingController();
  String _country   = 'México';

  final _cardNumCtrl   = TextEditingController();
  final _cardNameCtrl  = TextEditingController();
  final _expiryCtrl    = TextEditingController();
  final _cvvCtrl       = TextEditingController();
  int _selectedCard    = -1;

  bool _isProcessing   = false;

  final _savedCards = const [
    SavedCard(last4: '4242', brand: 'Visa',       holder: 'Usuario Demo', expiry: '12/26'),
    SavedCard(last4: '5100', brand: 'Mastercard', holder: 'Usuario Demo', expiry: '08/25'),
  ];

  @override
  void dispose() {
    _nameCtrl.dispose(); _streetCtrl.dispose();
    _cityCtrl.dispose(); _zipCtrl.dispose();
    _cardNumCtrl.dispose(); _cardNameCtrl.dispose();
    _expiryCtrl.dispose(); _cvvCtrl.dispose();
    super.dispose();
  }

  String get _fullAddress =>
      '${_nameCtrl.text}, ${_streetCtrl.text}, ${_cityCtrl.text} ${_zipCtrl.text}, $_country';

  String get _cardLast4 => _selectedCard >= 0
      ? _savedCards[_selectedCard].last4
      : (_cardNumCtrl.text.length >= 4
          ? _cardNumCtrl.text.substring(_cardNumCtrl.text.length - 4)
          : '????');

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    context.read<OrderBloc>().add(PlaceOrder(
      items:           widget.cart.items,
      total:           widget.cart.total,
      shippingAddress: _fullAddress,
      cardLast4:       _cardLast4,
    ));
    await widget.cart.clearCart();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar:          AppBar(title: const Text('Finalizar compra')),
    body: Column(children: [
      
      Container(
        color:   AppColors.card,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _StepIndicator(n: 1, label: 'Dirección', isActive: _currentStep >= 0, isDone: _currentStep > 0),
          _StepConnector(isDone: _currentStep > 0),
          _StepIndicator(n: 2, label: 'Pago',      isActive: _currentStep >= 1, isDone: _currentStep > 1),
          _StepConnector(isDone: _currentStep > 1),
          _StepIndicator(n: 3, label: 'Revisar',   isActive: _currentStep >= 2, isDone: false),
        ]),
      ),

      Expanded(
        child: Form(
          key: _formKey,
          child: IndexedStack(index: _currentStep, children: [
            _AddressStep(
              nameCtrl:  _nameCtrl, streetCtrl: _streetCtrl,
              cityCtrl:  _cityCtrl, zipCtrl: _zipCtrl,
              country:   _country,
              onCountryChanged: (v) => setState(() => _country = v),
            ),
            _PaymentStep(
              savedCards:    _savedCards,
              selectedIndex: _selectedCard,
              onSelect:      (i) => setState(() => _selectedCard = i),
              cardNumCtrl:   _cardNumCtrl,
              cardNameCtrl:  _cardNameCtrl,
              expiryCtrl:    _expiryCtrl,
              cvvCtrl:       _cvvCtrl,
            ),
            _ReviewStep(
              cart:       widget.cart,
              address:    _fullAddress,
              savedCard:  _selectedCard >= 0 ? _savedCards[_selectedCard] : null,
              cardLast4:  _cardLast4,
            ),
          ]),
        ),
      ),

      Container(
        padding:    const EdgeInsets.fromLTRB(16, 14, 16, 0),
        decoration: BoxDecoration(color: AppColors.card, boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06),
              blurRadius: 10, offset: const Offset(0, -3)),
        ]),
        child: SafeArea(child: Column(children: [
          if (_currentStep == 2)
            Text('Total: ${widget.cart.formattedTotal}',
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.ink)),
          const SizedBox(height: 10),
          Row(children: [
            if (_currentStep > 0) ...[
              OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  side:    const BorderSide(color: AppColors.line),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
                child: const Text('Atrás', style: TextStyle(color: AppColors.ink)),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: AppButton(
                label:           _currentStep == 2
                    ? (_isProcessing ? 'Procesando...' : 'Confirmar pedido')
                    : 'Continuar',
                backgroundColor: _currentStep == 2 ? AppColors.orange : AppColors.yellow,
                foregroundColor: _currentStep == 2 ? Colors.white : AppColors.ink,
                icon:            _currentStep == 2 ? Icons.lock_outline : Icons.arrow_forward,
                isLoading:       _isProcessing,
                onTap: _isProcessing ? null : () {
                  if (_currentStep < 2) {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _currentStep++);
                  } else {
                    _placeOrder();
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 4),
        ])),
      ),
    ]),
  );
}

class _StepIndicator extends StatelessWidget {
  final int n; final String label; final bool isActive, isDone;
  const _StepIndicator({required this.n, required this.label, required this.isActive, required this.isDone});
  @override
  Widget build(BuildContext context) => Column(children: [
    AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 30, height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDone ? AppColors.green : isActive ? AppColors.orange : AppColors.line,
      ),
      child: Center(child: isDone
          ? const Icon(Icons.check, size: 16, color: Colors.white)
          : Text('$n', style: TextStyle(
              color: isActive ? Colors.white : AppColors.muted,
              fontWeight: FontWeight.bold, fontSize: 13))),
    ),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(
        fontSize: 10, color: isActive ? AppColors.ink : AppColors.muted,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal)),
  ]);
}

class _StepConnector extends StatelessWidget {
  final bool isDone;
  const _StepConnector({required this.isDone});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 40, height: 2,
      color: isDone ? AppColors.green : AppColors.line,
    ),
  );
}

class _AddressStep extends StatelessWidget {
  final TextEditingController nameCtrl, streetCtrl, cityCtrl, zipCtrl;
  final String country;
  final ValueChanged<String> onCountryChanged;
  const _AddressStep({
    required this.nameCtrl, required this.streetCtrl,
    required this.cityCtrl, required this.zipCtrl,
    required this.country,  required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Dirección de envío',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      AppTextField(controller: nameCtrl, hint: 'Nombre completo',
        prefixIcon: const Icon(Icons.person_outline),
        validator:  (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
      const SizedBox(height: 12),
      AppTextField(controller: streetCtrl, hint: 'Calle y número',
        prefixIcon: const Icon(Icons.home_outlined),
        validator:  (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: AppTextField(controller: cityCtrl, hint: 'Ciudad',
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null)),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: AppTextField(controller: zipCtrl, hint: 'C.P.',
          keyboardType: TextInputType.number, maxLength: 5,
          validator:    (v) => v == null || v.length < 5 ? 'Inválido' : null)),
      ]),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(
        value:     country,
        items:     ['México', 'Colombia', 'Argentina', 'España', 'Chile', 'Perú']
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
        onChanged: (v) => onCountryChanged(v!),
        decoration: const InputDecoration(
          labelText:  'País',
          prefixIcon: Icon(Icons.flag_outlined),
        ),
      ),
    ],
  );
}

class _PaymentStep extends StatelessWidget {
  final List<SavedCard>      savedCards;
  final int                  selectedIndex;
  final ValueChanged<int>    onSelect;
  final TextEditingController cardNumCtrl, cardNameCtrl, expiryCtrl, cvvCtrl;
  const _PaymentStep({
    required this.savedCards, required this.selectedIndex, required this.onSelect,
    required this.cardNumCtrl, required this.cardNameCtrl,
    required this.expiryCtrl, required this.cvvCtrl,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Método de pago',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      ...savedCards.asMap().entries.map((e) => _SavedCardTile(
        card:       e.value,
        isSelected: selectedIndex == e.key,
        onTap:      () => onSelect(e.key),
      )),
      _SavedCardTile(
        card:       const SavedCard(last4: '', brand: '+ Nueva tarjeta', holder: '', expiry: ''),
        isSelected: selectedIndex == -1,
        onTap:      () => onSelect(-1),
        isNew:      true,
      ),
      if (selectedIndex == -1) ...[
        const SizedBox(height: 16),
        AppTextField(controller: cardNumCtrl, hint: 'Número de tarjeta',
          keyboardType: TextInputType.number, maxLength: 19,
          prefixIcon:   const Icon(Icons.credit_card),
          validator:    (v) => v == null || v.replaceAll(' ', '').length < 16 ? 'Número inválido' : null),
        const SizedBox(height: 12),
        AppTextField(controller: cardNameCtrl, hint: 'Nombre en la tarjeta',
          validator: (v) => v == null || v.trim().isEmpty ? 'Requerido' : null),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: AppTextField(controller: expiryCtrl, hint: 'MM/AA',
            keyboardType: TextInputType.number, maxLength: 5,
            validator: (v) => v == null || v.length < 5 ? 'Inválido' : null)),
          const SizedBox(width: 10),
          SizedBox(width: 100, child: AppTextField(controller: cvvCtrl, hint: 'CVV',
            keyboardType: TextInputType.number, maxLength: 3, obscureText: true,
            validator: (v) => v == null || v.length < 3 ? 'Inválido' : null)),
        ]),
      ],
    ],
  );
}

class _SavedCardTile extends StatelessWidget {
  final SavedCard card;
  final bool      isSelected;
  final VoidCallback onTap;
  final bool      isNew;
  const _SavedCardTile({
    required this.card, required this.isSelected,
    required this.onTap, this.isNew = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        AppColors.card,
        borderRadius: const BorderRadius.all(kR8),
        border:       Border.all(
            color: isSelected ? AppColors.orange : AppColors.line,
            width: isSelected ? 2 : 1),
      ),
      child: Row(children: [
        Icon(
          isNew ? Icons.add_card_outlined : Icons.credit_card,
          color: isSelected ? AppColors.orange : AppColors.muted,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: isNew
              ? const Text('Agregar nueva tarjeta',
                  style: TextStyle(fontWeight: FontWeight.w500))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${card.brand} •••• ${card.last4}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('Vence ${card.expiry}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ]),
        ),
        if (isSelected)
          const Icon(Icons.check_circle, color: AppColors.orange, size: 20),
      ]),
    ),
  );
}

class _ReviewStep extends StatelessWidget {
  final CartService cart;
  final String      address;
  final SavedCard?  savedCard;
  final String      cardLast4;
  const _ReviewStep({
    required this.cart, required this.address,
    this.savedCard, required this.cardLast4,
  });

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text('Revisar pedido',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),

      _ReviewSection(title: 'Dirección de entrega', icon: Icons.home_outlined,
        content: address),
      _ReviewSection(
        title:   'Método de pago', icon: Icons.credit_card,
        content: savedCard != null
            ? '${savedCard!.brand} •••• ${savedCard!.last4}'
            : 'Tarjeta •••• $cardLast4',
      ),

      const SizedBox(height: 16),
      const Text('Artículos',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...cart.items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child:   Row(children: [
          Container(
            width: 40, height: 40, color: Colors.grey[50], padding: const EdgeInsets.all(4),
            child: ProductImage(imageUrl: item.product.imageUrl, heroTag: 'r-${item.id}'),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(item.product.title,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12))),
          const SizedBox(width: 8),
          Text('x${item.quantity}  ${item.formattedSubtotal}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ]),
      )),

      const Divider(height: 20),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Envío:', style: TextStyle(color: AppColors.muted)),
        const Text('GRATIS', style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(cart.formattedTotal,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ]),
      const SizedBox(height: 8),
      Row(children: const [
        Icon(Icons.security_outlined, size: 14, color: AppColors.green),
        SizedBox(width: 4),
        Text('Pago 100% seguro y encriptado',
          style: TextStyle(fontSize: 11, color: AppColors.green)),
      ]),
    ],
  );
}

class _ReviewSection extends StatelessWidget {
  final String   title, content;
  final IconData icon;
  const _ReviewSection({required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) => Container(
    margin:  const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        AppColors.bg,
      borderRadius: const BorderRadius.all(kR8),
      border:       Border.all(color: AppColors.line),
    ),
    child: Row(children: [
      Icon(icon, size: 18, color: AppColors.blue),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(content, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ])),
    ]),
  );
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SlideIn(child: Container(
              width: 90, height: 90,
              decoration: const BoxDecoration(
                  color: AppColors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            )),
            const SizedBox(height: 24),
            const SlideIn(
              delay: Duration(milliseconds: 100),
              child: Text('¡Pedido confirmado!',
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.ink)),
            ),
            const SizedBox(height: 8),
            SlideIn(
              delay: const Duration(milliseconds: 160),
              child: const Text(
                'Te enviaremos una confirmación y\npodrás rastrear tu pedido desde la app.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted, fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            SlideIn(
              delay: const Duration(milliseconds: 220),
              child: AppButton(
                label: 'Seguir comprando',
                onTap: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/', (r) => false),
              ),
            ),
          ]),
        ),
      ),
    ),
  );
}
