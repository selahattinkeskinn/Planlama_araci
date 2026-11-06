import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/finance_data.dart';
import '../../services/finance_service.dart';

abstract class FinanceEvent {
  const FinanceEvent();
}

class LoadFinanceData extends FinanceEvent {
  const LoadFinanceData();
}

abstract class FinanceState {
  const FinanceState();
}

class FinanceInitial extends FinanceState {
  const FinanceInitial();
}

class FinanceLoading extends FinanceState {
  const FinanceLoading();
}

class FinanceLoaded extends FinanceState {
  const FinanceLoaded(this.data);

  final FinanceData data;
}

class FinanceError extends FinanceState {
  const FinanceError(this.message);

  final String message;
}

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {
  FinanceBloc() : super(const FinanceInitial()) {
    on<LoadFinanceData>((event, emit) async {
      emit(const FinanceLoading());
      try {
        final service = FinanceService();
        final data = await service.fetchLiveData();
        emit(FinanceLoaded(data));
      } catch (e) {
        emit(FinanceError('Veriler yüklenemedi: $e'));
      }
    });
  }
}
