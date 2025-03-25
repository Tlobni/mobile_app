// ignore_for_file: unnecessary_getters_setters, file_names

import 'dart:async';
import 'dart:io';

import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PickImage {
  final ImagePicker _picker = ImagePicker();
  final StreamController _imageStreamController = StreamController.broadcast();

  Stream get imageStream => _imageStreamController.stream;

  StreamSink get _sink => _imageStreamController.sink;
  StreamSubscription? subscription;
  File? _pickedFile;

  File? get pickedFile => _pickedFile;

  set pickedFile(File? pickedFile) {
    _pickedFile = pickedFile;
  }

  void pick(
      {ImageSource? source,
      bool? pickMultiple,
      int? imageLimit,
      int? maxLength,
      required BuildContext context}) async {
    if (pickMultiple == false || pickMultiple == null) {
      await _picker
          .pickImage(
        source: source ?? ImageSource.gallery,
      )
          .then((XFile? pickedFile) async {
        if (pickedFile != null) {
          File file = File(pickedFile.path);

          if (await file.length() > Constant.maxSizeInBytes) {
            file = await HelperUtils.compressImageFile(file);
          }

          _sink.add({
            "error": "",
            "file": [file], // Wrapped in a list for consistency
          });
        }
      }).catchError((error) {
        _sink.add({
          "error": error,
          "file": [],
        });
      });
    } else {
      List<XFile> list = await _picker.pickMultiImage(
          imageQuality: Constant.uploadImageQuality, requestFullMetadata: true);

      if (imageLimit != null &&
          maxLength != null &&
          (list.length + maxLength) > imageLimit) {
        HelperUtils.showSnackBarMessage(
            context, "max5ImagesAllowed".translate(context));
      } else {
        Iterable<Future<File>> result = list.map((image) async {
          File myImage = File(image.path);
          if (await myImage.length() > Constant.maxSizeInBytes) {
            myImage = await HelperUtils.compressImageFile(myImage);
          } else {
            myImage = File(image.path);
          }
          return myImage;
        });
        List<File> templistFile = [];
        await for (Future<File> futureFile in Stream.fromIterable(result)) {
          File file = await futureFile;
          templistFile.add(file);
        }

        _sink.add({
          "error": "",
          "file": templistFile,
        });
      }
    }
  }

  /// This widget will listen changes in ui, it is wrapper around Stream builder
  Widget listenChangesInUI(
    dynamic Function(
      BuildContext context,
      List<File>? images,
    ) ondata,
  ) {
    return StreamBuilder(
      stream: imageStream,
      builder: ((context, AsyncSnapshot snapshot) {
        if (snapshot.hasData &&
            snapshot.connectionState == ConnectionState.active) {
          List<File>? files;
          if (snapshot.data['file'] is List) {
            files = (snapshot.data['file'] as List).cast<File>();
          } else if (snapshot.data['file'] is File) {
            files = [snapshot.data['file'] as File];
          }

          pickedFile = files?.isNotEmpty == true ? files![0] : null;

          return ondata.call(context, files);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return ondata.call(context, null);
        }
        return ondata.call(context, null);
      }),
    );
  }

  void listener(void Function(dynamic)? onData) {
    subscription = imageStream.listen((data) {
      if ((subscription?.isPaused == false)) {
        onData?.call(data['file']);
      }
    });
  }

  void pauseSubscription() {
    subscription?.pause();
  }

  void resumeSubscription() {
    subscription?.resume();
  }

  void clearImage() {
    pickedFile = null;
    _sink.add({"file": []});
  }

  void dispose() {
    if (!_imageStreamController.isClosed) {
      _imageStreamController.close();
    }
  }
}

enum PickImageStatus { initial, waiting, done, error }
