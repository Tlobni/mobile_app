import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/app/routes.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/data/cubits/system/fetch_system_settings_cubit.dart';
import 'package:eClassify/data/model/system_settings_model.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/hive_keys.dart';
import 'package:eClassify/utils/hive_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hive/hive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPageIndex = 0;
  int previousePageIndex = 0;
  double changedOnPageScroll = 0.5;
  double currentSwipe = 0;
  late int totalPages;
  double x = 0;
  double y = 0;
  ValueNotifier<Offset> valuess = ValueNotifier(const Offset(0, 0));

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List slidersList = [
      {
        'svg': "assets/svg/Illustrators/onbo_a.svg",
        'title': "onboarding_1_title".translate(context),
        'description': "onboarding_1_des".translate(context),
      },
      {
        'svg': "assets/svg/Illustrators/onbo_b.svg",
        'title': "onboarding_2_title".translate(context),
        'description': "onboarding_2_des".translate(context),
      },
      {
        'svg': "assets/svg/Illustrators/onbo_c.svg",
        'title': "onboarding_3_title".translate(context),
        'description': "onboarding_3_des".translate(context),
      },
    ];

    totalPages = slidersList.length;

    double heightFactor = 0.79;
    return AnnotatedRegion(
      value: UiUtils.getSystemUiOverlayStyle(
        context: context,
        statusBarColor: context.color.secondaryColor,
      ),
      child: Scaffold(
          backgroundColor: context.color.backgroundColor,
          body: Column(
            children: [
              Stack(
                children: <Widget>[
                  Container(
                    height: context.screenHeight * (heightFactor + 0.05),
                  ),
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    child: ValueListenableBuilder(
                        valueListenable: valuess,
                        builder: (context, Offset value, c) {
                          return CustomPaint(
                            isComplex: true,
                            size: Size(
                              context.screenWidth,
                              context.screenHeight * heightFactor,
                            ),
                            painter: BottomCurvePainter(),
                          );
                        }),
                  ),
                  PositionedDirectional(
                      top: kPagingTouchSlop,
                      start: 26,
                      child: TextButton(
                          onPressed: () async {
                            context
                                .read<FetchSystemSettingsCubit>()
                                .fetchSettings();
                            Navigator.pushNamed(
                                context, Routes.languageListScreenRoute);
                          },
                          child: StreamBuilder(
                              stream: Hive.box(HiveKeys.languageBox)
                                  .watch(key: HiveKeys.currentLanguageKey),
                              builder:
                                  (context, AsyncSnapshot<BoxEvent> value) {
                                final defaultLanguage = context
                                    .watch<FetchSystemSettingsCubit>()
                                    .getSetting(SystemSetting.defaultLanguage)
                                    .toString()
                                    .firstUpperCase();

                                final languageCode =
                                    value.data?.value?['code'] ??
                                        defaultLanguage ??
                                        "En";

                                return Row(
                                  children: [
                                    CustomText(
                                      languageCode /*(value.data?.value == null ||
                                              defaultLanguage == "null")
                                          ? "En"
                                          : languageCode*/
                                      ,
                                      color: context.color.textColorDark,
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down_sharp,
                                      color: context.color.territoryColor,
                                    )
                                  ],
                                );
                              }))),
                  PositionedDirectional(
                      top: kPagingTouchSlop,
                      end: 26,
                      child: MaterialButton(
                          onPressed: () {
                            HiveUtils.setUserIsNotNew();
                            HiveUtils.setUserSkip();

                            Navigator.pushReplacementNamed(
                              context,
                              Routes.main,
                              arguments: {
                                "from": "login",
                                "isSkipped": true,
                              },
                            );
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          color:
                              context.color.forthColor.withValues(alpha: 0.102),
                          elevation: 0,
                          height: 28,
                          minWidth: 64,
                          child: CustomText(
                            "skip".translate(context),
                            color: context.color.forthColor,
                          ))),
                  Positioned.directional(
                      textDirection: Directionality.of(context),
                      top: kPagingTouchSlop + 50,
                      child: GestureDetector(
                        /* onHorizontalDragUpdate: (DragUpdateDetails details) {
                          currentSwipe = details.localPosition.direction;
                          setState(() {});
                        },
                        onHorizontalDragEnd: (details) {
                          if (currentSwipe < 0.9) {
                            if (changedOnPageScroll == 1 ||
                                changedOnPageScroll == 0.5) {
                              if (currentPageIndex > 0) {
                                currentPageIndex--;
                                changedOnPageScroll = 0;
                              }
                            }
                            //setState(() {});
                          } else {
                            if (currentPageIndex < totalPages) {
                              if (changedOnPageScroll == 0 ||
                                  changedOnPageScroll == 0.5) {
                                if (currentPageIndex < slidersList.length - 1) {
                                  currentPageIndex++;
                                } else {
                                  // Navigator.of(context).pushNamedAndRemoveUntil(
                                  //     Routes.login, (route) => false);
                                }
                                //setState(() {});
                              }
                            }
                          }

                          changedOnPageScroll = 0.5;
                          setState(() {});
                        },*/

                        onHorizontalDragUpdate: (DragUpdateDetails details) {
                          currentSwipe = details.localPosition.direction;
                          setState(() {});
                        },
                        onHorizontalDragEnd: (DragEndDetails details) {
                          if (currentSwipe < 0.9) {
                            if (changedOnPageScroll == 1 ||
                                changedOnPageScroll == 0.5) {
                              if (currentPageIndex > 0) {
                                currentPageIndex--;
                                changedOnPageScroll = 0;
                              }
                            }
                            //setState(() {});
                          } else {
                            if (currentPageIndex < totalPages) {
                              if (changedOnPageScroll == 0 ||
                                  changedOnPageScroll == 0.5) {
                                if (currentPageIndex < slidersList.length - 1) {
                                  currentPageIndex++;
                                } else {
                                  // Navigator.of(context).pushNamedAndRemoveUntil(
                                  //     Routes.login, (route) => false);
                                }
                                //setState(() {});
                              }
                            }
                          }

                          changedOnPageScroll = 0.5;
                          setState(() {});
                        },
                        child: SizedBox(
                          width: context.screenWidth,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Column(
                              children: <Widget>[
                                SizedBox(
                                  height: 60,
                                ),
                                SizedBox(
                                  width: context.screenWidth,
                                  height: 221,
                                  child: SvgPicture.asset(
                                      slidersList[currentPageIndex]['svg']),
                                ),
                                SizedBox(
                                  height: 39,
                                ),
                                SizedBox(
                                  width: context.screenWidth,
                                  child: CustomText(
                                    slidersList[currentPageIndex]['title'],
                                    fontSize: context.font.extraLarge,
                                    fontWeight: FontWeight.w600,
                                    color: context.color.textDefaultColor,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(
                                  height: 14,
                                ),
                                SizedBox(
                                  width: context.screenWidth,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 13),
                                    child: CustomText(
                                      slidersList[currentPageIndex]
                                          ['description'],
                                      textAlign: TextAlign.center,
                                      fontSize: context.font.larger,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 24,
                                ),
                                IndicatorBuilder(
                                  total: totalPages,
                                  selectedIndex: currentPageIndex,
                                )
                              ],
                            ),
                          ),
                        ),
                      )),
                  /* Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: kPagingTouchSlop + 50,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (DragUpdateDetails details) {
                        currentSwipe = details.primaryDelta?. ?? 0.0;
                      },
                      onHorizontalDragEnd: (DragEndDetails details) {
                        if (currentSwipe > 0) {
                          if (currentPageIndex < slidersList.length - 1) {
                            setState(() {
                              currentPageIndex++;
                            });
                          } else {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              Routes.login,
                              (route) => false,
                            );
                          }
                        } else if (currentSwipe < 0) {
                          if (currentPageIndex > 0) {
                            setState(() {
                              currentPageIndex--;
                            });
                          }
                        }
                      },
                      child: SizedBox(
                        width: context.screenWidth,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            children: <Widget>[
                              SizedBox(
                                height: 60,
                              ),
                              SizedBox(
                                width: context.screenWidth,
                                height: 221,
                                child: SvgPicture.asset(
                                    slidersList[currentPageIndex]['svg']),
                              ),
                              SizedBox(
                                height: 39,
                              ),
                              CustomText(slidersList[currentPageIndex]['title'])
                                  .size(context.font.extraLarge)
                                  .bold(weight: FontWeight.w600)
                                  .color(context.color.textDefaultColor),
                              SizedBox(
                                height: 14,
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 13),
                                child: CustomText(slidersList[currentPageIndex]
                                        ['description'])
                                    .centerAlign()
                                    .size(context.font.larger),
                              ),
                              SizedBox(
                                height: 24,
                              ),
                              IndicatorBuilder(
                                total: totalPages,
                                selectedIndex: currentPageIndex,
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),*/
                  Positioned.directional(
                      textDirection: Directionality.of(context),
                      top:
                          context.screenHeight * ((0.636 * heightFactor) / 0.7),
                      start: (context.screenWidth / 2) - 70 / 2,
                      child: GestureDetector(
                        onTap: () {
                          if (currentPageIndex < slidersList.length - 1) {
                            currentPageIndex++;
                          } else {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                                Routes.login, (route) => false);
                          }
                          HiveUtils.setUserIsNotNew();
                          setState(() {});
                        },
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                              color: context.color.forthColor,
                              boxShadow: context
                                          .watch<AppThemeCubit>()
                                          .state
                                          .appTheme ==
                                      AppTheme.dark
                                  ? null
                                  : [
                                      BoxShadow(
                                          color: context.color.forthColor
                                              .withValues(alpha: 0.8),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                          spreadRadius: 1)
                                    ],
                              shape: BoxShape.circle),
                          child: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                          ),
                        ),
                      )),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: context.watch<AppThemeCubit>().state.appTheme ==
                          AppTheme.dark
                      ? null
                      : [
                          BoxShadow(
                            color: context.color.territoryColor
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8), /*spreadRadius: 1*/
                          )
                        ],
                ),
                child: MaterialButton(
                    onPressed: () {
                      HiveUtils.setUserIsNotNew();
                      Navigator.of(context).pushNamedAndRemoveUntil(
                          Routes.login, (route) => false);
                    },
                    height: 56,
                    minWidth: 201,
                    color: context.color.territoryColor,
                    // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: CustomText(
                      currentPageIndex < slidersList.length - 1
                          ? "signIn".translate(context)
                          : "getStarted".translate(context),
                      color: context.color.buttonColor,
                      fontSize: context.font.larger,
                    )),
              ),
            ],
          )),
    );
  }
}

class IndicatorBuilder extends StatelessWidget {
  final int total;
  final int selectedIndex;

  const IndicatorBuilder(
      {super.key, required this.total, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemBuilder: (context, index) {
            return Container(
              width: selectedIndex == index ? 24 : 10,
              height: 10,
              decoration: BoxDecoration(
                  color: context.color.territoryColor,
                  borderRadius: BorderRadius.circular(6)),
            );
          },
          separatorBuilder: (context, index) {
            return const SizedBox(
              width: 7,
            );
          },
          itemCount: total),
    );
  }
}

// class RPSCustomPainter3 extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Path path_0 = Path();
//     path_0.moveTo(0.2, 0);
//     path_0.cubicTo(0.09000000000000001, 0, 0, 0.09, 0, 0.2);
//     path_0.lineTo(0, 0);
//     path_0.lineTo(0.2, 0);
//     path_0.close();
//     Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
//     paint_0_fill.color = Color(0xff606060).withValues(alpha: 1.0);
//     canvas.drawPath(path_0, paint_0_fill);
//     Path path_1 = Path();
//     path_1.moveTo(216, 0);
//     path_1.lineTo(216, 0.2);
//     path_1.cubicTo(216, 0.09000000000000001, 215.91, 0, 215.8, 0);
//     path_1.lineTo(216, 0);
//     path_1.close();
//     Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
//     paint_1_fill.color = Color(0xff606060).withValues(alpha: 1.0);
//     canvas.drawPath(path_1, paint_1_fill);
//     Path path_2 = Path();
//     path_2.moveTo(216, 0.2);
//     path_2.lineTo(216, 62.800000000000004);
//     path_2.cubicTo(216, 62.910000000000004, 215.91, 63.00000000000001, 215.8,
//         63.00000000000001);
//     path_2.lineTo(161.94, 63.00000000000001);
//     path_2.cubicTo(152.03, 63.00000000000001, 144, 54.91000000000001, 144,
//         45.00000000000001);
//     path_2.lineTo(144, 45.00000000000001);
//     path_2.cubicTo(144, 35.06000000000001, 139.97, 26.060000000000006, 133.46,
//         19.540000000000006);
//     path_2.cubicTo(126.94000000000001, 13.030000000000006, 117.94000000000001,
//         9.000000000000007, 108, 9.000000000000007);
//     path_2.cubicTo(88.12, 9.000000000000007, 72, 25.120000000000008, 72,
//         45.00000000000001);
//     path_2.lineTo(72, 45.00000000000001);
//     path_2.cubicTo(72, 54.91000000000001, 63.97, 63.00000000000001, 54.06,
//         63.00000000000001);
//     path_2.lineTo(0.2, 63.00000000000001);
//     path_2.cubicTo(0.09000000000000001, 63.00000000000001, 0,
//         62.910000000000004, 0, 62.800000000000004);
//     path_2.lineTo(0, 0.2);
//     path_2.cubicTo(0, 0.09000000000000001, 0.09, 0, 0.2, 0);
//     path_2.lineTo(215.79999999999998, 0);
//     path_2.cubicTo(
//         215.91, 0, 215.99999999999997, 0.09, 215.99999999999997, 0.2);
//     path_2.close();
//     Paint paint_2_fill = Paint()..style = PaintingStyle.fill;
//     paint_2_fill.color = Color(0xff606060).withValues(alpha: 1.0);
//     canvas.drawPath(path_2, paint_2_fill);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }
//
// class RPSCustomPainter2 extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
//     paint_0_fill.color = Color(0xff606060).withValues(alpha: 1.0);
//     canvas.drawRect(
//         Rect.fromLTWH(0, 0, size.width, size.height * 0.5555556), paint_0_fill);
//     Paint paint_1_fill = Paint()..style = PaintingStyle.fill;
//     paint_1_fill.color = Color(0xffffffff).withValues(alpha: 1.0);
//     canvas.drawRRect(
//         RRect.fromRectAndCorners(
//             Rect.fromLTWH(size.width * 0.3333333, size.height * 0.1111111,
//                 size.width * 0.3333333, size.height * 0.8888889),
//             bottomRight: Radius.circular(size.width * 0.1666667),
//             bottomLeft: Radius.circular(size.width * 0.1666667),
//             topLeft: Radius.circular(size.width * 0.1666667),
//             topRight: Radius.circular(size.width * 0.1666667)),
//         paint_1_fill);
//     Path path_2 = Path();
//     path_2.moveTo(144.2, 0);
//     path_2.lineTo(198.06, 0);
//     path_2.cubicTo(207.96, 0, 216, 8.04, 216, 17.94);
//     path_2.lineTo(216, 62.8);
//     path_2.cubicTo(216, 62.91, 215.91, 63, 215.8, 63);
//     path_2.lineTo(144.19, 63);
//     path_2.cubicTo(144.07999999999998, 63, 143.99, 62.91, 143.99, 62.8);
//     path_2.lineTo(143.99, 0.2);
//     path_2.cubicTo(144, 0.09, 144.09, 0, 144.2, 0);
//     path_2.close();
//     Paint paint_2_fill = Paint()..style = PaintingStyle.fill;
//     paint_2_fill.color = Color(0xff606060).withValues(alpha: 1.0);
//     canvas.drawPath(path_2, paint_2_fill);
//     Path path_3 = Path();
//     path_3.moveTo(0.2, 0);
//     path_3.lineTo(71.81, 0);
//     path_3.cubicTo(71.91, 0, 72, 0.09, 72, 0.2);
//     path_3.lineTo(72, 45.06);
//     path_3.cubicTo(72, 54.96, 63.96, 63, 54.06, 63);
//     path_3.lineTo(0.2, 63);
//     path_3.cubicTo(0.09, 63, 0, 62.91, 0, 62.8);
//     path_3.lineTo(0, 0.2);
//     path_3.cubicTo(0, 0.09, 0.09, 0, 0.2, 0);
//     path_3.close();
//     Paint paint_3_fill = Paint()..style = PaintingStyle.fill;
//     paint_3_fill.color = Color(0xff606060).withValues(alpha: 1.0);
//     canvas.drawPath(path_3, paint_3_fill);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }
//
// class MyPainter23 extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint();
//     Path path = Path();
//
//     // Path number 1
//
//     paint.color = Color(0xfffffffff);
//     path = Path();
//     path.lineTo(size.width, 0);
//     path.cubicTo(
//         size.width, 0, size.width, size.height, size.width, size.height);
//     path.cubicTo(size.width, size.height, size.width * 0.71, size.height,
//         size.width * 0.71, size.height);
//     path.cubicTo(size.width * 0.67, size.height, size.width * 0.63,
//         size.height * 0.98, size.width * 0.62, size.height * 0.95);
//     path.cubicTo(size.width * 0.61, size.height * 0.9, size.width / 2,
//         size.height * 0.88, size.width * 0.43, size.height * 0.91);
//     path.cubicTo(size.width * 0.4, size.height * 0.92, size.width * 0.39,
//         size.height * 0.94, size.width * 0.38, size.height * 0.95);
//     path.cubicTo(size.width * 0.38, size.height * 0.98, size.width * 0.34,
//         size.height, size.width * 0.29, size.height);
//     path.cubicTo(
//         size.width * 0.29, size.height, 0, size.height, 0, size.height);
//     path.cubicTo(0, size.height, 0, 0, 0, 0);
//     path.cubicTo(0, 0, size.width, 0, size.width, 0);
//     path.cubicTo(size.width, 0, size.width, 0, size.width, 0);
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return true;
//   }
// }

class BottomCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number 1

    paint.color = const Color(0xffffffff);
    path = Path();

    path.lineTo(0, 0);
    path.cubicTo(0, 0, 0, size.height, 0, size.height);
    path.cubicTo(0, size.height, size.width * 0.26, size.height,
        size.width * 0.26, size.height);
    path.cubicTo(size.width * 0.35, size.height, size.width * 0.36,
        size.height * 0.98, size.width * 0.38, size.height * 0.95);
    path.cubicTo(size.width * 0.38, size.height * 0.94, size.width * 0.41,
        size.height * 0.89, size.width / 2, size.height * 0.89);
    path.cubicTo(size.width * 0.58, size.height * 0.89, size.width * 0.6,
        size.height * 0.93, size.width * 0.61, size.height * 0.94);
    path.cubicTo(size.width * 0.63, size.height * 0.97, size.width * 0.63,
        size.height, size.width * 0.72, size.height);
    path.cubicTo(size.width * 0.72, size.height, size.width, size.height,
        size.width, size.height);
    path.cubicTo(size.width, size.height, size.width, 0, size.width, 0);
    path.cubicTo(size.width, 0, 0, 0, 0, 0);
    path.cubicTo(0, 0, 0, 0, 0, 0);
    canvas.drawShadow(
      path,
      Colors.grey.withValues(alpha: 0.1),
      6.0, // Shadow radius
      true, // Whether to include the shape itself in the shadow calculation
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

// class MyPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Paint paint = Paint();
//     Path path = Path();
//
//     // Path number 1
//
//     paint.color = Color(0xffffffff);
//     path = Path();
//     path.lineTo(0, 0);
//     path.cubicTo(0, 0, 0, size.height, 0, size.height);
//     path.cubicTo(0, size.height, size.width * 0.26, size.height,
//         size.width * 0.26, size.height);
//     path.cubicTo(size.width * 0.35, size.height, size.width * 0.37,
//         size.height * 0.97, size.width * 0.38, size.height * 0.95);
//     path.cubicTo(size.width * 0.39, size.height * 0.91, size.width * 0.42,
//         size.height * 0.9, size.width * 0.47, size.height * 0.89);
//     path.cubicTo(size.width * 0.48, size.height * 0.89, size.width * 0.49,
//         size.height * 0.89, size.width * 0.49, size.height * 0.89);
//     path.cubicTo(size.width / 2, size.height * 0.89, size.width * 0.51,
//         size.height * 0.89, size.width * 0.52, size.height * 0.89);
//     path.cubicTo(size.width * 0.58, size.height * 0.9, size.width * 0.6,
//         size.height * 0.93, size.width * 0.61, size.height * 0.94);
//     path.cubicTo(size.width * 0.63, size.height * 0.97, size.width * 0.63,
//         size.height, size.width * 0.72, size.height);
//     path.cubicTo(size.width * 0.72, size.height, size.width, size.height,
//         size.width, size.height);
//     path.cubicTo(size.width, size.height, size.width, 0, size.width, 0);
//     path.cubicTo(size.width, 0, 0, 0, 0, 0);
//     path.cubicTo(0, 0, 0, 0, 0, 0);
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) {
//     return true;
//   }
// }
//
// class RPSCustomPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     Path path_0 = Path();
//     path_0.moveTo(size.width * 1.050481, size.height * -0.7872098);
//     path_0.lineTo(size.width * 1.050606, size.height * 0.2127179);
//     path_0.lineTo(size.width * 0.7604024, size.height * 0.2127179);
//     path_0.arcToPoint(Offset(size.width * 0.6697437, size.height * 0.1667258),
//         radius: Radius.elliptical(
//             size.width * 0.09141329, size.height * 0.05269873),
//         rotation: 0,
//         largeArc: false,
//         clockwise: true);
//     path_0.arcToPoint(Offset(size.width * 0.4279703, size.height * 0.1667258),
//         radius:
//             Radius.elliptical(size.width * 0.1221359, size.height * 0.07040998),
//         rotation: 0,
//         largeArc: false,
//         clockwise: false);
//     path_0.arcToPoint(Offset(size.width * 0.3372983, size.height * 0.2127179),
//         radius: Radius.elliptical(
//             size.width * 0.09141329, size.height * 0.05269873),
//         rotation: 0,
//         largeArc: false,
//         clockwise: true);
//     path_0.lineTo(size.width * 0.05074220, size.height * 0.2126426);
//     path_0.lineTo(size.width * 0.05061688, size.height * -0.7872852);
//     path_0.close();
//
//     Paint paint_0_fill = Paint()..style = PaintingStyle.fill;
//     paint_0_fill.color = Color(0xffffffff).withValues(alpha: 1.0);
//     canvas.drawPath(path_0, paint_0_fill);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }
//
// class LongPressWidget extends StatefulWidget {
//   final VoidCallback onLongPress;
//   final Widget child;
//
//   LongPressWidget({required this.onLongPress, required this.child});
//
//   @override
//   _LongPressWidgetState createState() => _LongPressWidgetState();
// }
//
// class _LongPressWidgetState extends State<LongPressWidget> {
//   bool isLongPressing = false;
//
//   void _startLongPress() {
//     setState(() {
//       isLongPressing = true;
//     });
//
//     const Duration interval = Duration(milliseconds: 100);
//
//     Timer.periodic(interval, (Timer timer) {
//       if (!isLongPressing) {
//         timer.cancel();
//       } else {
//         widget.onLongPress();
//       }
//     });
//   }
//
//   void _endLongPress() {
//     setState(() {
//       isLongPressing = false;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onLongPress: _startLongPress,
//       onLongPressUp: _endLongPress,
//       child: widget.child,
//     );
//   }
// }
//
// //
// class InvertedUPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.blue // Set your desired color
//       ..style = PaintingStyle.fill;
//
//     final Path path = Path();
//     path.moveTo(0, 0);
//     path.lineTo(0, size.height);
//
//     path.lineTo((size.width / 2) - 50, size.height);
//     // path.cubicTo(
//     //     (size.width / 2) - 50,
//     //     size.height - 100,
//     //     (size.width / 2) + 100,
//     //     size.height - 100,
//     //     (size.width / 2) + 100,
//     //     size.height);
//     path.quadraticBezierTo(x1, y1, x2, y2);
//
//     path.lineTo(size.width, 0);
//
//     path.close();
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

// class InvertedUPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final shadowPaint = Paint()
//       ..color = Colors.grey // Set your shadow color
//       ..style = PaintingStyle.fill
//       ..maskFilter =
//           MaskFilter.blur(BlurStyle.normal, 10.0); // Set the blur radius
//
//     final paint = Paint()
//       ..color = Colors.blue // Set your desired color
//       ..style = PaintingStyle.fill;
//
//     final path = Path()
//       ..moveTo(0, size.height)
//       ..lineTo(0, size.height / 2)
//       ..quadraticBezierTo(size.width / 2, 0, size.width, size.height / 2)
//       ..lineTo(size.width, size.height)
//       ..close();
//
//     canvas.drawPath(path, shadowPaint);
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }
