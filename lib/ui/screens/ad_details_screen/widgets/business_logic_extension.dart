part of '../ad_details_screen.dart';

extension on AdDetailsScreenState {
  void _favoriteCubitListener(BuildContext context, UpdateFavoriteState? state) {
    if (state is UpdateFavoriteSuccess) {
      if (state.wasProcess) {
        context.read<FavoriteCubit>().addFavoriteitem(state.item);
      } else {
        context.read<FavoriteCubit>().removeFavoriteItem(state.item);
      }
    }
  }

  void _goToProviderDetails() => Navigator.pushNamed(
        context,
        Routes.sellerProfileScreen,
        arguments: {
          "model": model.user,
          "rating": model.user?.averageRating ?? 0.0,
          "total": model.user?.totalReviews ?? 0,
        },
      );

  Future<void> _onRefresh() async {
    try {
      // Refresh the entire detail screen data only if we have a slug to work with
      if (widget.slug != null || model.slug != null) {
        String slugToUse = widget.slug ?? model.slug!;
        final cubit = context.read<FetchItemFromSlugCubit>();

        // Start the refresh
        cubit.fetchItemFromSlug(slug: slugToUse);
      }

      // Always try to refresh related items even if the main item refresh fails
      if (categoryId != null) {
        context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
            categoryId: categoryId!,
            city: HiveUtils.getCityName(),
            areaId: HiveUtils.getAreaId(),
            country: HiveUtils.getCountryName(),
            state: HiveUtils.getStateName());
      }

      context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!);
      context.read<UserHasRatedItemCubit>().userHasRatedItem(itemId: model.id!);
    } catch (e) {
      // Log the error but don't navigate away
      log('Error refreshing: $e');
    }
  }

  void _onWhatsappPressed() {
    HelperUtils.launchWhatsapp(model.user?.mobile);
  }

  void _onChatPressed() {
    UiUtils.checkUser(
      onNotGuest: () {
        context.read<MakeAnOfferItemCubit>().makeAnOfferItem(id: model.id!, from: "chat");
      },
      context: context,
    );
  }

  void _makeOfferListener(BuildContext context, MakeAnOfferItemState state) {
    if (state is MakeAnOfferItemInProgress) {
      Widgets.showLoader(context);
    }
    if (state is MakeAnOfferItemSuccess || state is MakeAnOfferItemFailure) {
      Widgets.hideLoder(context);
    }
    if (state is MakeAnOfferItemSuccess) {
      dynamic data = state.data;

      context.read<GetBuyerChatListCubit>().addOrUpdateChat(chat_models.ChatUser(
          itemId: data['item_id'] is String ? int.parse(data['item_id']) : data['item_id'],
          amount: data['amount'] != null ? double.parse(data['amount'].toString()) : null,
          buyerId: data['buyer_id'] is String ? int.parse(data['buyer_id']) : data['buyer_id'],
          createdAt: data['created_at'],
          id: data['id'] is String ? int.parse(data['id']) : data['id'],
          sellerId: data['seller_id'] is String ? int.parse(data['seller_id']) : data['seller_id'],
          updatedAt: data['updated_at'],
          buyer: chat_models.Buyer.fromJson(data['buyer']),
          item: chat_models.Item.fromJson(data['item']),
          seller: chat_models.Seller.fromJson(data['seller'])));

      if (state.from == 'offer') {
        HelperUtils.showSnackBarMessage(
          context,
          state.message.toString(),
        );
      }

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
              profilePicture: model.user!.profile ?? "",
              userName: model.user!.name!,
              userId: model.user!.id!.toString(),
              from: "item",
              itemImage: model.image!,
              itemId: model.id.toString(),
              date: model.created!,
              itemTitle: model.name!,
              itemOfferId: state.data['id'] is String ? int.parse(state.data['id']) : state.data['id'],
              itemPrice: model.price!,
              status: model.status!,
              buyerId: HiveUtils.getUserId(),
              itemOfferPrice: state.data['amount'] != null ? double.parse(state.data['amount'].toString()) : null,
              isPurchased: model.isPurchased ?? 0,
              alreadyReview: model.review == null
                  ? false
                  : model.review!.isEmpty
                      ? false
                      : true,
              isFromBuyerList: true,
            ),
          );
        },
      ));
    }
    if (state is MakeAnOfferItemFailure) {
      HelperUtils.showSnackBarMessage(
        context,
        state.errorMessage.toString(),
      );
    }
  }

  void _shareItem() {
    if (model.slug != null) HelperUtils.share(context, model.slug!);
  }

  void _updateFavorite(bool isLike) {
    UiUtils.checkUser(
      onNotGuest: () {
        context.read<UpdateFavoriteCubit>().setFavoriteItem(
              item: model,
              type: isLike ? 0 : 1,
            );
      },
      context: context,
    );
  }

  void _onEditPressed() {
    Navigator.pushReplacementNamed(context, Routes.addItemDetails, arguments: {
      'isEdit': true,
      'item': model,
      'postType': model.type == 'experience' ? PostType.experience : PostType.service,
    });
  }

  void _onDeletePressed() async {
    if (model.id == null) return;
    var delete = await UiUtils.showBlurredDialoge(
      context,
      dialoge: BlurredDialogBox(
        title: "deleteBtnLbl".translate(context),
        content: CustomText(
          "deleteitemwarning".translate(context),
        ),
      ),
    );
    if (delete == true) {
      Future.delayed(
        Duration.zero,
        () {
          context.read<DeleteItemCubit>().deleteItem(model.id!);
        },
      );
    }
  }

  void _rootListener(BuildContext context, FetchItemFromSlugState? state) {
    if (state is FetchItemFromSlugInitial) {
      _onRefresh();
    }
    if (state is FetchItemFromSlugSuccess) {
      log('success');
      initVariables(state.item);
    } else if (state is FetchItemFromSlugFailure) {
      // Only show error message if it's not a refresh operation
      // or if it's a significant error like no internet
      if (state.errorMessage.contains("no-internet")) {
        HelperUtils.showSnackBarMessage(context, "noInternet".translate(context));
      } else if (!state.errorMessage.contains("unexpected-error") && !state.errorMessage.contains("session-expired")) {
        // Don't show generic errors during refresh operations
        log("Error ignored during refresh: ${state.errorMessage}");
      }
    }
  }

  void initVariables(ItemModel itemModel) {
    model = itemModel;

    if (!isAddedByMe) {
      context.read<FetchItemReportReasonsListCubit>().fetch();
      context.read<FetchSafetyTipsListCubit>().fetchSafetyTips();
      context.read<FetchSellerRatingsCubit>().fetch(sellerId: (model.user?.id != null ? model.user!.id! : model.userId!));

      // Fetch reviews specifically for this item
      if (model.id != null) {
        context.read<FetchItemReviewsCubit>().fetchItemReviews(itemId: model.id!);
      }
    } else {
      context.read<FetchAdsListingSubscriptionPackagesCubit>().fetchPackages();
    }
    categoryId = model.category != null ? model.category?.id : model.categoryId;

    setItemClick();
    //ImageView
    if (images.isEmpty) combineImages();
    context.read<FetchRelatedItemsCubit>().fetchRelatedItems(
        categoryId: categoryId!,
        city: HiveUtils.getCityName(),
        areaId: HiveUtils.getAreaId(),
        country: HiveUtils.getCountryName(),
        state: HiveUtils.getStateName());
    _pageScrollController.addListener(_pageScroll);
  }

  void _pageScroll() {
    if (_pageScrollController.isEndReached()) {
      if (context.read<FetchRelatedItemsCubit>().hasMoreData()) {
        context.read<FetchRelatedItemsCubit>().fetchRelatedItemsMore(
            categoryId: categoryId!,
            city: HiveUtils.getCityName(),
            areaId: HiveUtils.getAreaId(),
            country: HiveUtils.getCountryName(),
            state: HiveUtils.getStateName());
      }
    }
  }

  String _formatExperienceDateTime(DateTime? dateTime) => dateTime != null ? DateFormat('MMMM d, y, h:mm a').format(dateTime) : '';

  void combineImages() {
    images.add(model.image);
    if (model.galleryImages != null && model.galleryImages!.isNotEmpty) {
      for (var element in model.galleryImages!) {
        images.add(element.image);
      }
    }

    if (model.videoLink != null && model.videoLink!.isNotEmpty) {
      images.add(model.videoLink);
    }

    if (model.videoLink != "" && model.videoLink != null && !HelperUtils.isYoutubeVideo(model.videoLink ?? "")) {
      flickManager = FlickManager(
        videoPlayerController: VideoPlayerController.networkUrl(
          Uri.parse(model.videoLink!),
        ),
      );
      flickManager?.onVideoEnd = () {};
    }
    if (model.videoLink != "" && model.videoLink != null && HelperUtils.isYoutubeVideo(model.videoLink ?? "")) {
      String? videoId = YoutubePlayer.convertUrlToId(model.videoLink!);
      if (videoId != null) {
        String thumbnail = YoutubePlayer.getThumbnail(videoId: videoId);

        youtubeVideoThumbnail = thumbnail;
      }
    }
  }

  void setItemClick() {
    if (!isAddedByMe) {
      context.read<ItemTotalClickCubit>().itemTotalClick(model.id!);
    }
  }
}
