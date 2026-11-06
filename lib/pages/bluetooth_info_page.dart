import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:bluetooth_info/bluetooth_info.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/bluetooth_device_tile.dart';
import '../widgets/pressable_scale.dart';

@RoutePage()
class BluetoothInfoPage extends StatefulWidget {
  const BluetoothInfoPage({super.key});

  @override
  State<BluetoothInfoPage> createState() => _BluetoothInfoPageState();
}

class _BluetoothInfoPageState extends State<BluetoothInfoPage> {
  final _client = BluetoothInfoClient();

  BluetoothInfo? _info;
  String? _error;
  bool _loading = true;
  bool _requestingPermission = false;

  StreamSubscription<BluetoothScanEvent>? _scanSub;
  final Map<String, BluetoothDeviceInfo> _nearby = <String, BluetoothDeviceInfo>{};
  bool _scanning = false;
  bool _hasScanned = false;
  String? _scanError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final info = await _client.getInfo();
      if (!mounted) return;
      setState(() {
        _info = info;
        _loading = false;
      });
    } on BluetoothInfoException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    }
  }

  Future<void> _toggleScan() async {
    if (_scanning) {
      await _stopScan();
      return;
    }
    await _startScan();
  }

  Future<void> _startScan() async {
    final current = _info;
    if (current == null) return;

    if (!current.scanPermissionGranted) {
      final granted = await _requestPermission();
      if (!mounted || !granted) return;
    }

    await _scanSub?.cancel();
    setState(() {
      _nearby.clear();
      _scanError = null;
      _scanning = true;
      _hasScanned = true;
    });

    _scanSub = _client.scan().listen(
      (event) {
        if (!mounted) return;
        switch (event.type) {
          case BluetoothScanEventType.started:
            setState(() => _scanning = true);
          case BluetoothScanEventType.finished:
            setState(() => _scanning = false);
          case BluetoothScanEventType.device:
            final device = event.device;
            if (device == null) return;
            setState(() => _nearby[device.address] = device);
        }
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _scanning = false;
          _scanError = error is BluetoothInfoException
              ? error.message
              : 'Tarama hatası: $error';
        });
      },
      onDone: () {
        if (mounted) setState(() => _scanning = false);
      },
      cancelOnError: true,
    );
  }

  Future<void> _stopScan() async {
    await _scanSub?.cancel();
    _scanSub = null;
    if (mounted) setState(() => _scanning = false);
  }

  Future<bool> _requestPermission() async {
    setState(() => _requestingPermission = true);
    try {
      final granted = await _client.requestPermissions();
      if (!mounted) return granted;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            granted
                ? 'Bluetooth izinleri verildi.'
                : 'İzin verilmedi; cihaz adı, adresi ve tarama çalışmaz.',
          ),
        ),
      );
      await _load(silent: true);
      return granted;
    } on BluetoothInfoException catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return false;
    } finally {
      if (mounted) setState(() => _requestingPermission = false);
    }
  }

  Future<void> _openSettings() async {
    try {
      await _client.openSettings();
    } on BluetoothInfoException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.page),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              _PageHeader(
                onBack: () {
                  if (context.router.canPop()) {
                    context.router.maybePop();
                  } else {
                    context.router.navigatePath('/');
                  }
                },
                onRefresh: _load,
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }

    final info = _info;
    if (info == null) {
      return const Center(
        child: Text(
          'Bluetooth bilgisi yok.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: <Widget>[
        _StatusHero(info: info),
        if (info.supported &&
            (!info.permissionGranted || !info.scanPermissionGranted)) ...<Widget>[
          const SizedBox(height: 12),
          _PermissionBanner(
            busy: _requestingPermission,
            onRequest: _requestPermission,
          ),
        ],
        const SizedBox(height: 18),
        const _SectionTitle('ADAPTÖR'),
        const SizedBox(height: 8),
        _InfoCard(
          children: <Widget>[
            _InfoRow(label: 'Durum', value: info.state, highlight: info.enabled),
            _InfoRow(
              label: 'Destek',
              value: info.supported ? 'Var' : 'Yok',
              highlight: info.supported,
            ),
            _InfoRow(
              label: 'Ad',
              value: info.hasName
                  ? info.name!
                  : (info.permissionGranted ? 'Okunamadı' : 'İzin gerekli'),
            ),
            _InfoRow(
              label: 'MAC adresi',
              value: (info.address ?? '').isNotEmpty
                  ? info.address!
                  : (info.permissionGranted ? 'Okunamadı' : 'İzin gerekli'),
              monospace: true,
            ),
          ],
        ),
        if (info.permissionError != null) ...<Widget>[
          const SizedBox(height: 8),
          Text(
            info.permissionError!,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: Color(0xFFFCD34D),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: _SectionTitle(
                _nearby.isEmpty
                    ? 'YAKINDAKİ CİHAZLAR'
                    : 'YAKINDAKİ CİHAZLAR (${_nearby.length})',
              ),
            ),
            if (info.supported)
              _ScanButton(
                scanning: _scanning,
                enabled: info.enabled && !_requestingPermission,
                onTap: _toggleScan,
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_scanning) ...<Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: const LinearProgressIndicator(minHeight: 3),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.8),
              ),
              const SizedBox(width: 8),
              Text(
                'Taranıyor… yakındaki cihazlar aranıyor',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.cyan.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        if (_scanError != null) ...<Widget>[
          _ScanErrorCard(message: _scanError!, onRetry: _startScan),
          const SizedBox(height: 10),
        ],
        if (!info.supported)
          const _EmptyCard(
            icon: Icons.bluetooth_disabled_rounded,
            text: 'Bu cihazda Bluetooth adaptörü bulunmadığı için tarama yapılamaz.',
          )
        else if (!info.enabled)
          const _EmptyCard(
            icon: Icons.power_settings_new_rounded,
            text: 'Tarama için Bluetooth’u açın.',
          )
        else if (!info.scanPermissionGranted)
          const _EmptyCard(
            icon: Icons.lock_outline_rounded,
            text: 'Yakındaki cihazları taramak için Bluetooth izni gerekir.',
          )
        else if (_nearby.isEmpty && !_scanning)
          _EmptyCard(
            icon: Icons.bluetooth_searching_rounded,
            text: _hasScanned && !_scanning
                ? 'Tarama tamamlandı, yakında cihaz bulunamadı. Yeniden denemek için TARA’ya basın.'
                : 'Yakındaki cihazları bulmak için TARA’ya basın.',
          )
        else
          ...(_nearby.values.toList()
                ..sort((a, b) => b.rssi.compareTo(a.rssi)))
              .map(
                (device) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: BluetoothDeviceTile(device: device, showSignal: true),
                ),
              ),
        const SizedBox(height: 18),
        const _SectionTitle('CİHAZ'),
        const SizedBox(height: 8),
        _InfoCard(
          children: <Widget>[
            _InfoRow(label: 'Model', value: info.deviceModel),
            _InfoRow(label: 'Sistem', value: info.androidVersion),
            _InfoRow(label: 'Kanal', value: 'bluetooth_info (Kotlin)'),
          ],
        ),
        const SizedBox(height: 18),
        _SectionTitle(
          info.bondedDevices.isEmpty
              ? 'EŞLEŞMİŞ CİHAZLAR'
              : 'EŞLEŞMİŞ CİHAZLAR (${info.bondedDevices.length})',
        ),
        const SizedBox(height: 8),
        if (!info.permissionGranted)
          const _EmptyCard(
            icon: Icons.lock_outline_rounded,
            text: 'Eşleşmiş cihazları görmek için Bluetooth izni gerekir.',
          )
        else if (info.bondedDevices.isEmpty)
          const _EmptyCard(
            icon: Icons.bluetooth_searching_rounded,
            text: 'Eşleşmiş cihaz bulunamadı.',
          )
        else
          ...info.bondedDevices.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: BluetoothDeviceTile(device: device),
            ),
          ),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('YENİLE', style: TextStyle(fontSize: 11.5)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings_bluetooth_rounded, size: 16),
                label: const Text(
                  'AYARLAR',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: <Widget>[
          PressableScale(
            scale: 0.9,
            onTap: onBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Bluetooth Bilgisi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Platform channel · Kotlin',
                  maxLines: 1,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          PressableScale(
            scale: 0.9,
            onTap: onRefresh,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: const Icon(
                Icons.refresh_rounded,
                size: 19,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.info});

  final BluetoothInfo info;

  @override
  Widget build(BuildContext context) {
    final active = info.enabled;
    final accent = !info.supported
        ? const Color(0xFFF87171)
        : (active ? const Color(0xFF34D399) : const Color(0xFFFBBF24));

    final title = !info.supported
        ? 'Bluetooth desteklenmiyor'
        : (active ? 'Bluetooth açık' : 'Bluetooth kapalı');
    final subtitle = !info.supported
        ? 'Bu cihazda Bluetooth adaptörü bulunamadı.'
        : (active
              ? 'Yakındaki cihazları taramaya hazır.'
              : 'Bilgi okumak için Bluetooth’u açın.');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            accent.withValues(alpha: 0.22),
            const Color(0xFF111A33),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Icon(Icons.bluetooth_rounded, color: accent, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  const _PermissionBanner({required this.busy, required this.onRequest});

  final bool busy;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: AppColors.amber,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Android 12+ sürümlerinde cihaz adı, MAC adresi, eşleşmiş '
                  'cihazlar ve yakındaki cihaz taraması için izin gerekir.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: AppColors.amber.withValues(alpha: 0.95),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: busy ? null : onRequest,
              child: Text(busy ? 'İSTENİYOR…' : 'İZİN VER'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10.5,
        letterSpacing: 1.1,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted.withValues(alpha: 0.9),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.highlight,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool? highlight;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final valueColor = highlight == null
        ? AppColors.textPrimary
        : (highlight! ? const Color(0xFF6EE7B7) : const Color(0xFFFCD34D));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted.withValues(alpha: 0.95),
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
                fontFamily: monospace ? 'monospace' : null,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bölüm başlığının yanındaki TARA / DURDUR düğmesi.
class _ScanButton extends StatelessWidget {
  const _ScanButton({
    required this.scanning,
    required this.enabled,
    required this.onTap,
  });

  final bool scanning;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = scanning ? const Color(0xFFF87171) : AppColors.cyan;
    return PressableScale(
      scale: 0.94,
      onTap: enabled ? onTap : () {},
      child: Container(
        key: const ValueKey<String>('bluetooth-scan-button'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.14 : 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: enabled ? 0.4 : 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              scanning ? Icons.stop_rounded : Icons.radar_rounded,
              size: 14,
              color: color.withValues(alpha: enabled ? 1 : 0.4),
            ),
            const SizedBox(width: 5),
            Text(
              scanning ? 'DURDUR' : 'TARA',
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: enabled ? 1 : 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarama sırasında oluşan hatayı gösterir.
class _ScanErrorCard extends StatelessWidget {
  const _ScanErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF87171).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF87171).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 16,
            color: Color(0xFFF87171),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 11.5, height: 1.35),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('TEKRAR', style: TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            PressableScale(
              scale: 0.9,
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tekrar dene',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
