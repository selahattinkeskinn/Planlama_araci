// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i12;
import 'package:flutter/material.dart' as _i13;
import 'package:flutter_application_1/pages/bluetooth_info_page.dart' as _i1;
import 'package:flutter_application_1/pages/finance_dashboard.dart' as _i2;
import 'package:flutter_application_1/pages/home_page.dart' as _i3;
import 'package:flutter_application_1/pages/llm_chat_page.dart' as _i4;
import 'package:flutter_application_1/pages/not_detay_sayfasi.dart' as _i5;
import 'package:flutter_application_1/pages/notlar_sayfasi.dart' as _i6;
import 'package:flutter_application_1/pages/payment_simulation_page.dart'
    as _i7;
import 'package:flutter_application_1/pages/sohbet_app_network_info.dart'
    as _i8;
import 'package:flutter_application_1/pages/sohbet_detay.dart' as _i9;
import 'package:flutter_application_1/pages/sohbet_device_info.dart' as _i10;
import 'package:flutter_application_1/pages/sohbet_listesi.dart' as _i11;

/// generated route for
/// [_i1.BluetoothInfoPage]
class BluetoothInfoRoute extends _i12.PageRouteInfo<void> {
  const BluetoothInfoRoute({List<_i12.PageRouteInfo>? children})
    : super(BluetoothInfoRoute.name, initialChildren: children);

  static const String name = 'BluetoothInfoRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i1.BluetoothInfoPage();
    },
  );
}

/// generated route for
/// [_i2.FinanceDashboardPage]
class FinanceDashboardRoute extends _i12.PageRouteInfo<void> {
  const FinanceDashboardRoute({List<_i12.PageRouteInfo>? children})
    : super(FinanceDashboardRoute.name, initialChildren: children);

  static const String name = 'FinanceDashboardRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i2.FinanceDashboardPage();
    },
  );
}

/// generated route for
/// [_i3.HomePage]
class HomeRoute extends _i12.PageRouteInfo<void> {
  const HomeRoute({List<_i12.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i3.HomePage();
    },
  );
}

/// generated route for
/// [_i4.LlmChatPage]
class LlmChatRoute extends _i12.PageRouteInfo<void> {
  const LlmChatRoute({List<_i12.PageRouteInfo>? children})
    : super(LlmChatRoute.name, initialChildren: children);

  static const String name = 'LlmChatRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i4.LlmChatPage();
    },
  );
}

/// generated route for
/// [_i5.NotDetaySayfasi]
class NotDetayRoute extends _i12.PageRouteInfo<NotDetayRouteArgs> {
  NotDetayRoute({
    _i13.Key? key,
    required int noteKey,
    List<_i12.PageRouteInfo>? children,
  }) : super(
         NotDetayRoute.name,
         args: NotDetayRouteArgs(key: key, noteKey: noteKey),
         rawPathParams: {'key': noteKey},
         initialChildren: children,
       );

  static const String name = 'NotDetayRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<NotDetayRouteArgs>(
        orElse: () => NotDetayRouteArgs(noteKey: pathParams.getInt('key')),
      );
      return _i5.NotDetaySayfasi(key: args.key, noteKey: args.noteKey);
    },
  );
}

class NotDetayRouteArgs {
  const NotDetayRouteArgs({this.key, required this.noteKey});

  final _i13.Key? key;

  final int noteKey;

  @override
  String toString() {
    return 'NotDetayRouteArgs{key: $key, noteKey: $noteKey}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NotDetayRouteArgs) return false;
    return key == other.key && noteKey == other.noteKey;
  }

  @override
  int get hashCode => key.hashCode ^ noteKey.hashCode;
}

/// generated route for
/// [_i6.NotlarSayfasi]
class NotlarRoute extends _i12.PageRouteInfo<void> {
  const NotlarRoute({List<_i12.PageRouteInfo>? children})
    : super(NotlarRoute.name, initialChildren: children);

  static const String name = 'NotlarRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i6.NotlarSayfasi();
    },
  );
}

/// generated route for
/// [_i7.PaymentSimulationPage]
class PaymentSimulationRoute extends _i12.PageRouteInfo<void> {
  const PaymentSimulationRoute({List<_i12.PageRouteInfo>? children})
    : super(PaymentSimulationRoute.name, initialChildren: children);

  static const String name = 'PaymentSimulationRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i7.PaymentSimulationPage();
    },
  );
}

/// generated route for
/// [_i8.SohbetAppNetworkInfoPage]
class SohbetAppNetworkInfoRoute extends _i12.PageRouteInfo<void> {
  const SohbetAppNetworkInfoRoute({List<_i12.PageRouteInfo>? children})
    : super(SohbetAppNetworkInfoRoute.name, initialChildren: children);

  static const String name = 'SohbetAppNetworkInfoRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i8.SohbetAppNetworkInfoPage();
    },
  );
}

/// generated route for
/// [_i9.SohbetDetay]
class SohbetRoute extends _i12.PageRouteInfo<SohbetRouteArgs> {
  SohbetRoute({
    _i13.Key? key,
    required int id,
    List<_i12.PageRouteInfo>? children,
  }) : super(
         SohbetRoute.name,
         args: SohbetRouteArgs(key: key, id: id),
         rawPathParams: {'id': id},
         initialChildren: children,
       );

  static const String name = 'SohbetRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<SohbetRouteArgs>(
        orElse: () => SohbetRouteArgs(id: pathParams.getInt('id')),
      );
      return _i9.SohbetDetay(key: args.key, id: args.id);
    },
  );
}

class SohbetRouteArgs {
  const SohbetRouteArgs({this.key, required this.id});

  final _i13.Key? key;

  final int id;

  @override
  String toString() {
    return 'SohbetRouteArgs{key: $key, id: $id}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SohbetRouteArgs) return false;
    return key == other.key && id == other.id;
  }

  @override
  int get hashCode => key.hashCode ^ id.hashCode;
}

/// generated route for
/// [_i10.SohbetDeviceInfoPage]
class SohbetDeviceInfoRoute extends _i12.PageRouteInfo<void> {
  const SohbetDeviceInfoRoute({List<_i12.PageRouteInfo>? children})
    : super(SohbetDeviceInfoRoute.name, initialChildren: children);

  static const String name = 'SohbetDeviceInfoRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i10.SohbetDeviceInfoPage();
    },
  );
}

/// generated route for
/// [_i11.SohbetListesi]
class SohbetListesiRoute extends _i12.PageRouteInfo<void> {
  const SohbetListesiRoute({List<_i12.PageRouteInfo>? children})
    : super(SohbetListesiRoute.name, initialChildren: children);

  static const String name = 'SohbetListesiRoute';

  static _i12.PageInfo page = _i12.PageInfo(
    name,
    builder: (data) {
      return const _i11.SohbetListesi();
    },
  );
}
