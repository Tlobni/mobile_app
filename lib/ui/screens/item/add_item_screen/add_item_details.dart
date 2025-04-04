import 'dart:io';
import 'dart:convert';

import 'package:dotted_border/dotted_border.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/custom_field/fetch_custom_fields_cubit.dart';
import 'package:tlobni/data/cubits/item/manage_item_cubit.dart';
import 'package:tlobni/data/cubits/item/fetch_my_item_cubit.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/confirm_location_screen.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/models/post_type.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/select_category.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/image_adapter.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/widgets/location_autocomplete.dart';
import 'package:tlobni/ui/screens/item/my_item_tab_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:tlobni/ui/screens/widgets/custom_text_form_field.dart';
import 'package:tlobni/ui/screens/widgets/dynamic_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/cloud_state/cloud_state.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/image_picker.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:tlobni/utils/validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:path/path.dart' as p;

class AddItemDetails extends StatefulWidget {
  final List<CategoryModel>? breadCrumbItems;
  final bool? isEdit;

  const AddItemDetails({
    super.key,
    this.breadCrumbItems,
    required this.isEdit,
  });

  static Route route(RouteSettings settings) {
    Map<String, dynamic>? arguments =
        settings.arguments as Map<String, dynamic>?;
    return BlurredRouter(
      builder: (context) {
        return MultiBlocProvider(
          providers: [
            BlocProvider(create: (context) => FetchCustomFieldsCubit()),
            BlocProvider(create: (context) => ManageItemCubit()),
          ],
          child: AddItemDetails(
            breadCrumbItems: arguments?['breadCrumbItems'],
            isEdit: arguments?['isEdit'],
          ),
        );
      },
    );
  }

  @override
  CloudState<AddItemDetails> createState() => _AddItemDetailsState();
}

class _AddItemDetailsState extends CloudState<AddItemDetails> {
  final PickImage _pickTitleImage = PickImage();
  final PickImage itemImagePicker = PickImage();
  String titleImageURL = "";
  List<dynamic> mixedItemImageList = [];
  List<int> deleteItemImageList = [];
  late final GlobalKey<FormState> _formKey;

  // Compression method moved to correct position
  Future<File?> compressImage(File file) async {
    try {
      final dir = await path_provider.getTemporaryDirectory();
      final targetPath =
          p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // Adjust quality (0-100)
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // Return original file if compression fails
    }
  }

  // Variables for service and experience fields
  Map<String, bool> _specialTags = {
    "exclusive_women": false,
    "corporate_package": false
  };
  String? _priceType;
  bool _atClientLocation = false;
  bool _atPublicVenue = false;
  bool _atMyLocation = false;
  bool _isVirtual = false;
  DateTime? _expirationDate;
  TimeOfDay? _expirationTime;
  AddressComponent? formatedAddress;
  bool _isSubmitting = false; // Add loading state for submit button

  // Add missing controllers
  final TextEditingController cityTextController = TextEditingController();
  final TextEditingController stateTextController = TextEditingController();
  final TextEditingController countryTextController = TextEditingController();

  // Location autocomplete
  final TextEditingController locationController = TextEditingController();

  //Text Controllers
  final TextEditingController adTitleController = TextEditingController();
  final TextEditingController adDescriptionController = TextEditingController();
  final TextEditingController adPriceController = TextEditingController();
  final TextEditingController adPhoneNumberController = TextEditingController();
  final TextEditingController adAdditionalDetailsController =
      TextEditingController();

  void _onBreadCrumbItemTap(int index) {
    int popTimes = (widget.breadCrumbItems!.length - 1) - index;
    int current = index;
    int length = widget.breadCrumbItems!.length;

    for (int i = length - 1; i >= current + 1; i--) {
      widget.breadCrumbItems!.removeAt(i);
    }

    for (int i = 0; i < popTimes; i++) {
      Navigator.pop(context);
    }
    setState(() {});
  }

  late List selectedCategoryList;
  ItemModel? item;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    AbstractField.fieldsData.clear();
    AbstractField.files.clear();

    // Check if post_type is set and valid
    dynamic rawPostType = getCloudData("post_type");
    if (rawPostType == null || !(rawPostType is PostType)) {
      // Set a default post type if none is set
      addCloudData("post_type", PostType.service);
    }

    if (widget.isEdit == true) {
      item = getCloudData('edit_request') as ItemModel;

      // Debug the item's location details
      _debugItemLocationDetails();

      clearCloudData("item_details");
      clearCloudData("with_more_details");
      context.read<FetchCustomFieldsCubit>().fetchCustomFields(
            categoryIds: item?.allCategoryIds ?? "",
          );
      adTitleController.text = item?.name ?? "";
      adDescriptionController.text = item?.description ?? "";
      adPriceController.text = item?.price.toString() ?? "";
      adPhoneNumberController.text = item?.contact ?? "";
      adAdditionalDetailsController.text = item?.videoLink ?? "";
      titleImageURL = item?.image ?? "";

      // Set the price type if it exists
      if (item?.priceType != null && item!.priceType!.isNotEmpty) {
        _priceType = item!.priceType;
      }

      // Set the formatted address for location
      if (item != null) {
        formatedAddress = AddressComponent(
            area: item!.area,
            areaId: item!.areaId,
            city: item!.city,
            country: item!.country,
            state: item!.state,
            mixed: "${item!.city}, ${item!.country}");

        // Set location controller text - prioritize showing city and country
        // Build location text prioritizing city and country
        String cityCountry = "";
        if ((item!.city != null && item!.city!.isNotEmpty) &&
            (item!.country != null && item!.country!.isNotEmpty)) {
          cityCountry = "${item!.city}, ${item!.country}";
        }

        // If we have city,country - use that, otherwise try other combinations
        if (cityCountry.isNotEmpty) {
          locationController.text = cityCountry;
        } else {
          // Fallback to combining all location parts
          String locationText = [
            item!.area,
            item!.city,
            item!.state,
            item!.country
          ].where((part) => part != null && part.isNotEmpty).join(', ');

          if (locationText.isNotEmpty) {
            locationController.text = locationText;
          }
        }

        print("Location set to: ${locationController.text}");
      }

      // Load special tags if they exist
      if (item?.specialTags != null) {
        try {
          print("Loading special tags: ${item!.specialTags}");

          if (item!.specialTags!.containsKey('exclusive_women')) {
            // Handle both boolean and string values
            var value = item!.specialTags!['exclusive_women'];
            _specialTags['exclusive_women'] = (value == true) ||
                (value == "true") ||
                (value.toString().toLowerCase() == "true");
          }

          if (item!.specialTags!.containsKey('corporate_package')) {
            // Handle both boolean and string values
            var value = item!.specialTags!['corporate_package'];
            _specialTags['corporate_package'] = (value == true) ||
                (value == "true") ||
                (value.toString().toLowerCase() == "true");
          }
        } catch (e) {
          print("Error loading special tags: $e");
        }
      }

      // Load service location options
      if (item?.locationType != null) {
        List<String> locationTypes = item!.locationType ?? [];

        _atClientLocation = locationTypes.contains('client_location');
        _atPublicVenue = locationTypes.contains('public_venue');
        _atMyLocation = locationTypes.contains('my_location');
        _isVirtual = locationTypes.contains('virtual');
      }

      List<String?>? list = item?.galleryImages?.map((e) => e.image).toList();
      mixedItemImageList.addAll([...list ?? []]);

      setState(() {});
    } else {
      List<int> ids = widget.breadCrumbItems!.map((item) => item.id!).toList();

      context
          .read<FetchCustomFieldsCubit>()
          .fetchCustomFields(categoryIds: ids.join(','));
      selectedCategoryList = ids;
      adPhoneNumberController.text = HiveUtils.getUserDetails().mobile ?? "";
    }

    _pickTitleImage.listener((p0) {
      titleImageURL = "";
      WidgetsBinding.instance.addPersistentFrameCallback((timeStamp) {
        if (mounted) setState(() {});
      });
    });

    itemImagePicker.listener((images) {
      try {
        mixedItemImageList.addAll(List<dynamic>.from(images));
      } catch (e) {}

      setState(() {});
    });
  }

  void _debugItemLocationDetails() {
    if (widget.isEdit == true && item != null) {
      print("=== DEBUG ITEM LOCATION DETAILS ===");
      print("Item ID: ${item!.id}");
      print("City: ${item!.city}");
      print("Country: ${item!.country}");
      print("State: ${item!.state}");
      print("Area: ${item!.area}");
      print("Area ID: ${item!.areaId}");
      print("All Location Data: ${item!.toJson()}");
      print("=================================");
    }
  }

  // Safely update location data without immediate setState
  void _updateLocationData(Map<String, String> locationData) {
    // Update the address component directly
    formatedAddress = AddressComponent(
      city: locationData['city'] ?? formatedAddress?.city,
      state: locationData['state'] ?? formatedAddress?.state,
      country: locationData['country'] ?? formatedAddress?.country,
      area: locationData['city'] ?? formatedAddress?.area,
      mixed: "${locationData['city'] ?? ''}, ${locationData['country'] ?? ''}",
      areaId: formatedAddress?.areaId,
    );

    // Always ensure the locationController has the consistent value
    if (formatedAddress != null &&
        formatedAddress!.mixed != null &&
        formatedAddress!.mixed!.isNotEmpty) {
      // Only update if it's different to avoid unnecessary text controller changes
      if (locationController.text != formatedAddress!.mixed) {
        locationController.text = formatedAddress!.mixed!;
      }
    }

    // Schedule a rebuild for after the current call stack is complete
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          // This empty setState will trigger a rebuild with the updated data
        });
      });
    }

    // Add debug log
    print("Location updated to: ${locationController.text}");
    print("FormatedAddress: $formatedAddress");
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ManageItemCubit, ManageItemState>(
      listener: (context, state) {
        if (state is ManageItemSuccess) {
          // Get the updated item
          ItemModel updatedItem = state.model;

          if (widget.isEdit == true) {
            // If we're editing, update other BLoCs with this item
            try {
              // If we have myAdsCubitReference (from MyItemTabScreen)
              String? statusKey = getCloudData('edit_from') as String?;
              if (statusKey != null &&
                  myAdsCubitReference.containsKey(statusKey)) {
                // Update the specific tab's cubit
                FetchMyItemsCubit tabCubit = myAdsCubitReference[statusKey]!;
                tabCubit.edit(updatedItem);
                print("Successfully updated MyItemTab with status: $statusKey");
              }

              // Also try to update the cubit in the current context
              context
                  .read<ManageItemCubit>()
                  .updateItemInOtherBlocs(updatedItem, context);
            } catch (e) {
              print("Error updating other BLoCs: $e");
            }
          }

          // Show success message
          HelperUtils.showSnackBarMessage(
              context,
              widget.isEdit == true
                  ? "Item updated successfully"
                  : "Waiting for review");

          // Navigate based on edit or new item
          if (widget.isEdit == true) {
            // For edit mode, return to previous screen with refresh value
            setState(() {
              _isSubmitting = false;
            });

            // Pop and return refresh value to trigger update in ad_details_screen
            Navigator.of(context).pop("refresh");
          } else {
            // For new item, navigate to the details page of the newly created service
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context).popUntil((route) => route.isFirst);

              // Navigate to the details page of the newly created service
              Navigator.pushNamed(context, Routes.adDetailsScreen, arguments: {
                'model': updatedItem,
              });
            });
          }
        } else if (state is ManageItemFail) {
          // Show error message with more detail
          String errorMessage = "Failed to process request: ${state.error}";
          print("Error updating/adding item: ${state.error}");

          // Reset the submitting state
          setState(() {
            _isSubmitting = false;
          });

          // Show error message to user
          HelperUtils.showSnackBarMessage(context, errorMessage);
        }
      },
      child: AnnotatedRegion(
        value: UiUtils.getSystemUiOverlayStyle(
            context: context, statusBarColor: context.color.secondaryColor),
        child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            return;
          },
          child: SafeArea(
            child: Scaffold(
              appBar: UiUtils.buildAppBar(context,
                  showBackButton: true, title: "AdDetails".translate(context)),
              bottomNavigationBar: Container(
                color: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: UiUtils.buildButton(context, onPressed: () async {
                    // Return early if already submitting to prevent multiple submissions
                    if (_isSubmitting) return;

                    // Set loading state
                    setState(() {
                      _isSubmitting = true;
                    });

                    // Get post type
                    dynamic rawPostType = getCloudData("post_type");
                    PostType? postType =
                        rawPostType is PostType ? rawPostType : null;

                    // Validate required fields for both types
                    if (!_validateRequiredFields(postType)) {
                      // Reset loading state if validation fails
                      setState(() {
                        _isSubmitting = false;
                      });
                      return;
                    }

                    // Set up location check
                    bool isEdit = widget.isEdit == true;
                    bool hasLocationData = false;

                    // Check if the item already has location data in edit mode
                    if (isEdit && item != null) {
                      hasLocationData = (item!.city != null &&
                              item!.city!.isNotEmpty) ||
                          (item!.area != null && item!.area!.isNotEmpty) ||
                          (item!.country != null && item!.country!.isNotEmpty);
                    }

                    // For experience type OR if location is valid for service type
                    if (postType == PostType.experience ||
                        hasLocationData ||
                        (formatedAddress != null &&
                            !((formatedAddress!.city == "" ||
                                    formatedAddress!.city == null) &&
                                (formatedAddress!.area == "" ||
                                    formatedAddress!.area == null)) &&
                            !(formatedAddress!.country == "" ||
                                formatedAddress!.country == null))) {
                      try {
                        // Create a fresh cloudData map to ensure we're collecting current values
                        // This avoids using potentially stale data from getCloudData("with_more_details")
                        Map<String, dynamic> cloudData = {};

                        // Merge any existing custom fields data which might have been set in more_details screen
                        Map<String, dynamic> existingData =
                            getCloudData("with_more_details") ?? {};
                        if (existingData.containsKey('custom_fields')) {
                          cloudData['custom_fields'] =
                              existingData['custom_fields'];
                        } else if (AbstractField.fieldsData.isNotEmpty) {
                          // If we have data in AbstractField.fieldsData but it wasn't in more_details,
                          // encode it directly
                          cloudData['custom_fields'] =
                              json.encode(AbstractField.fieldsData);
                          print(
                              "Using AbstractField.fieldsData directly: ${AbstractField.fieldsData}");
                        }

                        // Preserve any file references or binary data from the previous screen
                        existingData.forEach((key, value) {
                          if (key.startsWith('custom_file_') || value is File) {
                            cloudData[key] = value;
                          }
                        });

                        // Add form data to cloudData
                        cloudData['name'] = adTitleController.text;
                        cloudData['description'] = adDescriptionController.text;
                        cloudData['price'] = adPriceController.text;
                        cloudData['contact'] = adPhoneNumberController.text;

                        // Handle the video link - validate URL format or set to empty
                        String videoLink =
                            adAdditionalDetailsController.text.trim();
                        if (videoLink.isEmpty) {
                          cloudData['video_link'] = '';
                        } else if (videoLink.startsWith('http://') ||
                            videoLink.startsWith('https://')) {
                          cloudData['video_link'] = videoLink;
                        } else {
                          // Show error for invalid URL and return
                          setState(() {
                            _isSubmitting = false;
                          });
                          HelperUtils.showSnackBarMessage(context,
                              "Please enter a valid URL starting with http:// or https://");
                          return;
                        }

                        // Add category_id - critical for API request
                        if (widget.isEdit == true) {
                          // For edit, use the item's existing category IDs
                          if (item != null && item!.allCategoryIds != null) {
                            cloudData['category_id'] = item!.allCategoryIds;
                          }
                        } else {
                          // For new item, get the last (most specific) category ID from the breadcrumb
                          if (widget.breadCrumbItems != null &&
                              widget.breadCrumbItems!.isNotEmpty) {
                            // Get the most specific category (last one in breadcrumb)
                            int categoryId = widget.breadCrumbItems!.last.id!;
                            cloudData['category_id'] = categoryId.toString();

                            // If the API requires the full category path, we can also add it
                            if (selectedCategoryList.isNotEmpty) {
                              cloudData['category_hierarchy'] =
                                  selectedCategoryList.join(',');
                            }
                          }
                        }

                        // Add special tags and price type
                        // Format special tags as strings to match database format
                        Map<String, String> formattedSpecialTags = {};
                        _specialTags.forEach((key, value) {
                          formattedSpecialTags[key] = value.toString();
                        });

                        print("Saving special tags: $formattedSpecialTags");
                        cloudData['special_tags'] = formattedSpecialTags;
                        cloudData['price_type'] = _priceType;

                        // Add post type
                        cloudData['post_type'] =
                            postType?.toString() ?? PostType.service.toString();

                        // Add service location options if applicable
                        if (postType == PostType.service) {
                          // Create a list to gather location types
                          List<String> locationTypes = [];

                          if (_atClientLocation)
                            locationTypes.add('client_location');
                          if (_atPublicVenue) locationTypes.add('public_venue');
                          if (_atMyLocation) locationTypes.add('my_location');
                          if (_isVirtual) locationTypes.add('virtual');

                          print("Saving location types: $locationTypes");

                          // Store location types in the format expected by the API
                          // The API might expect different formats for new vs edit
                          if (locationTypes.isNotEmpty) {
                            if (widget.isEdit == true) {
                              // For edit, send as array/list (original format from loaded item)
                              cloudData['location_type'] =
                                  locationTypes.join(',');
                            } else {
                              // For new posts, try both formats to ensure compatibility
                              cloudData['location_type'] =
                                  locationTypes.join(',');
                            }
                          }

                          // Add individual flags for backward compatibility
                          cloudData['at_client_location'] = _atClientLocation;
                          cloudData['at_public_venue'] = _atPublicVenue;
                          cloudData['at_my_location'] = _atMyLocation;
                          cloudData['is_virtual'] = _isVirtual;
                        }

                        // Add expiration date/time if applicable
                        if (postType == PostType.experience) {
                          if (_expirationDate != null) {
                            cloudData['expiration_date'] =
                                _expirationDate!.toIso8601String();
                          }
                          if (_expirationTime != null) {
                            cloudData['expiration_time'] =
                                '${_expirationTime!.hour}:${_expirationTime!.minute}';
                          }
                        }

                        // Add location data if available
                        if (formatedAddress != null) {
                          cloudData['address'] = formatedAddress?.mixed;
                          cloudData['country'] = formatedAddress!.country;
                          cloudData['city'] = (formatedAddress!.city == "" ||
                                  formatedAddress!.city == null)
                              ? (formatedAddress!.area == "" ||
                                      formatedAddress!.area == null
                                  ? null
                                  : formatedAddress!.area)
                              : formatedAddress!.city;
                          cloudData['state'] = formatedAddress!.state;
                          if (formatedAddress!.areaId != null)
                            cloudData['area_id'] = formatedAddress!.areaId;
                        }

                        // Get main image with compression
                        File? mainImage;
                        if (_pickTitleImage.pickedFile != null) {
                          try {
                            // Check if pickedFile is a List<File> or a single File
                            if (_pickTitleImage.pickedFile is List<File> &&
                                (_pickTitleImage.pickedFile as List<File>)
                                    .isNotEmpty) {
                              File originalFile =
                                  (_pickTitleImage.pickedFile as List<File>)
                                      .first;
                              mainImage = await compressImage(originalFile);
                            } else if (_pickTitleImage.pickedFile is File) {
                              File originalFile =
                                  _pickTitleImage.pickedFile as File;
                              mainImage = await compressImage(originalFile);
                            }

                            if (mainImage == null) {
                              throw Exception("Failed to process main image");
                            }
                          } catch (e) {
                            print("Error processing main image: $e");
                            setState(() {
                              _isSubmitting = false;
                            });
                            HelperUtils.showSnackBarMessage(context,
                                "Failed to process main image. Try a different image.");
                            return;
                          }
                        }

                        // Get other images with compression
                        List<File> otherImages = [];
                        try {
                          for (var item in mixedItemImageList) {
                            if (item is File) {
                              File? compressed = await compressImage(item);
                              if (compressed != null) {
                                otherImages.add(compressed);
                              }
                            }
                          }
                        } catch (e) {
                          print("Error processing additional images: $e");
                          setState(() {
                            _isSubmitting = false;
                          });
                          HelperUtils.showSnackBarMessage(context,
                              "Failed to process some additional images.");
                          return;
                        }

                        // Add deleted image IDs if editing
                        if (widget.isEdit == true &&
                            deleteItemImageList.isNotEmpty) {
                          cloudData['deleted_images'] = deleteItemImageList;
                        }

                        // Add error handling for the cubit call
                        try {
                          if (widget.isEdit == true) {
                            // Add item ID for editing
                            cloudData['id'] = item?.id;

                            context.read<ManageItemCubit>().manage(
                                ManageItemType.edit,
                                cloudData,
                                mainImage,
                                otherImages);
                          } else {
                            context.read<ManageItemCubit>().manage(
                                ManageItemType.add,
                                cloudData,
                                mainImage,
                                otherImages);
                          }
                        } catch (e) {
                          print("Error during API call: $e");
                          setState(() {
                            _isSubmitting = false;
                          });
                          HelperUtils.showSnackBarMessage(
                              context, "Failed to upload. Please try again.");
                          return;
                        }
                      } catch (e, st) {
                        print("Error submitting form: $e");
                        // Reset loading state on error
                        setState(() {
                          _isSubmitting = false;
                        });
                        HelperUtils.showSnackBarMessage(
                            context, "An error occurred. Please try again.");
                      }
                    } else {
                      // Reset loading state when validation fails
                      setState(() {
                        _isSubmitting = false;
                      });
                      HelperUtils.showSnackBarMessage(
                          context, "cityRequired".translate(context));
                      Future.delayed(Duration(seconds: 2), () {
                        dialogueBottomSheet(
                            controller: cityTextController,
                            title: "enterCity".translate(context),
                            hintText: "city".translate(context),
                            from: 1);
                      });
                    }

                    return;
                  },
                      height: 48,
                      fontSize: context.font.large,
                      autoWidth: false,
                      radius: 8,
                      disabledColor: const Color.fromARGB(255, 104, 102, 106),
                      disabled: false,
                      isInProgress: _isSubmitting,
                      width: double.maxFinite,
                      buttonTitle: widget.isEdit == true
                          ? "Update Post".translate(context)
                          : "postNow".translate(context),
                      textColor: const Color(0xFFE6CBA8)),
                ),
              ),
              body: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          "youAreAlmostThere".translate(context),
                          fontSize: context.font.large,
                          fontWeight: FontWeight.w600,
                          color: context.color.textColorDark,
                        ),
                        SizedBox(
                          height: 16,
                        ),
                        if (widget.breadCrumbItems != null)
                          SizedBox(
                            height: 20,
                            width: context.screenWidth,
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ListView.builder(
                                  shrinkWrap: true,
                                  scrollDirection: Axis.horizontal,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    bool isNotLast =
                                        (widget.breadCrumbItems!.length - 1) !=
                                            index;

                                    return Row(
                                      children: [
                                        InkWell(
                                            onTap: () {
                                              _onBreadCrumbItemTap(index);
                                            },
                                            child: CustomText(
                                              widget.breadCrumbItems![index]
                                                  .name!,
                                              color: isNotLast
                                                  ? context.color.textColorDark
                                                  : context
                                                      .color.territoryColor,
                                              firstUpperCaseWidget: true,
                                            )),
                                        if (index <
                                            widget.breadCrumbItems!.length - 1)
                                          CustomText(" > ",
                                              color:
                                                  context.color.territoryColor),
                                      ],
                                    );
                                  },
                                  itemCount: widget.breadCrumbItems!.length),
                            ),
                          ),
                        SizedBox(
                          height: 18,
                        ),
                        CustomText("adTitle".translate(context) + " *"),
                        SizedBox(
                          height: 10,
                        ),
                        CustomTextFormField(
                          controller: adTitleController,
                          validator: CustomTextFieldValidator.nullCheck,
                          action: TextInputAction.next,
                          capitalization: TextCapitalization.sentences,
                          hintText: "adTitleHere".translate(context),
                          hintTextStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.3),
                              fontSize: context.font.large),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        CustomText("descriptionLbl".translate(context) + " *"),
                        SizedBox(
                          height: 15,
                        ),
                        CustomTextFormField(
                          controller: adDescriptionController,
                          action: TextInputAction.newline,
                          validator: CustomTextFieldValidator.nullCheck,
                          capitalization: TextCapitalization.sentences,
                          hintText: "writeSomething".translate(context),
                          maxLine: 100,
                          minLine: 6,
                          hintTextStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.3),
                              fontSize: context.font.large),
                        ),
                        SizedBox(
                          height: 15,
                        ),

                        // Special Tags Section - Changed to use switches
                        _buildSpecialTagsSection(context),

                        // Price Type Section (for both Service and Experience)
                        _buildPriceTypeSection(context),

                        // Service Location Options
                        _buildServiceLocationOptions(context),

                        // Experience Location
                        _buildExperienceLocationSection(context),

                        // Auto-Expiration Date & Time (for Experience only)
                        _buildExpirationDateTimeSection(context),

                        Row(
                          children: [
                            CustomText("mainPicture".translate(context) + " *"),
                            const SizedBox(
                              width: 3,
                            ),
                            CustomText(
                              "maxSize".translate(context),
                              fontStyle: FontStyle.italic,
                              fontSize: context.font.small,
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Wrap(
                          children: [
                            if (_pickTitleImage.pickedFile != null)
                              ...[]
                            else
                              ...[],
                            titleImageListener(),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            CustomText("otherPictures".translate(context) +
                                " (optional)"),
                            const SizedBox(
                              width: 3,
                            ),
                            CustomText(
                              "max5Images".translate(context),
                              fontStyle: FontStyle.italic,
                              fontSize: context.font.small,
                            )
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        itemImagesListener(),
                        SizedBox(
                          height: 10,
                        ),
                        CustomText("price".translate(context) + " *"),
                        SizedBox(
                          height: 10,
                        ),
                        CustomTextFormField(
                          controller: adPriceController,
                          action: TextInputAction.next,
                          prefix: CustomText("${Constant.currencySymbol} "),
                          formaters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*')),
                          ],
                          keyboard: TextInputType.number,
                          validator: CustomTextFieldValidator.nullCheck,
                          hintText: "00",
                          hintTextStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.3),
                              fontSize: context.font.large),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        CustomText(
                            "phoneNumber".translate(context) + " (optional)"),
                        SizedBox(
                          height: 10,
                        ),
                        CustomTextFormField(
                          controller: adPhoneNumberController,
                          action: TextInputAction.next,
                          formaters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d*')),
                          ],
                          keyboard: TextInputType.phone,
                          validator: CustomTextFieldValidator.phoneNumber,
                          hintText: "9876543210",
                          hintTextStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.3),
                              fontSize: context.font.large),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        CustomText(
                            "videoLink".translate(context) + " (optional)"),
                        SizedBox(
                          height: 10,
                        ),
                        CustomTextFormField(
                          controller: adAdditionalDetailsController,
                          validator:
                              null, // Use null validator (no validation at form level)
                          hintText: "http://example.com/video.mp4",
                          hintTextStyle: TextStyle(
                              color: context.color.textDefaultColor
                                  .withOpacity(0.3),
                              fontSize: context.font.large),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> showImageSourceDialog(
      BuildContext context, Function(ImageSource) onSelected) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: CustomText('selectImageSource'.translate(context)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: CustomText('camera'.translate(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(ImageSource.camera);
                  },
                ),
                Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: CustomText('gallery'.translate(context)),
                  onTap: () {
                    Navigator.of(context).pop();
                    onSelected(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget dialogueWidget(
      String title, TextEditingController controller, String hintText) {
    double bottomPadding = (MediaQuery.of(context).viewInsets.bottom - 50);
    bool isBottomPaddingNagative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                title,
                fontSize: context.font.larger,
                textAlign: TextAlign.center,
                fontWeight: FontWeight.bold,
              ),
              Divider(
                thickness: 1,
                color: context.color.borderColor.darken(30),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                    bottom: isBottomPaddingNagative ? 0 : bottomPadding,
                    start: 20,
                    end: 20,
                    top: 18),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.color.textDefaultColor.withOpacity(0.3)),
                  controller: controller,
                  cursorColor: context.color.territoryColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(val,
                          context: context);
                    } else {
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                      fillColor: context.color.borderColor.darken(20),
                      filled: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      hintText: hintText,
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color:
                              context.color.textDefaultColor.withOpacity(0.3)),
                      focusColor: context.color.territoryColor,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: context.color.borderColor.darken(60))),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: context.color.borderColor.darken(60))),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: context.color.territoryColor))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void dialogueBottomSheet(
      {required String title,
      required TextEditingController controller,
      required String hintText,
      required int from}) async {
    await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        content: dialogueWidget(title, controller, hintText),
        acceptButtonName: "add".translate(context),
        isAcceptContainerPush: true,
        onAccept: () => Future.value().then((_) {
          if (_formKey.currentState!.validate()) {
            setState(() {
              if (formatedAddress != null) {
                // Update existing formatedAddress
                if (from == 1) {
                  formatedAddress = AddressComponent.copyWithFields(
                      formatedAddress!,
                      newCity: controller.text);
                } else if (from == 2) {
                  formatedAddress = AddressComponent.copyWithFields(
                      formatedAddress!,
                      newState: controller.text);
                } else if (from == 3) {
                  formatedAddress = AddressComponent.copyWithFields(
                      formatedAddress!,
                      newCountry: controller.text);
                }
              } else {
                // Create a new AddressComponent if formatedAddress is null
                if (from == 1) {
                  formatedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: controller.text,
                    country: "",
                    state: "",
                  );
                } else if (from == 2) {
                  formatedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: "",
                    country: "",
                    state: controller.text,
                  );
                } else if (from == 3) {
                  formatedAddress = AddressComponent(
                    area: "",
                    areaId: null,
                    city: "",
                    country: controller.text,
                    state: "",
                  );
                }
              }
              Navigator.pop(context);
            });
          }
        }),
      ),
    );
  }

  Widget titleImageListener() {
    return _pickTitleImage.listenChangesInUI((context, List<File>? files) {
      Widget currentWidget = Container();
      File? file = files?.isNotEmpty == true ? files![0] : null;

      if (titleImageURL.isNotEmpty) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context,
                provider: NetworkImage(titleImageURL));
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: UiUtils.getImage(
              titleImageURL,
              fit: BoxFit.cover,
            ),
          ),
        );
      }

      if (file != null) {
        currentWidget = GestureDetector(
          onTap: () {
            UiUtils.showFullScreenImage(context, provider: FileImage(file));
          },
          child: Container(
            width: 100,
            height: 100,
            margin: const EdgeInsets.all(5),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.file(
              file,
              fit: BoxFit.cover,
            ),
          ),
        );
      }

      return Wrap(
        children: [
          if (file == null && titleImageURL.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    _pickTitleImage.resumeSubscription();
                    _pickTitleImage.pick(
                      pickMultiple: false,
                      context: context,
                      source: source,
                    );
                    _pickTitleImage.pauseSubscription();
                    titleImageURL = "";
                    setState(() {});
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: CustomText(
                    "addMainPicture".translate(context),
                    color: context.color.textDefaultColor,
                    fontSize: context.font.large,
                  ),
                ),
              ),
            ),
          Stack(
            children: [
              currentWidget,
              closeButton(context, () {
                _pickTitleImage.clearImage();
                titleImageURL = "";
                setState(() {});
              })
            ],
          ),
          if (file != null || titleImageURL.isNotEmpty)
            uploadPhotoCard(context, onTap: () {
              showImageSourceDialog(context, (source) {
                _pickTitleImage.resumeSubscription();
                _pickTitleImage.pick(
                  pickMultiple: false,
                  context: context,
                  source: source,
                );
                _pickTitleImage.pauseSubscription();
                titleImageURL = "";
                setState(() {});
              });
            }),
        ],
      );
    });
  }

  Widget itemImagesListener() {
    return itemImagePicker.listenChangesInUI((context, files) {
      Widget current = Container();

      current = Wrap(
        children: List.generate(mixedItemImageList.length, (index) {
          final image = mixedItemImageList[index];
          return Stack(
            children: [
              GestureDetector(
                onTap: () {
                  HelperUtils.unfocus();
                  if (image is String) {
                    UiUtils.showFullScreenImage(context,
                        provider: NetworkImage(image));
                  } else {
                    UiUtils.showFullScreenImage(context,
                        provider: FileImage(image));
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  margin: const EdgeInsets.all(5),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ImageAdapter(image: image),
                ),
              ),
              closeButton(context, () {
                if (image is String) {
                  final matchingIndex = item!.galleryImages!.indexWhere(
                    (galleryImage) => galleryImage.image == image,
                  );

                  if (matchingIndex != -1) {
                    print("Matching index: $matchingIndex");
                    print(
                        "Gallery Image ID: ${item!.galleryImages![matchingIndex].id}");

                    deleteItemImageList
                        .add(item!.galleryImages![matchingIndex].id!);

                    setState(() {});
                  } else {
                    print("No matching image found.");
                  }
                }

                mixedItemImageList.removeAt(index);
                setState(() {});
              }),
            ],
          );
        }),
      );

      return Wrap(
        runAlignment: WrapAlignment.start,
        children: [
          if ((files == null || files.isEmpty) && mixedItemImageList.isEmpty)
            DottedBorder(
              color: context.color.textLightColor,
              borderType: BorderType.RRect,
              radius: const Radius.circular(12),
              child: GestureDetector(
                onTap: () {
                  showImageSourceDialog(context, (source) {
                    itemImagePicker.pick(
                        pickMultiple: source == ImageSource.gallery,
                        context: context,
                        imageLimit: 5,
                        maxLength: mixedItemImageList.length,
                        source: source);
                  });
                },
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  alignment: AlignmentDirectional.center,
                  height: 48,
                  child: CustomText("addOtherPicture".translate(context),
                      color: context.color.textDefaultColor,
                      fontSize: context.font.large),
                ),
              ),
            ),
          current,
          if (mixedItemImageList.length < 5)
            if (files != null && files.isNotEmpty ||
                mixedItemImageList.isNotEmpty)
              uploadPhotoCard(context, onTap: () {
                showImageSourceDialog(context, (source) {
                  itemImagePicker.pick(
                      pickMultiple: source == ImageSource.gallery,
                      context: context,
                      imageLimit: 5,
                      maxLength: mixedItemImageList.length,
                      source: source);
                });
              })
        ],
      );
    });
  }

  Widget closeButton(BuildContext context, Function onTap) {
    return PositionedDirectional(
      top: 6,
      end: 6,
      child: GestureDetector(
        onTap: () {
          onTap.call();
        },
        child: Container(
          decoration: BoxDecoration(
              color: context.color.primaryColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(
              Icons.close,
              size: 24,
              color: context.color.textDefaultColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget uploadPhotoCard(BuildContext context, {required Function onTap}) {
    return GestureDetector(
      onTap: () {
        onTap.call();
      },
      child: Container(
        width: 100,
        height: 100,
        margin: const EdgeInsets.all(5),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: DottedBorder(
            color: context.color.textColorDark.withOpacity(0.3),
            borderType: BorderType.RRect,
            radius: const Radius.circular(10),
            child: Container(
              alignment: AlignmentDirectional.center,
              child: CustomText("uploadPhoto".translate(context)),
            )),
      ),
    );
  }

  // Special Tags Section - Changed to use switches
  Widget _buildSpecialTagsSection(BuildContext context) {
    // Check if we're in service or experience mode
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    if (postType == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 15),
        _buildSwitchOption(
          context,
          title: "Exclusive for Women",
          value: _specialTags["exclusive_women"] ?? false,
          onChanged: (value) {
            setState(() {
              _specialTags["exclusive_women"] = value;
            });
          },
        ),
        _buildSwitchOption(
          context,
          title: "Corporate Package",
          value: _specialTags["corporate_package"] ?? false,
          onChanged: (value) {
            setState(() {
              _specialTags["corporate_package"] = value;
            });
          },
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Helper widget for switch options
  Widget _buildSwitchOption(
    BuildContext context, {
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: CustomText(
              title.translate(context),
              color: value
                  ? context.color.textColorDark
                  : context.color.textColorDark,
              fontWeight: value ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            inactiveTrackColor: const Color(0xFF0F2137),
            activeColor: const Color(0xFF0F2137),
            activeTrackColor: const Color(0xFF0F2137).withOpacity(0.5),
            thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return const Icon(Icons.check, color: Colors.white, size: 16);
              }
              return null;
            }),
          ),
        ],
      ),
    );
  }

  // Price Type Section - Fixed radio button appearance
  Widget _buildPriceTypeSection(BuildContext context) {
    // Check if we're in service or experience mode
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    if (postType == null) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Price Type".translate(context) + " *",
          fontSize: context.font.large,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            _buildRadioOption(
              context,
              title: "Session",
              value: "session",
              groupValue: _priceType,
              onChanged: (value) {
                setState(() {
                  _priceType = value;
                });
              },
            ),
            _buildRadioOption(
              context,
              title: "Consultation",
              value: "consultation",
              groupValue: _priceType,
              onChanged: (value) {
                setState(() {
                  _priceType = value;
                });
              },
            ),
            _buildRadioOption(
              context,
              title: "Hour",
              value: "hour",
              groupValue: _priceType,
              onChanged: (value) {
                setState(() {
                  _priceType = value;
                });
              },
            ),
            _buildRadioOption(
              context,
              title: "Class",
              value: "class",
              groupValue: _priceType,
              onChanged: (value) {
                setState(() {
                  _priceType = value;
                });
              },
            ),
            _buildRadioOption(
              context,
              title: "Fixed Fee",
              value: "fixed_fee",
              groupValue: _priceType,
              onChanged: (value) {
                setState(() {
                  _priceType = value;
                });
              },
            ),
          ],
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Service Location Options
  Widget _buildServiceLocationOptions(BuildContext context) {
    // Only show for Service type
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    if (postType != PostType.service) return SizedBox.shrink();

    // Debug the current state of location options
    print("Current service location options:");
    print("At Client's Location: $_atClientLocation");
    print("At Public Venue: $_atPublicVenue");
    print("At My Location: $_atMyLocation");
    print("Virtual: $_isVirtual");
    print("Current location text: ${locationController.text}");
    if (formatedAddress != null) {
      print(
          "Formatted address - City: ${formatedAddress!.city}, Country: ${formatedAddress!.country}");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Service Location Options".translate(context) + " *",
          fontSize: context.font.large,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 10),

        // Location field with autocomplete
        CustomText("Service Location".translate(context) + " *"),
        SizedBox(height: 8),
        LocationAutocomplete(
          controller: locationController,
          hintText: "enterLocation".translate(context),
          onSelected: (value) {
            // Just update the controller, don't call setState() here
            locationController.text = value;
          },
          onLocationSelected: (locationData) {
            // Use the shared method to update location data safely
            _updateLocationData(locationData);
          },
        ),
        SizedBox(height: 15),

        // Location type options with improved visibility
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: context.color.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                "Service Delivery Methods".translate(context),
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 5),
              _buildCheckboxOption(
                context,
                title: "At the Client's Location",
                value: _atClientLocation,
                onChanged: (value) {
                  setState(() {
                    _atClientLocation = value ?? false;
                  });
                },
              ),
              _buildCheckboxOption(
                context,
                title: "At a Public Venue",
                value: _atPublicVenue,
                onChanged: (value) {
                  setState(() {
                    _atPublicVenue = value ?? false;
                  });
                },
              ),
              _buildCheckboxOption(
                context,
                title: "At My Location",
                value: _atMyLocation,
                onChanged: (value) {
                  setState(() {
                    _atMyLocation = value ?? false;
                  });
                },
              ),
              _buildCheckboxOption(
                context,
                title: "Online (Virtual)",
                value: _isVirtual,
                onChanged: (value) {
                  setState(() {
                    _isVirtual = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Experience Location
  Widget _buildExperienceLocationSection(BuildContext context) {
    // Only show for Experience type
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    if (postType != PostType.experience) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Experience Location".translate(context) + " *",
          fontSize: context.font.large,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 10),

        // Location field with autocomplete
        CustomText("Location".translate(context) + " *"),
        SizedBox(height: 8),
        LocationAutocomplete(
          controller: locationController,
          hintText: "enterLocation".translate(context),
          onSelected: (value) {
            // Just update the controller, don't call setState
            locationController.text = value;
          },
          onLocationSelected: (locationData) {
            // Use the shared method to update location data safely
            _updateLocationData(locationData);
          },
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Auto-Expiration Date & Time
  Widget _buildExpirationDateTimeSection(BuildContext context) {
    // Only show for Experience type
    dynamic rawPostType = getCloudData("post_type");
    PostType? postType;

    if (rawPostType is PostType) {
      postType = rawPostType;
    } else {
      // Handle the case where post_type is not properly cast
      return SizedBox.shrink();
    }

    if (postType != PostType.experience) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          "Auto-Expiration Date & Time".translate(context) + " *",
          fontSize: context.font.large,
          fontWeight: FontWeight.w500,
        ),
        SizedBox(height: 5),
        CustomText(
          "Experience disappears when the event ends".translate(context),
          fontSize: context.font.small,
          color: context.color.textLightColor,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate ??
                        DateTime.now().add(Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(Duration(days: 365)),
                  );
                  if (picked != null && picked != _expirationDate) {
                    setState(() {
                      _expirationDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.color.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        _expirationDate == null
                            ? "Select Date".translate(context)
                            : "${_expirationDate!.day}/${_expirationDate!.month}/${_expirationDate!.year}",
                        color: _expirationDate == null
                            ? context.color.textDefaultColor.withOpacity(0.5)
                            : context.color.textDefaultColor,
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: context.color.textLightColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _expirationTime ?? TimeOfDay.now(),
                  );
                  if (picked != null && picked != _expirationTime) {
                    setState(() {
                      _expirationTime = picked;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                  decoration: BoxDecoration(
                    border: Border.all(color: context.color.borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CustomText(
                        _expirationTime == null
                            ? "Select Time".translate(context)
                            : "${_expirationTime!.format(context)}",
                        color: _expirationTime == null
                            ? context.color.textDefaultColor.withOpacity(0.5)
                            : context.color.textDefaultColor,
                      ),
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: context.color.textLightColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 15),
      ],
    );
  }

  // Helper widgets - Fixed radio button appearance
  Widget _buildRadioOption(
    BuildContext context, {
    required String title,
    required String value,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    bool isSelected = groupValue == value;

    return InkWell(
      onTap: () => onChanged(value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F2137) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF0F2137)
                : context.color.borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Theme(
              data: ThemeData(
                unselectedWidgetColor: context.color.borderColor,
              ),
              child: Radio<String>(
                value: value,
                groupValue: groupValue,
                onChanged: onChanged,
                activeColor: Colors.white,
                fillColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.selected)) {
                    return Colors.white;
                  }
                  return context.color.borderColor;
                }),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Flexible(
              child: CustomText(
                title.translate(context),
                color: isSelected
                    ? context.color.primaryColor
                    : context.color.textColorDark,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(
    BuildContext context, {
    required String title,
    required bool value,
    required Function(bool?) onChanged,
  }) {
    // Debug print to help diagnose the issue
    print("Building checkbox for $title with value $value");

    return InkWell(
      onTap: () {
        print("Checkbox tapped: $title - changing from $value to ${!value}");
        onChanged(!value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          children: [
            Theme(
              data: ThemeData(
                unselectedWidgetColor: context.color.borderColor,
              ),
              child: Checkbox(
                value: value,
                onChanged: (newValue) {
                  print("Checkbox changed via checkbox: $title - to $newValue");
                  onChanged(newValue);
                },
                activeColor: const Color(0xFF0F2137),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Flexible(
              child: CustomText(
                title.translate(context),
                color: value
                    ? context.color.textColorDark
                    : context.color.textColorDark,
                fontWeight: value ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateRequiredFields(PostType? postType) {
    // Validate common required fields for both service and experience
    List<String> missingFields = [];

    // Check title
    if (adTitleController.text.isEmpty) {
      missingFields.add("Ad Title");
    }

    // Check description (required for both types)
    if (adDescriptionController.text.isEmpty) {
      missingFields.add("Description");
    }

    // Check price
    if (adPriceController.text.isEmpty) {
      missingFields.add("Price");
    }

    // Check price type
    if (_priceType == null) {
      missingFields.add("Price Type");
    }

    // Check main picture
    bool hasMainPicture =
        (_pickTitleImage.pickedFile != null) || titleImageURL.isNotEmpty;
    if (!hasMainPicture) {
      missingFields.add("Main Picture");
    }

    // In edit mode, we may have already retrieved the location from the item
    bool isEdit = widget.isEdit == true;

    // Location check for both types
    if (!isEdit &&
        (formatedAddress == null ||
            ((formatedAddress!.city == "" || formatedAddress!.city == null) &&
                (formatedAddress!.area == "" ||
                    formatedAddress!.area == null)) ||
            (formatedAddress!.country == "" ||
                formatedAddress!.country == null))) {
      // In edit mode, check if the item has location data
      if (isEdit && item != null) {
        bool hasLocationData = (item!.city != null && item!.city!.isNotEmpty) ||
            (item!.area != null && item!.area!.isNotEmpty) ||
            (item!.country != null && item!.country!.isNotEmpty);
        if (!hasLocationData) {
          missingFields.add("Location");
        }
      } else {
        missingFields.add("Location");
      }
    }

    // For experience type, check expiration date and time
    if (postType == PostType.experience) {
      if (_expirationDate == null &&
          !(isEdit && item?.expirationDate != null)) {
        missingFields.add("Expiration Date");
      }
      if (_expirationTime == null &&
          !(isEdit &&
              item?.expirationTime != null &&
              item!.expirationTime!.isNotEmpty)) {
        missingFields.add("Expiration Time");
      }
    }

    // If we have missing fields, show an error and return false
    if (missingFields.isNotEmpty) {
      String fieldList = missingFields.join(", ");
      HelperUtils.showSnackBarMessage(
          context, "Please complete the following required fields: $fieldList");
      return false;
    }

    return true;
  }
}

class AddressComponent {
  String? city;
  String? state;
  String? country;
  String? area;
  int? areaId;
  String? mixed;

  AddressComponent({
    this.city,
    this.state,
    this.country,
    this.area,
    this.areaId,
    this.mixed,
  }) {
    // Automatically set mixed if not provided but we have city and country
    if (mixed == null &&
        city != null &&
        country != null &&
        city!.isNotEmpty &&
        country!.isNotEmpty) {
      mixed = "$city, $country";
    }
  }

  static AddressComponent copyWithFields(
    AddressComponent original, {
    String? newCity,
    String? newState,
    String? newCountry,
  }) {
    String? newMixed;
    if (newCity != null && original.country != null) {
      newMixed = "$newCity, ${original.country}";
    } else if (original.city != null && newCountry != null) {
      newMixed = "${original.city}, $newCountry";
    }

    return AddressComponent(
      city: newCity ?? original.city,
      state: newState ?? original.state,
      country: newCountry ?? original.country,
      area: original.area,
      areaId: original.areaId,
      mixed: newMixed ?? original.mixed,
    );
  }

  @override
  String toString() {
    return 'AddressComponent{city: $city, country: $country, state: $state, area: $area, areaId: $areaId, mixed: $mixed}';
  }
}
