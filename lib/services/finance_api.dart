import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/finance_models.dart';

part 'finance_api.g.dart';

/// Frankfurter API — canlı döviz kurları (anahtar gerektirmez, ücretsiz).
@RestApi(baseUrl: "https://api.frankfurter.app")
abstract class FinanceApi {
  factory FinanceApi(Dio dio, {String? baseUrl}) = _FinanceApi;

  @GET("/latest")
  Future<CurrencyResponse> getLatestRates(@Query("from") String from);
}
