import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DeleteItemState {}

class DeleteItemInitial extends DeleteItemState {}

class DeleteItemInProgress extends DeleteItemState {}

class DeleteItemSuccess extends DeleteItemState {}

class DeleteItemFailure extends DeleteItemState {
  final String errorMessage;

  DeleteItemFailure(this.errorMessage);
}

class DeleteItemCubit extends Cubit<DeleteItemState> {
  final ItemRepository _itemRepository = ItemRepository();

  DeleteItemCubit() : super(DeleteItemInitial());

  Future<void> deleteItem(int id) async {
    try {
      emit(DeleteItemInProgress());

      await _itemRepository.deleteItem(id);
      emit(DeleteItemSuccess());
    } catch (e) {
      emit(DeleteItemFailure(e.toString()));
    }
  }
}
