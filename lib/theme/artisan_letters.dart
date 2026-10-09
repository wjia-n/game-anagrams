import 'package:flutter/material.dart';
import 'tile_themes.dart';

/// Artisan Letters — the physical-material design system for Anagrams.
/// Wooden letter tiles, a felt tray, brass trim. No neon, no cyberpunk,
/// no generic Material look.
class Atelier {
  static TextStyle display(double size,
          {Color? color, TileThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
        shadows: const [
          Shadow(
              color: Color(0xAA000000), offset: Offset(0, 2), blurRadius: 5),
        ],
      );

  static TextStyle body(double size, {Color? color, TileThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: color ?? theme?.ivory ?? const Color(0xFFF5EFE0),
      );

  static TextStyle label(double size, {Color? color, TileThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
      );

  static ThemeData theme(TileThemeDef t) {
    final darkText = false;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.woodDark,
      colorScheme: ColorScheme(
        brightness: darkText ? Brightness.light : Brightness.dark,
        primary: t.accent,
        onPrimary: t.woodDeep,
        secondary: t.accentLight,
        onSecondary: t.woodDeep,
        surface: t.woodMid,
        onSurface: t.ivory,
        error: t.playerColors[0],
        onError: t.ivory,
      ),
      textTheme: TextTheme(
        displayLarge: display(34, theme: t),
        displayMedium: display(26, theme: t),
        titleLarge: display(22, theme: t),
        bodyLarge: body(16, theme: t),
      ),
    );
  }
}

/// Dark wooden backdrop with a subtle vignette (painted, no images).
class WoodBackdrop extends StatelessWidget {
  final TileThemeDef theme;
  final Widget child;
  const WoodBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.woodMid, theme.woodDark, theme.woodDeep],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// A physical letter tile: face color, darker beveled edge, top-left
/// highlight for a carved-wood read, soft floor shadow.
class LetterTile extends StatelessWidget {
  final String letter;
  final double size;
  final Color face;
  final Color edge;
  final Color textColor;
  final double radius;
  final bool dimmed; // used/placed tiles sink into the tray
  final bool highlighted; // correct-guess glow frame
  final bool danger; // wrong-guess red tint
  const LetterTile({
    super.key,
    required this.letter,
    required this.size,
    required this.face,
    required this.edge,
    required this.textColor,
    this.radius = 10,
    this.dimmed = false,
    this.highlighted = false,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final f = danger ? face.withValues(alpha: 0.85) : face;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: f,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: highlighted
              ? const Color(0xFF7ED77E)
              : danger
                  ? const Color(0xFFD65348)
                  : edge,
          width: highlighted || danger ? 3 : 2,
        ),
        boxShadow: dimmed
            ? null
            : [
                const BoxShadow(
                    color: Color(0xAA000000),
                    offset: Offset(0, 4),
                    blurRadius: 8),
                BoxShadow(
                    color: f.withValues(alpha: 0.35),
                    offset: const Offset(-2, -2),
                    blurRadius: 4), // top-light bevel
              ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter.toUpperCase(),
        style: TextStyle(
          fontSize: size * 0.52,
          fontWeight: FontWeight.w900,
          color: dimmed ? textColor.withValues(alpha: 0.4) : textColor,
          shadows: dimmed
              ? null
              : const [
                  Shadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 1),
                      blurRadius: 1),
                ],
        ),
      ),
    );
  }
}

/// Chunky carved-wood button.
class WoodButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final TileThemeDef theme;
  final double width;
  final double fontSize;
  final bool primary;
  const WoodButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 220,
    this.fontSize = 17,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: primary
                ? [theme.accentLight, theme.accent, theme.accentDark]
                : [
                    theme.woodMid.withValues(alpha: 0.95),
                    theme.woodDeep.withValues(alpha: 0.95),
                  ],
          ),
          border: Border.all(
              color: primary ? theme.woodDeep : theme.accentDark, width: 2),
          boxShadow: const [
            BoxShadow(
                color: Color(0xAA000000), offset: Offset(0, 5), blurRadius: 10),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: primary ? theme.woodDeep : theme.accentLight,
          ),
        ),
      ),
    );
  }
}

/// Rounded panel card.
class WoodCard extends StatelessWidget {
  final TileThemeDef theme;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const WoodCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodMid.withValues(alpha: 0.9),
            theme.woodDeep.withValues(alpha: 0.92),
          ],
        ),
        border: Border.all(color: theme.accent.withValues(alpha: 0.7), width: 2),
        boxShadow: const [
          BoxShadow(
              color: Color(0xAA000000), offset: Offset(0, 6), blurRadius: 14),
        ],
      ),
      child: child,
    );
  }
}
