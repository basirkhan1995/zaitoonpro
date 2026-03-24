import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zaitoonpro/Views/Menu/Ui/Report/Ui/TotalDailyTxn/model/daily_txn_model.dart';
import '../../../../../../../Services/repositories.dart';
import '../model/total_daily_compare.dart';


part 'total_daily_event.dart';
part 'total_daily_state.dart';

class TotalDailyBloc extends Bloc<TotalDailyEvent, TotalDailyState> {
  final Repositories repository;

  TotalDailyBloc(this.repository) : super(TotalDailyInitial()) {
    on<LoadTotalDailyEvent>(_onLoadTotalDaily);
  }

  Future<void> _onLoadTotalDaily(
      LoadTotalDailyEvent event,
      Emitter<TotalDailyState> emit,
      ) async {
    // Preserve current data if already loaded
    List<TotalDailyCompare>? currentData;
    if (state is TotalDailyLoaded) {
      currentData = (state as TotalDailyLoaded).data;
    }

    // Only show full loading if no previous data
    if (currentData == null || currentData.isEmpty) {
      emit(TotalDailyLoading());
    }

    try {
      /// TODAY DATA
      final todayList = await repository.totalDailyTxnReport(
        fromDate: event.fromDate,
        toDate: event.toDate,
      );

      /// YESTERDAY DATE
      final yesterdayDate =
      DateTime.parse(event.fromDate).subtract(const Duration(days: 1));
      final yDate = _formatDate(yesterdayDate);

      /// YESTERDAY DATA
      final yesterdayList = await repository.totalDailyTxnReport(
        fromDate: yDate,
        toDate: yDate,
      );

      /// MERGE
      final compareList = _mergeTxn(todayList, yesterdayList);

      emit(TotalDailyLoaded(compareList));
    } catch (e) {
      // On error, keep current data if exists
      if (currentData != null) {
        emit(TotalDailyLoaded(currentData, isRefreshing: false));
      } else {
        emit(TotalDailyError(e.toString()));
      }
    }
  }

  /// 🔹 DATE FORMAT
  String _formatDate(DateTime d) {
    return "${d.year}-${d.month}-${d.day}";
  }

  /// 🔹 MERGE TODAY + YESTERDAY
  List<TotalDailyCompare> _mergeTxn(
      List<TotalDailyTxnModel> today,
      List<TotalDailyTxnModel> yesterday,
      ) {
    final yMap = {for (var y in yesterday) y.txnName ?? '' : y};

    return today.map((t) {
      final y = yMap[t.txnName ?? ''];

      return TotalDailyCompare(
        today: t,
        yesterday: y ?? TotalDailyTxnModel(
          txnName: t.txnName,
          totalAmount: 0,
          totalCount: 0,
        ),
      );
    }).toList();
  }
}
