import 'package:cached_network_image/cached_network_image.dart';
import 'package:eClassify/data/cubits/chat/blocked_users_list_cubit.dart';
import 'package:eClassify/data/cubits/chat/unblock_user_cubit.dart';
import 'package:eClassify/data/model/chat/chat_user_model.dart';
import 'package:eClassify/ui/screens/home/home_screen.dart';
import 'package:eClassify/ui/screens/widgets/animated_routes/blur_page_route.dart';
import 'package:eClassify/ui/screens/widgets/blurred_dialoge_box.dart';
import 'package:eClassify/ui/screens/widgets/errors/no_data_found.dart';
import 'package:eClassify/ui/screens/widgets/errors/something_went_wrong.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_icon.dart';
import 'package:eClassify/utils/custom_text.dart';
import 'package:eClassify/utils/extensions/extensions.dart';
import 'package:eClassify/utils/helper_utils.dart';
import 'package:eClassify/utils/ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class BlockedUserListScreen extends StatefulWidget {
  const BlockedUserListScreen({super.key});

  static Route route(RouteSettings settings) {
    return BlurredRouter(
      builder: (context) {
        return const BlockedUserListScreen();
      },
    );
  }

  @override
  State<BlockedUserListScreen> createState() => _BlockedUserListScreenState();
}

class _BlockedUserListScreenState extends State<BlockedUserListScreen> {
  late final ScrollController _pageScrollController = ScrollController();

  @override
  void initState() {
    context.read<BlockedUsersListCubit>().blockedUsersList();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.color.backgroundColor,
      appBar: UiUtils.buildAppBar(context,
          showBackButton: true, title: "blockedUsers".translate(context)),
      body: BlocBuilder<BlockedUsersListCubit, BlockedUsersListState>(
        builder: (context, state) {
          if (state is BlockedUsersListInProgress) {
            return Center(
              child: UiUtils.progress(),
            );
          }
          if (state is BlockedUsersListFail) {
            return const SomethingWentWrong();
          }
          if (state is BlockedUsersListSuccess) {
            if (state.data.isEmpty) {
              return NoDataFound(
                subMessage: "",
                onTap: () {
                  context.read<BlockedUsersListCubit>().blockedUsersList();
                },
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _pageScrollController,
                    itemCount: state.data.length,
                    padding: EdgeInsets.only(top: 10),
                    itemBuilder: (context, index) {
                      BlockedUserModel user = state.data[index];

                      return Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 0.0, horizontal: sidePadding),
                        child: Container(
                            // height: 100,
                            decoration: BoxDecoration(
                                color: context.color.secondaryColor,
                                border: Border.all(
                                    color: context.color.borderColor,
                                    width: 1.5),
                                borderRadius: BorderRadius.circular(10)),
                            child: userList(context, user)),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return Container();
        },
      ),
    );
  }

  Widget userList(BuildContext context, BlockedUserModel user) {
    return BlocProvider(
        create: (context) => UnblockUserCubit(),
        child: Builder(builder: (context) {
          return BlocListener<UnblockUserCubit, UnblockUserState>(
            listener: (context, unblockState) {
              if (unblockState is UnblockUserSuccess) {
                // Remove the unblocked user from the list
                context.read<BlockedUsersListCubit>().unblockUser(user.id!);
                HelperUtils.showSnackBarMessage(context, unblockState.message);
              } else if (unblockState is UnblockUserFail) {
                HelperUtils.showSnackBarMessage(
                    context, unblockState.error.toString());
              }
            },
            child: InkWell(
              onTap: () async {
                var unBlock = await UiUtils.showBlurredDialoge(
                  context,
                  dialoge: BlurredDialogBox(
                    acceptButtonName: "unBlockLbl".translate(context),
                    content: CustomText(
                      "${"unBlockLbl".translate(context)}\t${user.name!}\t${"toSendMessage".translate(context)}"
                          .translate(context),
                    ),
                  ),
                );
                if (unBlock == true) {
                  Future.delayed(Duration.zero, () {
                    context.read<UnblockUserCubit>().unBlockUser(
                          blockUserId: user.id!,
                        );
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (user.profile == "" || user.profile == null) {
                          return;
                        }
                        UiUtils.showFullScreenImage(context,
                            provider:
                                CachedNetworkImageProvider(user.profile!));
                      },
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 1)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: user.profile == "" || user.profile == null
                              ? CircleAvatar(
                                  radius: 18,
                                  backgroundColor: context.color.territoryColor,
                                  child: SvgPicture.asset(AppIcons.profile,
                                      height: 20,
                                      width: 20,
                                      colorFilter: ColorFilter.mode(
                                          context.color.buttonColor,
                                          BlendMode.srcIn)),
                                )
                              : CircleAvatar(
                                  radius: 15,
                                  backgroundColor: context.color.territoryColor,
                                  backgroundImage: NetworkImage(user.profile!),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    Expanded(
                      child: CustomText(
                        user.name!,
                        color: context.color.textColorDark,
                        fontSize: context.font.large,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }));
  }
}
