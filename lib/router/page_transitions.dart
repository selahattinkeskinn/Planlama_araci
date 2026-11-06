import 'package:flutter/material.dart';

/// Yeni sayfa: hafif yukarı kayma + ölçek + fade ile girer.
/// Alttaki sayfa çok hafifçe küçülerek derinlik verir.
Widget softPageTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final Animation<double> enter = CurvedAnimation(
    parent: animation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  final Animation<double> exit = CurvedAnimation(
    parent: secondaryAnimation,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  return FadeTransition(
    opacity: enter,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(enter),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1).animate(enter),
        child: ScaleTransition(
          scale: Tween<double>(begin: 1, end: 0.98).animate(exit),
          child: child,
        ),
      ),
    ),
  );
}

/// Sohbet listesi ile detay ekranı arasındaki ikon geçişi için etiket.
String chatIconHeroTag(int chatId) => 'sohbet-ikon-$chatId';
