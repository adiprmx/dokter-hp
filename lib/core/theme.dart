import 'package:flutter/material.dart';

/// Tema Dokter HP v1.1.0: gelap, basis hitam, aksen putih.
///
/// Keputusan desain (satu baris per keputusan, lihat
/// docs/redesign-v11-spec.md bagian 3 dan DESIGN.md):
/// - Tema gelap karena design lock owner menulis basis hitam dengan
///   aksen putih; keputusan terang v1.0.0 dibuat tim audit, bukan owner.
/// - Satu tema saja yang dikirim (gelap), tanpa toggle terang/gelap.
/// - Warna hanya status fungsional (hijau/merah/kuning/biru) dan logo
///   brand pihak ketiga; tanpa warna dekoratif dan tanpa gradasi.
/// - Font tetap font sistem agar build offline tidak bergantung pada
///   unduhan font; angka memakai angka tabular agar tidak bergeser
///   saat nilai live berubah.
/// - Abu paling gelap untuk teks adalah #757575 (kontras 4,56:1 di
///   atas hitam, lolos WCAG AA); #737373 gagal di 4,43:1.
class AppTheme {
  AppTheme._();

  // Permukaan.
  static const Color bg = Color(0xFF000000);
  static const Color surface = Color(0xFF111111);
  static const Color surfaceRaised = Color(0xFF1C1C1C);
  static const Color line = Color(0xFF262626);
  static const Color lineStrong = Color(0xFF3D3D3D);
  static const Color track = Color(0xFF2A2A2A);

  // Teks.
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA3A3A3);

  /// Abu paling redup yang boleh dipakai untuk teks. Jangan pakai abu
  /// yang lebih gelap untuk teks, karena kontrasnya jatuh di bawah 4,5:1.
  static const Color textFaint = Color(0xFF757575);

  /// Aksen: putih. Tombol utama, penanda meter, elemen fokus.
  static const Color accent = Color(0xFFFFFFFF);

  // Status fungsional saja (bukan dekorasi).
  static const Color success = Color(0xFF4ADE80);
  static const Color danger = Color(0xFFF87171);
  static const Color warning = Color(0xFFFACC15);
  static const Color info = Color(0xFF60A5FA);

  // Tipografi (satu sistem, lihat spesifikasi bagian 3.2).
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];

  /// Satu angka besar per layar (skor, kecepatan, persen baterai).
  static const TextStyle display = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    height: 1.0,
    letterSpacing: -1.12,
    fontFeatures: tabularFigures,
    color: textPrimary,
  );

  /// Judul layar di AppBar besar (Dashboard).
  static const TextStyle headline = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.15,
    color: textPrimary,
  );

  /// Judul layar di AppBar biasa.
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    color: textPrimary,
  );

  /// Judul bagian di dalam layar.
  static const TextStyle section = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: textPrimary,
  );

  /// Isi, penjelasan, jawaban AI.
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: textPrimary,
  );

  /// Label di atas nilai, keterangan baris.
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: textSecondary,
  );

  /// Cap waktu, catatan kaki. Minimal 12, tidak ada teks 10-11.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: textSecondary,
  );

  /// Teks tombol (15/600).
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  // Spacing skala 4 pt (spesifikasi bagian 3.3).
  static const double pagePadding = 20;
  static const double sectionGap = 32;
  static const double cardGap = 12;
  static const double cardPadding = 20;
  static const double bottomPadding = 32;

  // Radius satu sistem (spesifikasi bagian 3.4).
  static const double radiusCard = 16;
  static const double radiusButton = 12;
  static const double radiusChip = 8;
  static const double radiusMeter = 4;

  // Gerak (spesifikasi bagian 3.7).
  static const Duration tapFeedback = Duration(milliseconds: 200);
  static const Duration resultTransition = Duration(milliseconds: 350);
  static const Duration countUp = Duration(milliseconds: 600);
  static const Duration pressScale = Duration(milliseconds: 100);
  static const Duration shimmerCycle = Duration(milliseconds: 1200);
  static const Duration livePulse = Duration(milliseconds: 1200);

  /// True bila pengguna mengaktifkan pengurangan gerak di sistem:
  /// semua gerak menjadi instan.
  static bool animationsDisabled(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  static ThemeData dark() {
    const colorScheme = ColorScheme.dark(
      primary: accent,
      onPrimary: bg,
      secondary: textSecondary,
      onSecondary: bg,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      error: danger,
      onError: bg,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      textTheme: const TextTheme(
        displayLarge: display,
        headlineLarge: headline,
        headlineMedium: headline,
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.2,
          color: textPrimary,
        ),
        titleLarge: title,
        titleMedium: section,
        titleSmall: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: textPrimary,
        ),
        bodyLarge: body,
        bodyMedium: body,
        bodySmall: label,
        labelLarge: button,
        labelMedium: label,
        labelSmall: caption,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: textPrimary,
        selectionColor: textPrimary.withValues(alpha: 0.3),
        selectionHandleColor: textPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accent,
        linearTrackColor: track,
        circularTrackColor: track,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: title,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: line),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
          side: const BorderSide(color: lineStrong),
        ),
        titleTextStyle: section,
        contentTextStyle: body,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusCard),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bg,
          disabledBackgroundColor: track,
          disabledForegroundColor: textFaint,
          minimumSize: const Size.fromHeight(56),
          textStyle: button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size.fromHeight(56),
          textStyle: button,
          side: const BorderSide(color: lineStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          minimumSize: const Size(64, 48),
          textStyle: button,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: body.copyWith(color: textSecondary),
        labelStyle: body.copyWith(color: textSecondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(color: lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(color: lineStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusButton),
          borderSide: const BorderSide(color: danger, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(color: line, thickness: 1),
      dividerColor: line,
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: body,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
