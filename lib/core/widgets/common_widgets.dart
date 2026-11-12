import 'package:flutter/material.dart';
import 'package:dokter_hp/core/theme.dart';

/// Widget bersama v1.1.0: meter dengan tanda strip, baris data, chip
/// status, tombol, header bagian, kartu, strip status, skeleton,
/// empty/error state, dialog, dan bottom sheet.
///
/// Aturan yang dipakai di file ini (spesifikasi bagian 3-5):
/// - Satu sistem warna gelap dari [AppTheme]; abu paling gelap untuk
///   teks adalah #757575 (kontras 4,56:1, lolos WCAG AA).
/// - Tap target minimal 48x48, kontras minimal 4,5:1.
/// - Tidak ada data dummy: angka hanya dari data nyata.
/// - Gerak menghormati pengaturan pengurangan gerak di sistem.

/// Label kategori skor dari nilai mentah yang tersimpan di database
/// ('baik'/'cukup'/'buruk').
String labelKategori(String kategori) {
  switch (kategori) {
    case 'baik':
      return 'Baik';
    case 'cukup':
      return 'Cukup';
    case 'buruk':
      return 'Perlu perhatian';
    default:
      return kategori;
  }
}

const _namaBulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Format tanggal dan jam yang mudah dibaca, misal "11 Nov 2026, 12:34".
/// Dipakai di dashboard dan riwayat sebagai pengganti string DateTime
/// mentah ("2026-11-11 12:34:56.789").
String formatTanggalWaktu(DateTime waktu) {
  final lokal = waktu.toLocal();
  return '${lokal.day} ${_namaBulan[lokal.month - 1]} ${lokal.year}, '
      '${formatJam(lokal)}';
}

/// Format tanggal saja, misal "11 Nov 2026".
String formatTanggal(DateTime waktu) {
  final lokal = waktu.toLocal();
  return '${lokal.day} ${_namaBulan[lokal.month - 1]} ${lokal.year}';
}

/// Format jam saja, misal "12:34".
String formatJam(DateTime waktu) {
  final lokal = waktu.toLocal();
  final jam = lokal.hour.toString().padLeft(2, '0');
  final menit = lokal.minute.toString().padLeft(2, '0');
  return '$jam:$menit';
}

/// Format jam dengan detik, misal "12:34:56".
String formatJamDetik(DateTime waktu) {
  final lokal = waktu.toLocal();
  final detik = lokal.second.toString().padLeft(2, '0');
  return '${formatJam(lokal)}:$detik';
}

/// Pembatas tanggal linimasa: "Hari ini", "Kemarin", atau tanggal
/// ("11 Nov 2026").
String formatTanggalHeader(DateTime waktu) {
  final lokal = waktu.toLocal();
  final sekarang = DateTime.now();
  final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
  final hariWaktu = DateTime(lokal.year, lokal.month, lokal.day);
  final selisih = hariIni.difference(hariWaktu).inDays;
  if (selisih == 0) return 'Hari ini';
  if (selisih == 1) return 'Kemarin';
  return formatTanggal(lokal);
}

/// Umpan balik tekan: skala 0,97 selama 100 ms. Dipakai semua tombol
/// dan kartu yang bisa diketuk. Nonaktif bila pengurangan gerak aktif.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _ditekan = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppTheme.animationsDisabled(context)) {
      return widget.child;
    }
    return GestureDetector(
      onTapDown: (_) => setState(() => _ditekan = true),
      onTapUp: (_) => setState(() => _ditekan = false),
      onTapCancel: () => setState(() => _ditekan = false),
      child: AnimatedScale(
        scale: _ditekan ? 0.97 : 1.0,
        duration: AppTheme.pressScale,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Tombol utama: latar putih, teks hitam, tinggi 56, radius 12.
/// Satu aksi utama per layar.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.leading,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;

  /// Widget di kiri label sebagai pengganti [icon] (misal logo Google).
  final Widget? leading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget tombol;
    if (leading != null) {
      tombol = FilledButton.icon(
        onPressed: onPressed,
        icon: leading!,
        label: Text(label),
      );
    } else if (icon == null) {
      tombol = FilledButton(
        onPressed: onPressed,
        child: Text(label),
      );
    } else {
      tombol = FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
      );
    }
    return _PressScale(
      enabled: onPressed != null,
      child: SizedBox(width: double.infinity, child: tombol),
    );
  }
}

/// Tombol sekunder: bingkai 1 px, teks putih, tinggi 56, radius 12.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tombol = icon == null
        ? OutlinedButton(
            onPressed: onPressed,
            child: Text(label),
          )
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
          );
    return _PressScale(
      enabled: onPressed != null,
      child: SizedBox(width: double.infinity, child: tombol),
    );
  }
}

/// Tombol teks: tanpa latar dan bingkai, tinggi minimum 48. Varian
/// [destructive] memakai teks merah untuk aksi destruktif.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: destructive
          ? TextButton.styleFrom(foregroundColor: AppTheme.danger)
          : null,
      child: Text(label),
    );
  }
}

/// Nada warna chip status.
enum StatusTone { success, danger, warning, info, neutral }

extension _StatusToneColor on StatusTone {
  Color get color {
    switch (this) {
      case StatusTone.success:
        return AppTheme.success;
      case StatusTone.danger:
        return AppTheme.danger;
      case StatusTone.warning:
        return AppTheme.warning;
      case StatusTone.info:
        return AppTheme.info;
      case StatusTone.neutral:
        return AppTheme.textSecondary;
    }
  }
}

/// Chip kecil: ikon plus teks, tidak pernah warna saja. Latar warna
/// status dengan opasitas 12 persen, teks warna status penuh.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.icon,
    this.tone = StatusTone.neutral,
    this.large = false,
  });

  final String label;
  final IconData icon;
  final StatusTone tone;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final warna = tone.color;
    // UnconstrainedBox: Container tanpa lebar melebar selebar parent bila
    // chip diletakkan langsung di ListView/Column (kendala lebar ketat).
    // Terbukti di layar Akun v1.1.0: chip "Mode lokal" jadi selebar layar,
    // bukan chip kecil seperti spesifikasi bagian 4.3. Row min dan
    // IntrinsicWidth TIDAK cukup di sini: kendala ketat memaksa ukuran
    // widget jadi selebar parent apa pun isinya (terbukti dua test
    // regresi gagal). UnconstrainedBox melonggarkan kendala untuk
    // Container, jadi latar chip selalu sekecil isinya; kotaknya sendiri
    // tetap selebar parent tapi transparan. Label chip di aplikasi ini
    // pendek, jadi anak tanpa kendala tidak akan meluap.
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: warna.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: large ? 12 : 10,
          vertical: large ? 8 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: large ? 20 : 16, color: warna),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: large
                    ? AppTheme.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: warna,
                      )
                    : AppTheme.label.copyWith(color: warna),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Titik denyut hijau untuk pemantau live: satu-satunya animasi loop
/// yang diizinkan, karena menandai pemantauan yang benar-benar aktif.
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.livePulse,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppTheme.animationsDisabled(context)) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.success,
          shape: BoxShape.circle,
        ),
      );
    }
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.success,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Chip "Live" dengan titik denyut hijau.
class LiveChip extends StatelessWidget {
  const LiveChip({super.key});

  @override
  Widget build(BuildContext context) {
    // UnconstrainedBox: alasan yang sama seperti StatusChip, latar chip
    // tidak boleh melebar selebar parent (misal di dalam Expanded panel
    // live saat pemantau aktif).
    return UnconstrainedBox(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.success.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LiveDot(),
            SizedBox(width: 6),
            Text(
              'Live',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
                color: AppTheme.success,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ukuran meter: besar (angka 56) untuk dashboard, WiFi, baterai;
/// ringkas (angka 28) untuk Performa dan Penyimpanan.
enum MeterSize { large, compact }

/// Meter horizontal dengan tanda strip: motif identitas aplikasi.
///
/// Anatomi: angka besar di kiri atas, chip kategori di kanan angka,
/// garis meter di bawah angka dengan strip vertikal tiap interval,
/// penanda nilai berupa blok putih yang menembus garis, dan label
/// skala di bawah garis. Saat nilai berubah, penanda meluncur
/// (350 ms) dan angka menghitung (600 ms).
class MeterGauge extends StatelessWidget {
  const MeterGauge({
    super.key,
    required this.fraction,
    required this.displayValue,
    this.displayUnit,
    this.label,
    this.emptyText,
    this.chip,
    this.fillColor = AppTheme.accent,
    this.size = MeterSize.large,
    this.scaleMinLabel = '0',
    this.scaleMaxLabel = '100',
    this.ticks,
    this.semanticsLabel,
    this.animatedNumber,
    this.formatNumber,
  });

  /// Posisi nilai dalam skala, 0 sampai 1. Null berarti tidak ada
  /// data: meter tampil kosong tanpa isi dan tanpa penanda.
  final double? fraction;

  /// Teks angka besar (misal "82" atau "5,75"). Diabaikan bila
  /// [animatedNumber] dan [formatNumber] diisi.
  final String displayValue;

  /// Satuan kecil di samping angka (misal "%" atau "MB/detik").
  final String? displayUnit;

  /// Label kecil di atas angka (dipakai varian ringkas).
  final String? label;

  /// Teks yang tampil sebagai pengganti angka bila [fraction] null.
  final String? emptyText;

  /// Chip kategori di kanan angka.
  final Widget? chip;

  /// Warna isi meter: putih untuk nilai netral, warna status untuk
  /// kategori. Tidak pernah bergradasi.
  final Color fillColor;

  final MeterSize size;

  /// Label skala kiri dan kanan di bawah garis.
  final String scaleMinLabel;
  final String scaleMaxLabel;

  /// Posisi strip (0 sampai 1). Bila null, strip tiap 10 persen.
  final List<double>? ticks;

  /// Label semantik, misal "Skor kesehatan 82 dari 100, Baik".
  final String? semanticsLabel;

  /// Nilai numerik untuk hitungan angka. Bila diisi bersama
  /// [formatNumber], angka besar menghitung dari nilai lama ke
  /// nilai baru selama 600 ms.
  final double? animatedNumber;
  final String Function(double value)? formatNumber;

  bool get _large => size == MeterSize.large;

  @override
  Widget build(BuildContext context) {
    final kosong = fraction == null;
    final angka = _large ? AppTheme.display : AppTheme.headline;
    final unitStyle = _large ? AppTheme.title : AppTheme.section;
    final tinggiBar = _large ? 8.0 : 6.0;
    final tinggiPenanda = _large ? 16.0 : 12.0;

    Widget angkaBesar;
    if (kosong) {
      angkaBesar = Text(
        emptyText ?? 'Tidak tersedia',
        style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
      );
    } else if (animatedNumber != null && formatNumber != null) {
      final format = formatNumber!;
      angkaBesar = TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: animatedNumber!),
        duration: AppTheme.animationsDisabled(context)
            ? Duration.zero
            : AppTheme.countUp,
        curve: Curves.easeOutCubic,
        builder: (context, nilai, _) => Text(
          format(nilai),
          style: angka,
        ),
      );
    } else {
      angkaBesar = Text(displayValue, style: angka);
    }

    final meter = Semantics(
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: AppTheme.label),
            const SizedBox(height: 4),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(child: angkaBesar),
              if (displayUnit != null && !kosong) ...[
                const SizedBox(width: 6),
                Text(
                  displayUnit!,
                  style: unitStyle.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              if (chip != null && !kosong) ...[
                const SizedBox(width: 12),
                Flexible(child: chip!),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _MeterBar(
            fraction: fraction?.clamp(0.0, 1.0),
            fillColor: fillColor,
            barHeight: tinggiBar,
            markerHeight: tinggiPenanda,
            ticks: ticks ??
                const [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(scaleMinLabel, style: AppTheme.caption),
              Text(scaleMaxLabel, style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
    return meter;
  }
}

/// Garis meter: jalur, isi, strip, dan penanda nilai.
class _MeterBar extends StatelessWidget {
  const _MeterBar({
    required this.fraction,
    required this.fillColor,
    required this.barHeight,
    required this.markerHeight,
    required this.ticks,
  });

  final double? fraction;
  final Color fillColor;
  final double barHeight;
  final double markerHeight;
  final List<double> ticks;

  @override
  Widget build(BuildContext context) {
    final durasi = AppTheme.animationsDisabled(context)
        ? Duration.zero
        : AppTheme.resultTransition;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction ?? 0),
      duration: durasi,
      curve: Curves.easeInOutCubic,
      builder: (context, nilai, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final lebar = constraints.maxWidth;
            final posisiPenanda = (nilai * lebar).clamp(0.0, lebar);
            return SizedBox(
              height: 6 + 2 + markerHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Strip di atas garis.
                  for (final tick in ticks)
                    Positioned(
                      left: (tick * lebar - 0.5).clamp(0.0, lebar - 1),
                      top: 0,
                      child: Container(
                        width: 1,
                        height: 6,
                        color: AppTheme.lineStrong,
                      ),
                    ),
                  // Garis meter.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 8 + (markerHeight - barHeight) / 2,
                    child: Container(
                      height: barHeight,
                      decoration: BoxDecoration(
                        color: AppTheme.track,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMeter,
                        ),
                      ),
                    ),
                  ),
                  // Isi meter.
                  if (fraction != null && nilai > 0)
                    Positioned(
                      left: 0,
                      top: 8 + (markerHeight - barHeight) / 2,
                      child: Container(
                        width: posisiPenanda,
                        height: barHeight,
                        decoration: BoxDecoration(
                          color: fillColor,
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMeter,
                          ),
                        ),
                      ),
                    ),
                  // Penanda nilai: blok putih yang menembus garis.
                  if (fraction != null)
                    Positioned(
                      left: (posisiPenanda - 1.5).clamp(0.0, lebar - 3),
                      top: 8,
                      child: Container(
                        width: 3,
                        height: markerHeight,
                        color: AppTheme.accent,
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Satu baris data: label di kiri, nilai di kanan. Nilai yang tidak
/// tersedia menampilkan "Tidak tersedia" dengan warna sekunder, bukan
/// tanda strip. Baris dalam satu kelompok dipisah ruang 12, tanpa garis.
class StatRow extends StatelessWidget {
  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(label, style: AppTheme.label),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: AppTheme.body.copyWith(
              fontFeatures: AppTheme.tabularFigures,
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight:
                  valueBold ? FontWeight.w600 : FontWeight.w400,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

/// Judul bagian plus aksi opsional di kanan. Tanpa eyebrow, tanpa
/// garis hias, tanpa nomor bagian. Jarak: 32 di atas, 12 di bawah.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.marginTop = AppTheme.sectionGap,
  });

  final String title;
  final Widget? action;

  /// Jarak di atas judul. Isi 0 bila header adalah elemen pertama
  /// di halaman.
  final double marginTop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: marginTop, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(title, style: AppTheme.section),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Kartu: latar surface, radius 16, bingkai 1 px, padding 20, tanpa
/// bayangan. Dipakai hanya bila kelompok konten butuh batas yang jelas.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.cardPadding),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final kartu = Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    if (onTap == null) return kartu;
    return _PressScale(enabled: true, child: kartu);
  }
}

/// Strip status kompak satu baris: ikon, teks, latar surface, radius
/// 12, tanpa tombol di dalamnya. Untuk status mode lokal dan penjelasan
/// batasan Android. Tidak pernah setinggi kartu konten.
class StatusStrip extends StatelessWidget {
  const StatusStrip({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? AppTheme.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: AppTheme.body)),
        ],
      ),
    );
  }
}

/// Blok skeleton: abu #1C1C1C dengan radius 8, di posisi konten akhir.
class SkeletonBlock extends StatelessWidget {
  const SkeletonBlock({
    super.key,
    this.width,
    required this.height,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Kilau shimmer yang bergerak satu arah di atas rangka skeleton.
/// Statis bila pengurangan gerak aktif.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTheme.shimmerCycle,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppTheme.animationsDisabled(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                AppTheme.surfaceRaised,
                Color(0xFF2E2E2E),
                AppTheme.surfaceRaised,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              transform: _SlidingGradientTransform(
                _controller.value * 2 - 1,
              ),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * slidePercent,
      0.0,
      0.0,
    );
  }
}

/// Kerangka pemuatan yang meniru bentuk layar akhir, plus satu baris
/// teks yang menjelaskan apa yang sedang dimuat.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer(child: child),
          const SizedBox(height: 16),
          Text(label, style: AppTheme.caption),
          const SizedBox(height: AppTheme.bottomPadding),
        ],
      ),
    );
  }
}

/// Empty state v2: rata kiri, ikon di dalam kotak bingkai, judul,
/// pesan yang menyebut penyebab dan aksi berikutnya dengan spesifik,
/// lalu tombol aksi bila ada.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Tombol aksi (utama atau sekunder), ditampilkan berurutan.
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusButton),
            border: Border.all(color: AppTheme.line),
          ),
          child: Icon(icon, size: 28, color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        Text(title, style: AppTheme.section),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        ),
        if (actions case final daftar? when daftar.isNotEmpty) ...[
          const SizedBox(height: 16),
          for (final aksi in daftar)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: aksi,
            ),
        ],
      ],
    );
  }
}

/// Error state v2: sama seperti EmptyState v2, tetapi ikon memakai
/// warna danger dan judul menyebut apa yang gagal. Tidak pernah
/// menampilkan rincian exception sistem.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius:
                BorderRadius.circular(AppTheme.radiusButton),
            border: Border.all(color: AppTheme.line),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 28,
            color: AppTheme.danger,
          ),
        ),
        const SizedBox(height: 16),
        Text(title, style: AppTheme.section),
        const SizedBox(height: 8),
        Text(
          message,
          style: AppTheme.body.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Coba lagi', onPressed: onRetry),
      ],
    );
  }
}

/// Dialog konfirmasi: latar surfaceRaised, radius 16, judul section,
/// isi body, tombol teks "Batal" di kiri dan tombol utama di kanan.
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String confirmLabel,
  String cancelLabel = 'Batal',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        AppTextButton(
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Bottom sheet penjelasan langkah manual: pegangan 32x4 di atas,
/// judul section, isi body, dan tombol utama di bawah.
Future<void> showAppBottomSheet({
  required BuildContext context,
  required String title,
  required Widget body,
  required String primaryLabel,
  required VoidCallback onPrimary,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.pagePadding,
            12,
            AppTheme.pagePadding,
            AppTheme.pagePadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.lineStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppTheme.section),
              const SizedBox(height: 12),
              body,
              const SizedBox(height: 20),
              PrimaryButton(label: primaryLabel, onPressed: onPrimary),
            ],
          ),
        ),
      ),
    ),
  );
}
