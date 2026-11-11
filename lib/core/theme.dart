import 'package:flutter/material.dart';

/// Tema Dokter HP: terang, basis putih, aksen hitam dan abu-abu.
///
/// Keputusan desain (satu baris per keputusan):
/// - Putih/hitam/abu saja karena aplikasi alat harus tenang dan mudah
///   dibaca, bukan pajangan.
/// - Tanpa warna dekoratif (tanpa kuning/amber) dan tanpa font serif
///   Didone/Playfair; font memakai font sistem agar build tidak
///   bergantung pada unduhan font dari internet.
/// - Radius 12 di semua kartu dan tombol agar satu sistem bentuk.
/// - Tombol minimal 48 px karena area sentuh yang nyaman di HP.
/// - Warna teks sekunder memakai abu #757575 karena kontrasnya 4,6:1
///   terhadap putih, lolos WCAG AA untuk teks biasa.
class AppTheme {
  AppTheme._();

  static const Color ink = Color(0xFF111111);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color surfaceGrey = Color(0xFFF5F5F5);
  static const Color lineGrey = Color(0xFFE0E0E0);

  /// Abu untuk teks sekunder. Jangan pakai abu yang lebih muda dari ini
  /// untuk teks, karena kontrasnya jatuh di bawah 4,5:1.
  static const Color mutedGrey = Color(0xFF757575);

  /// Warna status fungsional saja (bukan dekorasi).
  static const Color success = Color(0xFF1B7A3D);
  static const Color danger = Color(0xFFB3261E);
  static const Color info = Color(0xFF1565C0);

  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: ink,
      onPrimary: paper,
      secondary: Color(0xFF424242),
      onSecondary: paper,
      surface: paper,
      onSurface: ink,
      onSurfaceVariant: mutedGrey,
      error: danger,
      onError: paper,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: paper,
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: ink,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: lineGrey),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: paper,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: ink),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(64, 48),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lineGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lineGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ink, width: 2),
        ),
      ),
      dividerColor: lineGrey,
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: TextStyle(color: paper),
      ),
    );
  }
}
