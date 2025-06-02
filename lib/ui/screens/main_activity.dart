// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/item/search_item_cubit.dart';
import 'package:tlobni/data/cubits/subscription/fetch_user_package_limit_cubit.dart';
import 'package:tlobni/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/model/system_settings_model.dart';
import 'package:tlobni/ui/screens/chat/chat_list_screen.dart';
import 'package:tlobni/ui/screens/favorite_screen.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/ui/screens/home/search_screen.dart';
import 'package:tlobni/ui/screens/item/my_items_screen.dart';
import 'package:tlobni/ui/screens/user_profile/profile_screen.dart';
import 'package:tlobni/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:tlobni/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:tlobni/ui/screens/widgets/maintenance_mode.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/error_filter.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/svg/svg_edit.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:url_launcher/url_launcher.dart';

List<ItemModel> myItemList = [];
Map<String, dynamic> searchBody = {};
String selectedCategoryId = "0";
String selectedCategoryName = "";
dynamic selectedCategory;

//this will set when i will visit in any category
dynamic currentVisitingCategoryId = "";
dynamic currentVisitingCategory = "";

List<int> navigationStack = [0];

ScrollController homeScreenController = ScrollController();
//ScrollController chatScreenController = ScrollController();
ScrollController profileScreenController = ScrollController();

List<ScrollController> controllerList = [
  homeScreenController,
  //chatScreenController,
  profileScreenController
];

//
class MainActivity extends StatefulWidget {
  final String from;
  final String? itemSlug;
  static final GlobalKey<MainActivityState> globalKey = GlobalKey<MainActivityState>();

  MainActivity({Key? key, required this.from, this.itemSlug}) : super(key: globalKey);

  @override
  State<MainActivity> createState() => MainActivityState();

  static Route route(RouteSettings routeSettings) {
    final arg = routeSettings.arguments;
    // Safely handle the case when `arg` is null or not a Map
    if (arg is Map) {
      return BlurredRouter(
        builder: (_) => MainActivity(
          from: arg['from'] as String,
          itemSlug: arg['slug'] as String?,
        ),
      );
    } else {
      // Provide defaults or handle it if no arguments were passed
      return BlurredRouter(
        builder: (_) => MainActivity(
          from: '', // or some default
          itemSlug: null, // or some default
        ),
      );
    }
  }
}

class MainActivityState extends State<MainActivity> with TickerProviderStateMixin {
  PageController pageController = PageController(initialPage: 0);
  int currentTab = 0;
  static final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
  final List _pageHistory = [];

  DateTime? currentBackPressTime;

//This is rive file artboards and setting you can check rive package's documentation at [pub.dev]
  bool svgLoaded = false;
  bool isAddMenuOpen = false;
  int rotateAnimationDurationMs = 2000;

  bool isChecked = false;
  SVGEdit svgEdit = SVGEdit();
  bool isBack = false;
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    initAppLinks();

    rootBundle.loadString(AppIcons.plusIcon).then((value) {
      svgEdit.loadSVG(value);
      svgEdit.change("Path_11299-2", attribute: "fill", value: svgEdit.flutterColorToHexColor(context.color.territoryColor));
      svgLoaded = true;
      setState(() {});
    });

    FetchSystemSettingsCubit settings = context.read<FetchSystemSettingsCubit>();
    if (!const bool.fromEnvironment("force-disable-demo-mode", defaultValue: false)) {
      Constant.isDemoModeOn = settings.getSetting(SystemSetting.demoMode) ?? false;
    }
    var numberWithSuffix = settings.getSetting(SystemSetting.numberWithSuffix);
    Constant.isNumberWithSuffix = numberWithSuffix == "1" ? true : false;

    ///This will check for update
    versionCheck(settings);

//This will init page controller
    initPageController();

    if (widget.itemSlug != null) {
      Navigator.of(context).pushNamed(Routes.adDetailsScreen, arguments: {"slug": widget.itemSlug!});
    }
  }

  Future<void> initAppLinks() async {
    _appLinks = AppLinks();

    // Listen for incoming deep links
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        handleDeepLink(uri);
      }
    });
  }

  void handleDeepLink(Uri uri) {
    if (uri.path.contains('/product-details/')) {
      // Navigator.push(
      //   context,
      //   Routes.onGenerateRouted(RouteSettings(name: uri.toString())),
      // );
    } else {
      print('Received deep link: $uri');
      // Handle other deep link paths here if necessary
    }
  }

  void addHistory(int index) {
    List<int> stack = navigationStack;
    if (stack.last != index) {
      stack.add(index);
      navigationStack = stack;
    }

    setState(() {});
  }

  void initPageController() {
    pageController
      ..addListener(() {
        _pageHistory.insert(0, pageController.page);
      });
  }

  void completeProfileCheck() {
    if (HiveUtils.getUserDetails().name == "" || HiveUtils.getUserDetails().email == "") {
      Future.delayed(
        const Duration(milliseconds: 100),
        () {
          Navigator.pushReplacementNamed(context, Routes.completeProfile, arguments: {"from": "login"});
        },
      );
    }
  }

  void versionCheck(settings) async {
    var remoteVersion = settings.getSetting(Platform.isIOS ? SystemSetting.iosVersion : SystemSetting.androidVersion);
    var remote = remoteVersion;

    var forceUpdate = settings.getSetting(SystemSetting.forceUpdate);

    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    var current = packageInfo.version;

    int currentVersion = HelperUtils.comparableVersion(packageInfo.version);
    if (remoteVersion == null) {
      return;
    }

    remoteVersion = HelperUtils.comparableVersion(
      remoteVersion,
    );

    if (remoteVersion > currentVersion) {
      Constant.isUpdateAvailable = true;
      Constant.newVersionNumber = settings.getSetting(
        Platform.isIOS ? SystemSetting.iosVersion : SystemSetting.androidVersion,
      );

      Future.delayed(
        Duration.zero,
        () {
          if (forceUpdate == "1") {
            ///This is force update
            UiUtils.showBlurredDialoge(context,
                dialoge: BlurredDialogBox(
                    onAccept: () async {
                      await launchUrl(
                          Uri.parse(
                            Constant.playstoreURLAndroid,
                          ),
                          mode: LaunchMode.externalApplication);
                    },
                    backAllowedButton: false,
                    svgImagePath: AppIcons.update,
                    isAcceptContainerPush: true,
                    svgImageColor: context.color.territoryColor,
                    showCancelButton: false,
                    title: "updateAvailable".translate(context),
                    acceptTextColor: context.color.buttonColor,
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText("$current>$remote"),
                        CustomText("newVersionAvailableForce".translate(context), textAlign: TextAlign.center),
                      ],
                    )));
          } else {
            UiUtils.showBlurredDialoge(
              context,
              dialoge: BlurredDialogBox(
                onAccept: () async {
                  await launchUrl(Uri.parse(Constant.playstoreURLAndroid), mode: LaunchMode.externalApplication);
                },
                svgImagePath: AppIcons.update,
                svgImageColor: context.color.territoryColor,
                showCancelButton: true,
                title: "updateAvailable".translate(context),
                content: CustomText(
                  "newVersionAvailable".translate(context),
                ),
              ),
            );
          }
        },
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ErrorFilter.setContext(context);
    svgEdit.change("Path_11299-2", attribute: "fill", value: svgEdit.flutterColorToHexColor(context.color.territoryColor));
  }

  @override
  void dispose() {
    pageController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  late List<Widget> pages = [
    HomeScreen(from: widget.from),
    ChatListScreen(),
    HiveUtils.getUserType() == "Client" ? const FavoriteScreen() : const ItemsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(context: context, statusBarColor: context.color.primaryColor),
      child: PopScope(
        canPop: isBack,
        onPopInvokedWithResult: (didPop, result) {
          if (currentTab != 0) {
            pageController.animateToPage(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
            setState(() {
              currentTab = 0;
              isBack = false;
            });
            return;
          } else {
            DateTime now = DateTime.now();
            if (currentBackPressTime == null || now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
              currentBackPressTime = now;

              HelperUtils.showSnackBarMessage(context, "pressAgainToExit".translate(context));

              setState(() {
                isBack = false;
              });
              return;
            }
            setState(() {
              isBack = true;
            });
            return;
          }
        },
        child: Scaffold(
          backgroundColor: context.color.primaryColor,
          bottomNavigationBar: Constant.maintenanceMode == "1" ? null : bottomBar(),
          body: Stack(
            children: <Widget>[
              PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: pageController,
                //onPageChanged: onItemSwipe,
                children: pages,
              ),
              if (Constant.maintenanceMode == "1") MaintenanceMode()
            ],
          ),
        ),
      ),
    );
  }

  void onItemTapped(int index) {
    addHistory(index);

    FocusManager.instance.primaryFocus?.unfocus();

    if (index != 1) {
      context.read<SearchItemCubit>().clearSearch();

      if (SearchScreenState.searchController.hasListeners) {
        SearchScreenState.searchController.text = "";
      }
    }
    searchBody = {};
    if (index == 1) {
      UiUtils.checkUser(
          onNotGuest: () {
            currentTab = index;
            pageController.jumpToPage(currentTab);
            setState(
              () {},
            );
          },
          context: context);
    } else if (index == 2) {
      UiUtils.checkUser(
          onNotGuest: () {
            // Re-initialize the page dynamically based on current user role
            pages[2] = HiveUtils.getUserType() == "Client" ? const FavoriteScreen() : const ItemsScreen();

            currentTab = index;
            pageController.jumpToPage(currentTab);
            setState(
              () {},
            );
          },
          context: context);
    } else {
      currentTab = index;
      pageController.jumpToPage(currentTab);
      setState(
        () {},
      );
    }
  }

  BottomAppBar bottomBar() {
    final isProvider = HiveUtils.getUserType() == "Expert" || HiveUtils.getUserType() == "Business";
    log('Bottom navigation: User type is ${HiveUtils.getUserType()}, isProvider: $isProvider');

    // Check if user is logged in
    final isLoggedIn = HiveUtils.isUserAuthenticated();

    // Check if user is a Client
    final isClient = HiveUtils.getUserType() == "Client";

    return BottomAppBar(
      color: context.color.secondaryColor,
      shape: const CircularNotchedRectangle(),
      height: isProvider ? 70 : 60, // Consistent height
      child: Container(
        color: context.color.secondaryColor,
        // Consistent padding for all users
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(mainAxisSize: MainAxisSize.max, mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
          buildBottomNavigationbarItem(0, AppIcons.homeNav, AppIcons.homeNavActive, "homeTab".translate(context)),
          buildBottomNavigationbarItem(1, AppIcons.chatNav, AppIcons.chatNavActive, "chat".translate(context)),
          // Only show post button if user is a provider
          isProvider
              ? BlocListener<FetchUserPackageLimitCubit, FetchUserPackageLimitState>(
                  listener: (context, state) {
                    if (state is FetchUserPackageLimitFailure) {
                      // Check if the error message is "User is pending"
                      if (state.error.toString() == "User is pending") {
                        // Show pending dialog for this specific error message
                        UiUtils.showBlurredDialoge(
                          context,
                          dialoge: BlurredDialogBox(
                            onAccept: () async {
                              // Just close the dialog without returning anything
                              // and use async to ensure it works as Future
                            },
                            svgImageColor: context.color.territoryColor,
                            showCancelButton: false,
                            title: "Pending".translate(context),
                            content: CustomText(
                              "Your subscription is pending. The admin will contact you soon.",
                              textAlign: TextAlign.center,
                            ),
                            acceptButtonName: "OK", // Ensuring the button text is OK or any label you prefer
                            acceptTextColor: Colors.white, // Setting button text color to white
                          ),
                        );
                      } else {
                        // Show the regular error dialog for other errors
                        UiUtils.noPackageAvailableDialog(context);
                      }
                    }
                    if (state is FetchUserPackageLimitPending) {
                      UiUtils.showBlurredDialoge(
                        context,
                        dialoge: BlurredDialogBox(
                          onAccept: () async {
                            // Just close the dialog without returning anything
                            // and use async to ensure it works as Future
                            Navigator.of(context).pop();
                          },
                          svgImagePath: AppIcons.notification,
                          svgImageColor: context.color.territoryColor,
                          showCancelButton: false,
                          title: "Pending".translate(context),
                          content: CustomText(
                            state.message,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (state is FetchUserPackageLimitInSuccess) {
                      Navigator.pushNamed(context, Routes.selectPostTypeScreen);
                    }
                  },
                  child: Transform(
                    transform: Matrix4.identity()..translate(0.toDouble(), -20),
                    child: InkWell(
                      onTap: () async {
                        UiUtils.checkUser(
                            onNotGuest: () {
                              context.read<FetchUserPackageLimitCubit>().fetchUserPackageLimit(packageType: "item_listing");
                            },
                            context: context);
                      },
                      child: SizedBox(
                        width: 53,
                        height: 58,
                        child: svgLoaded == false
                            ? Container()
                            : SvgPicture.string(
                                svgEdit.toSVGString() ?? "",
                              ),
                      ),
                    ),
                  ),
                )
              : SizedBox(width: 10), // Fixed spacing when not a provider
          buildBottomNavigationbarItem(
            2,
            isClient ? AppIcons.favoriteNav : AppIcons.myAdsNav,
            isClient ? AppIcons.favoriteNavActive : AppIcons.myAdsNavActive,
            isClient ? "favorites".translate(context) : "myAdsTab".translate(context),
          ),
          buildBottomNavigationbarItem(3, AppIcons.profileNav, AppIcons.profileNavActive, "profileTab".translate(context))
        ]),
      ),
    );
  }

  Widget buildBottomNavigationbarItem(
    int index,
    String svgImage,
    String activeSvg,
    String title,
  ) {
    // Define a consistent size for all icons
    const double iconSize = 24.0;

    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
          onTap: () => onItemTapped(index),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (index == 0)
                // Home icon - use the PNG logo
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: Image.asset(
                    'assets/images/letter-logo.png',
                    width: iconSize,
                    height: iconSize,
                    color: currentTab == index ? context.color.territoryColor : context.color.textLightColor.darken(30),
                  ),
                )
              else if (currentTab == index)
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: UiUtils.getSvg(
                    activeSvg,
                    color: context.color.territoryColor,
                  ),
                )
              else
                SizedBox(
                  width: iconSize,
                  height: iconSize,
                  child: UiUtils.getSvg(
                    svgImage,
                    color: context.color.textLightColor.darken(30),
                  ),
                ),
              const SizedBox(height: 4),
              CustomText(
                title,
                textAlign: TextAlign.center,
                fontSize: context.font.smaller,
                color: currentTab == index ? context.color.textDefaultColor : context.color.textLightColor.darken(30),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
