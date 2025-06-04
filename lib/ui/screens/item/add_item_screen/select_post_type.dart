import 'package:flutter/material.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/ui/widgets/buttons/primary_button.dart';
import 'package:tlobni/ui/widgets/text/description_text.dart';
import 'package:tlobni/ui/widgets/text/heading_text.dart';
import 'package:tlobni/utils/cloud_state/cloud_state.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';

class SelectPostTypeScreen extends StatefulWidget {
  final List<CategoryModel>? breadCrumbItems;

  const SelectPostTypeScreen({super.key, this.breadCrumbItems});

  static Route route(RouteSettings settings) {
    Map<String, dynamic>? arguments = settings.arguments as Map<String, dynamic>?;
    return BlurredRouter(
      builder: (context) {
        return SelectPostTypeScreen(
          breadCrumbItems: arguments?['breadCrumbItems'],
        );
      },
    );
  }

  @override
  CloudState<SelectPostTypeScreen> createState() => _SelectPostTypeScreenState();
}

class _SelectPostTypeScreenState extends CloudState<SelectPostTypeScreen> {
  PostType? selectedPostType;

  void _onClickedOnItem(PostType selectedPostType) {
    // Store the selected post type in cloud data
    addCloudData("post_type", selectedPostType);

    // Navigate to add item details screen with breadcrumb items
    Navigator.pushNamed(
      context,
      Routes.addItemDetails,
      arguments: <String, dynamic>{
        "breadCrumbItems": widget.breadCrumbItems,
        "isEdit": false,
        'postType': selectedPostType,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UiUtils.buildAppBar(context, title: 'Post Listing', showBackButton: true),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          spacing: 30,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ('Post a Service', 'Offer ongoing services to clients with flexible availability', PostType.service),
            ('Post an Experience', 'Create time-limited, exclusive events for premium clients', PostType.experience),
          ].map((e) {
            final (title, description, resultType) = e;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: kElevationToShadow[1],
                color: Colors.white,
                border: Border.all(color: context.color.secondary),
              ),
              padding: EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  HeadingText(title, textAlign: TextAlign.center),
                  SizedBox(height: 20),
                  DescriptionText(description, color: Colors.grey.shade600, textAlign: TextAlign.center, fontSize: 16),
                  SizedBox(height: 30),
                  PrimaryButton.text(
                    title,
                    padding: EdgeInsets.all(20),
                    borderRadius: 10,
                    fontSize: 15,
                    onPressed: () => _onClickedOnItem(resultType),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context, statusBarColor: context.color.secondaryColor),
      child: SafeArea(
        child: Scaffold(
          appBar: UiUtils.buildAppBar(
            context,
            showBackButton: true,
            title: "Choose Post Type".translate(context),
          ),
          bottomNavigationBar: Container(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: UiUtils.buildButton(
                context,
                onPressed: () {
                  if (selectedPostType != null) {
                    // Store the selected post type in cloud data
                    addCloudData("post_type", selectedPostType);

                    // Navigate to add item details screen with breadcrumb items
                    Navigator.pushNamed(
                      context,
                      Routes.addItemDetails,
                      arguments: <String, dynamic>{
                        "breadCrumbItems": widget.breadCrumbItems,
                        "isEdit": false,
                      },
                    );
                  }
                },
                height: 48,
                fontSize: context.font.large,
                buttonTitle: "Next".translate(context),
                textColor: const Color(0xFFE6CBA8),
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display selected category
                  if (widget.breadCrumbItems != null && widget.breadCrumbItems!.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Selected Category".translate(context),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                ),
                              ),
                              Text(
                                widget.breadCrumbItems!.last.name ?? "",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text(
                    "Select the type of post you want to create:".translate(context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose the option that best describes what you're offering".translate(context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Service Option
                  _buildPostTypeCard(
                    context,
                    title: "Service",
                    description: "Premium, always-available professional services",
                    isSelected: selectedPostType == PostType.service,
                    onTap: () {
                      setState(() {
                        selectedPostType = PostType.service;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Experience Option
                  _buildPostTypeCard(
                    context,
                    title: "Exclusive Experience",
                    description: "Limited-time, unique opportunities that disappear after they end",
                    isSelected: selectedPostType == PostType.experience,
                    onTap: () {
                      setState(() {
                        selectedPostType = PostType.experience;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Additional information about the selected post type
                  if (selectedPostType != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.color.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.color.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            selectedPostType == PostType.service
                                ? "About Services".translate(context)
                                : "About Experiences".translate(context),
                            fontWeight: FontWeight.w600,
                            color: context.color.textColorDark,
                          ),
                          const SizedBox(height: 8),
                          CustomText(
                            selectedPostType == PostType.service
                                ? "Services are professional offerings that are always available for booking. They include consultations, professional skills, and ongoing services."
                                    .translate(context)
                                : "Experiences are time-limited, unique opportunities that have specific dates and times. They automatically expire after the event ends."
                                    .translate(context),
                            color: context.color.textColorDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostTypeCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? context.color.primaryColor.withOpacity(0.15) : context.color.secondaryColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.color.primaryColor : context.color.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.color.territoryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? context.color.territoryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? context.color.primaryColor : context.color.borderColor,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title.translate(context),
                    fontWeight: FontWeight.w600,
                    fontSize: context.font.large,
                    color: isSelected ? context.color.territoryColor : context.color.textColorDark,
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    description.translate(context),
                    color: context.color.textLightColor,
                    fontSize: context.font.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
