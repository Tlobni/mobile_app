/*
import 'package:flutter/cupertino.dart';

import '../../../Ui/screens/Widgets/Errors/something_went_wrong.dart';
import '../../../Utils/helper_utils.dart';
import '../../../Utils/ui_utils.dart';
import '../../../app/routes.dart';
import '../../model/item/item_model.dart';

abstract class ItemSuccessStateWireframe {
  abstract List<ItemModel> items;
  abstract bool isLoadingMore;
}

///this will force class to have error field
abstract class ItemErrorStateWireframe {
  dynamic error;
}

///This implementation is for cubit this will force item cubit to implement this methods.
abstract mixin class ItemCubitWireframe {
  void fetch();

  bool hasMoreData();

  void fetchMore();
}

class StateMap<INITIAL, PROGRESS, SUCCESS extends ItemSuccessStateWireframe,
    FAIL extends ItemErrorStateWireframe> {
  Widget _buildState(dynamic state, ScrollController controller) {
    if (state is INITIAL) {
      return Container();
    }
    if (state is PROGRESS) {
      return Center(child: UiUtils.progress());
    }
    if (state is FAIL) {
      return const SomethingWentWrong();
    }

    if (state is SUCCESS) {
      return Column(
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: RemoveGlow(),
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(20),
                itemBuilder: (context, index) {
                  ItemModel model = state.items[index];
                  return GestureDetector(
                      onTap: () {
                        HelperUtils.goToNextPage(
                          Routes.adDetailsScreen,
                          context,
                          false,
                          args: {
                            'model': model,
                          },
                        );
                      },
                      child: Container() */
/*ItemHorizontalCard(item: model)*/ /*
);
                },
                itemCount: state.items.length,
              ),
            ),
          ),
          if (state.isLoadingMore) UiUtils.progress()
        ],
      );
    }

    return Container();
  }
}
*/
