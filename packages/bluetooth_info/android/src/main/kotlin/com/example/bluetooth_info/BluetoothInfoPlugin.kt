package com.example.bluetooth_info

import android.Manifest
import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

/**
 * Bluetooth adaptör bilgilerini ve yakındaki cihazları Flutter'a aktaran
 * platform channel eklentisi.
 *
 * Metot kanalı: `bluetooth_info`
 *   - getInfo, requestPermissions, openSettings
 *
 * Olay kanalı: `bluetooth_info/discovery`
 *   - Dinleyici eklendiğinde tarama başlar, kaldırıldığında durur.
 *   - Olaylar: {type: started|device|finished, device: {...}}
 */
class BluetoothInfoPlugin :
    FlutterPlugin,
    MethodChannel.MethodCallHandler,
    EventChannel.StreamHandler,
    ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var appContext: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var receiverRegistered = false

    private val discoveryReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val sink = eventSink ?: return
            when (intent?.action) {
                BluetoothAdapter.ACTION_DISCOVERY_STARTED ->
                    sink.success(mapOf("type" to "started"))

                BluetoothAdapter.ACTION_DISCOVERY_FINISHED ->
                    sink.success(mapOf("type" to "finished"))

                BluetoothDevice.ACTION_FOUND -> {
                    val device = extractDevice(intent) ?: return
                    val rssi = intent.getShortExtra(BluetoothDevice.EXTRA_RSSI, 0).toInt()
                    sink.success(
                        mapOf(
                            "type" to "device",
                            "device" to safeDeviceMap(device, rssi),
                        ),
                    )
                }
            }
        }
    }

    // ---------------------------------------------------------------------
    // Yaşam döngüsü
    // ---------------------------------------------------------------------

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL)
        eventChannel.setStreamHandler(this)

        registerDiscoveryReceiver()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopDiscovery()
        unregisterDiscoveryReceiver()
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        eventSink = null
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

    // ---------------------------------------------------------------------
    // Metot kanalı
    // ---------------------------------------------------------------------

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getInfo" -> {
                try {
                    result.success(collectInfo())
                } catch (error: SecurityException) {
                    result.error(
                        "permission_denied",
                        "Bluetooth bilgilerine erişmek için izin gerekiyor.",
                        error.message,
                    )
                } catch (error: Exception) {
                    result.error("bluetooth_error", error.message, null)
                }
            }

            "requestPermissions" -> requestPermissions(result)

            "startDiscovery" -> startDiscovery(result)

            "stopDiscovery" -> {
                stopDiscovery()
                result.success(null)
            }

            "openSettings" -> {
                try {
                    openBluetoothSettings()
                    result.success(null)
                } catch (error: Exception) {
                    result.error("settings_error", error.message, null)
                }
            }

            else -> result.notImplemented()
        }
    }

    // ---------------------------------------------------------------------
    // Bilgi toplama
    // ---------------------------------------------------------------------

    private fun adapter(): BluetoothAdapter? {
        val manager =
            appContext.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
        return manager?.adapter
    }

    private fun sdkName(): String =
        "Android ${Build.VERSION.RELEASE} (API ${Build.VERSION.SDK_INT})"

    private fun hasConnectPermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
        return appContext.checkSelfPermission(Manifest.permission.BLUETOOTH_CONNECT) ==
            PackageManager.PERMISSION_GRANTED
    }

    private fun hasScanPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return appContext.checkSelfPermission(Manifest.permission.BLUETOOTH_SCAN) ==
                PackageManager.PERMISSION_GRANTED
        }
        // Android 11 ve altında klasik keşif konum izni ister.
        return appContext.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED
    }

    /**
     * `isDiscovering` Android 12+ sürümlerinde BLUETOOTH_SCAN izni ister.
     * İzin yoksa bilgi sorgusu bloke olmasın diye güvenli varsayılana düşer.
     */
    private fun safeDiscovering(adapter: BluetoothAdapter?): Boolean {
        if (adapter == null) return false
        return try {
            adapter.isDiscovering
        } catch (_: SecurityException) {
            false
        }
    }

    /** `isEnabled` Android 12+ sürümlerinde BLUETOOTH_CONNECT izni ister. */
    private fun safeEnabled(adapter: BluetoothAdapter?): Boolean {
        if (adapter == null) return false
        return try {
            adapter.isEnabled
        } catch (_: SecurityException) {
            false
        }
    }

    /** `state` Android 12+ sürümlerinde BLUETOOTH_CONNECT izni ister. */
    private fun safeState(adapter: BluetoothAdapter?): Int {
        if (adapter == null) return -1
        return try {
            adapter.state
        } catch (_: SecurityException) {
            -1
        }
    }

    private fun collectInfo(): Map<String, Any?> {
        val bluetoothAdapter = adapter()
        val permissionGranted = hasConnectPermission()

        val info = mutableMapOf<String, Any?>(
            "supported" to (bluetoothAdapter != null),
            "enabled" to safeEnabled(bluetoothAdapter),
            "stateCode" to safeState(bluetoothAdapter),
            "state" to stateLabel(safeState(bluetoothAdapter)),
            "permissionGranted" to permissionGranted,
            "scanPermissionGranted" to hasScanPermission(),
            "discovering" to safeDiscovering(bluetoothAdapter),
            "androidVersion" to sdkName(),
            "deviceModel" to "${Build.MANUFACTURER} ${Build.MODEL}",
            "name" to null,
            "address" to null,
            "bondedDevices" to emptyList<Map<String, Any?>>(),
        )

        if (bluetoothAdapter == null) return info

        // Ad/adres/eşleşmiş cihazlar Android 12+ için izin ister.
        if (!permissionGranted) return info

        try {
            info["name"] = bluetoothAdapter.name
            info["address"] = bluetoothAdapter.address
            info["bondedDevices"] = bluetoothAdapter.bondedDevices
                ?.map { device -> safeDeviceMap(device, 0) }
                ?: emptyList<Map<String, Any?>>()
        } catch (error: SecurityException) {
            info["permissionGranted"] = false
            info["permissionError"] =
                "Bluetooth izni olmadan ad, adres ve eşleşmiş cihazlar okunamaz."
        }

        return info
    }

    private fun safeDeviceMap(device: BluetoothDevice, rssi: Int): Map<String, Any?> {
        var name: String? = null
        var address = "-"
        var bonded = false

        try {
            name = device.name
        } catch (_: SecurityException) {
            // İzin yoksa ad okunamaz.
        }
        try {
            address = device.address
        } catch (_: SecurityException) {
            // İzin yoksa adres okunamaz.
        }
        try {
            bonded = device.bondState == BluetoothDevice.BOND_BONDED
        } catch (_: SecurityException) {
            // Bağ durumu okunamaz.
        }

        return mapOf(
            "name" to name,
            "address" to address,
            "type" to deviceTypeLabel(device.type),
            "bonded" to bonded,
            "rssi" to rssi,
        )
    }

    @Suppress("DEPRECATION")
    private fun extractDevice(intent: Intent): BluetoothDevice? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE, BluetoothDevice::class.java)
        } else {
            intent.getParcelableExtra(BluetoothDevice.EXTRA_DEVICE)
        }
    }

    private fun stateLabel(state: Int?): String = when (state) {
        BluetoothAdapter.STATE_ON -> "Açık"
        BluetoothAdapter.STATE_OFF -> "Kapalı"
        BluetoothAdapter.STATE_TURNING_ON -> "Açılıyor"
        BluetoothAdapter.STATE_TURNING_OFF -> "Kapanıyor"
        else -> "Bilinmiyor"
    }

    private fun deviceTypeLabel(type: Int): String = when (type) {
        BluetoothDevice.DEVICE_TYPE_CLASSIC -> "Klasik"
        BluetoothDevice.DEVICE_TYPE_LE -> "Düşük enerji (BLE)"
        BluetoothDevice.DEVICE_TYPE_DUAL -> "Çift mod"
        else -> "Bilinmiyor"
    }

    // ---------------------------------------------------------------------
    // Keşif (yakındaki cihazlar)
    // ---------------------------------------------------------------------

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val sink = events ?: return
        startDiscoveryInternal(sink)
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
        stopDiscovery()
    }

    private fun startDiscoveryInternal(sink: EventChannel.EventSink) {
        val bluetoothAdapter = adapter()
        if (bluetoothAdapter == null) {
            sink.error("unsupported", "Bu cihazda Bluetooth adaptörü bulunmuyor.", null)
            return
        }
        if (!safeEnabled(bluetoothAdapter)) {
            sink.error("bluetooth_off", "Bluetooth kapalı. Ayarlardan açın.", null)
            return
        }
        if (!hasScanPermission()) {
            sink.error(
                "scan_permission_denied",
                "Yakındaki cihazları taramak için izin gerekiyor.",
                null,
            )
            return
        }

        try {
            if (bluetoothAdapter.isDiscovering) {
                bluetoothAdapter.cancelDiscovery()
            }
            bluetoothAdapter.startDiscovery()
        } catch (error: SecurityException) {
            sink.error("scan_permission_denied", "Tarama izni verilmedi.", error.message)
        }
    }

    private fun startDiscovery(result: MethodChannel.Result) {
        val bluetoothAdapter = adapter()
        if (bluetoothAdapter == null) {
            result.error("unsupported", "Bu cihazda Bluetooth adaptörü bulunmuyor.", null)
            return
        }
        if (!safeEnabled(bluetoothAdapter)) {
            result.error("bluetooth_off", "Bluetooth kapalı. Ayarlardan açın.", null)
            return
        }
        if (!hasScanPermission()) {
            result.error(
                "scan_permission_denied",
                "Yakındaki cihazları taramak için izin gerekiyor.",
                null,
            )
            return
        }

        try {
            if (bluetoothAdapter.isDiscovering) {
                bluetoothAdapter.cancelDiscovery()
            }
            result.success(bluetoothAdapter.startDiscovery())
        } catch (error: SecurityException) {
            result.error("scan_permission_denied", "Tarama izni verilmedi.", error.message)
        }
    }

    private fun stopDiscovery() {
        try {
            val bluetoothAdapter = adapter() ?: return
            if (bluetoothAdapter.isDiscovering) {
                bluetoothAdapter.cancelDiscovery()
            }
        } catch (_: SecurityException) {
            // İzin yoksa yapılacak bir şey yok.
        }
    }

    private fun registerDiscoveryReceiver() {
        if (receiverRegistered) return
        val filter = IntentFilter().apply {
            addAction(BluetoothDevice.ACTION_FOUND)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_STARTED)
            addAction(BluetoothAdapter.ACTION_DISCOVERY_FINISHED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            // Bluetooth yayınları com.android.bluetooth sürecinden gelir;
            // NOT_EXPORTED bu yayınları engeller.
            appContext.registerReceiver(
                discoveryReceiver,
                filter,
                Context.RECEIVER_EXPORTED,
            )
        } else {
            appContext.registerReceiver(discoveryReceiver, filter)
        }
        receiverRegistered = true
    }

    private fun unregisterDiscoveryReceiver() {
        if (!receiverRegistered) return
        try {
            appContext.unregisterReceiver(discoveryReceiver)
        } catch (_: IllegalArgumentException) {
            // Zaten kaldırılmış.
        }
        receiverRegistered = false
    }

    // ---------------------------------------------------------------------
    // İzinler
    // ---------------------------------------------------------------------

    private fun requiredPermissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_SCAN,
            )
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    private fun requestPermissions(result: MethodChannel.Result) {
        val currentActivity = activity
        if (currentActivity == null) {
            result.error("no_activity", "Aktif bir Activity bulunamadı.", null)
            return
        }

        val missing = requiredPermissions().filter {
            currentActivity.checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED
        }

        if (missing.isEmpty()) {
            result.success(true)
            return
        }

        if (pendingPermissionResult != null) {
            result.error("request_in_progress", "Zaten bir izin isteği sürüyor.", null)
            return
        }

        pendingPermissionResult = result
        currentActivity.requestPermissions(missing.toTypedArray(), PERMISSION_REQUEST_CODE)
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

    private fun openBluetoothSettings() {
        val intent = Intent(Settings.ACTION_BLUETOOTH_SETTINGS).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        appContext.startActivity(intent)
    }

    companion object {
        private const val METHOD_CHANNEL = "bluetooth_info"
        private const val EVENT_CHANNEL = "bluetooth_info/discovery"
        private const val PERMISSION_REQUEST_CODE = 4711
    }
}
