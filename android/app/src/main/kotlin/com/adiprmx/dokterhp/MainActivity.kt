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
import java.net.Inet4Address

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
                "wifiSsid" -> result.success(wifiSsid())
                "wifiGatewayIp" -> result.success(wifiGatewayIp())
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

    /**
     * SSID WiFi yang sedang tersambung. WifiInfo.ssid mengembalikan nama
     * dalam tanda kutip ("ACHA") dan "<unknown ssid>" bila Android
     * menahan namanya (izin lokasi belum diberikan atau layanan lokasi
     * mati). Keduanya dibersihkan di sini; Dart menerima null secara
     * jujur bila nama tidak bisa dibaca.
     */
    private fun wifiSsid(): String? {
        return try {
            val mentah = wifiConnectionInfo()?.ssid ?: return null
            val bersih = mentah.trim().removeSurrounding("\"")
            if (bersih.isEmpty() || bersih == "<unknown ssid>") null else bersih
        } catch (e: Exception) {
            null
        }
    }

    /**
     * Alamat IP gateway. Sumber utama DhcpInfo.gateway (int little-endian);
     * bila 0 (tidak ada DHCP atau WiFi tidak tersambung), fallback ke
     * gateway dari rute LinkProperties jaringan aktif.
     */
    private fun wifiGatewayIp(): String? {
        return try {
            val wifiManager =
                applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            @Suppress("DEPRECATION")
            val dhcp = wifiManager.dhcpInfo
            if (dhcp != null && dhcp.gateway != 0) {
                return intKeIp(dhcp.gateway)
            }
            val cm =
                getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val props = cm.getLinkProperties(cm.activeNetwork) ?: return null
            for (rute in props.routes) {
                val gateway = rute.gateway
                if (gateway is Inet4Address) {
                    return gateway.hostAddress
                }
            }
            null
        } catch (e: Exception) {
            null
        }
    }

    /** Konversi int little-endian ala DhcpInfo menjadi string IPv4. */
    private fun intKeIp(nilai: Int): String {
        return "${nilai and 0xff}.${nilai shr 8 and 0xff}" +
            ".${nilai shr 16 and 0xff}.${nilai shr 24 and 0xff}"
    }

    /**
     * Daftar server DNS dari LinkProperties jaringan aktif, sudah
     * disaring: alamat link-local (fe80::/10, juga 169.254.0.0/16),
     * alamat yang membawa zone id ("%wlan0"), dan teks yang bukan
     * alamat IP dibuang. Hanya IPv4 valid dan IPv6 global yang lolos.
     */
    private fun dnsServers(): List<String> {
        return try {
            val cm =
                getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
            val props = cm.getLinkProperties(cm.activeNetwork) ?: return emptyList()
            props.dnsServers.mapNotNull { alamat ->
                val host = alamat.hostAddress ?: return@mapNotNull null
                if (alamat.isLinkLocalAddress) return@mapNotNull null
                if ('%' in host) return@mapNotNull null
                if (!host.all {
                        it.isDigit() || it == '.' || it == ':' ||
                            it in 'a'..'f' || it in 'A'..'F'
                    }
                ) {
                    return@mapNotNull null
                }
                host
            }
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
