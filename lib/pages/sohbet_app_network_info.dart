import 'package:auto_route/auto_route.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/app_network_info/app_network_info_bloc.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';

@RoutePage()
class SohbetAppNetworkInfoPage extends StatelessWidget {
  const SohbetAppNetworkInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AppNetworkInfoBloc()..add(const LoadAppNetworkInfo()),
      child: const _SohbetAppNetworkInfoView(),
    );
  }
}

class _SohbetAppNetworkInfoView extends StatelessWidget {
  const _SohbetAppNetworkInfoView();

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
                            'Uygulama ve Ağ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Paket ve bağlantı bilgileri',
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    StreamBuilder<List<ConnectivityResult>>(
                      stream: Connectivity().onConnectivityChanged,
                      initialData: const <ConnectivityResult>[],
                      builder: (context, snapshot) {
                        final results = snapshot.data ?? const <ConnectivityResult>[];
                        final bool offline = results.isEmpty ||
                            results.every((r) => r == ConnectivityResult.none);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: offline
                                ? Colors.redAccent.withValues(alpha: 0.2)
                                : Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                offline
                                    ? Icons.wifi_off_rounded
                                    : Icons.wifi_rounded,
                                color: offline
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                offline ? 'Çevrimdışı' : 'Çevrimiçi',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<AppNetworkInfoBloc, AppNetworkInfoState>(
                  builder: (context, state) {
                    if (state is AppNetworkInfoLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state is AppNetworkInfoError) {
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
                                    .read<AppNetworkInfoBloc>()
                                    .add(const LoadAppNetworkInfo()),
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
                    if (state is AppNetworkInfoLoaded) {
                      return _AppNetworkInfoList(data: state.data);
                    }
                    return const Center(
                      child: Text(
                        'Bilgi yok',
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

class _AppNetworkInfoList extends StatelessWidget {
  const _AppNetworkInfoList({required this.data});

  final AppNetworkInfoData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      children: <Widget>[
        _InfoRow(
          icon: Icons.info_rounded,
          title: 'Uygulama Adı',
          value: data.appName,
          accent: AppColors.primary,
        ),
        _InfoRow(
          icon: Icons.label_rounded,
          title: 'Paket Adı',
          value: data.packageName,
          accent: AppColors.cyan,
        ),
        _InfoRow(
          icon: Icons.numbers_rounded,
          title: 'Versiyon',
          value: data.version,
          accent: AppColors.amber,
        ),
        _InfoRow(
          icon: Icons.build_rounded,
          title: 'Build Numarası',
          value: data.buildNumber,
          accent: AppColors.primary,
        ),
        _InfoRow(
          icon: Icons.wifi_rounded,
          title: 'Bağlantı Türü',
          value: data.connectivityType,
          accent: data.isOnline ? Colors.greenAccent : Colors.redAccent,
        ),
        _InfoRow(
          icon: Icons.wifi_rounded,
          title: 'Ağ Durumu',
          value: data.isOnline ? 'Çevrimiçi' : 'Çevrimdışı',
          accent: data.isOnline ? Colors.greenAccent : Colors.redAccent,
        ),
        _InfoRow(
          icon: Icons.access_time_rounded,
          title: 'Son Kontrol',
          value: '${data.lastChecked.hour}:${data.lastChecked.minute.toString().padLeft(2, '0')}:${data.lastChecked.second.toString().padLeft(2, '0')}',
          accent: AppColors.cyan,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                '${data.appName} (${data.packageName}) '
                'v${data.version} (+${data.buildNumber}) '
                '| ${data.connectivityType}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color accent;

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
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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
