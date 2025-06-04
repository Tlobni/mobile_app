import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:tlobni/ui/screens/item/add_item_screen/custom_filed_structure/custom_field.dart';
import 'package:tlobni/ui/screens/widgets/dynamic_field.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:tlobni/utils/validator.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class CustomFileField extends CustomField {
  @override
  String type = "fileinput";

  String? picked;

  @override
  void init() {
    if (parameters['isEdit'] == true) {
      if ((parameters['value'] as List).isNotEmpty) {
        picked = parameters['value'][0].toString();
        update(() {});
      }
    }
    super.init();
  }

  Future<File?> pickFile() async {
    FilePickerResult? picker = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'svg', 'pdf'],
    );
    if (picker != null) {
      PlatformFile file = picker.files.first;
      File selectedFile = File(file.path!);
      picked = selectedFile.path;

      if (_isImageFile(selectedFile)) {
        if (await selectedFile.length() > Constant.maxSizeInBytes) {
          File compressedFile = await HelperUtils.compressImageFile(selectedFile);
          return compressedFile;
        } else {
          return selectedFile;
        }
      } else {
        // Return the selected PDF file without compression
        return selectedFile;
      }
    }
    picked = null;
    return null;
  }

  bool _isImageFile(File file) {
    List<String> imageExtensions = ['png', 'jpg', 'jpeg', 'svg'];
    String extension = file.path.split('.').last.toLowerCase();
    return imageExtensions.contains(extension);
  }

  @override
  Widget render() {
    return CustomValidator(
      validator: (value) {
        if (parameters['required'] == 1 && (value == null && picked == null)) {
          return "pleaseSelectFile".translate(context);
        }
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (parameters['image'] != null) ...[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.color.territoryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: FittedBox(
                        fit: BoxFit.none,
                        child: UiUtils.imageType(parameters['image'],
                            width: 24, height: 24, fit: BoxFit.cover, color: context.color.textDefaultColor),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                ],
                Expanded(
                  child: CustomText(
                    parameters['name'],
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    maxLines: 3,
                    fontSize: context.font.large,
                    fontWeight: FontWeight.w500,
                    color: context.color.textColorDark,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 14,
            ),
            GestureDetector(
              onTap: () async {
                File? file = await pickFile();
                if (file != null) {
                  MultipartFile multipartFile = await MultipartFile.fromFile(file.path);
                  update(() {});
                  state.didChange(multipartFile);
                  AbstractField.files.addAll({"custom_field_files[${parameters['id']}]": multipartFile});
                }
              },
              child: DottedBorder(
                borderType: BorderType.RRect,
                radius: const Radius.circular(10),
                color: state.hasError ? context.color.error : context.color.textLightColor.darken(50),
                strokeCap: StrokeCap.round,
                padding: const EdgeInsets.all(5),
                dashPattern: const [3, 3],
                child: Container(
                  width: double.infinity,
                  height: 43,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add),
                      const SizedBox(
                        width: 5,
                      ),
                      CustomText(
                        "addFile".translate(context),
                        color: context.color.textDefaultColor.withOpacity(0.3),
                        fontSize: context.font.large,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Builder(builder: (context) {
              if (picked == null) {
                return const SizedBox.shrink();
              }
              return Container(
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file,
                      color: context.color.territoryColor,
                      size: 35,
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            picked?.split("/").last ?? "",
                            maxLines: 1,
                            fontWeight: FontWeight.w500,
                          ),
                          if (!((picked ?? "").startsWith("http") || (picked ?? "").startsWith("https")))
                            CustomText(
                              HelperUtils.getFileSizeString(
                                bytes: File((picked ?? "")).lengthSync(),
                              ).toUpperCase(),
                              fontSize: context.font.smaller,
                            ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 1),
                    IconButton(
                      onPressed: () {
                        state.didChange(null);
                        picked = null;
                        update(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            CustomText(
              'allowedFileTypes'.translate(context),
              color: context.color.error,
              fontSize: context.font.small,
            ),
          ],
        );
      },
    );
  }
}
