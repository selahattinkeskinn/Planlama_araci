import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/llm_chat/llm_chat_bloc.dart';
import '../models/llm_chat_model.dart';
import '../models/llm_provider.dart';
import '../services/llm_service.dart';
import '../services/llm_settings_service.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';

@RoutePage()
class LlmChatPage extends StatelessWidget {
  const LlmChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LlmChatBloc>(
      create: (_) => LlmChatBloc(),
      child: const _LlmChatView(),
    );
  }
}

class _LlmChatView extends StatefulWidget {
  const _LlmChatView();

  @override
  State<_LlmChatView> createState() => _LlmChatViewState();
}

class _LlmChatViewState extends State<_LlmChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<LlmChatBloc>().add(const LlmChatStarted());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send(BuildContext context, String text) {
    if (text.trim().isEmpty) return;
    _controller.clear();
    context.read<LlmChatBloc>().add(SendPrompt(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _openSettings(BuildContext context) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => const _LlmSettingsDialog(),
    );
    if (!context.mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('LLM ayarları kaydedildi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.page),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('LLM Sohbet'),
          centerTitle: true,
          elevation: 0,
          leading: PressableScale(
            scale: 0.9,
            onTap: () {
              if (context.router.canPop()) {
                context.router.maybePop();
              } else {
                context.router.navigatePath('/');
              }
            },
            child: const Icon(Icons.arrow_back_rounded, size: 20),
          ),
          actions: <Widget>[
            IconButton(
              tooltip: 'Ayarlar',
              icon: const Icon(Icons.tune_rounded, size: 20),
              onPressed: () => _openSettings(context),
            ),
            IconButton(
              tooltip: 'Yeni sohbet',
              icon: const Icon(Icons.add_comment_outlined, size: 20),
              onPressed: () =>
                  context.read<LlmChatBloc>().add(const NewSession()),
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: BlocConsumer<LlmChatBloc, LlmChatState>(
                listenWhen: (previous, current) =>
                    previous != current &&
                    (current is LlmChatLoaded || current is LlmChatError),
                listener: (context, state) => _scrollToBottom(),
                builder: (context, state) {
                  final messages = switch (state) {
                    LlmChatLoaded(:final messages) => messages,
                    LlmChatError(:final messages) => messages,
                    _ => const <LlmMessage>[],
                  };

                  if (messages.isEmpty) {
                    return _EmptyState(
                      error: state is LlmChatError ? state.message : null,
                      onConfigure: () => _openSettings(context),
                    );
                  }

                  return Column(
                    children: <Widget>[
                      if (state is LlmChatError)
                        _ErrorBanner(
                          message: state.message,
                          onRetry: () => context.read<LlmChatBloc>().add(
                            const RetryLastPrompt(),
                          ),
                          onSettings: () => _openSettings(context),
                        ),
                      Expanded(
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: messages.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final message = messages[index];
                            return _MessageBubble(message: message);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            BlocBuilder<LlmChatBloc, LlmChatState>(
              builder: (context, state) {
                final isSending = state is LlmChatLoaded && state.isSending;
                return _InputField(
                  controller: _controller,
                  enabled: !isSending,
                  onSend: (text) => _send(context, text),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.error, required this.onConfigure});

  final String? error;
  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[AppColors.primary, AppColors.cyan],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(
                hasError
                    ? Icons.error_outline_rounded
                    : Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              hasError ? 'Bağlantı kurulamadı' : 'Yapay zekâ ile sohbet',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error ??
                  'Bir soru yazın; yanıt canlı olarak burada görünecek. '
                      'Sohbetler cihazınızda saklanır.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (hasError) ...<Widget>[
              const SizedBox(height: 20),
              PressableScale(
                scale: 0.95,
                onTap: onConfigure,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButton,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'API ANAHTARINI GİR',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.onSettings,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.error_outline_rounded,
                color: Color(0xFFF87171),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: Color(0xFFFCA5A5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              TextButton(
                onPressed: onRetry,
                child: const Text('TEKRAR DENE'),
              ),
              TextButton(
                onPressed: onSettings,
                child: const Text('AYARLAR'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final LlmMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Row(
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (!isUser) ...<Widget>[
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: isUser
                  ? AppColors.primary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 18),
              ),
              border: Border.all(
                color: isUser
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : Colors.white.withValues(alpha: 0.09),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SelectableText(
                  message.text.isEmpty ? '…' : message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: isUser ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (message.isStreaming) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Yazılıyor…',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isUser) ...<Widget>[
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 14,
              color: AppColors.cyan,
            ),
          ),
        ],
      ],
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.onSend,
    required this.enabled,
  });

  final TextEditingController controller;
  final void Function(String) onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF090F1E).withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: 5,
                minLines: 1,
                enabled: enabled,
                textInputAction: TextInputAction.newline,
                style: const TextStyle(fontSize: 14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: enabled ? 'Bir şeyler sorun…' : 'Yanıt yazılıyor…',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                onSubmitted: enabled ? onSend : null,
              ),
            ),
            const SizedBox(width: 10),
            PressableScale(
              scale: 0.9,
              onTap: enabled ? () => onSend(controller.text) : () {},
              child: Opacity(
                opacity: enabled ? 1 : 0.5,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[AppColors.primary, AppColors.cyan],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
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

/// API anahtarı / sunucu / model ayarları.
class _LlmSettingsDialog extends StatefulWidget {
  const _LlmSettingsDialog();

  @override
  State<_LlmSettingsDialog> createState() => _LlmSettingsDialogState();
}

class _LlmSettingsDialogState extends State<_LlmSettingsDialog> {
  final _service = LlmSettingsService();
  final _apiKeyController = TextEditingController();
  final _baseUrlController = TextEditingController(text: LlmDefaults.baseUrl);
  final _modelController = TextEditingController(text: LlmDefaults.model);
  bool _obscure = true;
  bool _loading = true;
  bool _saving = false;
  bool _fetchingModels = false;
  String? _fetchError;

  LlmProviderPreset? get _provider =>
      LlmProviders.matchByBaseUrl(_baseUrlController.text);

  @override
  void initState() {
    super.initState();
    _apiKeyController.addListener(_onFieldChanged);
    _baseUrlController.addListener(_onFieldChanged);
    _load();
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    final settings = await _service.load();
    if (!mounted) return;
    setState(() {
      _apiKeyController.text = settings.apiKey;
      _baseUrlController.text = settings.baseUrl;
      _modelController.text = settings.model;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  void _applyPreset(LlmProviderPreset preset) {
    setState(() {
      _baseUrlController.text = preset.baseUrl;
      _modelController.text = preset.defaultModel;
      _fetchError = null;
    });
  }

  Future<void> _fetchModels() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _fetchingModels = true;
      _fetchError = null;
    });
    try {
      final service = LlmService(
        apiKey: _apiKeyController.text.trim(),
        baseUrl: _baseUrlController.text.trim(),
        model: _modelController.text.trim(),
      );
      final models = await service.listModels();
      if (!mounted) return;
      final picked = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: AppColors.surface,
        isScrollControlled: true,
        builder: (_) => _ModelPickerSheet(
          models: models,
          selected: _modelController.text.trim(),
        ),
      );
      if (picked != null && picked.isNotEmpty && mounted) {
        setState(() => _modelController.text = picked);
      }
    } on LlmApiException catch (error) {
      if (!mounted) return;
      setState(() => _fetchError = error.message);
    } finally {
      if (mounted) setState(() => _fetchingModels = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final baseUrl = LlmProviders.normalizeBaseUrl(_baseUrlController.text);
    final model = _modelController.text.trim();
    final provider = LlmProviders.matchByBaseUrl(baseUrl);
    await _service.save(
      LlmSettings(
        apiKey: _apiKeyController.text,
        baseUrl: baseUrl.isEmpty ? LlmDefaults.baseUrl : baseUrl,
        model: model.isEmpty
            ? (provider?.defaultModel ?? LlmDefaults.model)
            : model,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget _buildKeyWarning() {
    final key = _apiKeyController.text.trim();
    final provider = _provider;
    if (key.isEmpty || provider == null) return const SizedBox.shrink();
    if (provider.acceptsKey(key)) return const SizedBox.shrink();

    final owner = LlmProviders.detectByKey(key);
    final text = owner != null && owner.id != provider.id
        ? 'Bu anahtar ${owner.label} anahtarı gibi görünüyor. '
              '${provider.label} anahtarı ${provider.keyHint}.'
        : '${provider.label} anahtarı ${provider.keyHint}.';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.warning_amber_rounded,
            size: 15,
            color: Color(0xFFFBBF24),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: Color(0xFFFCD34D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('LLM Ayarları'),
      content: SizedBox(
        width: 420,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'SAĞLAYICI',
                      style: TextStyle(
                        fontSize: 10.5,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: LlmProviders.all.map((preset) {
                        final selected = provider?.id == preset.id;
                        return ChoiceChip(
                          label: Text(
                            preset.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: AppColors.primary.withValues(
                            alpha: 0.28,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.05),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.12),
                          ),
                          onSelected: (_) => _applyPreset(preset),
                        );
                      }).toList(),
                    ),
                    if (provider?.note != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        provider!.note!,
                        style: TextStyle(
                          fontSize: 11,
                          height: 1.35,
                          color: AppColors.textMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: _obscure,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: 'API Anahtarı',
                        hintText: provider?.keyHint ?? 'sk-...',
                        helperText:
                            'Anahtar yalnızca bu cihazda saklanır. '
                            'Kredi/limit biterse 429 hatası alırsınız.',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    _buildKeyWarning(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _baseUrlController,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Sunucu (Base URL)',
                        hintText: 'https://api.openai.com/v1',
                        helperText:
                            'Sağlayıcı seçince otomatik dolar. OpenAI uyumlu '
                            'her sunucu kullanılabilir.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _modelController,
                      autocorrect: false,
                      decoration: const InputDecoration(
                        labelText: 'Model',
                        hintText: 'gpt-4o-mini',
                      ),
                    ),
                    if (provider != null &&
                        provider.modelSuggestions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: provider.modelSuggestions.map((model) {
                          return ActionChip(
                            label: Text(
                              model,
                              style: const TextStyle(fontSize: 10.5),
                            ),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.04,
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
                            onPressed: () =>
                                setState(() => _modelController.text = model),
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _fetchingModels ? null : _fetchModels,
                        icon: _fetchingModels
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(
                          _fetchingModels ? 'GETİRİLİYOR…' : 'MODELLERİ GETİR',
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ),
                    if (_fetchError != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        _fetchError!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.35,
                          color: Color(0xFFFCA5A5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('VAZGEÇ'),
        ),
        FilledButton(
          onPressed: (_saving || _loading) ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('KAYDET'),
        ),
      ],
    );
  }
}

/// Sunucudan gelen model kimliklerinden birini seçtiren liste.
class _ModelPickerSheet extends StatefulWidget {
  const _ModelPickerSheet({required this.models, required this.selected});

  final List<String> models;
  final String selected;

  @override
  State<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends State<_ModelPickerSheet> {
  final _filterController = TextEditingController();

  @override
  void dispose() {
    _filterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _filterController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.models
        : widget.models
              .where((model) => model.toLowerCase().contains(query))
              .toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 14),
            Text(
              'MODEL SEÇ (${widget.models.length})',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _filterController,
                autocorrect: false,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Filtrele…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Flexible(
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Eşleşen model yok.',
                        style: TextStyle(fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final model = filtered[index];
                        final isSelected = model == widget.selected;
                        return ListTile(
                          dense: true,
                          title: Text(
                            model,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: isSelected
                                  ? AppColors.primary
                                  : null,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                )
                              : null,
                          onTap: () => Navigator.of(context).pop(model),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
