import 'dart:io';

import 'package:eClassify/data/cubits/subscription/assign_free_package_cubit.dart';
import 'package:eClassify/data/cubits/subscription/get_payment_intent_cubit.dart';
import 'package:eClassify/data/helper/widgets.dart';
import 'package:eClassify/data/model/subscription_pacakage_model.dart';
import 'package:eClassify/settings.dart';
import 'package:eClassify/ui/screens/subscription/payment_gatways.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/extensions/lib/currency_formatter.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:eClassify/utils/payment/gateaways/payment_webview.dart';
import 'package:eClassify/utils/payment/gateaways/stripe_service.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' as intl;

class ItemListingSubscriptionPlansItem extends StatefulWidget {
  final int itemIndex, index;
  final SubscriptionPackageModel model;
  final InAppPurchaseManager inAppPurchaseManager;

  const ItemListingSubscriptionPlansItem({
    super.key,
    required this.itemIndex,
    required this.index,
    required this.model,
    required this.inAppPurchaseManager,
  });

  @override
  _ItemListingSubscriptionPlansItemState createState() =>
      _ItemListingSubscriptionPlansItemState();
}

class _ItemListingSubscriptionPlansItemState
    extends State<ItemListingSubscriptionPlansItem> {
  String? _selectedGateway;

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      if (AppSettings.stripeStatus == 1) {
        StripeService.initStripe(
          AppSettings.stripePublishableKey,
          "test",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      bottomNavigationBar: bottomWidget(),
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AssignFreePackageCubit(),
          ),
          BlocProvider(
            create: (context) => GetPaymentIntentCubit(),
          ),
        ],
        child: Builder(builder: (context) {
          return BlocListener<GetPaymentIntentCubit, GetPaymentIntentState>(
            listener: (context, state) {
              if (state is GetPaymentIntentInSuccess) {
                Widgets.hideLoder(context);

                if (_selectedGateway == "stripe") {
                  PaymentGateways.stripe(context,
                      price: widget.model.finalPrice!.toDouble(),
                      packageId: widget.model.id!,
                      paymentIntent: state.paymentIntent);
                } else if (_selectedGateway == "paystack") {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PaymentWebView(
                      authorizationUrl:
                          state.paymentIntent["payment_gateway_response"]
                              ["data"]["authorization_url"],
                      reference: state.paymentIntent["payment_gateway_response"]
                          ["data"]["reference"],
                      onSuccess: (reference) {
                        HelperUtils.showSnackBarMessage(context,
                            "paymentSuccessfullyCompleted".translate(context));
                        // Handle successful payment
                      },
                      onFailed: (reference) {
                        HelperUtils.showSnackBarMessage(
                            context, "purchaseFailed".translate(context));
                        // Handle failed payment
                      },
                      onCancel: () {
                        HelperUtils.showSnackBarMessage(context,
                            "subscriptionsCancelled".translate(context));
                      },
                    ),
                  ));
                } else if (_selectedGateway == "phonepe") {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => PaymentWebView(
                      authorizationUrl:
                          state.paymentIntent["payment_gateway_response"],
                      onSuccess: (reference) {
                        HelperUtils.showSnackBarMessage(context,
                            "paymentSuccessfullyCompleted".translate(context));
                        // Handle successful payment
                      },
                      onFailed: (reference) {
                        HelperUtils.showSnackBarMessage(
                            context, "purchaseFailed".translate(context));
                        // Handle failed payment
                      },
                      onCancel: () {
                        HelperUtils.showSnackBarMessage(context,
                            "subscriptionsCancelled".translate(context));
                      },
                    ),
                  ));
                } else if (_selectedGateway == "razorpay") {
                  PaymentGateways.razorpay(
                    orderId: state.paymentIntent["id"].toString(),
                    context: context,
                    packageId: widget.model.id!,
                    price: widget.model.finalPrice!.toDouble(),
                  );
                }
              }

              if (state is GetPaymentIntentInProgress) {
                Widgets.showLoader(context);
              }

              if (state is GetPaymentIntentFailure) {
                Widgets.hideLoder(context);
                HelperUtils.showSnackBarMessage(
                    context, state.error.toString());
              }
            },
            child: BlocListener<AssignFreePackageCubit, AssignFreePackageState>(
              listener: (context, state) {
                if (state is AssignFreePackageInSuccess) {
                  Widgets.hideLoder(context);
                  HelperUtils.showSnackBarMessage(
                      context, state.responseMessage);
                  Navigator.pop(context);
                }
                if (state is AssignFreePackageFailure) {
                  Widgets.hideLoder(context);
                  HelperUtils.showSnackBarMessage(
                      context, state.error.toString());
                }
                if (state is AssignFreePackageInProgress) {
                  Widgets.showLoader(context);
                }
              },
              child: Padding(
                padding: EdgeInsets.only(
                    top: (widget.index == widget.itemIndex) ? 40 : 70,
                    bottom: (widget.index == widget.itemIndex) ? 100 : 120),
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (widget.model.isActive!)
                      ClipPath(
                        clipper: CapShapeClipper(),
                        child: Container(
                          alignment: Alignment.center,
                          color: context.color.territoryColor,
                          width: MediaQuery.of(context).size.width / 1.6,
                          height: 33,
                          padding: EdgeInsets.only(top: 3),
                          child: CustomText('activePlanLbl'.translate(context),
                              color: context.color.secondaryColor,
                              textAlign: TextAlign.center,
                              fontWeight: FontWeight.w500,
                              fontSize: 15),
                        ),
                      ),
                    Card(
                      color: context.color.secondaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                              color: widget.model.isActive!
                                  ? context.color.territoryColor
                                  : context.color.secondaryColor,
                              width: 1.5)),
                      elevation: 0,
                      margin: EdgeInsets.fromLTRB(14, 33, 14, 0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start, //temp
                        children: [
                          SizedBox(height: 50),
                          ClipPath(
                            clipper: HexagonClipper(),
                            child: Container(
                              width: 100,
                              height: 110,
                              padding: EdgeInsets.all(30),

                              color: context.color.primaryColor,
                              //TODO: replace url below with model data response
                              child: UiUtils.imageType(widget.model.icon!,
                                  fit: BoxFit.contain),
                            ),
                          ),
                          SizedBox(height: 18),
                          widget.model.isActive! && widget.model.finalPrice! > 0
                              ? activeAdsData()
                              : adsData(),
                          const Spacer(),
                          CustomText(
                            widget.model.finalPrice! > 0
                                ? widget.model.finalPrice!.currencyFormat
                                : "free".translate(context),
                            fontSize: context.font.xxLarge,
                            fontWeight: FontWeight.bold,
                            color: context.color.textDefaultColor,
                          ),
                          if (widget.model.discount! > 0)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText(
                                    "${widget.model.discount}%\t${"OFF".translate(context)}",
                                    color: context.color.forthColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    " ${Constant.currencySymbol}${widget.model.price.toString()}",
                                    style: const TextStyle(
                                        decoration: TextDecoration.lineThrough),
                                  )
                                ],
                              ),
                            ),
                          UiUtils.buildButton(context, onPressed: () {
                            UiUtils.checkUser(
                                onNotGuest: () {
                                  if (!widget.model.isActive!) {
                                    if (widget.model.finalPrice! > 0) {
                                      if (Platform.isIOS) {
                                        widget.inAppPurchaseManager.buy(
                                            widget.model.iosProductId!,
                                            widget.model.id!.toString());
                                      } else {
                                        paymentGatewayBottomSheet()
                                            .then((value) {
                                          context
                                              .read<GetPaymentIntentCubit>()
                                              .getPaymentIntent(
                                                  paymentMethod:
                                                      _selectedGateway ==
                                                              "stripe"
                                                          ? "Stripe"
                                                          : _selectedGateway ==
                                                                  "paystack"
                                                              ? "Paystack"
                                                              : _selectedGateway ==
                                                                      "razorpay"
                                                                  ? "Razorpay"
                                                                  : "PhonePe",
                                                  packageId: widget.model.id!);
                                        });
                                      }
                                    } else {
                                      context
                                          .read<AssignFreePackageCubit>()
                                          .assignFreePackage(
                                              packageId: widget.model.id!);
                                    }
                                  }
                                },
                                context: context);
                          },
                              radius: 10,
                              height: 46,
                              fontSize: context.font.large,
                              buttonColor: widget.model.isActive!
                                  ? context.color.textLightColor.brighten(300)
                                  : context.color.territoryColor,
                              textColor: widget.model.isActive!
                                  ? context.color.textDefaultColor
                                      .withValues(alpha: 0.5)
                                  : context.color.secondaryColor,
                              buttonTitle: widget.model.isActive ?? false
                                  ? "purchased".translate(context)
                                  : "purchaseThisPackage".translate(context),

                              //TODO: change title to Your Current Plan according to condition
                              outerPadding: const EdgeInsets.all(20))
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget adsData() {
    return Expanded(
      flex: 10,
      child: ListView(
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        children: [
          CustomText(
            widget.model.name!,
            firstUpperCaseWidget: true,
            fontWeight: FontWeight.w600,
            fontSize: context.font.larger,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          if (widget.model.type == "item_listing")
            checkmarkPoint(context,
                "${widget.model.limit == "unlimited" ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${"adsListing".translate(context)}"),
          if (widget.model.type == "advertisement")
            checkmarkPoint(context,
                "${widget.model.limit == "unlimited" ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${"featuredAdsListing".translate(context)}"),
          checkmarkPoint(context,
              "${widget.model.duration.toString()}\t${"days".translate(context)}"),
          if (widget.model.description != null &&
              widget.model.description != "") ...[
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: CustomText(
                  widget.model.description!,
                  textAlign: TextAlign.start,
                  color: context.color.textDefaultColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget activeAdsData() {
    return Expanded(
      flex: 10,
      child: ListView(
        physics: BouncingScrollPhysics(),
        shrinkWrap: true,
        children: [
          CustomText(
            widget.model.name!,
            firstUpperCaseWidget: true,
            fontWeight: FontWeight.w600,
            fontSize: context.font.larger,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          if (widget.model.type == "item_listing")
            checkmarkPoint(context,
                "${widget.model.userPurchasedPackages![0].remainingItemLimit}/${widget.model.limit == "unlimited" ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${"adsListing".translate(context)}"),
          if (widget.model.type == "advertisement")
            checkmarkPoint(context,
                "${widget.model.userPurchasedPackages![0].remainingItemLimit}/${widget.model.limit == "unlimited" ? "unlimitedLbl".translate(context) : widget.model.limit.toString()}\t${"featuredAdsListing".translate(context)}"),
          checkmarkPoint(context,
              "${widget.model.userPurchasedPackages![0].remainingDays}/${widget.model.duration.toString()}\t${"days".translate(context)}"),
          if (widget.model.description != null &&
              widget.model.description != "")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomText(
                    widget.model.description!,
                    color:
                        context.color.textDefaultColor.withValues(alpha: 0.7),
                    textAlign: TextAlign.start,
                  )),
            ),
        ],
      ),
    );
  }

  SingleChildRenderObjectWidget bottomWidget() {
    if (widget.model.isActive! &&
        widget.model.finalPrice! > 0 &&
        widget.model.userPurchasedPackages != null &&
        widget.model.userPurchasedPackages![0].endDate != null) {
      DateTime dateTime =
          DateTime.parse(widget.model.userPurchasedPackages![0].endDate!);
      String formattedDate = intl.DateFormat.yMMMMd().format(dateTime);
      return Padding(
        padding: EdgeInsetsDirectional.only(
            bottom: 15.0,
            start: 15,
            end: 15), // EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        child: CustomText(
            "${"yourSubscriptionWillExpireOn".translate(context)} $formattedDate"),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget circlePoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        // mainAxisAlignment: MainAxisAlignment.start,
        // width: context.screenWidth * 0.55,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: 2.0),
            child: Icon(
              Icons.circle_rounded,
              size: 8,
            ),
          ),
          //  const Icon(Icons.check_box_rounded, size: 25.0, color: Colors.cyan), //TODO: change it to given icon and fill according to status passed
          SizedBox(width: 15),
          Expanded(
              child: CustomText(
            text,
            textAlign: TextAlign.start,
            color: context.color.textDefaultColor,
          )),
        ],
      ),
    );
  }

  Widget checkmarkPoint(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        // width: context.screenWidth * 0.55,
        children: [
          UiUtils.getSvg(
            AppIcons.active_mark,
            //(boolVariable) ? AppIcons.active_mark : AppIcons.deactive_mark,
          ),
          //  const Icon(Icons.check_box_rounded, size: 25.0, color: Colors.cyan), //TODO: change it to given icon and fill according to status passed
          SizedBox(width: 8),
          Expanded(
              child: CustomText(
            text,
            textAlign: TextAlign.start,
          )),
        ],
      ),
    );
  }

  Future<void> paymentGatewayBottomSheet() async {
    List<PaymentGateway> enabledGateways =
        AppSettings.getEnabledPaymentGateways();

    if (enabledGateways.isEmpty) {
      return;
    }

    String? selectedGateway = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.0),
          topRight: Radius.circular(18.0),
        ),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        String? _localSelectedGateway = _selectedGateway;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: context.color.secondaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: context.color.textDefaultColor
                              .withValues(alpha: 0.1),
                        ),
                        height: 6,
                        width: 60,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 5),
                    child: CustomText(
                      'selectPaymentMethod'.translate(context),
                      color: context.color.textDefaultColor,
                      fontWeight: FontWeight.bold,
                      fontSize: context.font.larger,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.only(top: 10),
                    itemCount: enabledGateways.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return PaymentMethodTile(
                        gateway: enabledGateways[index],
                        isSelected: _localSelectedGateway ==
                            enabledGateways[index].type,
                        onSelect: (String? value) {
                          setState(() {
                            _localSelectedGateway = value;
                          });
                          Navigator.pop(
                              context, value); // Return the selected value
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selectedGateway != null) {
      setState(() {
        _selectedGateway = selectedGateway;
      });
    }
  }
}

class PaymentMethodTile extends StatelessWidget {
  final PaymentGateway gateway;
  final bool isSelected;
  final ValueChanged<String?> onSelect;

  PaymentMethodTile({
    required this.gateway,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: UiUtils.getSvg(gatewayIcon(gateway.type),
          width: 23, height: 23, fit: BoxFit.contain),
      title: CustomText(gateway.name),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: context.color.territoryColor)
          : Icon(Icons.radio_button_unchecked,
              color: context.color.textDefaultColor.withValues(alpha: 0.5)),
      onTap: () => onSelect(gateway.type),
    );
  }

  String gatewayIcon(String type) {
    switch (type) {
      case 'stripe':
        return AppIcons.stripeIcon;
      case 'paystack':
        return AppIcons.paystackIcon;
      case 'razorpay':
        return AppIcons.razorpayIcon;
      case 'phonepe':
        return AppIcons.phonePeIcon;
      default:
        return "";
    }
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();

    path
      ..moveTo(size.width / 2, 0) // moving to topCenter 1st, then draw the path
      ..lineTo(size.width, size.height * .25)
      ..lineTo(size.width, size.height * .75)
      ..lineTo(size.width * .5, size.height)
      ..lineTo(0, size.height * .75)
      ..lineTo(0, size.height * .25)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class CapShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, size.height)
      ..cubicTo(
        size.width * 0.15,
        size.height,
        size.width * 0.1,
        size.height * 0.1,
        size.width * 0.25,
        size.height * 0.1,
      )
      ..lineTo(size.width * 0.75, size.height * 0.1)
      ..cubicTo(
        size.width * 0.9,
        size.height * 0.1,
        size.width * 0.85,
        size.height,
        size.width,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
