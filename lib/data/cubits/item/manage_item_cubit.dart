import 'dart:async';
import 'dart:io';
import 'package:tlobni/data/repositories/item/item_repository.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:flutter/material.dart';
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

// Create a global event bus to notify other parts of the app when an item is edited
class ItemEvents {
  static final ItemEvents _instance = ItemEvents._internal();

  factory ItemEvents() {
    return _instance;
  }

  ItemEvents._internal();

  // Define event streams
  final itemEditedStream = StreamController<ItemModel>.broadcast();

  // Method to notify when an item is edited
  void itemEdited(ItemModel item) {
    itemEditedStream.add(item);
  }

  // Clean up
  void dispose() {
    itemEditedStream.close();
  }
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

        // Notify other parts of the app about the edited item
        ItemEvents().itemEdited(itemModel);

        emit(ManageItemSuccess(itemModel, type));
      }
    } catch (e) {
      emit(ManageItemFail(e));
    }
  }

  // Method to update a specific item in other BLoCs
  Future<void> updateItemInOtherBlocs(
      ItemModel editedItem, BuildContext context) async {
    // Update FetchMyItemsCubit if it exists
    try {
      final myItemsCubit = context.read<FetchMyItemsCubit>();
      if (myItemsCubit.state is FetchMyItemsSuccess) {
        myItemsCubit.edit(editedItem);
      }
    } catch (e) {
      print("Could not update FetchMyItemsCubit: $e");
    }

    // You can add more BLoCs to update here as needed
  }
}
