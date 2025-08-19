import 'package:flutter/material.dart';
import 'dart:ui'; // Added for ImageFilter
import 'dart:math'; // Added for cos, sin functions

class AppColors {
  static const Color primary = Color(0xFF6C63FF); // Vibrant blue-purple
  static const Color secondary = Color(0xFF00D2FF); // Teal
  static const Color background = Color(0xFFF5F7FA); // Light background
  static const Color card = Colors.white;
  static const Color glass = Color(0x80FFFFFF); // Semi-transparent white
  static const Color accent = Color(0xFFB621FE); // Purple accent
  static const Color text = Color(0xFF22223B);
  static const Color error = Color(0xFFFF5252);
}

final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  fontFamily: 'Roboto',
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.text),
    titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.text),
    bodyLarge: TextStyle(fontSize: 16, color: AppColors.text),
    bodyMedium: TextStyle(fontSize: 14, color: AppColors.text),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.glass,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: Color(0x336C63FF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: AppColors.error),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.primary),
      foregroundColor: WidgetStatePropertyAll(Colors.white),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16)))),
      padding: WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 16, horizontal: 32)),
      textStyle: WidgetStatePropertyAll(TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      elevation: WidgetStatePropertyAll(8),
      shadowColor: WidgetStatePropertyAll(AppColors.primary.withOpacity(0.2)),
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.glass,
    elevation: 8,
    shadowColor: AppColors.primary.withOpacity(0.1),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
    margin: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
  ),
  iconTheme: const IconThemeData(color: AppColors.primary, size: 28),
);

// Glassmorphism card widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const GlassCard({required this.child, this.padding, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

// 3D Glassmorphic Card with animated shadow
class Glass3DCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const Glass3DCard({required this.child, this.padding, super.key});

  @override
  State<Glass3DCard> createState() => _Glass3DCardState();
}

class _Glass3DCardState extends State<Glass3DCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shadowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _shadowAnim = Tween<double>(begin: 8, end: 24).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shadowAnim,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.glass,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.18),
                blurRadius: _shadowAnim.value,
                offset: Offset(0, _shadowAnim.value / 2),
              ),
              BoxShadow(
                color: AppColors.secondary.withOpacity(0.10),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Padding(
                padding: widget.padding ?? const EdgeInsets.all(28),
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Neumorphic 3D Button
class Neumorphic3DButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;
  final Color? color;
  const Neumorphic3DButton({required this.child, required this.onTap, this.borderRadius = 18, this.color, super.key});

  @override
  State<Neumorphic3DButton> createState() => _Neumorphic3DButtonState();
}

class _Neumorphic3DButtonState extends State<Neumorphic3DButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.card;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    offset: const Offset(-6, -6),
                    blurRadius: 16,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.18),
                    offset: const Offset(6, 6),
                    blurRadius: 16,
                  ),
                ],
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

// Usage Example (in your page):
// Glass3DCard(
//   child: Column(children: [ ... ]),
// )
// Neumorphic3DButton(
//   child: Text('3D Button'),
//   onTap: () {},
// ) 

// Animated Background with gradient and floating particles
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  const AnimatedBackground({required this.child, super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  late Animation<double> _particleAnimation;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _gradientAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _gradientController, curve: Curves.easeInOut),
    );
    
    _particleAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_gradientAnimation, _particleAnimation]),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(0.1 + _gradientAnimation.value * 0.1),
                AppColors.secondary.withOpacity(0.05 + _gradientAnimation.value * 0.05),
                AppColors.accent.withOpacity(0.08 + _gradientAnimation.value * 0.08),
              ],
              stops: [
                0.0,
                0.5 + _gradientAnimation.value * 0.1,
                1.0,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Floating particles
              ...List.generate(15, (index) => _buildParticle(index)),
              // Main content
              widget.child,
            ],
          ),
        );
      },
    );
  }

  Widget _buildParticle(int index) {
    final random = (index * 0.1) % 1.0;
    final size = 2.0 + (random * 4.0);
    final opacity = 0.1 + (random * 0.2);
    
    return Positioned(
      left: (index * 80.0 + _particleAnimation.value * 50) % MediaQuery.of(context).size.width,
      top: (index * 60.0 + _particleAnimation.value * 30) % MediaQuery.of(context).size.height,
      child: AnimatedBuilder(
        animation: _particleAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: opacity * (0.5 + 0.5 * _particleAnimation.value),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Touch Effect Overlay with ripple and particle effects
class TouchEffectOverlay extends StatefulWidget {
  final Widget child;
  const TouchEffectOverlay({required this.child, super.key});

  @override
  State<TouchEffectOverlay> createState() => _TouchEffectOverlayState();
}

class _TouchEffectOverlayState extends State<TouchEffectOverlay>
    with TickerProviderStateMixin {
  final List<_TouchEffect> _effects = [];
  final List<_ParticleEffect> _particles = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _addTouchEffect(details.localPosition),
      onPanUpdate: (details) => _addTouchEffect(details.localPosition),
      child: Stack(
        children: [
          widget.child,
          // Touch ripple effects
          ..._effects.map((effect) => _buildTouchEffect(effect)),
          // Particle effects
          ..._particles.map((particle) => _buildParticleEffect(particle)),
        ],
      ),
    );
  }

  void _addTouchEffect(Offset position) {
    final effect = _TouchEffect(
      position: position,
      controller: AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      ),
    );
    
    final particle = _ParticleEffect(
      position: position,
      controller: AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
    );

    setState(() {
      _effects.add(effect);
      _particles.add(particle);
    });

    effect.controller.forward().then((_) {
      setState(() => _effects.remove(effect));
      effect.controller.dispose();
    });

    particle.controller.forward().then((_) {
      setState(() => _particles.remove(particle));
      particle.controller.dispose();
    });
  }

  Widget _buildTouchEffect(_TouchEffect effect) {
    return AnimatedBuilder(
      animation: effect.controller,
      builder: (context, child) {
        final scale = 1.0 + (effect.controller.value * 2.0);
        final opacity = 1.0 - effect.controller.value;
        
        return Positioned(
          left: effect.position.dx - 20,
          top: effect.position.dy - 20,
          child: Transform.scale(
            scale: scale,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(opacity * 0.3),
                border: Border.all(
                  color: AppColors.primary.withOpacity(opacity * 0.6),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticleEffect(_ParticleEffect particle) {
    return AnimatedBuilder(
      animation: particle.controller,
      builder: (context, child) {
        final progress = particle.controller.value;
        final angle = progress * 2 * 3.14159;
        final radius = progress * 50;
        
        return Positioned(
          left: particle.position.dx + radius * cos(angle),
          top: particle.position.dy + radius * sin(angle),
          child: Opacity(
            opacity: 1.0 - progress,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.secondary,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.5),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper classes for touch effects
class _TouchEffect {
  final Offset position;
  final AnimationController controller;
  
  _TouchEffect({required this.position, required this.controller});
}

class _ParticleEffect {
  final Offset position;
  final AnimationController controller;
  
  _ParticleEffect({required this.position, required this.controller});
} 