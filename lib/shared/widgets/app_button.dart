import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../extensions/context_extensions.dart';

enum AppButtonSize { small, medium, large }
enum AppButtonVariant { filled, outlined, text }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonSize size;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  
  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
    this.variant = AppButtonVariant.filled,
    this.isLoading = false,
    this.fullWidth = false,
    this.backgroundColor,
    this.textColor,
  });
  
  const AppButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.backgroundColor,
    this.textColor,
  }) : variant = AppButtonVariant.outlined;
  
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
    this.backgroundColor,
    this.textColor,
  }) : variant = AppButtonVariant.text;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: AppDimensions.animationFast),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  double get _height {
    switch (widget.size) {
      case AppButtonSize.small:
        return AppDimensions.buttonHeightSmall;
      case AppButtonSize.medium:
        return AppDimensions.buttonHeightMedium;
      case AppButtonSize.large:
        return AppDimensions.buttonHeightLarge;
    }
  }

  double get _fontSize {
    switch (widget.size) {
      case AppButtonSize.small:
        return 14.0;
      case AppButtonSize.medium:
        return 16.0;
      case AppButtonSize.large:
        return 18.0;
    }
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Widget button = _buildButton(context);
    
    return GestureDetector(
      onTapDown: widget.onPressed != null ? _onTapDown : null,
      onTapUp: widget.onPressed != null ? _onTapUp : null,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value.clamp(0.8, 1.0),
            child: button,
          );
        },
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (widget.variant) {
      case AppButtonVariant.filled:
        return _buildFilledButton(context);
      case AppButtonVariant.outlined:
        return _buildOutlinedButton(context);
      case AppButtonVariant.text:
        return _buildTextButton(context);
    }
  }

  Widget _buildFilledButton(BuildContext context) {
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: _height,
      child: ElevatedButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? context.primary,
          foregroundColor: widget.textColor ?? context.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
          elevation: AppDimensions.elevationLow,
        ),
        icon: _buildIcon(context),
        label: _buildLabel(context),
      ),
    );
  }

  Widget _buildOutlinedButton(BuildContext context) {
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: _height,
      child: OutlinedButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: widget.textColor ?? context.primary,
          side: BorderSide(color: context.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          ),
        ),
        icon: _buildIcon(context),
        label: _buildLabel(context),
      ),
    );
  }

  Widget _buildTextButton(BuildContext context) {
    return SizedBox(
      width: widget.fullWidth ? double.infinity : null,
      height: _height,
      child: TextButton.icon(
        onPressed: widget.isLoading ? null : widget.onPressed,
        style: TextButton.styleFrom(
          foregroundColor: widget.textColor ?? context.primary,
        ),
        icon: _buildIcon(context),
        label: _buildLabel(context),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    if (widget.isLoading) {
      return SizedBox(
        width: AppDimensions.iconMedium,
        height: AppDimensions.iconMedium,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.variant == AppButtonVariant.filled 
                ? context.onPrimary 
                : context.primary,
          ),
        ),
      );
    }
    
    if (widget.icon != null) {
      return Icon(widget.icon, size: AppDimensions.iconMedium);
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildLabel(BuildContext context) {
    return Text(
      widget.text,
      style: TextStyle(
        fontSize: _fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}