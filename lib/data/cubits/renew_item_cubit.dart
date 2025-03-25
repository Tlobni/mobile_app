import 'package:tlobni/data/repositories/renew_item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class RenewItemState {}

class RenewItemInitial extends RenewItemState {}

class RenewItemInProgress extends RenewItemState {}

class RenewItemInSuccess extends RenewItemState {
  final String responseMessage;

  RenewItemInSuccess(this.responseMessage);
}

class RenewItemFailure extends RenewItemState {
  final dynamic error;

  RenewItemFailure(this.error);
}

class RenewItemCubit extends Cubit<RenewItemState> {
  RenewItemCubit() : super(RenewItemInitial());
  RenewItemRepositoryRepository repository = RenewItemRepositoryRepository();

  void renewItem({required int itemId, required int packageId}) async {
    emit(RenewItemInProgress());

    repository.renewItem(itemId: itemId, packageId: packageId).then((value) {
      emit(RenewItemInSuccess(value['message']));
    }).catchError((e) {
      emit(RenewItemFailure(e.toString()));
    });
  }
}
