import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ItemTotalClickState {}

class ItemTotalClickInitial extends ItemTotalClickState {}

class ItemTotalClickInProgress extends ItemTotalClickState {}

class ItemTotalClickSuccess extends ItemTotalClickState {}

class ItemTotalClickFailure extends ItemTotalClickState {
  final String errorMessage;

  ItemTotalClickFailure(this.errorMessage);
}

class ItemTotalClickCubit extends Cubit<ItemTotalClickState> {
  final ItemRepository _itemRepository = ItemRepository();

  ItemTotalClickCubit() : super(ItemTotalClickInitial());

  Future<void> itemTotalClick(int id) async {
    try {
      emit(ItemTotalClickInProgress());

      await _itemRepository.itemTotalClick(id);
      emit(ItemTotalClickSuccess());
    } catch (e) {
      emit(ItemTotalClickFailure(e.toString()));
    }
  }
}
