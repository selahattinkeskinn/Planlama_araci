import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/chat_thread.dart';
import '../router/app_router.gr.dart';
import '../router/page_transitions.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';

@RoutePage(name: 'SohbetListesiRoute')
class SohbetListesi extends StatelessWidget {
  const SohbetListesi({super.key});

  void _goBack(BuildContext context) {
    if (context.router.canPop()) {
      context.router.maybePop();
    } else {
      context.router.navigatePath('/');
    }
  }

  Future<void> _openChat(BuildContext context, ChatThread chat) async {
    await context.pushRoute<String>(SohbetRoute(id: chat.id));
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
              top: -160,
              right: -90,
              child: _ListGlow(color: AppColors.primary, size: 300),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
                    child: Row(
                      children: <Widget>[
                        PressableScale(
                          scale: 0.9,
                          onTap: () => _goBack(context),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Tüm sohbetler',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontSize: 19),
                              ),
                              Text(
                                '${planningChats.length} aktif sohbet',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.cyan.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              const Icon(
                                Icons.forum_rounded,
                                size: 14,
                                color: AppColors.cyan,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${planningChats.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      key: const ValueKey<String>('sohbet-listesi'),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      itemCount: planningChats.length,
                      itemBuilder: (BuildContext context, int index) {
                        final ChatThread chat = planningChats[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == planningChats.length - 1 ? 0 : 12,
                          ),
                          child: _ChatListTile(
                            key: ValueKey<String>('sohbet-satiri-${chat.id}'),
                            chat: chat,
                            onTap: () => _openChat(context, chat),
                          ),
                        );
                      },
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

class _ChatListTile extends StatelessWidget {
  const _ChatListTile({super.key, required this.chat, required this.onTap});

  final ChatThread chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final int messageCount = chat.messages.length;

    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              chat.accent.withValues(alpha: 0.16),
              Colors.white.withValues(alpha: 0.03),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: chat.accent.withValues(alpha: 0.26)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Hero(
              tag: chatIconHeroTag(chat.id),
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: chat.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: chat.accent.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(chat.icon, color: chat.accent, size: 26),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          chat.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$messageCount mesaj',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: chat.accent.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    chat.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.circle,
                        size: 7,
                        color: const Color(0xFF34D399),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Aktif',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: AppColors.textMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: chat.accent.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: chat.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListGlow extends StatelessWidget {
  const _ListGlow({required this.color, required this.size});

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
                color.withValues(alpha: 0.22),
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
