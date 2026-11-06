import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/chat_thread.dart';
import '../router/page_transitions.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_composer.dart';
import '../widgets/media_message.dart';
import '../widgets/rotating_cube_3d.dart';
import '../widgets/pressable_scale.dart';

@RoutePage(name: 'SohbetRoute')
class SohbetDetay extends StatefulWidget {
  const SohbetDetay({super.key, @PathParam('id') required this.id});

  final int id;

  @override
  State<SohbetDetay> createState() => _SohbetDetayState();
}

class _SohbetDetayState extends State<SohbetDetay> {
  late int _selectedIndex = _initialIndex();

  int _initialIndex() {
    final int index = planningChats.indexWhere(
      (ChatThread chat) => chat.id == widget.id,
    );
    return index < 0 ? 0 : index;
  }

  late final Map<int, List<ChatMessage>> _messages = <int, List<ChatMessage>>{
    for (final ChatThread chat in planningChats)
      chat.id: List<ChatMessage>.of(chat.messages),
  };

  ChatThread get _selectedChat => planningChats[_selectedIndex];

  List<ChatMessage> get _selectedMessages => _messages[_selectedChat.id]!;

  void _selectChat(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  void _sendMessage(String text, ChatAttachment? attachment) {
    final int threadId = _selectedChat.id;
    setState(() {
      _messages[threadId] = <ChatMessage>[
        ..._messages[threadId]!,
        ChatMessage(fromAgent: false, text: text, attachment: attachment),
      ];
    });
  }

  void _goBack(BuildContext context) {
    if (context.router.canPop()) {
      context.router.maybePop();
    } else {
      context.router.navigatePath('/');
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
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: <Widget>[
                    _RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => _goBack(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Planlama Ajanı',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Oturum #${widget.id}',
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Canlı',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    PressableScale(
                      key: const ValueKey<String>('archive-button'),
                      scale: 0.9,
                      onTap: () => context.pop('arsivlendi'),
                      child: const _RoundIconButtonBody(
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                child: _SelectedChatCard(
                  chat: _selectedChat,
                  messageCount: _selectedMessages.length,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 46,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: planningChats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final ChatThread chat = planningChats[index];
                    return _ChatButton(
                      key: ValueKey<String>('chat-chip-${chat.id}'),
                      chat: chat,
                      selected: index == _selectedIndex,
                      onTap: () => _selectChat(index),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              if (_selectedChat.id == 3)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: RotatingCube3D(),
                ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 380),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        final Animation<Offset> slide = Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: slide, child: child),
                        );
                      },
                  child: _ChatThreadView(
                    key: ValueKey<String>('thread-${_selectedChat.id}'),
                    thread: _selectedChat,
                    messages: _selectedMessages,
                  ),
                ),
              ),
              ChatComposer(
                key: ValueKey<String>('composer-${_selectedChat.id}'),
                accent: _selectedChat.accent,
                onSend: _sendMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.9,
      onTap: onTap,
      child: _RoundIconButtonBody(icon: icon),
    );
  }
}

class _RoundIconButtonBody extends StatelessWidget {
  const _RoundIconButtonBody({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, size: 19, color: AppColors.textPrimary),
    );
  }
}

class _SelectedChatCard extends StatelessWidget {
  const _SelectedChatCard({required this.chat, required this.messageCount});

  final ChatThread chat;
  final int messageCount;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: chat.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: <Widget>[
          Hero(
            tag: chatIconHeroTag(chat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: chat.accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(chat.icon, color: chat.accent, size: 24),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              layoutBuilder:
                  (Widget? currentChild, List<Widget> previousChildren) {
                    return Stack(
                      alignment: Alignment.centerLeft,
                      children: <Widget>[...previousChildren, ?currentChild],
                    );
                  },
              child: Column(
                key: ValueKey<int>(chat.id),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    chat.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chat.summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: chat.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$messageCount mesaj',
              style: TextStyle(
                color: chat.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatButton extends StatelessWidget {
  const _ChatButton({
    super.key,
    required this.chat,
    required this.selected,
    required this.onTap,
  });

  final ChatThread chat;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color selectedForeground = chat.accent.computeLuminance() > 0.4
        ? const Color(0xFF0B1020)
        : Colors.white;

    return PressableScale(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: <Color>[
                    chat.accent.withValues(alpha: 0.95),
                    chat.accent.withValues(alpha: 0.62),
                  ],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: chat.accent.withValues(alpha: 0.32),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              chat.icon,
              size: 17,
              color: selected ? selectedForeground : chat.accent,
            ),
            const SizedBox(width: 7),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? selectedForeground : AppColors.textMuted,
              ),
              child: Text(chat.title),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatThreadView extends StatefulWidget {
  const _ChatThreadView({
    super.key,
    required this.thread,
    required this.messages,
  });

  final ChatThread thread;
  final List<ChatMessage> messages;

  @override
  State<_ChatThreadView> createState() => _ChatThreadViewState();
}

class _ChatThreadViewState extends State<_ChatThreadView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();
  late final int _initialCount;

  @override
  void initState() {
    super.initState();
    _initialCount = widget.messages.length;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _scrollToBottomLater(jump: true);
  }

  @override
  void didUpdateWidget(covariant _ChatThreadView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      _scrollToBottomLater();
    }
  }

  void _scrollToBottomLater({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final double target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ChatMessage> messages = widget.messages;
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final Widget bubble = _MessageBubble(
          message: messages[index],
          accent: widget.thread.accent,
        );

        if (index >= _initialCount) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == messages.length - 1 ? 0 : 14,
            ),
            child: _AppearMessage(child: bubble),
          );
        }

        final double start = (index / (_initialCount + 1))
            .clamp(0.0, 0.65)
            .toDouble();
        final double end = (start + 0.45).clamp(0.0, 1.0).toDouble();
        final CurvedAnimation animation = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.18),
              end: Offset.zero,
            ).animate(animation),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: index == messages.length - 1 ? 0 : 14,
              ),
              child: bubble,
            ),
          ),
        );
      },
    );
  }
}

class _AppearMessage extends StatelessWidget {
  const _AppearMessage({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.accent});

  final ChatMessage message;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final bool isAgent = message.fromAgent;
    final bool hasAttachment = message.attachment != null;

    final Widget content = hasAttachment
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MediaMessage(attachment: message.attachment!, accent: accent),
              if (message.text.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.textPrimary.withValues(alpha: 0.92),
                  ),
                ),
              ],
            ],
          )
        : Text(
            message.text,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isAgent
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.82),
            ),
          );

    final Widget bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.74,
      ),
      padding: hasAttachment
          ? const EdgeInsets.all(9)
          : const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: isAgent
            ? accent.withValues(alpha: 0.13)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isAgent ? 6 : 18),
          bottomRight: Radius.circular(isAgent ? 18 : 6),
        ),
        border: Border.all(
          color: isAgent
              ? accent.withValues(alpha: 0.32)
              : Colors.white.withValues(alpha: 0.09),
        ),
      ),
      child: content,
    );

    return Row(
      mainAxisAlignment: isAgent
          ? MainAxisAlignment.start
          : MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        if (isAgent) ...<Widget>[
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
          ),
        ],
        Flexible(child: bubble),
      ],
    );
  }
}
