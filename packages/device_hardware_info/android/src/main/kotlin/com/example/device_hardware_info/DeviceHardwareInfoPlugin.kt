package com.example.device_hardware_info

import android.Manifest
import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.os.StatFs
import android.os.SystemClock
import android.provider.Settings
import android.telephony.TelephonyManager
import android.view.WindowManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.io.File

/**
 * Donanım numaralarını, IMEI/seri no bilgisini ve root göstergelerini
 * Flutter'a aktaran Kotlin platform channel eklentisi.
 *
 * Kanal: `device_hardware_info`
 * Metotlar: `getInfo`, `requestPermissions`
 *
 * Not: Android 10 (API 29) ve üzerinde IMEI/seri no yalnızca sistem,
 * operatör veya cihaz sahibi (device owner) uygulamalarına açıktır.
 * Bu durumda alanlar null döner ve `imeiStatus`/`serialStatus`
 * "restricted" olur; uygulama bunu kullanıcıya açıklar.
 */
class DeviceHardwareInfoPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        pendingPermissionResult = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activityBinding = binding
        activity = binding.activity
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        detachActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        detachActivity()
    }

    private fun detachActivity() {
        activityBinding?.removeRequestPermissionsResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInfo" -> {
                try {
                    result.success(collectInfo())
                } catch (error: Exception) {
                    result.error("hardware_error", error.message, null)
                }
            }

            "requestPermissions" -> requestPhonePermission(result)

            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------------
    // Bilgi toplama
    // ---------------------------------------------------------------------

    private fun hasPhonePermission(): Boolean =
        appContext.checkSelfPermission(Manifest.permission.READ_PHONE_STATE) ==
            PackageManager.PERMISSION_GRANTED

    private fun collectInfo(): Map<String, Any?> {
        val rootReport = detectRoot()
        val imei = imeiReport()
        val meid = meidReport()
        val serial = serialReport()
        val screen = screenMetrics()

        return mapOf(
            // Kimlik / build
            "manufacturer" to Build.MANUFACTURER,
            "brand" to Build.BRAND,
            "model" to Build.MODEL,
            "device" to Build.DEVICE,
            "product" to Build.PRODUCT,
            "board" to Build.BOARD,
            "hardware" to Build.HARDWARE,
            "bootloader" to Build.BOOTLOADER,
            "buildId" to Build.ID,
            "buildDisplay" to Build.DISPLAY,
            "buildFingerprint" to Build.FINGERPRINT,
            "buildTags" to Build.TAGS,
            "buildType" to Build.TYPE,
            "radioVersion" to Build.getRadioVersion(),
            "socManufacturer" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Build.SOC_MANUFACTURER
            } else {
                null
            },
            "socModel" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                Build.SOC_MODEL
            } else {
                null
            },
            "securityPatch" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Build.VERSION.SECURITY_PATCH
            } else {
                null
            },
            "kernelVersion" to System.getProperty("os.version"),
            "javaVmVersion" to System.getProperty("java.vm.version"),
            "selinux" to selinuxStatus(),

            // Donanım numaraları
            "imei" to imei.first,
            "imeiStatus" to imei.second,
            "imeiNote" to imei.third,
            "meid" to meid.first,
            "meidStatus" to meid.second,
            "serial" to serial.first,
            "serialStatus" to serial.second,
            "androidId" to androidId(),

            // CPU / bellek / depolama
            "cpuCores" to Runtime.getRuntime().availableProcessors(),
            "cpuAbi" to Build.SUPPORTED_ABIS.firstOrNull(),
            "supportedAbis" to Build.SUPPORTED_ABIS.toList(),
            "cpuHardware" to cpuModel(),
            "cpuMaxFreqKHz" to cpuMaxFreqKHz(),
            "totalRamBytes" to totalRamBytes(),
            "availableRamBytes" to availableRamBytes(),
            "totalStorageBytes" to totalStorageBytes(),
            "freeStorageBytes" to freeStorageBytes(),

            // Ekran
            "screenWidthPx" to screen.first,
            "screenHeightPx" to screen.second,
            "densityDpi" to screen.third,
            "refreshRate" to screen.fourth,

            // Root / sistem
            "isRooted" to rootReport.first,
            "rootIndicators" to rootReport.second,
            "phonePermissionGranted" to hasPhonePermission(),
            "isEmulator" to isEmulator(),
            "uptimeMillis" to SystemClock.elapsedRealtime(),
        )
    }

    // ---------------------------------------------------------------------
    // Donanım numaraları
    // ---------------------------------------------------------------------

    private fun telephony(): TelephonyManager? =
        appContext.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager

    private fun imeiReport(): Triple<String?, String, String?> {
        val manager = telephony()
            ?: return Triple(null, "unavailable", "Telefon servisi bulunamadı.")

        return try {
            val value =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    manager.imei
                } else {
                    @Suppress("DEPRECATION")
                    manager.deviceId
                }

            if (value.isNullOrBlank()) {
                Triple(null, "unavailable", "IMEI okunamadı (SIM veya telefon modemi yok).")
            } else {
                Triple(value, "ok", null)
            }
        } catch (error: SecurityException) {
            val restricted = Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
            Triple(
                null,
                if (restricted) "restricted" else "permission_required",
                if (restricted) {
                    "Android 10+ sürümlerinde IMEI yalnızca sistem/operatör " +
                        "uygulamalarına açıktır; normal uygulamalar okuyamaz."
                } else {
                    "IMEI için telefon izni (READ_PHONE_STATE) gerekir."
                },
            )
        } catch (error: Exception) {
            Triple(null, "unavailable", error.message ?: "IMEI okunamadı.")
        }
    }

    private fun meidReport(): Pair<String?, String> {
        val manager = telephony() ?: return null to "unavailable"
        return try {
            val value =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    manager.meid
                } else {
                    null
                }
            if (value.isNullOrBlank()) null to "unavailable" else value to "ok"
        } catch (error: SecurityException) {
            null to "restricted"
        } catch (error: Exception) {
            null to "unavailable"
        }
    }

    private fun serialReport(): Pair<String?, String> {
        return try {
            val value =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Build.getSerial()
                } else {
                    @Suppress("DEPRECATION")
                    Build.SERIAL
                }

            if (value.isNullOrBlank() || value.equals("unknown", ignoreCase = true)) {
                null to "unavailable"
            } else {
                value to "ok"
            }
        } catch (error: SecurityException) {
            null to "restricted"
        } catch (error: Exception) {
            null to "unavailable"
        }
    }

    private fun androidId(): String? = try {
        Settings.Secure.getString(appContext.contentResolver, Settings.Secure.ANDROID_ID)
    } catch (error: Exception) {
        null
    }

    // ---------------------------------------------------------------------
    // CPU / bellek / depolama / ekran
    // ---------------------------------------------------------------------

    private fun cpuModel(): String? {
        return try {
            File("/proc/cpuinfo")
                .readLines()
                .firstOrNull { line ->
                    line.startsWith("Hardware") || line.startsWith("model name")
                }
                ?.substringAfter(':')
                ?.trim()
                ?.takeIf { it.isNotEmpty() }
        } catch (error: Exception) {
            null
        }
    }

    private fun cpuMaxFreqKHz(): Long? {
        return try {
            File("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq")
                .readText()
                .trim()
                .toLongOrNull()
        } catch (error: Exception) {
            null
        }
    }

    private fun totalRamBytes(): Long {
        val manager = appContext.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return 0L
        val info = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(info)
        return info.totalMem
    }

    private fun availableRamBytes(): Long {
        val manager = appContext.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            ?: return 0L
        val info = ActivityManager.MemoryInfo()
        manager.getMemoryInfo(info)
        return info.availMem
    }

    private fun storage(): StatFs? = try {
        StatFs(Environment.getDataDirectory().absolutePath)
    } catch (error: Exception) {
        null
    }

    private fun totalStorageBytes(): Long {
        val stat = storage() ?: return 0L
        return stat.blockCountLong * stat.blockSizeLong
    }

    private fun freeStorageBytes(): Long {
        val stat = storage() ?: return 0L
        return stat.availableBlocksLong * stat.blockSizeLong
    }

    private fun screenMetrics(): Quadruple<Int, Int, Int, Double> {
        val metrics = appContext.resources.displayMetrics
        return Quadruple(
            metrics.widthPixels,
            metrics.heightPixels,
            metrics.densityDpi,
            refreshRate(),
        )
    }

    /** Ekran yenileme hızı (Hz). DisplayMetrics üzerinde bu alan yoktur. */
    private fun refreshRate(): Double {
        return try {
            val activityRate = activity?.display?.refreshRate
            if (activityRate != null && activityRate > 0f) {
                return activityRate.toDouble()
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                appContext.display?.refreshRate?.toDouble() ?: 0.0
            } else {
                @Suppress("DEPRECATION")
                (appContext.getSystemService(Context.WINDOW_SERVICE) as WindowManager)
                    .defaultDisplay
                    .refreshRate
                    .toDouble()
            }
        } catch (error: Exception) {
            0.0
        }
    }

    // ---------------------------------------------------------------------
    // Root / emülatör tespiti
    // ---------------------------------------------------------------------

    private fun detectRoot(): Pair<Boolean, List<String>> {
        val indicators = mutableListOf<String>()

        val suPaths = listOf(
            "/system/bin/su",
            "/system/xbin/su",
            "/sbin/su",
            "/su/bin/su",
            "/data/local/bin/su",
            "/data/local/xbin/su",
            "/data/local/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
        )
        suPaths.firstOrNull { File(it).exists() }?.let { indicators.add("su: $it") }

        val rootPaths = listOf(
            "/sbin/.magisk",
            "/data/adb/magisk",
            "/data/adb/modules",
            "/system/app/Superuser.apk",
            "/system/xbin/busybox",
            "/system/bin/busybox",
            "/data/local/tmp/busybox",
        )
        rootPaths.firstOrNull { File(it).exists() }?.let { indicators.add("Dosya: $it") }

        if (Build.TAGS?.contains("test-keys") == true) {
            indicators.add("Build etiketi: test-keys")
        }
        if (Build.TYPE == "userdebug" || Build.TYPE == "eng") {
            indicators.add("Build tipi: ${Build.TYPE}")
        }

        return indicators.isNotEmpty() to indicators
    }

    private fun selinuxStatus(): String {
        return try {
            val enforcing = File("/sys/fs/selinux/enforce").readText().trim()
            if (enforcing == "1") "Enforcing" else "Permissive"
        } catch (error: Exception) {
            "Bilinmiyor"
        }
    }

    private fun isEmulator(): Boolean {
        return Build.FINGERPRINT.startsWith("generic") ||
            Build.FINGERPRINT.contains("emulator") ||
            Build.MODEL.contains("Emulator") ||
            Build.MODEL.contains("Android SDK built for") ||
            Build.HARDWARE.contains("goldfish") ||
            Build.HARDWARE.contains("ranchu") ||
            Build.PRODUCT.contains("sdk")
    }

    // ---------------------------------------------------------------------
    // İzinler
    // ---------------------------------------------------------------------

    private fun requestPhonePermission(result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("no_activity", "Aktif bir Activity bulunamadı.", null)
            return
        }

        if (hasPhonePermission()) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("request_in_progress", "Zaten bir izin isteği sürüyor.", null)
            return
        }

        pendingPermissionResult = result
        currentActivity.requestPermissions(
            arrayOf(Manifest.permission.READ_PHONE_STATE),
            PERMISSION_REQUEST_CODE,
        )
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false

        val granted =
            grantResults.isNotEmpty() &&
                grantResults.all { it == PackageManager.PERMISSION_GRANTED }

        pendingPermissionResult?.success(granted)
        pendingPermissionResult = null
        return true
    }

    /** Kotlin'de yerleşik 4'lü taşıyıcı olmadığı için küçük yardımcı. */
    private data class Quadruple<A, B, C, D>(
        val first: A,
        val second: B,
        val third: C,
        val fourth: D,
    )

    companion object {
        private const val CHANNEL_NAME = "device_hardware_info"
        private const val PERMISSION_REQUEST_CODE = 4712
    }
}
