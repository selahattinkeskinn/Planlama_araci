import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/chat_thread.dart';
import '../router/app_router.gr.dart';
import '../theme/app_theme.dart';
import '../widgets/network_status_banner.dart';
import '../widgets/pressable_scale.dart';

@RoutePage()
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _openChat(BuildContext context) async {
    final result = await context.pushRoute<String>(SohbetRoute(id: 42));
    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Dönüş değeri: ${result ?? 'yok'}')));
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.page),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: <Widget>[
            const Positioned(
              top: -140,
              right: -80,
              child: _Glow(color: AppColors.primary, size: 320),
            ),
            const Positioned(
              bottom: -120,
              left: -120,
              child: _Glow(color: AppColors.cyan, size: 340),
            ),
            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                children: <Widget>[
                  const NetworkStatusBanner(),
                  const SizedBox(height: 8),
                  const _HomeHeader(),
                  const SizedBox(height: 36),
                  Text(
                    'Planlama Ajanı',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Sohbetlerini tek yerden yönet, gününü planla ve '
                    'fikirlerini kaçırma.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 26),
                  PressableScale(
                    key: const ValueKey<String>('agent-card'),
                    onTap: () => _openChat(context),
                    child: const _AgentCard(),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    key: const ValueKey<String>('all-chats-button'),
                    scale: 0.98,
                    onTap: () => context.pushRoute(const SohbetListesiRoute()),
                    child: const _AllChatsButton(),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    key: const ValueKey<String>('notes-button'),
                    scale: 0.98,
                    onTap: () => context.pushRoute(const NotlarRoute()),
                    child: const _NotesButton(),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: <Widget>[
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.bolt_rounded,
                          title: 'Hızlı',
                          subtitle: 'Anında yanıt',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.shield_outlined,
                          title: 'Güvenli',
                          subtitle: 'Yerel oturum',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PressableScale(
                    key: const ValueKey<String>('device-info-button'),
                    scale: 0.98,
                    onTap: () => context.pushRoute(const SohbetDeviceInfoRoute()),
                    child: const _InfoCard(
                      icon: Icons.phone_android_rounded,
                      title: 'Cihaz Bilgisi',
                      subtitle: 'Sistem ve donanım detayları',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    key: const ValueKey<String>('app-network-button'),
                    scale: 0.98,
                    onTap: () =>
                        context.pushRoute(const SohbetAppNetworkInfoRoute()),
                    child: const _InfoCard(
                      icon: Icons.info_rounded,
                      title: 'Uygulama ve Ağ',
                      subtitle: 'Paket ve bağlantı bilgileri',
                    ),
                  ),
                  const SizedBox(height: 16),
                  PressableScale(
                    key: const ValueKey<String>('finance-dashboard-button'),
                    scale: 0.98,
                    onTap: () => context.pushRoute(const FinanceDashboardRoute()),
                    child: const _InfoCard(
                      icon: Icons.attach_money_rounded,
                      title: 'Finans Pano',
                      subtitle: 'Para birimleri, haberler ve istatistikler',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    key: const ValueKey<String>('llm-chat-button'),
                    scale: 0.98,
                    onTap: () => context.pushRoute(const LlmChatRoute()),
                    child: const _InfoCard(
                      icon: Icons.auto_awesome_rounded,
                      title: 'LLM Sohbet',
                      subtitle: 'Yapay zekâ ile canlı sohbet',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    key: const ValueKey<String>('bluetooth-info-button'),
                    scale: 0.98,
                    onTap: () => context.pushRoute(const BluetoothInfoRoute()),
                    child: const _InfoCard(
                      icon: Icons.bluetooth_rounded,
                      title: 'Bluetooth Bilgisi',
                      subtitle: 'Platform channel (Kotlin) ile adaptör durumu',
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableScale(
                    key: const ValueKey<String>('payment-simulation-button'),
                    scale: 0.98,
                    onTap: () =>
                        context.pushRoute(const PaymentSimulationRoute()),
                    child: const _InfoCard(
                      icon: Icons.credit_card_rounded,
                      title: 'Ödeme Alanı',
                      subtitle: '6 aşamalı JavaScript ödeme simülasyonu',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[AppColors.primary, AppColors.cyan],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Merhaba', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                'Planlama alanın hazır',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFF34D399),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                'Çevrimiçi',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgentCard extends StatelessWidget {
  const _AgentCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF241C4D), Color(0xFF132A4A)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[AppColors.primary, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Planlama Ajanı',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '3 sohbet · seni bekliyor',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final ChatThread chat in planningChats) _ChatTag(chat: chat),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatTag extends StatelessWidget {
  const _ChatTag({required this.chat});

  final ChatThread chat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: chat.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: chat.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(chat.icon, size: 14, color: chat.accent),
          const SizedBox(width: 6),
          Text(
            chat.title,
            style: TextStyle(
              color: chat.accent.withValues(alpha: 0.95),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AllChatsButton extends StatelessWidget {
  const _AllChatsButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.cyan.withValues(alpha: 0.28),
                  AppColors.primary.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.view_list_rounded,
              color: AppColors.cyan,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Tüm sohbetler',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(
                  '${planningChats.length} sohbet tek listede',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesButton extends StatelessWidget {
  const _NotesButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  AppColors.amber.withValues(alpha: 0.28),
                  AppColors.primary.withValues(alpha: 0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
            ),
            child: const Icon(
              Icons.note_alt_rounded,
              color: AppColors.amber,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Notlar (Hive)',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 1),
                Text(
                  'Yerel depolama ile not ekle/düzenle',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: AppColors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontSize: 14),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                color.withValues(alpha: 0.28),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
