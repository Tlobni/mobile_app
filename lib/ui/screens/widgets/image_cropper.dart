import 'package:eClassify/ui/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:eClassify/utils/extensions/extensions.dart';

//This will open image crop SDK
class CropImage {
  static BuildContext? _context;

  static void init(BuildContext context) {
    _context = context;
  }

  static Future<CroppedFile?>? crop({required String filePath}) async {
    if (_context == null) {
      return null;
    }

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: filePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: _context!.color.territoryColor,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: false,
          activeControlsWidgetColor: _context!.color.territoryColor,
          lockAspectRatio: true,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
          ],
        ),
        WebUiSettings(
          context: _context!,
        ),
      ],
    );

    return croppedFile;
  }
}
