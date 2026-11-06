import 'package:auto_route/auto_route.dart';

import 'app_router.gr.dart';
import 'page_transitions.dart';

@AutoRouterConfig(replaceInRouteName: 'Page,Route', generateForDir: ['lib'])
class AppRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => <AutoRoute>[
    CustomRoute(
      page: HomeRoute.page,
      initial: true,
      path: '/',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: SohbetListesiRoute.page,
      path: '/sohbetler',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: NotlarRoute.page,
      path: '/notlar',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: NotDetayRoute.page,
      path: '/not/:key',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: SohbetRoute.page,
      path: '/sohbet/:id',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: SohbetDeviceInfoRoute.page,
      path: '/sohbet/device-info',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: SohbetAppNetworkInfoRoute.page,
      path: '/sohbet/app-network',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: FinanceDashboardRoute.page,
      path: '/finans',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: LlmChatRoute.page,
      path: '/llm',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: BluetoothInfoRoute.page,
      path: '/bluetooth',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    CustomRoute(
      page: PaymentSimulationRoute.page,
      path: '/odeme',
      transitionsBuilder: softPageTransition,
      duration: const Duration(milliseconds: 420),
      reverseDuration: const Duration(milliseconds: 320),
    ),
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}
