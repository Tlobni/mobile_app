import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ChangeMyItemStatusState {}

class ChangeMyItemStatusInitial extends ChangeMyItemStatusState {}

class ChangeMyItemStatusInProgress extends ChangeMyItemStatusState {}

class ChangeMyItemStatusSuccess extends ChangeMyItemStatusState {
  final String message;

  ChangeMyItemStatusSuccess(this.message);
}

class ChangeMyItemStatusFailure extends ChangeMyItemStatusState {
  final String errorMessage;

  ChangeMyItemStatusFailure(this.errorMessage);
}

class ChangeMyItemStatusCubit extends Cubit<ChangeMyItemStatusState> {
  final ItemRepository _itemRepository = ItemRepository();

  ChangeMyItemStatusCubit() : super(ChangeMyItemStatusInitial());

  Future<void> changeMyItemStatus(
      {required int id, required String status, int? userId}) async {
    try {
      emit(ChangeMyItemStatusInProgress());

      await _itemRepository
          .changeMyItemStatus(itemId: id, status: status, userId: userId)
          .then((value) {
        emit(ChangeMyItemStatusSuccess(value["message"]));
      });
    } catch (e) {
      emit(ChangeMyItemStatusFailure(e.toString()));
    }
  }
}
