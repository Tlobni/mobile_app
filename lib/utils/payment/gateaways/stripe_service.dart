import 'package:eClassify/app/app_theme.dart';
import 'package:eClassify/data/cubits/system/app_theme_cubit.dart';
import 'package:eClassify/settings.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';

class StripeService {
  // static BuildContext? currContext;
  static String paymentIntentSuccessResponse = "succeeded";

  static void initStripe(String? stripeId, String? stripeMode) async {
    // if (AppSettings.stripeStatus == 1) {
    //   Stripe.publishableKey = stripeId ?? '';
    //   Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    //   Stripe.urlScheme = 'flutterstripe';
    //   await Stripe.instance.applySettings();
    // }
  }

  static dynamic payWithPaymentSheet({
    required BuildContext context,
    String amount = "0",
    String currency = 'INR',
    String clientSecret = '',
    String paymentIntentId = '',
    String merchantDisplayName = "",
  }) async {
    try {
      // currContext = bcontext;
      //setting up Payment Sheet
      // await Stripe.instance.initPaymentSheet(
      //   paymentSheetParameters: SetupPaymentSheetParameters(
      //     paymentIntentClientSecret: clientSecret,
      //     style: context.read<AppThemeCubit>().state.appTheme == AppTheme.dark
      //         ? ThemeMode.dark
      //         : ThemeMode.light,
      //     billingDetailsCollectionConfiguration:
      //         const BillingDetailsCollectionConfiguration(
      //             address: AddressCollectionMode.full,
      //             email: CollectionMode.always,
      //             name: CollectionMode.always,
      //             phone: CollectionMode.always),
      //     merchantDisplayName: merchantDisplayName,
      //   ),
      // );

      //open payment sheet
      displayPaymentSheet(context);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  static void displayPaymentSheet(BuildContext context) async {
    try {
      // await Stripe.instance.presentPaymentSheet();

      HelperUtils.showSnackBarMessage(
          Constant.navigatorKey.currentContext!,
          "paymentSuccessfullyCompleted"
              .translate(Constant.navigatorKey.currentContext!));
      Future.delayed(Duration.zero, () {
        Navigator.pop(Constant.navigatorKey.currentContext!);
      });
    } on Exception catch (e) {
      // if (e is StripeException) {
      //   HelperUtils.showSnackBarMessage(Constant.navigatorKey.currentContext!,
      //       'Error from Stripe: ${e.error.localizedMessage}');
      // } else {
      //   HelperUtils.showSnackBarMessage(
      //       Constant.navigatorKey.currentContext!, 'Unforeseen error: ${e}');
      // }
    }
  }

  static StripeTransactionResponse getPlatformExceptionErrorResult(err) {
    String message = "Something went wrong";
    if (err.code == 'cancelled') {
      message = "Transaction is cancelled";
    }
    return StripeTransactionResponse(
      message: message,
      success: false,
      status: 'cancelled',
    );
  }
}

class StripeTransactionResponse {
  final String? message, status;
  bool? success;

  StripeTransactionResponse({this.message, this.success, this.status});
}
