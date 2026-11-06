import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';

import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';

@RoutePage(name: 'NotDetayRoute')
class NotDetaySayfasi extends StatefulWidget {
  const NotDetaySayfasi({super.key, @PathParam('key') required this.noteKey});

  final int noteKey;

  @override
  State<NotDetaySayfasi> createState() => _NotDetaySayfasiState();
}

class _NotDetaySayfasiState extends State<NotDetaySayfasi> {
  late final Box _box = Hive.box('notes');
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    final dynamic raw = _box.get(widget.noteKey);
    if (raw is Map) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(raw);
      _titleController.text = (data['title'] as String?) ?? '';
      _contentController.text = (data['content'] as String?) ?? '';
    }
    _loaded = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    final Map<String, dynamic> current = Map<String, dynamic>.from(
      _box.get(widget.noteKey) as Map,
    );
    current['title'] = _titleController.text.trim();
    current['content'] = _contentController.text;
    current['updatedAt'] = DateTime.now().toIso8601String();
    _box.put(widget.noteKey, current);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Not kaydedildi')));
  }

  Future<void> _delete() async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notu sil'),
        content: const Text('Bu not kalıcı olarak silinecek.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _box.delete(widget.noteKey);
      if (mounted) context.router.maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final dynamic raw = _box.get(widget.noteKey);
    if (raw == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Not bulunamadı')),
        body: const Center(child: Text('Bu not silinmiş olabilir.')),
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.page),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Not detayı'),
          actions: <Widget>[
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Sil',
            ),
          ],
          leading: PressableScale(
            scale: 0.9,
            onTap: () {
              if (context.router.canPop()) {
                context.router.maybePop();
              } else {
                context.router.navigatePath('/notlar');
              }
            },
            child: const Icon(Icons.arrow_back_rounded),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _titleController,
                style: Theme.of(context).textTheme.titleLarge,
                decoration: const InputDecoration(
                  hintText: 'Başlık',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    hintText: 'Not içeriği...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
