import 'package:auto_route/auto_route.dart';
import 'package:device_hardware_info/device_hardware_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/device_info/device_info_bloc.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/pressable_scale.dart';

@RoutePage()
class SohbetDeviceInfoPage extends StatelessWidget {
  const SohbetDeviceInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DeviceInfoBloc()..add(const LoadDeviceInfo()),
      child: const _SohbetDeviceInfoView(),
    );
  }
}

class _SohbetDeviceInfoView extends StatelessWidget {
  const _SohbetDeviceInfoView();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.page),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: <Widget>[
                    PressableScale(
                      scale: 0.9,
                      onTap: () {
                        if (context.router.canPop()) {
                          context.router.maybePop();
                        } else {
                          context.router.navigatePath('/');
                        }
                      },
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
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
                            'Cihaz Bilgileri',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Donanım numaraları · IMEI · root',
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    PressableScale(
                      scale: 0.9,
                      onTap: () => context.read<DeviceInfoBloc>().add(
                        const LoadDeviceInfo(),
                      ),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
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
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<DeviceInfoBloc, DeviceInfoState>(
                  builder: (context, state) {
                    if (state is DeviceInfoLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state is DeviceInfoError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
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
                                state.message,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              PressableScale(
                                scale: 0.9,
                                onTap: () => context
                                    .read<DeviceInfoBloc>()
                                    .add(const LoadDeviceInfo()),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
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
                    if (state is DeviceInfoLoaded) {
                      return _DeviceInfoList(data: state.data);
                    }
                    return const Center(
                      child: Text(
                        'Cihaz bilgisi yok',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceInfoList extends StatelessWidget {
  const _DeviceInfoList({required this.data});

  final DeviceInfoData data;

  @override
  Widget build(BuildContext context) {
    final hardware = data.hardware;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: <Widget>[
        _InfoRow(
          icon: Icons.phone_android_rounded,
          title: 'Model',
          value: data.model,
          accent: AppColors.primary,
        ),
        _InfoRow(
          icon: Icons.factory_rounded,
          title: 'Üretici',
          value: data.manufacturer,
          accent: AppColors.cyan,
        ),
        _InfoRow(
          icon: Icons.devices_rounded,
          title: 'Cihaz Adı',
          value: data.deviceName,
          accent: AppColors.amber,
        ),
        _InfoRow(
          icon: Icons.info_rounded,
          title: 'İşletim Sistemi',
          value: '${data.osName} ${data.osVersion}',
          accent: AppColors.primary,
        ),
        _InfoRow(
          icon: Icons.info_rounded,
          title: 'API Seviyesi',
          value: '${data.sdkInt}',
          accent: AppColors.cyan,
        ),
        _InfoRow(
          icon: Icons.computer_rounded,
          title: 'Emülatör',
          value: data.isEmulator ? 'Evet' : 'Hayır',
          accent: data.isEmulator ? Colors.redAccent : Colors.greenAccent,
        ),
        if (hardware != null)
          ..._hardwareWidgets(context, hardware)
        else
          _NoteCard(
            text:
                data.hardwareError ??
                'Donanım bilgileri bu platformda kullanılamıyor.',
          ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Özet',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.manufacturer} ${data.model}, '
                '${data.osName} ${data.osVersion} (API ${data.sdkInt}) '
                'cihazında çalışıyor.'
                '${hardware == null ? '' : '\n${hardware.cpuCores} çekirdek · '
                          '${formatBytes(hardware.totalRamBytes)} RAM · '
                          '${formatBytes(hardware.totalStorageBytes)} depolama'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _hardwareWidgets(
    BuildContext context,
    DeviceHardwareInfo hardware,
  ) {
    final soc = <String?>[
      hardware.socManufacturer,
      hardware.socModel,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

    return <Widget>[
      const _SectionLabel('DONANIM NUMARALARI'),
      _InfoRow(
        icon: Icons.tag_rounded,
        title: 'IMEI',
        value: hardware.imeiDisplay,
        accent: hardware.imei != null
            ? AppColors.cyan
            : AppColors.textMuted,
        monospace: true,
      ),
      _InfoRow(
        icon: Icons.sim_card_rounded,
        title: 'MEID',
        value: hardware.meid ?? 'Okunamadı',
        accent: hardware.meid != null ? AppColors.cyan : AppColors.textMuted,
        monospace: true,
      ),
      _InfoRow(
        icon: Icons.pin_rounded,
        title: 'Seri No',
        value: hardware.serialDisplay,
        accent: hardware.serial != null ? AppColors.cyan : AppColors.textMuted,
        monospace: true,
      ),
      _InfoRow(
        icon: Icons.fingerprint_rounded,
        title: 'Android ID',
        value: hardware.androidId ?? 'Okunamadı',
        accent: AppColors.amber,
        monospace: true,
      ),
      _InfoRow(
        icon: Icons.perm_identity_rounded,
        title: 'Parmak izi',
        value: hardware.buildFingerprint,
        accent: AppColors.primary,
        monospace: true,
        maxLines: 2,
      ),
      if (hardware.imeiNote != null) _NoteCard(text: hardware.imeiNote!),
      if (!hardware.phonePermissionGranted &&
          hardware.serialStatus == 'permission_required')
        _PermissionCard(
          onRequest: () => context.read<DeviceInfoBloc>().add(
            const RequestHardwarePermission(),
          ),
        ),
      const _SectionLabel('DONANIM'),
      _InfoRow(
        icon: Icons.memory_rounded,
        title: 'İşlemci',
        value: hardware.cpuHardware ?? hardware.hardware,
        accent: AppColors.primary,
        maxLines: 2,
      ),
      _InfoRow(
        icon: Icons.developer_board_rounded,
        title: 'Çekirdek / ABI',
        value: '${hardware.cpuCores} çekirdek · ${hardware.cpuAbi ?? '-'}',
        accent: AppColors.cyan,
      ),
      if (hardware.cpuMaxFreqLabel != null)
        _InfoRow(
          icon: Icons.speed_rounded,
          title: 'CPU Hızı',
          value: hardware.cpuMaxFreqLabel!,
          accent: AppColors.amber,
        ),
      _InfoRow(
        icon: Icons.storage_rounded,
        title: 'RAM',
        value:
            '${formatBytes(hardware.availableRamBytes)} boş / '
            '${formatBytes(hardware.totalRamBytes)}',
        accent: AppColors.cyan,
      ),
      _InfoRow(
        icon: Icons.sd_storage_rounded,
        title: 'Depolama',
        value:
            '${formatBytes(hardware.freeStorageBytes)} boş / '
            '${formatBytes(hardware.totalStorageBytes)}',
        accent: AppColors.amber,
      ),
      _InfoRow(
        icon: Icons.aspect_ratio_rounded,
        title: 'Ekran',
        value:
            '${hardware.resolutionLabel} · ${hardware.densityDpi} dpi · '
            '${hardware.refreshRate.toStringAsFixed(0)} Hz',
        accent: AppColors.primary,
      ),
      _InfoRow(
        icon: Icons.dashboard_rounded,
        title: 'Kart / Bootloader',
        value: '${hardware.board} · ${hardware.bootloader}',
        accent: AppColors.cyan,
        maxLines: 2,
      ),
      _InfoRow(
        icon: Icons.settings_input_component_rounded,
        title: 'SoC',
        value: soc.isEmpty ? hardware.hardware : soc,
        accent: AppColors.amber,
        maxLines: 2,
      ),
      const _SectionLabel('KÖK / SİSTEM'),
      _InfoRow(
        icon: hardware.isRooted
            ? Icons.gpp_bad_rounded
            : Icons.verified_user_rounded,
        title: 'Root',
        value: hardware.isRooted
            ? 'Evet · ${hardware.rootIndicators.length} gösterge'
            : 'Hayır (temiz)',
        accent: hardware.isRooted ? Colors.redAccent : Colors.greenAccent,
      ),
      if (hardware.rootIndicators.isNotEmpty)
        _NoteCard(text: hardware.rootIndicators.join('\n')),
      _InfoRow(
        icon: Icons.security_rounded,
        title: 'SELinux',
        value: hardware.selinux,
        accent: hardware.selinux == 'Enforcing'
            ? Colors.greenAccent
            : AppColors.amber,
      ),
      _InfoRow(
        icon: Icons.terminal_rounded,
        title: 'Çekirdek',
        value: hardware.kernelVersion ?? '-',
        accent: AppColors.primary,
        monospace: true,
        maxLines: 2,
      ),
      _InfoRow(
        icon: Icons.build_circle_rounded,
        title: 'Build',
        value: '${hardware.buildId} · ${hardware.buildType}',
        accent: AppColors.cyan,
        monospace: true,
        maxLines: 2,
      ),
      _InfoRow(
        icon: Icons.label_rounded,
        title: 'Build Etiketleri',
        value: hardware.buildTags,
        accent: AppColors.amber,
        monospace: true,
        maxLines: 2,
      ),
      _InfoRow(
        icon: Icons.update_rounded,
        title: 'Güvenlik Yaması',
        value: hardware.securityPatch ?? '-',
        accent: AppColors.primary,
      ),
      _InfoRow(
        icon: Icons.radio_rounded,
        title: 'Radyo',
        value: hardware.radioVersion,
        accent: AppColors.cyan,
        monospace: true,
        maxLines: 2,
      ),
    ];
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted.withValues(alpha: 0.9),
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.amber,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              text,
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: AppColors.amber.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.lock_open_rounded,
            size: 16,
            color: AppColors.cyan,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Seri no/IMEI için telefon izni gerekir.',
              style: TextStyle(fontSize: 11, height: 1.35),
            ),
          ),
          TextButton(
            onPressed: onRequest,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('İZİN VER', style: TextStyle(fontSize: 10.5)),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
    this.maxLines = 1,
    this.monospace = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;
  final int maxLines;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  maxLines: maxLines,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: monospace ? 'monospace' : null,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
