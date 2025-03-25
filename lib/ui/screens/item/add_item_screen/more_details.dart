import 'dart:convert';
import 'dart:io';

import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/custom_field/fetch_custom_fields_cubit.dart';
import 'package:tlobni/data/model/custom_field/custom_field_model.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/select_category.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/dynamic_field.dart';
import 'package:tlobni/utils/cloud_state/cloud_state.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddMoreDetailsScreen extends StatefulWidget {
  final bool? isEdit;
  final File? mainImage;

  final List<File>? otherImage;

  const AddMoreDetailsScreen(
      {super.key, this.isEdit, this.mainImage, this.otherImage});

  static BlurredRouter route(RouteSettings settings) {
    Map? args = settings.arguments as Map?;
    return BlurredRouter(
      builder: (context) {
        return BlocProvider.value(
          value:
              (args?['context'] as BuildContext).read<FetchCustomFieldsCubit>(),
          child: AddMoreDetailsScreen(
            isEdit: args?['isEdit'],
            mainImage: args?['mainImage'],
            otherImage: args?['otherImage'],
          ),
        );
      },
    );
  }

  @override
  CloudState<AddMoreDetailsScreen> createState() =>
      _AddMoreDetailsScreenState();
}

class _AddMoreDetailsScreenState extends CloudState<AddMoreDetailsScreen> {
  List<CustomFieldBuilder> moreDetailDynamicFields = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    Future.delayed(
      Duration.zero,
      () {
        moreDetailDynamicFields =
            context.read<FetchCustomFieldsCubit>().getFields().map((field) {
          Map<String, dynamic> fieldData = field.toMap();
          // Assuming 'getCloudData' returns the correct item based on 'edit_request'

          // Check if 'item' and 'item.customFields' are not null before accessing them
          if (widget.isEdit == true) {
            ItemModel item = getCloudData('edit_request') as ItemModel;

            // Find the matching custom field value in the item
            if (item.customFields != null) {
              CustomFieldModel? matchingField =
                  item.customFields!.any((e) => e.id == field.id)
                      ? item.customFields?.firstWhere((e) => e.id == field.id)
                      : null;

              if (matchingField != null && matchingField.value != null) {
                // Set 'value' in 'fieldData' based on the matching field's value
                fieldData['value'] = matchingField.value;

                // Pre-populate the AbstractField.fieldsData for submission
                if (matchingField.value is List &&
                    (matchingField.value as List).isNotEmpty) {
                  AbstractField.fieldsData[field.id.toString()] =
                      matchingField.value;
                }
              }
            }
          }

          fieldData['isEdit'] = widget.isEdit == true;
          CustomFieldBuilder customFieldBuilder = CustomFieldBuilder(fieldData);
          customFieldBuilder.stateUpdater(setState);
          customFieldBuilder.init();
          return customFieldBuilder;
        }).toList();

        setState(() {});
      },
    );
    _scrollController.addListener(_onScroll);
    super.initState();
  }

  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.atEdge) {
      if (_scrollController.position.pixels != 0) {
        // Reached the bottom of the list
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: UiUtils.buildAppBar(context,
            showBackButton: true, title: "AdDetails".translate(context)),
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: UiUtils.buildButton(
              context,
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  Map itemDetailsScreenData = getCloudData("item_details");
                  itemDetailsScreenData['custom_fields'] =
                      json.encode(AbstractField.fieldsData);

                  itemDetailsScreenData.addAll(AbstractField.files);

                  addCloudData("with_more_details", itemDetailsScreenData);
// itemDetailsScreenData
                  screenStack++;
                  Navigator.pushNamed(
                    context,
                    Routes.confirmLocationScreen,
                    arguments: {
                      "isEdit": widget.isEdit == true,
                      "mainImage": widget.mainImage,
                      "otherImage": widget.otherImage
                    },
                  ).then((value) {
                    screenStack--;

                    if (value == "success") {
                      screenStack = 0;
                    }
                  });
                }
              },
              height: 48,
              fontSize: context.font.large,
              buttonTitle: "next".translate(context),
            ),
          ),
        ),
        body: BlocConsumer<FetchCustomFieldsCubit, FetchCustomFieldState>(
          listener: (context, state) {
            if (state is FetchCustomFieldSuccess) {
              if (state.fields.isEmpty) {
                Navigator.pushNamed(context, Routes.confirmLocationScreen,
                    arguments: {
                      "mainImage": widget.mainImage,
                      "otherImage": widget.otherImage,
                      "isEdit": widget.isEdit,
                    }).then((value) {
                  screenStack--;

                  if (value == "success") {
                    screenStack = 0;
                  }
                });
              }
            }
          },
          builder: (context, state) {
            if (state is FetchCustomFieldFail) {
              return Center(
                child: CustomText(state.error.toString()),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(18.0),
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        "giveMoreDetailsAboutYourAds".translate(context),
                        fontSize: context.font.large,
                        fontWeight: FontWeight.w600,
                      ),
                      ...moreDetailDynamicFields.map(
                        (field) {
                          field.stateUpdater(setState);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9.0),
                            child: field.build(context),
                          );
                        },
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
