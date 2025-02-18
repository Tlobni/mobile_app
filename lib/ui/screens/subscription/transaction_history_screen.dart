import 'package:eClassify/data/cubits/utility/fetch_transactions_cubit.dart';
import 'package:eClassify/data/model/transaction_model.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/screens/widgets/intertitial_ads_screen.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TransactionHistory extends StatefulWidget {
  const TransactionHistory({super.key});

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return BlocProvider(
          create: (context) {
            return FetchTransactionsCubit();
          },
          child: const TransactionHistory(),
        );
      },
    );
  }

  @override
  State<TransactionHistory> createState() => _TransactionHistoryState();
}

class _TransactionHistoryState extends State<TransactionHistory> {
  late final ScrollController _pageScrollController = ScrollController();

  /* ..addListener(_pageScrollListener);*/

  @override
  void initState() {
    AdHelper.loadInterstitialAd();
    context.read<FetchTransactionsCubit>().fetchTransactions();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    AdHelper.showInterstitialAd();
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(context,
          showBackButton: true, title: "transactionHistory".translate(context)),
      body: BlocBuilder<FetchTransactionsCubit, FetchTransactionsState>(
        builder: (context, state) {
          if (state is FetchTransactionsInProgress) {
            return Center(
              child: UiUtils.progress(),
            );
          }
          if (state is FetchTransactionsFailure) {
            return const SomethingWentWrong();
          }
          if (state is FetchTransactionsSuccess) {
            if (state.transactionModel.isEmpty) {
              return NoDataFound(
                onTap: () {
                  context.read<FetchTransactionsCubit>().fetchTransactions();
                },
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _pageScrollController,
                    itemCount: state.transactionModel.length,
                    itemBuilder: (context, index) {
                      TransactionModel transaction =
                          state.transactionModel[index];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 15.0, horizontal: 16),
                        child: Container(
                            // height: 100,
                            decoration: BoxDecoration(
                                color: context.color.secondaryColor,
                                border: Border.all(
                                    color: context.color.borderColor,
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(10)),
                            child: customTransactionItem(context, transaction)),
                      );
                    },
                  ),
                ),
                if (state.isLoadingMore) UiUtils.progress()
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  Widget customTransactionItem(
      BuildContext context, TransactionModel transaction) {
    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 41,
              decoration: BoxDecoration(
                color: context.color.territoryColor,
                borderRadius: const BorderRadiusDirectional.only(
                  topEnd: Radius.circular(4),
                  bottomEnd: Radius.circular(4),
                ),
              ),
              // padding: const EdgeInsets.symmetric(vertical: 2.0),
              // margin: EdgeInsets.all(4),
              // height:,
            ),
            const SizedBox(
              width: 16,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: context.color.territoryColor
                            .withValues(alpha: 0.1)),
                    padding: EdgeInsets.symmetric(vertical: 3, horizontal: 7),
                    child: CustomText(
                      transaction.paymentGateway!,
                      fontSize: context.font.small,
                      color: context.color.territoryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          transaction.orderId != null
                              ? transaction.orderId.toString()
                              : "",
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CustomText(
                    transaction.createdAt.toString().formatDate(),
                    fontSize: context.font.small,
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () async {
                await HapticFeedback.vibrate();
                var clipboardData =
                    ClipboardData(text: transaction.orderId ?? "");
                Clipboard.setData(clipboardData).then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: CustomText("copied".translate(context)),
                    ),
                  );
                });
              },
              child: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                    color: context.color.secondaryColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: context.color.borderColor, width: 1.5)),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Icon(
                    Icons.copy,
                    size: context.font.larger,
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomText(
                  "${Constant.currencySymbol}\t${transaction.amount}",
                  fontWeight: FontWeight.w700,
                  color: context.color.territoryColor,
                ),
                const SizedBox(
                  height: 6,
                ),
                CustomText(
                    transaction.paymentStatus!.toString().firstUpperCase()),
              ],
            ),
          ],
        ),
      );
    });
  }
}
