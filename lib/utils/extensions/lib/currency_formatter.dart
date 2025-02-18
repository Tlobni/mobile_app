import 'package:eClassify/utils/constant.dart';
import 'package:intl/intl.dart';

extension CurrencyFormatter on double {
  String get currencyFormat => Constant.currencyPositionIsLeft
      ? '${Constant.currencySymbol} ${NumberFormat('#,##0.00', Constant.currentLocale).format(this)}'
      : '${NumberFormat('#,##0.00', Constant.currentLocale).format(this)} ${Constant.currencySymbol}';
}
