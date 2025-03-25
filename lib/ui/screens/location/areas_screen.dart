import 'dart:async';

import 'package:tlobni/app/app_theme.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:tlobni/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:tlobni/data/cubits/location/fetch_areas_cubit.dart';
import 'package:tlobni/data/cubits/system/app_theme_cubit.dart';
import 'package:tlobni/data/model/location/area_model.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_data_found.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/api.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class AreasScreen extends StatefulWidget {
  final int cityId;
  final String cityName;
  final String countryName;
  final String stateName;
  final String from;
  final double latitude;
  final double longitude;

  const AreasScreen({
    super.key,
    required this.cityId,
    required this.cityName,
    required this.from,
    required this.countryName,
    required this.stateName,
    required this.latitude,
    required this.longitude,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return BlurredRouter(
      builder: (context) => BlocProvider(
          create: (context) => FetchAreasCubit(),
          child: AreasScreen(
            cityId: arguments?['cityId'],
            cityName: arguments?['cityName'],
            countryName: arguments?['countryName'],
            stateName: arguments?['stateName'],
            from: arguments?['from'],
            latitude: arguments?['latitude'],
            longitude: arguments?['longitude'],
          )),
    );
  }

  @override
  AreasScreenState createState() => AreasScreenState();
}

class AreasScreenState extends State<AreasScreen> {
  bool isFocused = false;
  String previousSearchQuery = "";
  TextEditingController searchController = TextEditingController(text: null);
  final ScrollController controller = ScrollController();
  Timer? _searchDelay;

  @override
  void initState() {
    super.initState();
    context
        .read<FetchAreasCubit>()
        .fetchAreas(search: searchController.text, cityId: widget.cityId);
    searchController = TextEditingController();

    searchController.addListener(searchItemListener);
    controller.addListener(pageScrollListen);
  }

  void pageScrollListen() {
    if (controller.isEndReached()) {
      if (context.read<FetchAreasCubit>().hasMoreData()) {
        context.read<FetchAreasCubit>().fetchAreasMore(cityId: widget.cityId);
      }
    }
  }

//this will listen and manage search
  void searchItemListener() {
    _searchDelay?.cancel();
    searchCallAfterDelay();
    setState(() {});
  }

//This will create delay so we don't face rapid api call
  void searchCallAfterDelay() {
    _searchDelay = Timer(const Duration(milliseconds: 500), itemSearch);
  }

  ///This will call api after some delay
  void itemSearch() {
    // if (searchController.text.isNotEmpty) {
    if (previousSearchQuery != searchController.text) {
      context
          .read<FetchAreasCubit>()
          .fetchAreas(search: searchController.text, cityId: widget.cityId);
      previousSearchQuery = searchController.text;
      setState(() {});
    }
    // } else {
    // context.read<SearchItemCubit>().clearSearch();
    // }
  }

  PreferredSizeWidget appBarWidget() {
    return AppBar(
      systemOverlayStyle:
          SystemUiOverlayStyle(statusBarColor: context.color.backgroundColor),
      bottom: PreferredSize(
          preferredSize: Size.fromHeight(58),
          child: Container(
              width: double.maxFinite,
              height: 48,
              margin: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              alignment: AlignmentDirectional.center,
              decoration: BoxDecoration(
                  border: Border.all(
                      width: context.watch<AppThemeCubit>().state.appTheme ==
                              AppTheme.dark
                          ? 0
                          : 1,
                      color: context.color.borderColor.darken(30)),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  color: context.color.secondaryColor),
              child: TextFormField(
                  controller: searchController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    //OutlineInputBorder()
                    fillColor: Theme.of(context).colorScheme.secondaryColor,
                    hintText:
                        "${"search".translate(context)}\t${"area".translate(context)}",
                    prefixIcon: setSearchIcon(),
                    prefixIconConstraints:
                        const BoxConstraints(minHeight: 5, minWidth: 5),
                  ),
                  enableSuggestions: true,
                  onEditingComplete: () {
                    setState(
                      () {
                        isFocused = false;
                      },
                    );
                    FocusScope.of(context).unfocus();
                  },
                  onTap: () {
                    //change prefix icon color to primary
                    setState(() {
                      isFocused = true;
                    });
                  }))),
      automaticallyImplyLeading: false,
      title: CustomText(
        widget.cityName,
        color: context.color.textDefaultColor,
        fontWeight: FontWeight.w600,
        fontSize: 18,
      ),
      leading: Material(
        clipBehavior: Clip.antiAlias,
        color: Colors.transparent,
        type: MaterialType.circle,
        child: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Padding(
                padding: EdgeInsetsDirectional.only(
                  start: 18.0,
                ),
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
                  ),
                ))),
      ),
      /*BackButton(
        color: context.color.textDefaultColor,
      ),*/
      elevation: context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark
          ? 0
          : 6,
      shadowColor:
          context.watch<AppThemeCubit>().state.appTheme == AppTheme.dark
              ? null
              : context.color.textDefaultColor.withOpacity(0.2),
      backgroundColor: context.color.backgroundColor,
    );
  }

  Widget shimmerEffect() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      /*   padding: const EdgeInsets.symmetric(
        vertical: 10 + defaultPadding,
        //horizontal: defaultPadding,
      ),*/
      itemCount: 15,
      separatorBuilder: (context, index) {
        return Container();
      },
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Theme.of(context).colorScheme.shimmerBaseColor,
          highlightColor: Theme.of(context).colorScheme.shimmerHighlightColor,
          child: Container(
            padding: EdgeInsets.all(5),
            width: double.maxFinite,
            height: 56,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border:
                    Border.all(color: context.color.borderColor.darken(30))),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(),
      body: bodyData(),
      backgroundColor: context.color.backgroundColor,
    );
  }

  Widget bodyData() {
    return searchItemsWidget();
  }

  Widget searchItemsWidget() {
    return BlocBuilder<FetchAreasCubit, FetchAreasState>(
      builder: (context, state) {
        if (state is FetchAreasInProgress) {
          return shimmerEffect();
        }

        if (state is FetchAreasFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return SingleChildScrollView(
                child: NoInternet(
                  onRetry: () {
                    context.read<FetchAreasCubit>().fetchAreas(
                        search: searchController.text, cityId: widget.cityId);
                  },
                ),
              );
            }
          }

          return Center(child: const SomethingWentWrong());
        }

        if (state is FetchAreasSuccess) {
          if (state.areasModel.isEmpty) {
            return SingleChildScrollView(
              child: NoDataFound(
                onTap: () {
                  context.read<FetchAreasCubit>().fetchAreas(
                      search: searchController.text, cityId: widget.cityId);
                },
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 17),
            child: Container(
              color: context.color.secondaryColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.from == "addItem"
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 18),
                          child: CustomText(
                            "${"lblall".translate(context)}\t${"area".translate(context)}",
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: context.color.textDefaultColor,
                            fontSize: context.font.normal,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : InkWell(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 12),
                            child: Row(
                              children: [
                                CustomText(
                                  "${"allIn".translate(context)}\t${widget.cityName}",
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  color: context.color.textDefaultColor,
                                  fontSize: context.font.normal,
                                  fontWeight: FontWeight.w600,
                                ),
                                Spacer(),
                                Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        color: context.color.borderColor
                                            .darken(10)),
                                    child: Icon(
                                      Icons.chevron_right_outlined,
                                      color: context.color.textDefaultColor,
                                    )),
                              ],
                            ),
                          ),
                          onTap: () {
                            if (widget.from == "home") {
                              HiveUtils.setLocation(
                                  country: widget.countryName,
                                  state: widget.stateName,
                                  city: widget.cityName);

                              Future.delayed(
                                Duration.zero,
                                () {
                                  context.read<FetchHomeScreenCubit>().fetch(
                                        country: widget.countryName,
                                        state: widget.stateName,
                                        city: widget.cityName,
                                      );
                                  context.read<FetchHomeAllItemsCubit>().fetch(
                                      country: widget.countryName,
                                      state: widget.stateName,
                                      city: widget.cityName,
                                      radius: null);
                                },
                              );

                              Navigator.popUntil(
                                  context, (route) => route.isFirst);
                            } else if (widget.from == "location") {
                              HiveUtils.setLocation(
                                  country: widget.countryName,
                                  state: widget.stateName,
                                  city: widget.cityName);
                              HelperUtils.killPreviousPages(
                                  context, Routes.main, {"from": "login"});
                            } else {
                              Map<String, dynamic> result = {
                                'area_id': null,
                                'area': null,
                                'state': widget.stateName,
                                'country': widget.countryName,
                                'city': widget.cityName,
                                'latitude': null,
                                'longitude': null
                              };
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context, result);
                            }
                          },
                        ),
                  const Divider(
                    thickness: 1.2,
                    height: 10,
                  ),
                  Expanded(
                    child: ListView.separated(
                      itemCount: state.areasModel.length,
                      padding: EdgeInsets.zero,
                      controller: controller,
                      physics: AlwaysScrollableScrollPhysics(),
                      shrinkWrap: true,
                      separatorBuilder: (context, index) {
                        return const Divider(
                          thickness: 1.2,
                          height: 10,
                        );
                      },
                      itemBuilder: (context, index) {
                        AreaModel area = state.areasModel[index];

                        return ListTile(
                          onTap: () {
                            if (widget.from == "home") {
                              if (Constant.isDemoModeOn) {
                                UiUtils.setDefaultLocationValue(
                                    isCurrent: false,
                                    isHomeUpdate: true,
                                    context: context);
                                Navigator.popUntil(
                                    context, (route) => route.isFirst);
                              } else {
                                HiveUtils.setLocation(
                                    city: widget.cityName,
                                    state: widget.stateName,
                                    country: widget.countryName,
                                    area: area.name,
                                    areaId: area.id,
                                    latitude: widget.latitude,
                                    longitude: widget.longitude);
                                Future.delayed(
                                  Duration.zero,
                                  () {
                                    context.read<FetchHomeScreenCubit>().fetch(
                                          areaId: area.id,
                                        );
                                    context
                                        .read<FetchHomeAllItemsCubit>()
                                        .fetch(areaId: area.id, radius: null);
                                  },
                                );
                              }
                              Navigator.popUntil(
                                  context, (route) => route.isFirst);
                            } else if (widget.from == "location") {
                              if (Constant.isDemoModeOn) {
                                UiUtils.setDefaultLocationValue(
                                    isCurrent: false,
                                    isHomeUpdate: false,
                                    context: context);
                                HelperUtils.killPreviousPages(
                                    context, Routes.main, {"from": "login"});
                              } else {
                                HiveUtils.setLocation(
                                  area: area.name,
                                  areaId: area.id,
                                  city: widget.cityName,
                                  state: widget.stateName,
                                  country: widget.countryName,
                                  latitude: widget.latitude,
                                  longitude: widget.longitude,
                                );
                                HelperUtils.killPreviousPages(
                                    context, Routes.main, {"from": "login"});
                              }
                            } else {
                              Map<String, dynamic> result = {
                                'area_id': area.id,
                                'area': area.name,
                                'city': widget.cityName,
                                'state': widget.stateName,
                                'country': widget.countryName,
                                'latitude': widget.latitude,
                                'longitude': widget.longitude
                              };

                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context, result);
                            }
                          },
                          title: CustomText(
                            area.name!,
                            textAlign: TextAlign.start,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: context.color.textDefaultColor,
                            fontSize: context.font.normal,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                  ),
                  if (state.isLoadingMore)
                    Center(
                      child: UiUtils.progress(
                        normalProgressColor: context.color.territoryColor,
                      ),
                    )
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }

  Widget setSearchIcon() {
    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: UiUtils.getSvg(AppIcons.search,
            color: context.color.territoryColor));
  }

  Widget setSuffixIcon() {
    return GestureDetector(
      onTap: () {
        searchController.clear();
        isFocused = false; //set icon color to black back
        FocusScope.of(context).unfocus(); //dismiss keyboard
        setState(() {});
      },
      child: Icon(
        Icons.close_rounded,
        color: Theme.of(context).colorScheme.blackColor,
        size: 30,
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
