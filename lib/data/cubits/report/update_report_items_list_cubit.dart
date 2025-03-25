import 'package:tlobni/data/model/item/item_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Define the states
class UpdatedReportItemState {
  final List<ItemModel> items;

  UpdatedReportItemState(this.items);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpdatedReportItemState &&
          runtimeType == other.runtimeType &&
          items == other.items;

  @override
  int get hashCode => items.hashCode;
}

// Define the Cubit
class UpdatedReportItemCubit extends Cubit<UpdatedReportItemState> {
  UpdatedReportItemCubit() : super(UpdatedReportItemState([]));

  void addItem(ItemModel model) {
    List<ItemModel> updatedItems = List.from(state.items)..add(model);
    emit(UpdatedReportItemState(updatedItems));
  }

  void removeItem(ItemModel model) {
    List<ItemModel> updatedItems = List.from(state.items)..remove(model);
    emit(UpdatedReportItemState(updatedItems));
  }

  void clearItem() {
    List<ItemModel> updatedItems = List.from(state.items)..clear();
    emit(UpdatedReportItemState(updatedItems));
  }

  bool containsItem(int itemId) {
    return state.items.any((item) => item.id == itemId);
  }

  @override
  void onChange(Change<UpdatedReportItemState> change) {
    super.onChange(change);
  }
}
