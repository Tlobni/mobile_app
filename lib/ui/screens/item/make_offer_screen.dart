/*
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/responsiveSize.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:eClassify/data/cubits/chat/get_buyer_chat_users_cubit.dart';
import 'package:eClassify/data/cubits/chat/make_an_offer_item_cubit.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../Utils/constant.dart';
import '../../../Utils/validator.dart';
import '../../../data/cubits/chatCubits/delete_message_cubit.dart';
import '../../../data/cubits/chatCubits/load_chat_messages.dart';
import '../../../data/cubits/chatCubits/send_message.dart';
import '../../../data/model/chat/chat_user_model.dart';
import '../Chat/chat_screen.dart';
import '../Widgets/AnimatedRoutes/blur_page_route.dart';

class MakeAnOfferItemScreen extends StatefulWidget {
  final ItemModel model;

  const MakeAnOfferItemScreen({super.key, required this.model});

  @override
  State<MakeAnOfferItemScreen> createState() => _MakeAnOfferItemScreenState();
}

class _MakeAnOfferItemScreenState extends State<MakeAnOfferItemScreen> {
  final TextEditingController _makeAnOffermessageController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double bottomPadding = (MediaQuery.of(context).viewInsets.bottom - 50);
    bool isBottomPaddingNagative = bottomPadding.isNegative;
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText("makeAnOffer".translate(context), style : TextStyle())
                  .size(context.font.larger)
                  .centerAlign()
                  .bold(),
              Divider(
                thickness: 1,
                color: context.color.borderColor.darken(30),
              ),
              const SizedBox(
                height: 15,
              ),
              RichCustomText(
                text: TextSpan(
                  text: "sellerPrice".translate(context),
                  style: TextStyle(
                      color: context.color.textDefaultColor.withValues(alpha: 0.5),
                      fontSize: 16),
                  children: <TextSpan>[
                    TextSpan(
                      text: "\t${Constant.currencySymbol}${widget.model.price}",
                      style: TextStyle(
                          color: context.color.textDefaultColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsetsDirectional.only(
                    bottom: isBottomPaddingNagative ? 0 : bottomPadding,
                    start: 20,
                    end: 20,
                    top: 18),
                child: TextFormField(
                  maxLines: null,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: context.color.textDefaultColor.withValues(alpha: 0.5)),
                  controller: _makeAnOffermessageController,
                  cursorColor: context.color.territoryColor,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return Validator.nullCheckValidator(val,context: context);
                    } else {
                      return null;
                    }
                  },
                  decoration: InputDecoration(
                      fillColor: context.color.borderColor.darken(20),
                      filled: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      hintText: "yourOffer".translate(context),
                      hintStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color:
                              context.color.textDefaultColor.withValues(alpha: 0.3)),
                      focusColor: context.color.territoryColor,
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: context.color.borderColor.darken(60))),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                              color: context.color.borderColor.darken(60))),
                      focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: context.color.territoryColor))),
                ),
              ),
              const SizedBox(
                height: 35,
              ),
              BlocConsumer<MakeAnOfferItemCubit, MakeAnOfferItemState>(
                  listener: (context, state) {
                if (state is MakeAnOfferItemSuccess) {
                  HelperUtils.showSnackBarMessage(
                      context, state.message.toString(),
                      messageDuration: 3);
                  dynamic data = state.data;

                  context.read<GetBuyerChatListCubit>().addNewChat(ChatedUser(
                      itemId: int.parse(data['item_id']),
                      amount: int.parse(data['amount']),
                      buyerId: data['buyer_id'],
                      createdAt: data['created_at'],
                      id: data['id'],
                      sellerId: data['seller_id'],
                      updatedAt: data['updated_at'],
                      userBlocked: data['user_blocked']?? false,
                      buyer: Buyer.fromJson(data['buyer']),
                      item: Item.fromJson(data['item']),
                      seller: Seller.fromJson(data['seller'])));
                  Future.delayed(Duration(seconds: 1), () {
                    Navigator.pop(context);
                  }).then((value) {
                    Navigator.push(context, BlurredRouter(
                      builder: (context) {
                        return MultiBlocProvider(
                          providers: [
                            BlocProvider(
                              create: (context) => SendMessageCubit(),
                            ),
                            BlocProvider(
                              create: (context) => LoadChatMessagesCubit(),
                            ),
                            BlocProvider(
                              create: (context) => DeleteMessageCubit(),
                            ),
                          ],
                          child: ChatScreen(
                            profilePicture: widget.model.user!.profile ?? "",
                            userName: widget.model.user!.name!,
                            userId: widget.model.user!.id!.toString(),
                            from: "item",
                            itemImage: widget.model.image!,
                            itemId: widget.model.id.toString(),
                            date: widget.model.created!,
                            itemTitle: widget.model.name!,
                            itemOfferId: state.data['id'],
                            itemPrice: widget.model.price!,
                            status: widget.model.status!,
                            itemOfferPrice: int.parse(state.data['amount']),
                          ),
                        );
                      },
                    ));
                  });
                }
                if (state is MakeAnOfferItemFailure) {
                  HelperUtils.showSnackBarMessage(
                      context, state.errorMessage.toString(),
                      messageDuration: 3);
                  Future.delayed(Duration(seconds: 1), () {
                    Navigator.pop(context);
                  });
                }
              }, builder: (context, state) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    MaterialButton(
                      height: 45,
                      minWidth: 104,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                            color: context.color.textDefaultColor,
                          )),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: CustomText("cancelLbl".translate(context))
                          .color(context.color.textDefaultColor),
                    ),
                    MaterialButton(
                      height: 45,
                      minWidth: 104,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          8,
                        ),
                      ),
                      color: context.color.territoryColor,
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          context.read<MakeAnOfferItemCubit>().makeAnOfferItem(
                              widget.model.id!,
                              int.parse(
                                  _makeAnOffermessageController.text.trim()));
                        }
                      },
                      child: (state is MakeAnOfferItemInProgress)
                          ? UiUtils.progress(width: 24, height: 24)
                          : CustomText("send".translate(context), style : TextStyle())
                  .color(context.color.buttonColor),
                    ),
                  ],
                );
              })
            ],
          ),
        ),
      ),
    );
  }
}
*/
