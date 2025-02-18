import 'dart:developer';
import 'dart:io';

import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:eClassify/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/item/add_item_screen/confirm_location_screen.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyLocationScreen extends StatefulWidget {
  final String from;

  const NearbyLocationScreen({
    super.key,
    required this.from,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return BlurredRouter(
        builder: (context) => NearbyLocationScreen(
              from: arguments?['from'],
            ));
  }

  @override
  NearbyLocationScreenState createState() => NearbyLocationScreenState();
}

class NearbyLocationScreenState extends State<NearbyLocationScreen>
    with WidgetsBindingObserver {
  double radius = 1.0;
  late GoogleMapController mapController;
  CameraPosition? _cameraPosition;
  final Set<Marker> _markers = Set();
  Set<Circle> circles = Set.from([]);
  var markerMove;
  bool _openedAppSettings = false;
  String currentLocation = '';
  double? latitude, longitude;
  AddressComponent? formatedAddress;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission;

    // Check location permission status
    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      if (Platform.isAndroid) {
        await Geolocator.openLocationSettings();
        _getCurrentLocation();
      }
      _showLocationServiceInstructions();
    } else if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        setDefaultLocation();
      } else {
        _getCurrentLocation();
      }
    } else {
      // Permission is granted, proceed to get the current location
      preFillLocationWhileEdit();
    }
  }

  void setDefaultLocation() {
    latitude = double.parse(Constant.defaultLatitude);
    longitude = double.parse(Constant.defaultLongitude);
    getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
    _cameraPosition = CameraPosition(
      target: LatLng(latitude!, longitude!),
      zoom: 14.4746,
      bearing: 0,
    );
    _markers.add(Marker(
      markerId: const MarkerId('currentLocation'),
      position: LatLng(latitude!, longitude!),
    ));
    _addCircle(LatLng(latitude!, longitude!), radius);
    setState(() {});
  }

  void preFillLocationWhileEdit() async {
    latitude = HiveUtils.getLatitude();
    longitude = HiveUtils.getLongitude();
    if (latitude != "" &&
        latitude != null &&
        longitude != "" &&
        longitude != null) {
      getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
      _cameraPosition = CameraPosition(
        target: LatLng(latitude!, longitude!),
        zoom: 14.4746,
        bearing: 0,
      );
      _markers.add(Marker(
        markerId: const MarkerId('currentLocation'),
        position: LatLng(latitude!, longitude!),
      ));
      radius = HiveUtils.getNearbyRadius();
      _addCircle(LatLng(latitude!, longitude!), radius);
      setState(() {});
    } else {
      currentLocation = [
        HiveUtils.getCurrentAreaName(),
        HiveUtils.getCurrentCityName(),
        HiveUtils.getCurrentStateName(),
        HiveUtils.getCurrentCountryName()
      ].where((part) => part != null && part.isNotEmpty).join(', ');
      if (currentLocation == "") {
        Position position = await Geolocator.getCurrentPosition(
            locationSettings:
                LocationSettings(accuracy: LocationAccuracy.high));
        _cameraPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 14.4746,
          bearing: 0,
        );
        getLocationFromLatitudeLongitude(
            latLng: LatLng(position.latitude, position.longitude));
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(position.latitude, position.longitude),
        ));
        latitude = position.latitude;
        longitude = position.longitude;
        _addCircle(LatLng(position.latitude, position.longitude), radius);
      } else {
        formatedAddress = AddressComponent(
            area: HiveUtils.getCurrentAreaName(),
            areaId: null,
            city: HiveUtils.getCurrentCityName(),
            country: HiveUtils.getCurrentCountryName(),
            state: HiveUtils.getCurrentStateName());
        latitude = HiveUtils.getCurrentLatitude();
        longitude = HiveUtils.getCurrentLongitude();
        _cameraPosition = CameraPosition(
          target: LatLng(latitude!, longitude!),
          zoom: 14.4746,
          bearing: 0,
        );
        radius = HiveUtils.getNearbyRadius();
        _addCircle(LatLng(latitude!, longitude!), radius);
        getLocationFromLatitudeLongitude(latLng: LatLng(latitude!, longitude!));
        _markers.add(Marker(
          markerId: const MarkerId('currentLocation'),
          position: LatLng(latitude!, longitude!),
        ));
      }
    }

    setState(() {});
  }

  void getLocationFromLatitudeLongitude({LatLng? latLng}) async {
    try {
      Placemark? placeMark = (await placemarkFromCoordinates(
              latLng?.latitude ?? _cameraPosition!.target.latitude,
              latLng?.longitude ?? _cameraPosition!.target.longitude))
          .first;

      formatedAddress = AddressComponent(
          area: placeMark.subLocality,
          areaId: null,
          city: placeMark.locality,
          country: placeMark.country,
          state: placeMark.administrativeArea);

      setState(() {});
    } catch (e) {
      log(e.toString());
      formatedAddress = null;
      setState(() {});
    }
  }

  void _showLocationServiceInstructions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: CustomText(
            'pleaseEnableLocationServicesManually'.translate(context)),
        action: SnackBarAction(
          label: 'ok'.translate(context),
          textColor: context.color.secondaryColor,
          onPressed: () {
            openAppSettings();
            setState(() {
              _openedAppSettings = true;
            });

            // Optionally handle action button press
          },
        ),
      ),
    );
  }

  void _addCircle(LatLng position, double radiusInKm) {
    final double radiusInMeters = radiusInKm * 1000; // Convert km to meters

    setState(() {
      circles.clear(); // Clear any existing circles
      circles.add(
        Circle(
          circleId: CircleId("radius_circle"),
          center: position,
          radius: radiusInMeters,
          // Set radius in meters
          fillColor: context.color.territoryColor.withValues(alpha: 0.15),
          strokeColor: context.color.territoryColor,
          strokeWidth: 2,
        ),
      );
    });
  }

  Widget bottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Divider(
          color: context.color.backgroundColor,
          thickness: 1.5,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: UiUtils.buildButton(context, radius: 8, fontSize: 16,
                      onPressed: () {
                setState(() {
                  radius = 1;
                  _addCircle(LatLng(latitude!, longitude!), radius);
                });
              },
                      buttonTitle: "reset".translate(context),
                      height: 43,
                      border: BorderSide(color: context.color.territoryColor),
                      textColor: context.color.territoryColor,
                      buttonColor: context.color.secondaryColor)),
              const SizedBox(width: 16),
              Expanded(
                  child: UiUtils.buildButton(context, radius: 8, fontSize: 16,
                      onPressed: () {
                HiveUtils.setNearbyRadius(radius.toInt());
                applyOnPressed();
              },
                      buttonTitle: "apply".translate(context),
                      height: 43,
                      textColor: context.color.secondaryColor,
                      buttonColor: context.color.territoryColor)),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  void applyOnPressed() {
    if (widget.from == "home") {
      HiveUtils.setLocation(
          city: formatedAddress!.city,
          state: formatedAddress!.state,
          area: formatedAddress!.area,
          country: formatedAddress!.country,
          latitude: latitude,
          longitude: longitude,
          radius: radius);

      Future.delayed(
        Duration.zero,
        () {
          context.read<FetchHomeScreenCubit>().fetch(
              country: formatedAddress!.country,
              state: formatedAddress!.state,
              city: formatedAddress!.city);
          context.read<FetchHomeAllItemsCubit>().fetch(
              country: formatedAddress!.country,
              state: formatedAddress!.state,
              city: formatedAddress!.city,
              radius: radius.toInt(),
              latitude: latitude,
              longitude: longitude);
        },
      );

      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (widget.from == "location") {
      HiveUtils.setLocation(
          city: formatedAddress!.city,
          state: formatedAddress!.state,
          area: formatedAddress!.area,
          country: formatedAddress!.country,
          latitude: latitude,
          longitude: longitude,
          radius: radius);
      HelperUtils.killPreviousPages(context, Routes.main, {"from": "login"});
    } else {
      Map<String, dynamic> result = {
        'area_id': null,
        'area': formatedAddress!.area,
        'state': formatedAddress!.state,
        'country': formatedAddress!.country,
        'city': formatedAddress!.city,
        'latitude': latitude,
        'longitude': longitude,
        'radius': radius.toInt()
      };
      Navigator.pop(context);
      Navigator.pop(context, result);
    }
  }

  Set<Factory<OneSequenceGestureRecognizer>> getMapGestureRecognizers() {
    return <Factory<OneSequenceGestureRecognizer>>{}..add(
        Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer()
              ..onDown = (dragUpdateDetails) {
                if (markerMove == false) {
                } else {
                  setState(() {
                    markerMove = false;
                  });
                }
              }));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
        bottomNavigationBar: bottomBar(),
        backgroundColor: context.color.secondaryColor,
        appBar: UiUtils.buildAppBar(context,
            showBackButton: true, title: "nearbyListings".translate(context)),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: context.color.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    _cameraPosition != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          color: context.color.backgroundColor),
                                      height: context.screenHeight * 0.6,
                                      child: GoogleMap(
                                          onCameraMove: (position) {
                                            _cameraPosition = position;
                                          },
                                          onCameraIdle: () async {
                                            if (markerMove == false) {
                                              if (LatLng(
                                                      latitude!, longitude!) ==
                                                  LatLng(
                                                      _cameraPosition!
                                                          .target.latitude,
                                                      _cameraPosition!
                                                          .target.longitude)) {
                                              } else {
                                                getLocationFromLatitudeLongitude();
                                              }
                                            }
                                          },
                                          initialCameraPosition:
                                              _cameraPosition!,
                                          //onMapCreated: _onMapCreated,
                                          circles: circles,
                                          markers: _markers,
                                          zoomControlsEnabled: false,
                                          minMaxZoomPreference:
                                              const MinMaxZoomPreference(0, 16),
                                          compassEnabled: true,
                                          indoorViewEnabled: true,
                                          mapToolbarEnabled: true,
                                          myLocationButtonEnabled: true,
                                          mapType: MapType.normal,
                                          onMapCreated:
                                              (GoogleMapController controller) {
                                            Future.delayed(const Duration(
                                                    milliseconds: 500))
                                                .then((value) {
                                              mapController = (controller);
                                              mapController.animateCamera(
                                                CameraUpdate.newCameraPosition(
                                                  _cameraPosition!,
                                                ),
                                              );
                                              //preFillLocationWhileEdit();
                                            });
                                          },
                                          onTap: (latLng) {
                                            setState(() {
                                              _markers
                                                  .clear(); // Clear existing markers
                                              _markers.add(Marker(
                                                markerId: MarkerId(
                                                    'selectedLocation'),
                                                position: latLng,
                                              ));
                                              latitude = latLng.latitude;
                                              longitude = latLng.longitude;

                                              getLocationFromLatitudeLongitude(
                                                  latLng: latLng);
                                              _addCircle(
                                                  LatLng(latitude!, longitude!),
                                                  radius); // Get location details
                                            });
                                          }))),
                              if (formatedAddress != null)
                                PositionedDirectional(
                                  start: 15,
                                  top: 15,
                                  end: 15,
                                  child: Container(
                                    /* margin:
                                        EdgeInsets.symmetric(horizontal: 18),*/
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: context.color.secondaryColor),
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                      child: Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 25,
                                                height: 25,
                                                decoration: BoxDecoration(
                                                  color: context
                                                      .color.territoryColor
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Icon(
                                                    Icons.location_on_outlined,
                                                    size: 20,
                                                    color: context
                                                        .color.territoryColor),
                                              ),
                                              SizedBox(
                                                width: 10,
                                              ),
                                              Expanded(
                                                child: CustomText(
                                                  [
                                                    if (formatedAddress!.area !=
                                                            null &&
                                                        formatedAddress!
                                                            .area!.isNotEmpty)
                                                      formatedAddress!.area,
                                                    if (formatedAddress!.city !=
                                                            null &&
                                                        formatedAddress!
                                                            .city!.isNotEmpty)
                                                      formatedAddress!.city,
                                                    if (formatedAddress!
                                                                .state !=
                                                            null &&
                                                        formatedAddress!
                                                            .state!.isNotEmpty)
                                                      formatedAddress!.state,
                                                    if (formatedAddress!
                                                                .country !=
                                                            null &&
                                                        formatedAddress!
                                                            .country!
                                                            .isNotEmpty)
                                                      formatedAddress!.country
                                                  ].join(", ").isEmpty
                                                      ? "____"
                                                      : [
                                                          if (formatedAddress!
                                                                      .area !=
                                                                  null &&
                                                              formatedAddress!
                                                                  .area!
                                                                  .isNotEmpty)
                                                            formatedAddress!
                                                                .area,
                                                          if (formatedAddress!
                                                                      .city !=
                                                                  null &&
                                                              formatedAddress!
                                                                  .city!
                                                                  .isNotEmpty)
                                                            formatedAddress!
                                                                .city,
                                                          if (formatedAddress!
                                                                      .state !=
                                                                  null &&
                                                              formatedAddress!
                                                                  .state!
                                                                  .isNotEmpty)
                                                            formatedAddress!
                                                                .state,
                                                          if (formatedAddress!
                                                                      .country !=
                                                                  null &&
                                                              formatedAddress!
                                                                  .country!
                                                                  .isNotEmpty)
                                                            formatedAddress!
                                                                .country
                                                        ].join(", "),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  softWrap: true,
                                                  maxLines: 3,
                                                  fontSize: context.font.normal,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              )
                                            ],
                                          )),
                                    ),
                                  ),
                                ),
                              PositionedDirectional(
                                end: 5,
                                bottom: 5,
                                child: Card(
                                  child: InkWell(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: const Icon(
                                        Icons.my_location_sharp,
                                        size: 30,
                                        // Change the icon color if needed
                                      ),
                                    ),
                                    onTap: () async {
                                      Position position =
                                          await Geolocator.getCurrentPosition(
                                              locationSettings:
                                                  LocationSettings(
                                                      accuracy: LocationAccuracy
                                                          .high));

                                      _markers
                                          .clear(); // Clear existing markers
                                      _markers.add(Marker(
                                        markerId: MarkerId('selectedLocation'),
                                        position: LatLng(position.latitude,
                                            position.longitude),
                                      ));

                                      _cameraPosition = CameraPosition(
                                        target: LatLng(position.latitude,
                                            position.longitude),
                                        zoom: 14.4746,
                                        bearing: 0,
                                      );
                                      latitude = position.latitude;
                                      longitude = position.longitude;
                                      getLocationFromLatitudeLongitude();
                                      _addCircle(
                                          LatLng(position.latitude,
                                              position.longitude),
                                          radius);
                                      mapController.animateCamera(
                                        CameraUpdate.newCameraPosition(
                                            _cameraPosition!),
                                      );
                                      setState(() {});
                                    },
                                  ),
                                ),
                              )
                            ],
                          )
                        : Container(),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: sidePadding),
                child: CustomText(
                  'selectAreaRange'.translate(context),
                  color: context.color.textDefaultColor,
                  fontWeight: FontWeight.w600,
                )),
            SizedBox(
              height: 15,
            ),
            Slider(
              value: radius,
              min: 1,
              activeColor: context.color.textDefaultColor,
              inactiveColor: context.color.backgroundColor.darken(20),
              max: 100,
              divisions: 99,
              label: '${radius.toInt()}\t${"km".translate(context)}',
              onChanged: (value) {
                setState(() {
                  radius = value;
                  _addCircle(LatLng(latitude!, longitude!), radius);
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: sidePadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CustomText('1\t${"km".translate(context)}',
                      color: context.color.textDefaultColor,
                      fontWeight: FontWeight.w500),
                  CustomText(
                    '100\t${"km".translate(context)}',
                    color: context.color.textDefaultColor,
                    fontWeight: FontWeight.w500,
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
