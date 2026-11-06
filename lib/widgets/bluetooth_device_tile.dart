import 'package:bluetooth_info/bluetooth_info.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Eşleşmiş ya da taramada bulunmuş bir Bluetooth cihazını gösteren kart.
///
/// [showSignal] true olduğunda RSSI değeri çubuklar ve dBm etiketiyle
/// gösterilir; false olduğunda eşleşme durumu simgesi çizilir.
class BluetoothDeviceTile extends StatelessWidget {
  const BluetoothDeviceTile({
    super.key,
    required this.device,
    this.showSignal = false,
  });

  final BluetoothDeviceInfo device;
  final bool showSignal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.devices_other_rounded,
              size: 18,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.address} · ${device.type}',
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          if (showSignal)
            _SignalMeter(device: device)
          else if (device.bonded)
            const Icon(
              Icons.link_rounded,
              size: 16,
              color: Color(0xFF34D399),
            ),
        ],
      ),
    );
  }
}

/// RSSI değerini çubuklar + dBm etiketiyle gösterir.
class _SignalMeter extends StatelessWidget {
  const _SignalMeter({required this.device});

  final BluetoothDeviceInfo device;

  int get _level {
    final rssi = device.rssi;
    if (rssi >= -60) return 4;
    if (rssi >= -70) return 3;
    if (rssi >= -80) return 2;
    return device.hasSignal ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    final color = level >= 3
        ? const Color(0xFF34D399)
        : (level == 2 ? AppColors.amber : const Color(0xFFF87171));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            for (var i = 1; i <= 4; i++)
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Container(
                  width: 3,
                  height: 4.0 + (i * 3),
                  decoration: BoxDecoration(
                    color: i <= level
                        ? color
                        : Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          device.hasSignal ? '${device.rssi} dBm' : '—',
          style: TextStyle(
            fontSize: 9.5,
            fontFamily: 'monospace',
            color: AppColors.textMuted.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}
