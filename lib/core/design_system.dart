import 'package:flutter/material.dart';

/// Design System centralizzato per Powerful Students
/// Garantisce coerenza visiva su tutte le schermate
class AppColors {
  // Colori primari
  static const primary = Color(0xFFF4C3F1); // Rosa - azioni principali
  static const secondary = Color(0xFFA9FFA6); // Verde - interattivi

  // Backgrounds
  static const background = Color(0xFFE7E7E7); // Grigio chiaro
  static const surface = Color(0xFFE9E9E9); // Grigio cards
  static const surfaceLight = Colors.white;

  // Testi
  static const textPrimary = Color(0xFF2A2A2A); // Nero soft
  static const textSecondary = Color(0xFF2F2F2F); // Con opacity 0.8

  // Stati
  static const success = Color(0xFFA9FFA6);
  static const error = Color(0xFFFF6B6B);
  static const warning = Color(0xFFFFA06B);

  // Helpers per opacity
  static Color textSecondaryWith(double opacity) {
    return textSecondary.withValues(alpha: opacity);
  }

  static Color primaryWith(double opacity) {
    return primary.withValues(alpha: opacity);
  }

  static Color secondaryWith(double opacity) {
    return secondary.withValues(alpha: opacity);
  }
}

class AppTypography {
  static const fontFamily = 'Helvetica';

  // Display (titoli grandi)
  static const headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  // Titoli sezioni
  static const title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    letterSpacing: 0.5,
  );

  // Sottotitoli
  static const subtitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    letterSpacing: 0.3,
  );

  // Body text
  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    letterSpacing: 0.3,
  );

  // Caption
  static const caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    letterSpacing: 0.3,
  );

  // Label (piccolo)
  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
    letterSpacing: 0.3,
  );

  // Timer grande
  static const timerLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );

  // Timer medio
  static const timerMedium = TextStyle(
    fontSize: 42,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    fontFamily: fontFamily,
  );
}

class AppSpacing {
  static const xs = 8.0;
  static const sm = 16.0;
  static const md = 24.0;
  static const lg = 40.0;
  static const xl = 60.0;
}

class AppRadius {
  static const sm = 12.0;
  static const md = 20.0;
  static const lg = 24.0;

  static BorderRadius circular(double radius) => BorderRadius.circular(radius);
  static RoundedRectangleBorder roundedRectangle(double radius) {
    return RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius));
  }
}

class AppShadows {
  static List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> md = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> lg = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double alpha = 0.5}) {
    return [
      BoxShadow(
        color: color.withValues(alpha: alpha),
        blurRadius: 16,
        spreadRadius: 2,
        offset: const Offset(0, 4),
      ),
    ];
  }
}

class AppButtons {
  // Pulsante primario (Study/Inizia)
  static ButtonStyle primary({bool enabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: enabled ? AppColors.primary : AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: 18,
      ),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: AppRadius.roundedRectangle(AppRadius.sm),
      disabledBackgroundColor: AppColors.surface,
    ).copyWith(elevation: WidgetStateProperty.all(0));
  }

  // Pulsante secondario (Cancel)
  static ButtonStyle secondary() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.textPrimary,
      padding: const EdgeInsets.symmetric(vertical: 18),
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: AppRadius.roundedRectangle(AppRadius.sm),
    ).copyWith(elevation: WidgetStateProperty.all(0));
  }

  // Text style per pulsanti
  static const textStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: AppTypography.fontFamily,
  );
}

class AppDecorations {
  // Badge/Pill (es. modalità selezionata)
  static BoxDecoration badge({Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      boxShadow: AppShadows.sm,
    );
  }

  // Card standard
  static BoxDecoration card({required bool isSelected, Color? selectedColor}) {
    return BoxDecoration(
      color: isSelected
          ? (selectedColor ?? AppColors.secondary)
          : AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(
        color: isSelected
            ? AppColors.textPrimary
            : AppColors.textPrimary.withValues(alpha: 0.3),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.05),
          blurRadius: isSelected ? 12 : 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // Cerchio timer
  static BoxDecoration timerCircle({bool withBorder = true}) {
    return BoxDecoration(
      color: AppColors.surfaceLight,
      shape: BoxShape.circle,
      border: withBorder
          ? Border.all(color: AppColors.secondary, width: 8)
          : null,
      boxShadow: AppShadows.lg,
    );
  }

  // Container circolare (es. icone)
  static BoxDecoration circleContainer({Color? color}) {
    return BoxDecoration(
      color: color ?? AppColors.surface,
      shape: BoxShape.circle,
    );
  }
}

class AppIcons {
  static const soloMode = Icons.person;
  static const groupMode = Icons.group;
  static const fire = Icons.local_fire_department;
  static const burn = Icons.whatshot;
  static const back = Icons.arrow_back;
  static const check = Icons.check_circle;
  static const share = Icons.share;
  static const drag = Icons.drag_indicator;
}
