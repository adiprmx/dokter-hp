import 'package:flutter/material.dart';
import 'package:dokter_hp/core/app_config.dart';
import 'package:dokter_hp/core/theme.dart';
import 'package:dokter_hp/data/local/app_database.dart';
import 'package:dokter_hp/features/auth/lock_gate.dart';
import 'package:dokter_hp/features/dashboard/dashboard_page.dart';

/// Root widget Dokter HP.
///
/// Dashboard dibungkus [LockGate]: bila PIN sudah diatur, layar kunci
/// tampil sebelum dashboard.
class DokterHpApp extends StatelessWidget {
  const DokterHpApp({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: LockGate(child: DashboardPage(database: database)),
    );
  }
}
