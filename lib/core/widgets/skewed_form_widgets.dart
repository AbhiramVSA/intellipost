import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Skewed Input Field - Part of the unique layered form design
/// Mimics the CSS skewed form aesthetic with 3D-like layer effects
class SkewedInputField extends StatefulWidget {
  final int layerIndex; // 1-4, determines the layer color
  final String placeholder;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool obscureText;
  final Widget? prefixIcon;

  const SkewedInputField({
    super.key,
    required this.layerIndex,
    required this.placeholder,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
  });

  @override
  State<SkewedInputField> createState() => _SkewedInputFieldState();
}

class _SkewedInputFieldState extends State<SkewedInputField>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _translateAnimation;
  bool _isFocused = false;
  bool _isHovered = false;

  // Layer colors matching the CSS design
  Color get _layerColor {
    switch (widget.layerIndex) {
      case 1:
        return AppColors.layer1;
      case 2:
        return AppColors.layer2;
      case 3:
        return AppColors.layer3;
      case 4:
        return AppColors.layer4;
      default:
        return AppColors.layer1;
    }
  }

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _translateAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered) {
      _hoverController.forward();
    } else if (!_isFocused) {
      _hoverController.reverse();
    }
  }

  void _onFocusChanged(bool hasFocus) {
    setState(() => _isFocused = hasFocus);
    if (hasFocus) {
      _hoverController.forward();
    } else if (!_isHovered) {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _translateAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_translateAnimation.value, 0),
          child: _buildSkewedContainer(),
        );
      },
    );
  }

  Widget _buildSkewedContainer() {
    const double fieldHeight = 50.0;
    const double sideWidth = 40.0;

    return SizedBox(
      height: fieldHeight + sideWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Top skewed panel (::after equivalent)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(0)
                ..setEntry(0, 1, -1.0), // skewX(45deg) approximation
              child: Container(
                height: sideWidth,
                decoration: BoxDecoration(
                  color: _layerColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Left skewed panel (::before equivalent)
          Positioned(
            top: sideWidth - 1,
            left: -sideWidth,
            child: Transform(
              alignment: Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..setEntry(1, 0, 1.0), // skewY(45deg) approximation
              child: Container(
                width: sideWidth,
                height: fieldHeight + 1,
                decoration: BoxDecoration(
                  color: _layerColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          // Main input container
          Positioned(
            top: sideWidth,
            left: 0,
            right: 0,
            child: MouseRegion(
              onEnter: (_) => _onHoverChanged(true),
              onExit: (_) => _onHoverChanged(false),
              child: Focus(
                onFocusChange: _onFocusChanged,
                child: Container(
                  height: fieldHeight,
                  decoration: BoxDecoration(
                    color: _layerColor,
                    border: _isFocused
                        ? Border.all(color: _layerColor.withValues(alpha: 0.8), width: 3)
                        : null,
                  ),
                  child: TextFormField(
                    controller: widget.controller,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    validator: widget.validator,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.placeholder,
                      hintStyle: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                      ),
                      prefixIcon: widget.prefixIcon,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      filled: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// AnimatedBuilder helper for the skewed input
class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilderWidget(
      animation: animation,
      builder: builder,
      child: child,
    );
  }
}

class AnimatedBuilderWidget extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilderWidget({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}

/// Skewed Submit Button - Matches the form design aesthetic
class SkewedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SkewedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<SkewedButton> createState() => _SkewedButtonState();
}

class _SkewedButtonState extends State<SkewedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _translateAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _translateAnimation = Tween<double>(begin: 0, end: -15).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
    _colorAnimation = ColorTween(
      begin: AppColors.primary,
      end: AppColors.primaryDark,
    ).animate(_hoverController);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHoverChanged(bool isHovered) {
    setState(() => _isHovered = isHovered);
    if (isHovered && !_isPressed) {
      _hoverController.forward();
    } else if (!_isPressed) {
      _hoverController.reverse();
    }
  }

  void _onTapDown(TapDownDetails _) {
    setState(() => _isPressed = true);
    _hoverController.reverse();
  }

  void _onTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _hoverController.forward();
    }
    widget.onPressed?.call();
  }

  void _onTapCancel() {
    setState(() => _isPressed = false);
    if (_isHovered) {
      _hoverController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_translateAnimation.value, 0),
          child: _buildSkewedButton(),
        );
      },
    );
  }

  Widget _buildSkewedButton() {
    const double buttonHeight = 50.0;
    const double sideWidth = 40.0;
    final buttonColor = _colorAnimation.value ?? AppColors.primary;

    return GestureDetector(
      onTapDown: widget.isLoading ? null : _onTapDown,
      onTapUp: widget.isLoading ? null : _onTapUp,
      onTapCancel: widget.isLoading ? null : _onTapCancel,
      child: MouseRegion(
        onEnter: (_) => _onHoverChanged(true),
        onExit: (_) => _onHoverChanged(false),
        cursor: widget.isLoading 
            ? SystemMouseCursors.wait 
            : SystemMouseCursors.click,
        child: SizedBox(
          height: buttonHeight + sideWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Top skewed panel
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.identity()..setEntry(0, 1, -1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: sideWidth,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              // Left skewed panel
              Positioned(
                top: sideWidth - 1,
                left: -sideWidth,
                child: Transform(
                  alignment: Alignment.centerRight,
                  transform: Matrix4.identity()..setEntry(1, 0, 1.0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: sideWidth,
                    height: buttonHeight + 1,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              // Main button
              Positioned(
                top: sideWidth,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: buttonColor,
                  ),
                  child: Center(
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary,
                              ),
                            ),
                          )
                        : Text(
                            widget.text,
                            style: AppTextStyles.button.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
