import 'dart:async';
import 'dart:developer';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/system/fetch_language_cubit.dart';
import 'package:tlobni/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:tlobni/data/cubits/system/language_cubit.dart';
import 'package:tlobni/data/model/system_settings_model.dart';
import 'package:tlobni/settings.dart';
import 'package:tlobni/ui/screens/widgets/errors/no_internet.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/hive_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({this.itemSlug, super.key});

  //Used when the app is terminated and then is opened using deep link, in which case
  //the main route needs to be added to navigation stack, previously it directly used to
  //push adDetails route.
  final String? itemSlug;
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool isTimerCompleted = false;
  bool isSettingsLoaded = false; //TODO: temp
  bool isLanguageLoaded = false;
  late StreamSubscription<List<ConnectivityResult>> subscription;
  bool hasInternet = true;
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    //locationPermission();
    super.initState();
    _initializeVideo();

    // Check initial connectivity state
    Connectivity().checkConnectivity().then((result) {
      setState(() {
        hasInternet = (!result.contains(ConnectivityResult.none));
      });

      if (hasInternet) {
        context
            .read<FetchSystemSettingsCubit>()
            .fetchSettings(forceRefresh: true);
        startTimer();
      }
    });

    // Listen for connectivity changes
    subscription = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        hasInternet = (!result.contains(ConnectivityResult.none));
      });
      if (hasInternet) {
        context
            .read<FetchSystemSettingsCubit>()
            .fetchSettings(forceRefresh: true);
        startTimer();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    subscription.cancel();
    super.dispose();
  }

  Future getDefaultLanguage(String code) async {
    try {
      if (HiveUtils.getLanguage() == null ||
          HiveUtils.getLanguage()?['data'] == null) {
        context.read<FetchLanguageCubit>().getLanguage(code);
      } else if (HiveUtils.isUserFirstTime() == true &&
          code != HiveUtils.getLanguage()?['code']) {
        context.read<FetchLanguageCubit>().getLanguage(code);
      } else {
        isLanguageLoaded = true;
        setState(() {});
      }
    } catch (e) {
      log("Error while load default language $e");
      // Set isLanguageLoaded to true to prevent getting stuck
      isLanguageLoaded = true;
      setState(() {});
    }
  }

  Future<void> startTimer() async {
    Timer(const Duration(seconds: 1), () {
      isTimerCompleted = true;
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeVideo() async {
    _controller = VideoPlayerController.asset('assets/videos/splashscreen.mp4');
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      await _controller.play();
      setState(() {
        _isVideoInitialized = true;
      });
    } catch (e) {
      log("Error initializing video: $e");
    }
  }

  void navigateCheck() {
    if (isTimerCompleted && isSettingsLoaded && isLanguageLoaded) {
      navigateToScreen();
    }
  }

  void navigateToScreen() async {
    if (context
            .read<FetchSystemSettingsCubit>()
            .getSetting(SystemSetting.maintenanceMode) ==
        "1") {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.maintenanceMode);
        }
      });
    } else if (HiveUtils.isUserFirstTime() == true) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.onboarding);
        }
      });
    } else if (HiveUtils.isUserAuthenticated()) {
      // If user is authenticated, they should go directly to the main screen
      // regardless of their profile completion status
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // We pass slug only when the user is authenticated otherwise drop the slug
          Navigator.of(context).pushReplacementNamed(Routes.main,
              arguments: {'from': "main", "slug": widget.itemSlug});
        }
      });
    } else {
      // User is not authenticated and not first time
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          if (HiveUtils.isUserSkip() == true) {
            Navigator.of(context)
                .pushReplacementNamed(Routes.main, arguments: {'from': "main"});
          } else {
            Navigator.of(context).pushReplacementNamed(Routes.welcome);
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    navigateCheck();
    return hasInternet
        ? BlocListener<FetchLanguageCubit, FetchLanguageState>(
            listener: (context, state) {
              if (state is FetchLanguageSuccess) {
                Map<String, dynamic> map = state.toMap();

                var data = map['file_name'];
                map['data'] = data;
                map.remove("file_name");

                HiveUtils.storeLanguage(map);
                context.read<LanguageCubit>().changeLanguages(map);
                isLanguageLoaded = true;
                if (mounted) {
                  setState(() {});
                }
              } else if (state is FetchLanguageFailure) {
                // Handle language fetch failure
                log("Failed to fetch language: ${state.errorMessage}");
                isLanguageLoaded = true;
                if (mounted) {
                  setState(() {});
                }
              }
            },
            child: BlocListener<FetchSystemSettingsCubit,
                FetchSystemSettingsState>(
              listener: (context, state) {
                if (state is FetchSystemSettingsSuccess) {
                  Constant.isDemoModeOn = context
                      .read<FetchSystemSettingsCubit>()
                      .getSetting(SystemSetting.demoMode);
                  getDefaultLanguage(
                      state.settings['data']['default_language']);
                  isSettingsLoaded = true;
                  setState(() {});
                }
                if (state is FetchSystemSettingsFailure) {
                  log("Failed to fetch system settings: ${state.errorMessage}");
                  isSettingsLoaded = true;
                  isLanguageLoaded = true;
                  setState(() {});
                }
              },
              child: AnnotatedRegion(
                value: SystemUiOverlayStyle(
                  statusBarColor: context.color.primaryColor,
                ),
                child: Scaffold(
                  backgroundColor: context.color.primaryColor,
                  body: Stack(
                    children: [
                      if (_isVideoInitialized)
                        Center(
                          child: AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          ),
                        ),
                      // Column(
                      //   crossAxisAlignment: CrossAxisAlignment.center,
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      //     Align(
                      //       alignment: AlignmentDirectional.center,
                      //       child: Padding(
                      //         padding: EdgeInsets.only(top: 10.0),
                      //         child: SizedBox(
                      //           width: 150,
                      //           height: 150,
                      //         ),
                      //       ),
                      //     ),
                      //     Padding(
                      //       padding: EdgeInsets.only(top: 10.0),
                      //       child: Column(
                      //         children: [
                      //           CustomText(
                      //             AppSettings.applicationName,
                      //             fontSize: context.font.xxLarge,
                      //             color: context.color.secondaryColor,
                      //             textAlign: TextAlign.center,
                      //             fontWeight: FontWeight.w600,
                      //           ),
                      //           CustomText(
                      //             "\"${"buyAndSellAnything".translate(context)}\"",
                      //             fontSize: context.font.smaller,
                      //             color: context.color.secondaryColor,
                      //             textAlign: TextAlign.center,
                      //           )
                      //         ],
                      //       ),
                      //     ),
                      //   ],
                      // ),
                   
                    ],
                  ),
                ),
              ),
            ),
          )
        : NoInternet(
            onRetry: () {
              setState(() {});
            },
          );
  }
}
