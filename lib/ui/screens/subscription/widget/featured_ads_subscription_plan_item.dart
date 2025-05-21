import 'dart:io';

import 'package:tlobni/data/cubits/subscription/assign_free_package_cubit.dart';
import 'package:tlobni/data/cubits/subscription/get_payment_intent_cubit.dart';
import 'package:tlobni/data/helper/widgets.dart';
import 'package:tlobni/data/model/subscription_pacakage_model.dart';
import 'package:tlobni/settings.dart';
import 'package:tlobni/ui/screens/subscription/payment_gatways.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/app_icon.dart';
import 'package:tlobni/utils/constant.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/extensions/lib/currency_formatter.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:tlobni/utils/payment/gateaways/inapp_purchase_manager.dart';
import 'package:tlobni/utils/payment/gateaways/payment_webview.dart';
import 'package:tlobni/utils/payment/gateaways/stripe_service.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeaturedAdsSubscriptionPlansItem extends StatefulWidget {
  final List<SubscriptionPackageModel> modelList;
  final InAppPurchaseManager inAppPurchaseManager;

  const FeaturedAdsSubscriptionPlansItem({
    super.key,
    required this.modelList,
    required this.inAppPurchaseManager,
  });

  @override
  _FeaturedAdsSubscriptionPlansItemState createState() => _FeaturedAdsSubscriptionPlansItemState();
}

class _FeaturedAdsSubscriptionPlansItemState extends State<FeaturedAdsSubscriptionPlansItem> {
  String? _selectedGateway;
  int? selectedIndex;

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

  Widget mainUi() {
    return Container(
      height: MediaQuery.of(context).size.height,
      margin: EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Card(
        color: context.color.secondaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
        ),
        elevation: 0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start, //temp
          children: [
            SizedBox(
              height: 50,
            ),
            UiUtils.getSvg(AppIcons.featuredAdsIcon),
            SizedBox(
              height: 35,
            ),
            CustomText(
              "featureAd".translate(context),
              fontWeight: FontWeight.w600,
              fontSize: context.font.larger,
            ),
            Expanded(
              child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  itemBuilder: (context, index) {
                    return itemData(index);
                  },
                  itemCount: widget.modelList.length),
            ),
            if (selectedIndex != null)
              Builder(builder: (context) {
                return BlocListener<GetPaymentIntentCubit, GetPaymentIntentState>(
                  listener: (context, state) {
                    if (state is GetPaymentIntentInSuccess) {
                      Widgets.hideLoder(context);

                      if (_selectedGateway == "stripe") {
                        PaymentGateways.stripe(context,
                            price: widget.modelList[selectedIndex!].finalPrice!.toDouble(),
                            packageId: widget.modelList[selectedIndex!].id!,
                            paymentIntent: state.paymentIntent);
                      } else if (_selectedGateway == "paystack") {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PaymentWebView(
                            authorizationUrl: state.paymentIntent["payment_gateway_response"]["data"]["authorization_url"],
                            reference: state.paymentIntent["payment_gateway_response"]["data"]["reference"],
                            onSuccess: (reference) {
                              HelperUtils.showSnackBarMessage(context, "paymentSuccessfullyCompleted".translate(context));
                              // Handle successful payment
                            },
                            onFailed: (reference) {
                              HelperUtils.showSnackBarMessage(context, "purchaseFailed".translate(context));
                              // Handle failed payment
                            },
                            onCancel: () {
                              HelperUtils.showSnackBarMessage(context, "subscriptionsCancelled".translate(context));
                            },
                          ),
                        ));
                      } else if (_selectedGateway == "phonepe") {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PaymentWebView(
                            authorizationUrl: state.paymentIntent["payment_gateway_response"],
                            onSuccess: (reference) {
                              HelperUtils.showSnackBarMessage(context, "paymentSuccessfullyCompleted".translate(context));
                              // Handle successful payment
                            },
                            onFailed: (reference) {
                              HelperUtils.showSnackBarMessage(context, "purchaseFailed".translate(context));
                              // Handle failed payment
                            },
                            onCancel: () {
                              HelperUtils.showSnackBarMessage(context, "subscriptionsCancelled".translate(context));
                            },
                          ),
                        ));
                      } else if (_selectedGateway == "razorpay") {
                        PaymentGateways.razorpay(
                          orderId: state.paymentIntent["id"].toString(),
                          context: context,
                          packageId: widget.modelList[selectedIndex!].id!,
                          price: widget.modelList[selectedIndex!].finalPrice!.toDouble(),
                        );
                      }
                    }

                    if (state is GetPaymentIntentInProgress) {
                      Widgets.showLoader(context);
                    }

                    if (state is GetPaymentIntentFailure) {
                      Widgets.hideLoder(context);
                      HelperUtils.showSnackBarMessage(context, state.error.toString());
                    }
                  },
                  child: BlocListener<AssignFreePackageCubit, AssignFreePackageState>(
                      listener: (context, state) {
                        if (state is AssignFreePackageInSuccess) {
                          Widgets.hideLoder(context);
                          HelperUtils.showSnackBarMessage(context, state.responseMessage);
                          Navigator.pop(context);
                        }
                        if (state is AssignFreePackageFailure) {
                          Widgets.hideLoder(context);
                          HelperUtils.showSnackBarMessage(context, state.error.toString());
                        }
                        if (state is AssignFreePackageInProgress) {
                          Widgets.showLoader(context);
                        }
                      },
                      child: UiUtils.buildButton(context, onPressed: () {
                        UiUtils.checkUser(
                            onNotGuest: () {
                              if (!widget.modelList[selectedIndex!].isActive!) {
                                if (widget.modelList[selectedIndex!].finalPrice! > 0) {
                                  if (Platform.isIOS) {
                                    //_purchaseSubscription(widget.modelList[selectedIndex!]);
                                    widget.inAppPurchaseManager.buy(
                                        widget.modelList[selectedIndex!].iosProductId!, widget.modelList[selectedIndex!].id!.toString());
                                  } else {
                                    paymentGatewayBottomSheet().then((value) {
                                      context.read<GetPaymentIntentCubit>().getPaymentIntent(
                                          paymentMethod: _selectedGateway == "stripe"
                                              ? "Stripe"
                                              : _selectedGateway == "paystack"
                                                  ? "Paystack"
                                                  : _selectedGateway == "razorpay"
                                                      ? "Razorpay"
                                                      : "PhonePe",
                                          packageId: widget.modelList[selectedIndex!].id!);
                                    });
                                  }
                                } else {
                                  context.read<AssignFreePackageCubit>().assignFreePackage(packageId: widget.modelList[selectedIndex!].id!);
                                }
                              }
                            },
                            context: context);
                      },
                          radius: 10,
                          height: 46,
                          fontSize: context.font.large,
                          buttonColor: widget.modelList[selectedIndex!].isActive!
                              ? context.color.textLightColor.brighten(300)
                              : context.color.territoryColor,
                          textColor: widget.modelList[selectedIndex!].isActive!
                              ? context.color.textDefaultColor.withOpacity(0.3)
                              : context.color.secondaryColor,
                          buttonTitle: widget.modelList[selectedIndex!].finalPrice! > 0
                              ? "${"payLbl".translate(context)}\t${widget.modelList[selectedIndex!].finalPrice!.currencyFormat}"
                              : "purchaseThisPackage".translate(context),

                          //TODO: change title to Your Current Plan according to condition
                          outerPadding: const EdgeInsets.all(20))),
                );
              })
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AssignFreePackageCubit(),
        ),
        BlocProvider(
          create: (context) => GetPaymentIntentCubit(),
        ),
      ],
      child: Scaffold(
        backgroundColor: context.color.backgroundColor,
        body: mainUi(),
      ),
    );
  }

  Widget itemData(int index) {
    return Padding(
      padding: const EdgeInsets.only(top: 7.0),
      child: Stack(
        alignment: Alignment.topLeft,
        children: [
          if (widget.modelList[index].isActive!)
            Padding(
              padding: EdgeInsetsDirectional.only(start: 13.0),
              child: ClipPath(
                clipper: CapShapeClipper(),
                child: Container(
                  color: context.color.territoryColor,
                  width: MediaQuery.of(context).size.width / 3,
                  height: 17,
                  padding: EdgeInsets.only(top: 3),
                  child: CustomText('activePlanLbl'.translate(context),
                      color: context.color.secondaryColor, textAlign: TextAlign.center, fontWeight: FontWeight.w500, fontSize: 12),
                ),
              ),
            ),
          InkWell(
            onTap: !widget.modelList[index].isActive!
                ? () {
                    setState(() {
                      selectedIndex = index;
                    });
                  }
                : null,
            child: Container(
              margin: EdgeInsets.only(top: 17),
              padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                      color: widget.modelList[index].isActive! || index == selectedIndex
                          ? context.color.territoryColor
                          : context.color.textDefaultColor.withOpacity(0.1),
                      width: 1.5)),
              child: !widget.modelList[index].isActive! ? adsWidget(index) : activeAdsWidget(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget adsWidget(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                widget.modelList[index].name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    '${widget.modelList[index].limit == "unlimited" ? "unlimitedLbl".translate(context) : widget.modelList[index].limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    color: context.color.textDefaultColor.withOpacity(0.3),
                  ),
                  Flexible(
                    child: CustomText(
                      '${widget.modelList[index].duration.toString()}\t${"days".translate(context)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      color: context.color.textDefaultColor.withAlpha(50),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 10.0),
          child: CustomText(
            widget.modelList[index].finalPrice! > 0 ? widget.modelList[index].finalPrice!.currencyFormat : "free".translate(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget activeAdsWidget(int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                widget.modelList[index].name!,
                firstUpperCaseWidget: true,
                fontWeight: FontWeight.w600,
                fontSize: context.font.large,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: widget.modelList[index].limit == "unlimited"
                          ? "${"unlimitedLbl".translate(context)}\t${"adsLbl".translate(context)}\t\t·\t\t"
                          : '',
                      style: TextStyle(
                        color: context.color.textDefaultColor.withOpacity(0.3),
                      ),
                      children: [
                        if (widget.modelList[index].limit != "unlimited")
                          TextSpan(
                            text: '${widget.modelList[index].userPurchasedPackages![0].remainingItemLimit}',
                            style: TextStyle(color: context.color.textDefaultColor),
                          ),
                        if (widget.modelList[index].limit != "unlimited")
                          TextSpan(
                            text: '/${widget.modelList[index].limit.toString()}\t${"adsLbl".translate(context)}\t\t·\t\t',
                          ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: widget.modelList[index].duration == "unlimited"
                            ? "${"unlimitedLbl".translate(context)}\t${"days".translate(context)}"
                            : '',
                        style: TextStyle(
                          color: context.color.textDefaultColor.withOpacity(0.3),
                        ),
                        children: [
                          if (widget.modelList[index].duration != "unlimited")
                            TextSpan(
                              text: '${widget.modelList[index].userPurchasedPackages![0].remainingDays}',
                              style: TextStyle(color: context.color.textDefaultColor),
                            ),
                          if (widget.modelList[index].duration != "unlimited")
                            TextSpan(
                              text: '/${widget.modelList[index].duration.toString()}\t${"days".translate(context)}',
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(start: 10.0),
          child: CustomText(
            widget.modelList[index].finalPrice! > 0
                ? "${Constant.currencySymbol}${widget.modelList[index].finalPrice.toString()}"
                : "free".translate(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Future<void> paymentGatewayBottomSheet() async {
    List<PaymentGateway> enabledGateways = AppSettings.getEnabledPaymentGateways();

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
                          color: context.color.textDefaultColor.withOpacity(0.1),
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
                      fontWeight: FontWeight.bold,
                      fontSize: context.font.larger,
                      color: context.color.textDefaultColor,
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
                        isSelected: _localSelectedGateway == enabledGateways[index].type,
                        onSelect: (String? value) {
                          setState(() {
                            _localSelectedGateway = value;
                          });
                          Navigator.pop(context, value); // Return the selected value
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
      leading: UiUtils.getSvg(gatewayIcon(gateway.type), width: 23, height: 23, fit: BoxFit.contain),
      title: CustomText(gateway.name),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: context.color.territoryColor)
          : Icon(Icons.radio_button_unchecked, color: context.color.textDefaultColor.withOpacity(0.3)),
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
