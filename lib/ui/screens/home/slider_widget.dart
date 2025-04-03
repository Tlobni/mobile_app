/*
import 'dart:async';

import 'package:tlobni/data/repositories/item/item_repository.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/routes.dart';

import '../../../data/cubits/slider_cubit.dart';
import '../../../data/helper/widgets.dart';
import '../../../data/model/data_output.dart';

import '../../../utils/Extensions/extensions.dart';
import '../../../utils/helper_utils.dart';
import '../../../utils/responsiveSize.dart';
import '../../../utils/ui_utils.dart';
import 'home_screen.dart';
import 'package:url_launcher/url_launcher.dart' as urllauncher;

class SliderWidget extends StatefulWidget {
  const SliderWidget({super.key});

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<int> _bannerIndex = ValueNotifier(0);
  int bannersLength = 0;
  late Timer _timer;
  final PageController _pageController = PageController(
    initialPage: 0,
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_bannerIndex.value < bannersLength - 1) {
        _bannerIndex.value++;
      } else {
        _bannerIndex.value = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _bannerIndex.value,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _bannerIndex.dispose();
    _timer.cancel();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocConsumer<SliderCubit, SliderState>(
      listener: (context, state) {
        if ((state is SliderFetchFailure && !state.isUserDeactivated) ||
            state is SliderFetchSuccess) {
          // context.read<SliderCubit>().fetchSlider(context);
        }
      },
      builder: (context, SliderState state) {
        if (state is SliderFetchInProgress) {
          return Container();
        }
        if (state is SliderFetchSuccess) {
          if (state.sliderlist.isNotEmpty)
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: sidePadding),
              child: SizedBox(
                height: 170,
                child: ListView.builder(
                    itemCount: state.sliderlist.length,
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, int index) {
                      return InkWell(
                        onTap: () async {
                          if (state.sliderlist[index].thirdPartyLink != "") {
                            await urllauncher.launchUrl(
                                Uri.parse(
                                    state.sliderlist[index].thirdPartyLink!),
                                mode: LaunchMode.externalApplication);
                          } else {
                            try {
                              ItemRepository fetch = ItemRepository();

                              Widgets.showLoader(context);

                              DataOutput<ItemModel> dataOutput =
                                  await fetch.fetchItemFromItemId(
                                      state.sliderlist[index].itemId!);

                              Future.delayed(
                                Duration.zero,
                                () {
                                  Widgets.hideLoder(context);
                                  Navigator.pushNamed(
                                      context, Routes.adDetailsScreen,
                                      arguments: {
                                        "model": dataOutput.modelList[0],
                                      });
                                },
                              );
                            } catch (e) {
                              Widgets.hideLoder(context);
                              HelperUtils.showSnackBarMessage(context,
                                  "somethingWentWrng".translate(context));
                            }
                          }
                        },
                        child: Container(
                          height: 170,
                          clipBehavior: Clip.antiAlias,
                          width: context.screenWidth - (sidePadding * 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey.shade200,
                          ),
                          child: UiUtils.getImage(
                              state.sliderlist[index].image ?? "",
                              fit: BoxFit.cover),
                        ),
                      );
                    }),
              ),
            );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
*/

import 'dart:async';

import 'package:tlobni/app/routes.dart';
import 'package:tlobni/data/cubits/slider_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/model/item/item_model.dart';
import 'package:tlobni/data/repositories/item/item_repository.dart';
import 'package:tlobni/ui/screens/home/home_screen.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart' as urllauncher;
import 'package:url_launcher/url_launcher.dart';
// Import your SliderCubit and other necessary dependencies

class SliderWidget extends StatefulWidget {
  const SliderWidget({super.key});

  @override
  State<SliderWidget> createState() => _SliderWidgetState();
}

class _SliderWidgetState extends State<SliderWidget>
    with AutomaticKeepAliveClientMixin {
  final ValueNotifier<int> _bannerIndex = ValueNotifier(0);
  late Timer _timer;
  int bannersLength = 0;
  final PageController _pageController = PageController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _startAutoSlider();
  }

  @override
  void dispose() {
    super.dispose();
    _bannerIndex.dispose();
    _timer.cancel();
    _pageController.dispose();
  }

  void _startAutoSlider() {
    // Set up a timer to automatically change the banner index
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      final int nextPage = _bannerIndex.value + 1;
      if (nextPage < bannersLength) {
        _bannerIndex.value = nextPage;
      } else {
        _bannerIndex.value = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _bannerIndex.value,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocConsumer<SliderCubit, SliderState>(
      listener: (context, state) {
        if ((state is SliderFetchFailure && !state.isUserDeactivated) ||
            state is SliderFetchSuccess) {
          // context.read<SliderCubit>().fetchSlider(context);
        }
      },
      builder: (context, SliderState state) {
        if (state is SliderFetchInProgress) {
          return Container();
        }
        // Custom exclusive experiences slider for the design in the image
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: sidePadding),
          child: SizedBox(
            height: 190,
            child: ListView.builder(
              itemCount: 1, // Just one featured item as shown in the image
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, int index) {
                return Container(
                  margin: const EdgeInsets.only(right: 15),
                  width: MediaQuery.of(context).size.width - (sidePadding * 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFFAF6E9), // Light beige background
                  ),
                  child: Stack(
                    children: [
                      // Content of the card
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top "A ONCE IN A LIFETIME EXPERIENCE" Text
                            Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                "A ONCE IN A LIFETIME EXPERIENCE",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            // Middle Row with "COFFEE WITH A BUSINESS TYCOON" text
                            const Spacer(),
                            Text(
                              "COFFEE WITH",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              "A BUSINESS TYCOON",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                            // Bottom "BOOK NOW" Button
                            SizedBox(
                              width: 120,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: () {
                                  // Handle booking
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF152238), // Dark blue
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                                child: Text(
                                  "BOOK NOW",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Business person image
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 120,
                          height: 140,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.person_outline,
                            size: 60,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      // "2 SLOTS LEFT" badge
                      Positioned(
                        left: 0,
                        top: 45,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadiusDirectional.only(
                              topEnd: Radius.circular(5),
                              bottomEnd: Radius.circular(5),
                            ),
                          ),
                          child: Text(
                            "2 SLOTS LEFT!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Dots indicator
                      Positioned(
                        bottom: 10,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (dotIndex) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: dotIndex == 0
                                    ? Colors.black
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
