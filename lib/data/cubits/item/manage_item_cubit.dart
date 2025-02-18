import 'dart:io';
import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ManageItemType { add, edit, delete }

abstract class ManageItemState {}

class ManageItemInitial extends ManageItemState {}

class ManageItemInProgress extends ManageItemState {}

class ManageItemSuccess extends ManageItemState {
  final ManageItemType type;
  final ItemModel model;

  ManageItemSuccess(this.model, this.type);
}

class ManageItemFail extends ManageItemState {
  final dynamic error;

  ManageItemFail(this.error);
}

class ManageItemCubit extends Cubit<ManageItemState> {
  ManageItemCubit() : super(ManageItemInitial());
  final ItemRepository _itemRepository = ItemRepository();

  void manage(ManageItemType type, Map<String, dynamic> data, File? mainImage,
      List<File>? otherImage) async {
    try {
      emit(ManageItemInProgress());

      if (type == ManageItemType.add) {
        ItemModel itemModel =
            await _itemRepository.createItem(data, mainImage!, otherImage!);
        emit(ManageItemSuccess(itemModel, type));
      } else if (type == ManageItemType.edit) {
        ItemModel itemModel =
            await _itemRepository.editItem(data, mainImage, otherImage);
        emit(ManageItemSuccess(itemModel, type));
      }
    } catch (e) {
      emit(ManageItemFail(e));
    }
  }
}
