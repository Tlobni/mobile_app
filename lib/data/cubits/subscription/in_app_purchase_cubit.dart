import 'package:tlobni/data/repositories/in_app_purchase_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class InAppPurchaseState {}

class InAppPurchaseInitial extends InAppPurchaseState {}

class InAppPurchaseInProgress extends InAppPurchaseState {}

class InAppPurchaseInSuccess extends InAppPurchaseState {
  final String responseMessage;

  InAppPurchaseInSuccess(this.responseMessage);
}

class InAppPurchaseFailure extends InAppPurchaseState {
  final dynamic error;

  InAppPurchaseFailure(this.error);
}

class InAppPurchaseCubit extends Cubit<InAppPurchaseState> {
  InAppPurchaseCubit() : super(InAppPurchaseInitial());
  InAppPurchaseRepository repository = InAppPurchaseRepository();

  void inAppPurchase(
      {required String purchaseToken,
      required String method,
      required int packageId}) async {
    emit(InAppPurchaseInProgress());

    repository
        .inAppPurchases(
            packageId: packageId, method: method, purchaseToken: purchaseToken)
        .then((value) {
      emit(InAppPurchaseInSuccess(value['message']));
    }).catchError((e) {
      emit(InAppPurchaseFailure(e.toString()));
    });
  }
}
