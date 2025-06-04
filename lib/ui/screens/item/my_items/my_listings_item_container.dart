import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/item/delete_item_cubit.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:tlobni/ui/widgets/buttons/regular_button.dart';
import 'package:tlobni/ui/widgets/buttons/unelevated_regular_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/ui/widgets/text/small_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class MyListingsItemContainer extends StatelessWidget {
  const MyListingsItemContainer(this.itemModel, {super.key, required this.refreshData});

  final ItemModel itemModel;
  final VoidCallback refreshData;

  double get _borderRadius => 10;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RegularButton(
          color: Colors.white,
          onPressed: () {
            Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
              'model': itemModel,
            }).then((_) => refreshData());
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_borderRadius), side: BorderSide(color: Color(0xfff3f3f3))),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(_borderRadius)),
                  child: Container(
                    width: 120,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: CachedNetworkImageProvider(itemModel.image ?? ''),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        _itemType(),
                        _title(),
                        _description(),
                        _price(),
                        SizedBox(),
                        _actions(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _status(),
        ),
      ],
    );
  }

  Widget _itemType() => Row(
        children: [
          Flexible(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                color: Colors.grey.shade100,
              ),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: SmallText(
                color: Color(0xff898989),
                switch (itemModel.type) {
                  'service' => 'Service',
                  'experience' => 'Experience',
                  _ => '',
                },
              ),
            ),
          ),
        ],
      );

  Widget _title() => HeadingText(
        itemModel.name ?? '',
        maxLines: 1,
        fontSize: 20,
      );

  Widget _description() => DescriptionText(
        itemModel.description ?? '',
        color: Colors.grey,
        fontSize: 14,
        maxLines: 2,
      );

  Widget _price() => Builder(builder: (context) {
        return Row(
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: context.color.secondary,
                ),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: DescriptionText('\$${itemModel.price?.toStringAsPrecision(2)}', fontSize: 14),
              ),
            )
          ],
        );
      });

  Widget _actions() => Builder(
      builder: (context) => Row(
            spacing: 10,
            children: [
              _button(
                borderColor: Colors.grey.shade100,
                icon: Icons.edit,
                contentColor: context.color.primary,
                text: 'Edit',
                onPressed: () {
                  Navigator.pushNamed(context, Routes.addItemDetails, arguments: {
                    'isEdit': true,
                    'postType': PostType.values.firstWhere((e) => itemModel.type == e.name),
                    'item': itemModel,
                  }).then((_) => refreshData());
                },
              ),
              _button(
                borderColor: Color(0xffd43232),
                icon: Icons.delete,
                contentColor: Color(0xffd43232),
                text: 'Delete',
                onPressed: () async {
                  await UiUtils.showBlurredDialoge(
                    context,
                    dialoge: BlurredDialogBox(
                      title: 'Delete Listing',
                      content: DescriptionText(
                        'Are you sure you want to delete this item?',
                      ),
                      isAcceptContainerPush: true,
                      onAccept: () async {
                        context.read<DeleteItemCubit>().deleteItem(itemModel.id!);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ].map<Widget>((e) => e).toList(),
          ));

  Widget _button({
    required Color borderColor,
    required IconData icon,
    required Color contentColor,
    required String text,
    required VoidCallback onPressed,
  }) =>
      UnelevatedRegularButton(
        color: Colors.transparent,
        onPressed: onPressed,
        padding: EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: contentColor),
            SizedBox(width: 5),
            SmallText(text, color: contentColor),
            SizedBox(width: 5),
          ],
        ),
      );

  Widget _status() => Builder(
        builder: (context) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(_borderRadius),
              bottomLeft: Radius.circular(_borderRadius),
            ),
            color: context.color.primary,
          ),
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          child: SmallText(
            itemModel.status ?? '',
            color: context.color.onPrimary,
            fontSize: 12,
          ),
        ),
      );

// Widget _old() => InkWell(
//   onTap: () {
//     Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
//       "model": item,
//     }).then((value) {
//       if (value == "refresh") {
//         context.read<FetchMyItemsCubit>().fetchMyItems(
//           getItemsWithStatus: widget.getItemsWithStatus,
//         );
//       }
//     });
//   },
//   child: ClipRRect(
//     borderRadius: BorderRadius.circular(15),
//     child: Container(
//       height: 130,
//       decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           color:
//           item.status == "inactive" ? context.color.deactivateColor.brighten(70) : context.color.secondaryColor,
//           border: Border.all(color: context.color.borderColor.darken(30), width: 1)),
//       width: double.infinity,
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Stack(
//             children: [
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(15),
//                 child: SizedBox(
//                   width: 116,
//                   height: double.infinity,
//                   child: UiUtils.getImage(item.image ?? "", height: double.infinity, fit: BoxFit.cover),
//                 ),
//               ),
//               if (item.isFeature ?? false)
//                 const PositionedDirectional(start: 5, top: 5, child: PromotedCard(type: PromoteCardType.icon))
//             ],
//           ),
//           Expanded(
//             flex: 8,
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 15),
//               child: Column(
//                 //mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       CustomText(
//                         (item.price ?? 0.0).currencyFormat,
//                         color: context.color.territoryColor,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       Spacer(),
//                       showStatus(item)
//                     ],
//                   ),
//                   //SizedBox(height: 7,),
//                   CustomText(
//                     item.name ?? "",
//                     maxLines: 2,
//                     firstUpperCaseWidget: true,
//                   ),
//                   //SizedBox(height: 12,),
//                   Row(
//                     //mainAxisAlignment: MainAxisAlignment.spaceAround,
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Flexible(
//                         flex: 1,
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             SvgPicture.asset(AppIcons.eye,
//                                 width: 14,
//                                 height: 14,
//                                 colorFilter: ColorFilter.mode(context.color.textDefaultColor, BlendMode.srcIn)),
//                             const SizedBox(
//                               width: 4,
//                             ),
//                             CustomText(
//                               "${"views".translate(context)}:${item.views}",
//                               fontSize: context.font.small,
//                               color: context.color.textColorDark.withValues(alpha: 0.3),
//                             )
//                           ],
//                         ),
//                       ),
//                       SizedBox(
//                         width: 20,
//                       ),
//                       Flexible(
//                         flex: 1,
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             SvgPicture.asset(AppIcons.heart,
//                                 width: 14,
//                                 height: 14,
//                                 colorFilter: ColorFilter.mode(context.color.textDefaultColor, BlendMode.srcIn)),
//                             const SizedBox(
//                               width: 4,
//                             ),
//                             CustomText(
//                               "${"like".translate(context)}:${item.totalLikes.toString()}",
//                               fontSize: context.font.small,
//                               color: context.color.textColorDark.withValues(alpha: 0.3),
//                             )
//                           ],
//                         ),
//                       ),
//                     ],
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     ),
//   ),
// );
}
