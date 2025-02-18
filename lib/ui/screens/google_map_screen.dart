import 'dart:async';

import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/settings.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/foundation.dart' as f;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapScreen extends StatefulWidget {
  const GoogleMapScreen({
    super.key,
    required this.item,
    required CameraPosition kInitialPlace,
    required Completer<GoogleMapController> controller,
  })  : _kInitialPlace = kInitialPlace,
        _controller = controller;

  final ItemModel? item;
  final CameraPosition _kInitialPlace;
  final Completer<GoogleMapController> _controller;

  @override
  State<GoogleMapScreen> createState() => _GoogleMapScreenState();
}

class _GoogleMapScreenState extends State<GoogleMapScreen> {
  bool isGoogleMapVisible = false;

  @override
  void initState() {
    Future.delayed(
      const Duration(milliseconds: 500),
      () {
        isGoogleMapVisible = true;
        setState(() {});
      },
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        isGoogleMapVisible = false;
        setState(() {});
        await Future.delayed(const Duration(milliseconds: 500));
        Future.delayed(
          Duration.zero,
          () {
            Navigator.pop(context);
          },
        );
        return;
      },
      child: Scaffold(
        /* appBar: UiUtils.buildAppBar(
          context,
          showBackButton: true,
        ),
        body: Builder(builder: (context) {
          if (!isGoogleMapVisible) {
            return Center(child: UiUtils.progress());
          }
          return GoogleMap(
            myLocationButtonEnabled: false,
            gestureRecognizers: <f.Factory<OneSequenceGestureRecognizer>>{
              f.Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            markers: {
              Marker(
                  markerId: const MarkerId("1"),
                  position: LatLng(
                      widget.item!.latitude ?? 0, widget.item!.longitude ?? 0))
            },
            mapType: AppSettings.googleMapType,
            initialCameraPosition: widget._kInitialPlace,
            onMapCreated: (GoogleMapController controller) {
              if (!widget._controller.isCompleted) {
                widget._controller.complete(controller);
              }
            },
          );
        }),
      ),
    );
  }
}*/

        body: Stack(
          children: [
            // Google Map Widget
            Builder(builder: (context) {
              if (!isGoogleMapVisible) {
                return Center(child: UiUtils.progress());
              }
              return GoogleMap(
                myLocationButtonEnabled: false,
                gestureRecognizers: <f.Factory<OneSequenceGestureRecognizer>>{
                  f.Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer(),
                  ),
                },
                markers: {
                  Marker(
                    markerId: const MarkerId("1"),
                    position: LatLng(
                      widget.item!.latitude ?? 0,
                      widget.item!.longitude ?? 0,
                    ),
                  )
                },
                mapType: AppSettings.googleMapType,
                initialCameraPosition: widget._kInitialPlace,
                onMapCreated: (GoogleMapController controller) {
                  if (!widget._controller.isCompleted) {
                    widget._controller.complete(controller);
                  }
                },
              );
            }),

            // Custom Back Button on top of the Map
            Positioned(
                top: 40, // Adjust based on your UI requirements
                left: 18,
                child: Material(
                  clipBehavior: Clip.antiAlias,
                  color: Colors.transparent,
                  type: MaterialType.circle,
                  child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Directionality(
                          textDirection: Directionality.of(context),
                          child: RotatedBox(
                            quarterTurns:
                                Directionality.of(context) == TextDirection.rtl
                                    ? 2
                                    : -4,
                            child: UiUtils.getSvg(AppIcons.arrowLeft,
                                fit: BoxFit.none,
                                color: context.color.textDefaultColor),
                          ))),
                )),
          ],
        ),
      ),
    );
  }
}
