import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/payment_simulation_result.dart';
import '../theme/app_theme.dart';
import '../widgets/pressable_scale.dart';

/// Tamamen JavaScript ile yazılmış 6 aşamalı ödeme simülasyonunu barındıran
/// WebView sayfası.
///
/// HTML varlığı: `assets/payment/payment_simulation.html`
/// JavaScript köprüsü: `PaymentBridge` (JSON mesajları)
@RoutePage()
class PaymentSimulationPage extends StatefulWidget {
  const PaymentSimulationPage({super.key});

  @override
  State<PaymentSimulationPage> createState() => _PaymentSimulationPageState();
}

class _PaymentSimulationPageState extends State<PaymentSimulationPage> {
  late final WebViewController _controller;

  bool _loading = true;
  String? _loadError;
  PaymentSimulationResult? _result;
  String? _lastMessageKey;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..addJavaScriptChannel(
        'PaymentBridge',
        onMessageReceived: _onBridgeMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _loadError = null;
            });
          },
          onPageFinished: (String url) {
            if (!mounted) return;
            setState(() => _loading = false);
            // Flutter başlığı varken HTML başlığı yinelenmesin.
            _controller.runJavaScript(
              "var header = document.querySelector('header');"
              "if (header) { header.style.display = 'none'; }",
            );
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _loading = false;
              _loadError =
                  'Ödeme ekranı yüklenemedi: ${error.description}';
            });
          },
        ),
      )
      ..loadFlutterAsset('assets/payment/payment_simulation.html');
  }

  void _reload() {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _controller.loadFlutterAsset('assets/payment/payment_simulation.html');
  }

  void _onBridgeMessage(JavaScriptMessage message) {
    final Object? decoded;
    try {
      decoded = jsonDecode(message.message);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;

    final result = PaymentSimulationResult.fromMap(decoded);
    if (result.status == null) return;

    if (result.isReset) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _lastMessageKey = null;
      });
      return;
    }

    // Aynı sonucu birden fazla kez göstermeyi engelle.
    final key = '${result.status}|${result.transactionId}|${result.reason}';
    if (key == _lastMessageKey) return;
    _lastMessageKey = key;

    if (!mounted) return;
    setState(() => _result = result);

    final String text;
    if (result.approved) {
      text = 'Ödeme simülasyonu onaylandı · ${result.totalLabel}';
    } else {
      text = 'Ödeme simülasyonu reddedildi · ${result.reasonLabel}';
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  void _goBack() {
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
          bottom: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(
                  children: <Widget>[
                    PressableScale(
                      key: const ValueKey<String>('payment-back-button'),
                      scale: 0.9,
                      onTap: _goBack,
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
                            'Ödeme Alanı',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '6 aşamalı doğrulama · JavaScript simülasyonu',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.amber.withValues(alpha: 0.35),
                        ),
                      ),
                      child: const Text(
                        'SİMÜLASYON',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_result != null)
                _ResultBanner(
                  result: _result!,
                  onDismiss: () => setState(() => _result = null),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      WebViewWidget(
                        key: const ValueKey<String>('payment-webview'),
                        controller: _controller,
                      ),
                      if (_loading)
                        const _LoadingOverlay()
                      else if (_loadError != null)
                        _ErrorOverlay(
                          message: _loadError!,
                          onRetry: _reload,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.result, required this.onDismiss});

  final PaymentSimulationResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final bool ok = result.approved;
    final Color accent = ok ? const Color(0xFF34D399) : const Color(0xFFF87171);
    final String title = ok ? 'Ödeme onaylandı' : 'Ödeme reddedildi';
    final String detail = ok
        ? '${result.totalLabel} · ${result.transactionId ?? '-'}'
        : '${result.reasonLabel} · ${result.totalLabel}';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            ok ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            visualDensity: VisualDensity.compact,
            iconSize: 16,
            color: AppColors.textMuted,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Sonucu kapat',
          ),
        ],
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Ödeme ekranı yükleniyor…',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.public_off_rounded,
                size: 34,
                color: AppColors.amber,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('TEKRAR DENE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
