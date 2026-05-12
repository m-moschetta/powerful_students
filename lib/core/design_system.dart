import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Design System centralizzato per Powerful Students
/// Evoluto per "Liquid Glass" e stile iOS 18/26
class AppColors {
  // Colori primari invertiti: Verde predominante, Rosa per CTA
  static const primary = Color(0xFFA9FFA6); // Verde (Branding principale)
  static const cta = Color(0xFFF4C3F1); // Rosa (Call to Action)
  static const accent = Color(0xFFA9FFA6); // Alias per il verde
  static const danger = Color(0xFFFF3B30); // Rosso iOS

  // Backgrounds
  static const background = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const separator = Color(0xFFE5E5EA); // Separatore iOS light

  // Vetro (Glassmorphism)
  static Color glass(double opacity) => Colors.white.withValues(alpha: opacity);
  static const glassBorder = Color(0x66000000);

  // Testi
  static const textPrimary = Color(0xFF000000);
  static const textSecondary = Color(0xFF1C1C1E);

  static Color textSecondaryWith(double opacity) {
    return textSecondary.withValues(alpha: opacity);
  }

  static Color primaryWith(double opacity) {
    return primary.withValues(alpha: opacity);
  }

  static Color ctaWith(double opacity) {
    return cta.withValues(alpha: opacity);
  }
}

class AppTypography {
  static const fontFamily = '.SF Pro Text';

  static const headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const subtitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    letterSpacing: -0.4,
  );

  static const caption = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: -0.2,
  );

  static const label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  static const timerLarge = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.w300,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -2.0,
  );
}

class AppSpacing {
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 32.0;
  static const xl = 48.0;
}

class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
}

class AppShadows {
  static const sm = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];

  static const md = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  static final ctaGlow = [
    BoxShadow(
      color: AppColors.cta.withValues(alpha: 0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

class AppDecorations {
  static Widget glassContainer({
    required Widget child,
    double blur = 20,
    double opacity = 0.1,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    Border? border,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.lg),
            border:
                border ?? Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: child,
        ),
      ),
    );
  }

  static BoxDecoration card() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: AppColors.separator),
      boxShadow: AppShadows.sm,
    );
  }
}

/// Asset paths for Bricky images
class AppAssets {
  static const brickyLogo = 'assets/images/bricky_logo.png';
  static const brickyBurn = 'assets/images/bricky_burn.png';
  static const brickyBurnSmall = 'assets/images/bricky_burn_small.png';
  static const brickyGroup = 'assets/images/bricky_group.png';
  static const brickyBroken = 'assets/images/Bricky rotto.png';
  static const brickyCounter = 'assets/images/1 mattoncino_2 mattoncini.png';
  static const brickyCelebration = 'assets/images/bricky_celebration.gif';
}

class AppIcons {
  static const soloMode = CupertinoIcons.person_fill;
  static const groupMode = CupertinoIcons.person_2_fill;
  static const fire = CupertinoIcons.flame_fill;
  static const burn = CupertinoIcons.bolt_fill;
  static const back = CupertinoIcons.chevron_back;
  static const check = CupertinoIcons.checkmark_circle_fill;
  static const share = CupertinoIcons.share;
  static const drag = CupertinoIcons.slider_horizontal_3;
}
