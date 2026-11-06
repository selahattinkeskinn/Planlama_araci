import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../router/app_router.gr.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';

@RoutePage(name: 'NotlarRoute')
class NotlarSayfasi extends StatefulWidget {
  const NotlarSayfasi({super.key});

  @override
  State<NotlarSayfasi> createState() => _NotlarSayfasiState();
}

class _NotlarSayfasiState extends State<NotlarSayfasi> {
  late final Box _box = Hive.box('notes');

  Future<void> _addNote() async {
    final int key = await _box.add(<String, dynamic>{
      'title': 'Yeni not',
      'content': '',
      'createdAt': DateTime.now().toIso8601String(),
    });
    if (!mounted) return;
    await context.pushRoute(NotDetayRoute(noteKey: key));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.page),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Notlar'),
          leading: PressableScale(
            scale: 0.9,
            onTap: () {
              if (context.router.canPop()) {
                context.router.maybePop();
              } else {
                context.router.navigatePath('/');
              }
            },
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addNote,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Yeni not'),
          backgroundColor: AppColors.primary,
        ),
        body: StreamBuilder<dynamic>(
          stream: _box.watch(),
          builder: (context, snapshot) {
            final List<dynamic> keys = _box.keys.toList();
            if (keys.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz not yok. + ile ekle.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
              itemCount: keys.length,
              itemBuilder: (context, index) {
                final dynamic key = keys[index];
                final Map data = Map<String, dynamic>.from(
                  _box.get(key) as Map,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PressableScale(
                    onTap: () =>
                        context.pushRoute(NotDetayRoute(noteKey: key as int)),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.cyan.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            (data['title'] as String?)?.trim().isEmpty ?? true
                                ? 'Başlıksız not'
                                : data['title'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (data['content'] as String?) ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
