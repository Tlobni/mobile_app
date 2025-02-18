import 'dart:async';

import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/home/fetch_home_all_items_cubit.dart';
import 'package:eClassify/data/cubits/home/fetch_home_screen_cubit.dart';
import 'package:eClassify/data/cubits/location/fetch_cities_cubit.dart';
import 'package:eClassify/data/cubits/location/fetch_states_cubit.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/model/location/states_model.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_internet.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/api.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';

class StatesScreen extends StatefulWidget {
  final int countryId;
  final String countryName;
  final String from;

  const StatesScreen({
    super.key,
    required this.countryId,
    required this.countryName,
    required this.from,
  });

  static Route route(RouteSettings settings) {
    Map? arguments = settings.arguments as Map?;

    return BlurredRouter(
      builder: (context) => MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => FetchStatesCubit(),
          ),
          /* BlocProvider(
            create: (context) => FetchCitiesCubit(),
          ),*/
        ],
        child: StatesScreen(
          countryId: arguments?['countryId'],
          countryName: arguments?['countryName'],
          from: arguments?['from'],
        ),
      ),
    );
  }

  @override
  StatesScreenState createState() => StatesScreenState();
}

class StatesScreenState extends State<StatesScreen> {
  bool isFocused = false;
  String previousSearchQuery = "";
  TextEditingController searchController = TextEditingController(text: null);
  final ScrollController controller = ScrollController();
  Timer? _searchDelay;

  @override
  void initState() {
    super.initState();
    context.read<FetchStatesCubit>().fetchStates(
        search: searchController.text, countryId: widget.countryId);
    searchController = TextEditingController();

    searchController.addListener(searchItemListener);
    controller.addListener(pageScrollListen);
  }

  void pageScrollListen() {
    if (controller.isEndReached()) {
      if (context.read<FetchStatesCubit>().hasMoreData()) {
        context
            .read<FetchStatesCubit>()
            .fetchStatesMore(countryId: widget.countryId);
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
      context.read<FetchStatesCubit>().fetchStates(
          search: searchController.text, countryId: widget.countryId);
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
                        "${"search".translate(context)}\t${"state".translate(context)}",
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
        widget.countryName,
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
                  ))),
        ),
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
              : context.color.textDefaultColor.withValues(alpha: 0.2),
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
    return BlocBuilder<FetchStatesCubit, FetchStatesState>(
      builder: (context, state) {
        if (state is FetchStatesInProgress) {
          return shimmerEffect();
        }

        if (state is FetchStatesFailure) {
          if (state.errorMessage is ApiException) {
            if (state.errorMessage == "no-internet") {
              return SingleChildScrollView(
                child: NoInternet(
                  onRetry: () {
                    context.read<FetchStatesCubit>().fetchStates(
                        search: searchController.text,
                        countryId: widget.countryId);
                  },
                ),
              );
            }
          }

          return Center(child: const SomethingWentWrong());
        }

        if (state is FetchStatesSuccess) {
          if (state.statesModel.isEmpty) {
            return SingleChildScrollView(
              child: NoDataFound(
                onTap: () {
                  context.read<FetchStatesCubit>().fetchStates(
                      search: searchController.text,
                      countryId: widget.countryId);
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.from == "addItem"
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 18),
                          child: CustomText(
                            "${"chooseLbl".translate(context)}\t${"state".translate(context)}",
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            color: context.color.primaryColor,
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
                                  "${"allIn".translate(context)}\t${widget.countryName}",
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
                                  country: widget.countryName);

                              Future.delayed(
                                Duration.zero,
                                () {
                                  context
                                      .read<FetchHomeScreenCubit>()
                                      .fetch(country: widget.countryName);
                                  context.read<FetchHomeAllItemsCubit>().fetch(
                                      country: widget.countryName,
                                      radius: null);
                                },
                              );

                              Navigator.popUntil(
                                  context, (route) => route.isFirst);
                            } else if (widget.from == "location") {
                              HiveUtils.setLocation(
                                  country: widget.countryName);
                              HelperUtils.killPreviousPages(
                                  context, Routes.main, {"from": "login"});
                            } else {
                              Map<String, dynamic> result = {
                                'area_id': null,
                                'area': null,
                                'state': null,
                                'country': widget.countryName,
                                'city': null,
                                'latitude': null,
                                'longitude': null
                              };
                              Navigator.pop(context);
                              Navigator.pop(context, result);
                            }
                          },
                        ),
                  const Divider(
                    thickness: 1.2,
                    height: 10,
                  ),
                  // Remove Expanded here
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      physics: AlwaysScrollableScrollPhysics(),
                      itemCount: state.statesModel.length,
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      separatorBuilder: (context, index) {
                        return const Divider(
                          thickness: 1.2,
                          height: 10,
                        );
                      },
                      itemBuilder: (context, index) {
                        StatesModel states = state.statesModel[index];

                        return BlocProvider(
                          create: (context) => FetchCitiesCubit(),
                          child: Builder(builder: (context) {
                            return BlocListener<FetchCitiesCubit,
                                FetchCitiesState>(
                              listener: (context, city) {
                                if (city is FetchCitiesSuccess) {
                                  if (city.citiesModel.isNotEmpty) {
                                    Navigator.pushNamed(
                                        context, Routes.citiesScreen,
                                        arguments: {
                                          "stateId": states.id!,
                                          "stateName": states.name!,
                                          "from": widget.from,
                                          "countryName": widget.countryName
                                        });
                                  }
                                }
                              },
                              child: ListTile(
                                onTap: () {
                                  context
                                      .read<FetchCitiesCubit>()
                                      .fetchCities(stateId: states.id!);
                                },
                                title: CustomText(
                                  states.name!,
                                  textAlign: TextAlign.start,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  color: context.color.textDefaultColor,
                                  fontSize: context.font.normal,
                                ),
                                trailing: Container(
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
                              ),
                            );
                          }),
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
