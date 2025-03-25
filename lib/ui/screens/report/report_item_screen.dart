import 'package:tlobni/data/cubits/report/fetch_item_report_reason_list.dart';
import 'package:tlobni/data/cubits/report/item_report_cubit.dart';
import 'package:tlobni/data/model/report_item/reason_model.dart';
import 'package:tlobni/ui/theme/theme.dart';
import 'package:tlobni/utils/custom_text.dart';
import 'package:tlobni/utils/extensions/extensions.dart';
import 'package:tlobni/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportItemScreen extends StatefulWidget {
  final int itemId;

  const ReportItemScreen({Key? key, required this.itemId}) : super(key: key);

  @override
  State<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends State<ReportItemScreen> {
  List<ReportReason>? reasons = [];
  late int selectedId;
  final TextEditingController _reportmessageController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void initState() {
    reasons = context.read<FetchItemReportReasonsListCubit>().getList() ?? [];

    if (reasons?.isEmpty ?? true) {
      selectedId = -10;
    } else {
      selectedId = reasons!.first.id;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottomPadding = MediaQuery.of(context).viewInsets.bottom - 50;
    bool isBottomPaddingNagative = bottomPadding.isNegative;

    return BlocListener<ItemReportCubit, ItemReportState>(
      listener: (context, state) {
        if (state is ItemReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(state.error.toString()),
            ),
          );
        }
        if (state is ItemReportInSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: CustomText(state.responseMessage),
            ),
          );
        }
      },
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  "reportItem".translate(context),
                  fontSize: context.font.larger,
                ),
                const SizedBox(
                  height: 15,
                ),
                ListView.separated(
                  shrinkWrap: true,
                  itemCount: reasons?.length ?? 0,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 10);
                  },
                  itemBuilder: (context, index) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        setState(() {
                          selectedId = reasons![index].id;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.color.primaryColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selectedId == reasons![index].id
                                ? context.color.territoryColor
                                : context.color.borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: CustomText(
                            reasons![index].reason.firstUpperCase(),
                            color: selectedId == reasons![index].id
                                ? context.color.territoryColor
                                : context.color.textColorDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (selectedId.isNegative)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      bottom: isBottomPaddingNagative ? 0 : bottomPadding,
                      start: 0,
                      end: 0,
                    ),
                    child: TextFormField(
                      maxLines: null,
                      controller: _reportmessageController,
                      cursorColor: context.color.territoryColor,
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return "addReportReason".translate(context);
                        } else {
                          return null;
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "writeReasonHere".translate(context),
                        focusColor: context.color.territoryColor,
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: context.color.territoryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(
                  height: 14,
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MaterialButton(
                        height: 40,
                        minWidth: 104,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(
                            color: context.color.borderColor,
                            width: 1.5,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: CustomText("cancelLbl".translate(context),
                            color: context.color.territoryColor),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      MaterialButton(
                        height: 40,
                        minWidth: 104,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        color: context.color.territoryColor,
                        onPressed: () async {
                          if (selectedId.isNegative) {
                            if (_formKey.currentState!.validate()) {
                              context.read<ItemReportCubit>().report(
                                    item_id: widget.itemId,
                                    reason_id: selectedId,
                                    message: _reportmessageController.text,
                                  );
                            }
                          } else {
                            context.read<ItemReportCubit>().report(
                                  item_id: widget.itemId,
                                  reason_id: selectedId,
                                );
                            Navigator.pop(context);
                          }
                        },
                        child: CustomText(
                          "report".translate(context),
                          color: context.color.buttonColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
