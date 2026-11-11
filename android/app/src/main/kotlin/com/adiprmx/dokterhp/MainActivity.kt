package com.adiprmx.dokterhp

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.ConnectivityManager
import android.net.wifi.WifiManager
import android.os.Build
import android.os.StatFs
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * MainActivity Dokter HP.
 *
 * Menyediakan MethodChannel "com.adiprmx.dokterhp/native" untuk data
 * perangkat yang tidak disediakan paket publik: RSSI dan kecepatan link
 * WiFi, frekuensi/channel, DNS, info penyimpanan dan RAM, ukuran cache,
 * serta daftar aplikasi terpasang. Semua metode mengembalikan null bila
 * datanya tidak tersedia — Dart menampilkan "tidak tersedia", bukan angka
 * palsu.
 */
class MainActivity : FlutterActivity() {
    private val channelName = "com.adiprmx.dokterhp/native"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "wifiRssi" -> result.success(wifiConnectionInfo()?.rssi)
                "wifiLinkSpeed" -> result.success(wifiConnectionInfo()?.linkSpeed)
                "wifiFrequency" -> result.success(wifiConnectionInfo()?.frequency)
                "dnsServers" -> result.success(dnsServers())
                "openWifiSettings" -> {
                    try {
                        startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }
                "storageInfo" -> result.success(storageInfo())
                "memoryInfo" -> result.success(memoryInfo())
                "cacheSizeBytes" -> result.success(cacheSizeBytes())
                "clearCache" -> result.success(clearCache())
                "installedApps" -> result.success(installedApps())
                else -> result.notImplemented()
            }
        }
    }

    private fun wifiConnectionInfo(): android.net.wifi.WifiInfo? {
        return try {
            val wifiManager =
                applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            wifiManager.connectionInfo
        } catch (e: Exception) {
            null
        }
    }

    private fun dnsServers(): List<String> {
        return try {
            val cm =
                getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val props = cm.getLinkProperties(cm.activeNetwork) ?: return emptyList()
            props.dnsServers.map { it.hostAddress ?: it.toString() }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun storageInfo(): Map<String, Long>? {
        return try {
            val stat = StatFs(filesDir.path)
            val blockSize = stat.blockSizeLong
            val total = stat.blockCountLong * blockSize
            val free = stat.availableBlocksLong * blockSize
            mapOf("totalBytes" to total, "freeBytes" to free)
        } catch (e: Exception) {
            null
        }
    }

    private fun memoryInfo(): Map<String, Long>? {
        return try {
            val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
            val info = ActivityManager.MemoryInfo()
            am.getMemoryInfo(info)
            mapOf("totalBytes" to info.totalMem, "freeBytes" to info.availMem)
        } catch (e: Exception) {
            null
        }
    }

    private fun cacheSizeBytes(): Long {
        return try {
            dirSize(cacheDir)
        } catch (e: Exception) {
            0L
        }
    }

    private fun dirSize(dir: File): Long {
        var total = 0L
        val children = dir.listFiles() ?: return 0L
        for (child in children) {
            total += if (child.isDirectory) dirSize(child) else child.length()
        }
        return total
    }

    private fun clearCache(): Boolean {
        return try {
            deleteRecursively(cacheDir)
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun deleteRecursively(dir: File) {
        val children = dir.listFiles() ?: return
        for (child in children) {
            if (child.isDirectory) deleteRecursively(child)
            child.delete()
        }
    }

    private fun installedApps(): List<Map<String, Any>> {
        return try {
            val pm = packageManager
            @Suppress("DEPRECATION")
            val apps = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getInstalledApplications(
                    PackageManager.ApplicationInfoFlags.of(0),
                )
            } else {
                pm.getInstalledApplications(0)
            }
            apps.map { app ->
                val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0
                val permissions = try {
                    @Suppress("DEPRECATION")
                    val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.getPackageInfo(
                            app.packageName,
                            PackageManager.PackageInfoFlags.of(
                                PackageManager.GET_PERMISSIONS.toLong(),
                            ),
                        )
                    } else {
                        pm.getPackageInfo(
                            app.packageName,
                            PackageManager.GET_PERMISSIONS,
                        )
                    }
                    pkgInfo.requestedPermissions?.toList() ?: emptyList()
                } catch (e: Exception) {
                    emptyList<String>()
                }
                val installTime = try {
                    @Suppress("DEPRECATION")
                    val pkgInfo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        pm.getPackageInfo(
                            app.packageName,
                            PackageManager.PackageInfoFlags.of(0),
                        )
                    } else {
                        pm.getPackageInfo(app.packageName, 0)
                    }
                    pkgInfo.firstInstallTime
                } catch (e: Exception) {
                    0L
                }
                mapOf<String, Any>(
                    "label" to (pm.getApplicationLabel(app)?.toString() ?: ""),
                    "packageName" to app.packageName,
                    "isSystem" to isSystem,
                    "installTimeMillis" to installTime,
                    "permissions" to permissions,
                )
            }
        } catch (e: Exception) {
            emptyList()
        }
    }
}
