import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../services/cart_service.dart';

class AppButton extends StatelessWidget {
  final String       label;
  final VoidCallback? onTap;
  final bool         isLoading;
  final Color?       backgroundColor;
  final Color?       foregroundColor;
  final IconData?    icon;
  final double?      width;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width ?? double.infinity,
    child: ElevatedButton(
      onPressed: isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      child: isLoading
          ? const SizedBox(
              width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))
          : icon != null
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                  Text(label),
                ])
              : Text(label),
    ),
  );
}

class AppTextField extends StatelessWidget {
  final TextEditingController       controller;
  final String                      hint;
  final bool                        obscureText;
  final TextInputType               keyboardType;
  final String? Function(String?)?  validator;
  final Widget?                     prefixIcon;
  final Widget?                     suffixIcon;
  final int?                        maxLength;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller:   controller,
    obscureText:  obscureText,
    keyboardType: keyboardType,
    validator:    validator,
    maxLength:    maxLength,
    decoration: InputDecoration(
      labelText:   hint,
      prefixIcon:  prefixIcon,
      suffixIcon:  suffixIcon,
      counterText: maxLength != null ? null : '',
    ),
  );
}

class ProductImage extends StatelessWidget {
  final String   imageUrl;
  final String   heroTag;
  final double?  height;
  final BoxFit   fit;

  const ProductImage({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) => Hero(
    tag: 'product-$heroTag',
    child: CachedNetworkImage(
      imageUrl:    imageUrl,
      fit:         fit,
      height:      height,
      placeholder: (_, __) => Shimmer.fromColors(
        baseColor:      Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(color: Colors.white),
      ),
      errorWidget: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
      ),
    ),
  );
}

class StarsWidget extends StatelessWidget {
  final double? value;
  final int?    count;
  final double  size;

  const StarsWidget({super.key, this.value, this.count, this.size = 13});

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: [
      ...List.generate(5, (i) => Icon(
        i < value!.round() ? Icons.star_rounded : Icons.star_outline_rounded,
        size:  size,
        color: const Color(0xFFFF8F00),
      )),
      if (count != null) ...[
        const SizedBox(width: 4),
        Text('$count', style: TextStyle(fontSize: size - 1, color: AppColors.blue)),
      ],
    ]);
  }
}

class SlideIn extends StatefulWidget {
  final Widget   child;
  final Duration delay;
  final Duration duration;
  final Offset   beginOffset;

  const SlideIn({
    super.key,
    required this.child,
    this.delay       = Duration.zero,
    this.duration    = const Duration(milliseconds: 300),
    this.beginOffset = const Offset(0, 0.06),
  });

  @override
  State<SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<SlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double>   _opacity;
  late final Animation<Offset>   _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _opacity    = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _slide      = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    Future.delayed(widget.delay, () { if (mounted) _controller.forward(); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

class PressEffect extends StatefulWidget {
  final Widget       child;
  final VoidCallback? onTap;

  const PressEffect({super.key, required this.child, this.onTap});

  @override
  State<PressEffect> createState() => _PressEffectState();
}

class _PressEffectState extends State<PressEffect> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:  (_) => _controller.forward(),
    onTapUp:    (_) { _controller.reverse(); widget.onTap?.call(); },
    onTapCancel: () => _controller.reverse(),
    child: AnimatedBuilder(
      animation: _scale,
      builder:   (_, child) => Transform.scale(scale: _scale.value, child: child),
      child:     widget.child,
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData     icon;
  final String       title;
  final String?      subtitle;
  final String?      buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SlideIn(child: Container(
          padding:    const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 52, color: AppColors.blue.withOpacity(0.35)),
        )),
        const SizedBox(height: 16),
        SlideIn(
          delay: const Duration(milliseconds: 60),
          child: Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.ink),
            textAlign: TextAlign.center,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          SlideIn(
            delay: const Duration(milliseconds: 100),
            child: Text(subtitle!,
              style: const TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (buttonLabel != null && onButtonTap != null) ...[
          const SizedBox(height: 18),
          SlideIn(
            delay: const Duration(milliseconds: 140),
            child: AppButton(label: buttonLabel!, onTap: onButtonTap, width: 160),
          ),
        ],
      ]),
    ),
  );
}

class ErrorBox extends StatelessWidget {
  final String       message;
  final VoidCallback onRetry;

  const ErrorBox({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 52, color: AppColors.danger),
        const SizedBox(height: 12),
        Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        AppButton(
          label: 'Reintentar',
          onTap:  onRetry,
          icon:   Icons.refresh_rounded,
          width:  140,
        ),
      ]),
    ),
  );
}

class CartBadge extends StatelessWidget {
  final Widget child;
  const CartBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartService>().itemCount;
    return Stack(clipBehavior: Clip.none, children: [
      child,
      if (count > 0)
        Positioned(
          right: -2, top: -4,
          child: Container(
            padding:     const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            decoration:  const BoxDecoration(
                color: AppColors.orange, shape: BoxShape.circle),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                  color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
    ]);
  }
}

class WishlistButton extends StatelessWidget {
  final int           productId;
  final bool          isFavorite;
  final VoidCallback? onToggle;

  const WishlistButton({
    super.key,
    required this.productId,
    required this.isFavorite,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onToggle?.call();
    },
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color:  Colors.white,
        shape:  BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset:     const Offset(0, 2),
          ),
        ],
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          key:   ValueKey(isFavorite),
          size:  16,
          color: isFavorite ? AppColors.danger : AppColors.muted,
        ),
      ),
    ),
  );
}

class DiscountBadge extends StatelessWidget {
  final int percent;
  const DiscountBadge({super.key, required this.percent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: const BoxDecoration(
      color:        AppColors.deal,
      borderRadius: BorderRadius.all(kR4),
    ),
    child: Text(
      '-$percent%',
      style: const TextStyle(
          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}
