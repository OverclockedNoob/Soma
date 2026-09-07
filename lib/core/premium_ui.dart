import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ════════════════════════════════════════════════════════════
//  WORKOUT TRACKER — PREMIUM DESIGN SYSTEM
// ════════════════════════════════════════════════════════════

class PUI {
  static const Color bg = Color(0xFF05060A);
  static const Color surface = Color(0xFF0D1016);
  static const Color primary = Color(0xFF8B7CFF);
  static const Color primaryDeep = Color(0xFF5A3CC4);
  static const Color mint = Color(0xFF3DDCB8);
  static const Color amber = Color(0xFFFFC24A);
  static const Color flame = Color(0xFFFF6B4A);
  static const Color pink = Color(0xFFFF6B9D);

  static TextStyle text({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = Colors.white,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.outfit(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );
}

// ── PRESS PHYSICS (squishes when tapped) ─────────────────────
class Pressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const Pressable({super.key, required this.child, this.onTap});

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
           return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── FROSTED GLASS CARD ────────────────────────────────────────
class Glass extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry? padding;

  const Glass({super.key, required this.child, this.radius = 24, this.padding});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.02),
              ],
            ),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ── METALLIC GRADIENT TEXT ────────────────────────────────────
class GradientText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final List<Color>? colors;

  const GradientText(
    this.text, {
    super.key,
    this.size = 20,
    this.weight = FontWeight.w800,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors ?? [Colors.white, Colors.white.withOpacity(0.55)],
      ).createShader(rect),
      child: Text(text, style: PUI.text(size: size, weight: weight)),
    );
  }
}

// ── UPPERCASE SECTION LABEL ───────────────────────────────────
class SectionTitle extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: PUI.text(
            size: 12,
            weight: FontWeight.w700,
            letterSpacing: 1.8,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        if (actionLabel != null)
          Pressable(
            onTap: onAction,
            child: Text(
              actionLabel!.toUpperCase(),
              style: PUI.text(
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 1.2,
                color: PUI.mint,
              ),
            ),
          ),
      ],
    );
  }
}

// ── GLOWING CTA BUTTON ────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool muted;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onTap,
    this.muted = false,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: muted
              ? null
              : const LinearGradient(colors: [PUI.primary, PUI.primaryDeep]),
          color: muted ? Colors.white.withOpacity(0.05) : null,
          borderRadius: BorderRadius.circular(20),
          border: muted ? Border.all(color: Colors.white.withOpacity(0.1)) : null,
          boxShadow: muted
              ? []
              : [
                  BoxShadow(
                    color: PUI.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: muted ? Colors.white70 : Colors.white, size: 24),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: PUI.text(
                    size: 16,
                    weight: FontWeight.w800,
                    color: muted ? Colors.white70 : Colors.white,
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

// ── AMBIENT AURORA BACKGROUND ─────────────────────────────────
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              top: -260,
              left: -180,
              child: Container(
                width: 650,
                height: 650,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    radius: 1.0,
                    colors: [
                      PUI.primary.withOpacity(0.14),
                      PUI.primary.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -160,
              right: -220,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    radius: 1.0,
                    colors: [
                      PUI.mint.withOpacity(0.08),
                      PUI.mint.withOpacity(0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PREMIUM SCAFFOLD (use on EVERY screen) ────────────────────
class PremiumScaffold extends StatelessWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget body;
  final bool aurora;
  final Widget? bottomNavigationBar;
  final bool safeArea;

  const PremiumScaffold({
    super.key,
    this.title,
    this.actions,
    required this.body,
    this.aurora = true,
    this.bottomNavigationBar,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PUI.bg,
      extendBodyBehindAppBar: true,
      bottomNavigationBar: bottomNavigationBar,
      appBar: title == null
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leadingWidth: Navigator.canPop(context) ? 64 : 0,
              leading: !Navigator.canPop(context)
                  ? null
                  : Padding(
                padding: const EdgeInsets.all(10),
                child: Pressable(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 18),
                  ),
                ),
              ),
              title: Text(title!, style: PUI.text(size: 20, weight: FontWeight.w800)),
              centerTitle: true,
              actions: actions,
            ),
      body: Stack(
        children: [
          if (aurora) const AuroraBackground(),
          if (safeArea) SafeArea(child: body) else body,
        ],
      ),
    );
  }
}

// ── GLASS BOTTOM NAVIGATION BAR ───────────────────────────────
class PremiumBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const PremiumBottomBar({super.key, required this.index, required this.onTap});

  static const List<_NavItem> _items = [
    _NavItem(Icons.home_rounded, 'Home'),
    _NavItem(Icons.fitness_center, 'Library'),
    _NavItem(Icons.bar_chart_rounded, 'Stats'),
    _NavItem(Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final active = i == index;
              return Expanded(
                child: Pressable(
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                          horizontal: active ? 14 : 0,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: active
                              ? const LinearGradient(
                                  colors: [PUI.primary, PUI.primaryDeep])
                              : null,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: PUI.primary.withOpacity(0.4),
                                    blurRadius: 12,
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          _items[i].icon,
                          color: active ? Colors.white : Colors.white.withOpacity(0.35),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _items[i].label,
                        style: PUI.text(
                          size: 10,
                          weight: active ? FontWeight.w700 : FontWeight.w500,
                          color: active ? Colors.white : Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}