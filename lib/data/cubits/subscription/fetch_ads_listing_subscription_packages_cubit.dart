// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/subscription_pacakage_model.dart';
import 'package:eClassify/data/repositories/subscription_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchAdsListingSubscriptionPackagesState {}

class FetchAdsListingSubscriptionPackagesInitial
    extends FetchAdsListingSubscriptionPackagesState {}

class FetchAdsListingSubscriptionPackagesInProgress
    extends FetchAdsListingSubscriptionPackagesState {}

class FetchAdsListingSubscriptionPackagesSuccess
    extends FetchAdsListingSubscriptionPackagesState {
  final List<SubscriptionPackageModel> subscriptionPackages;
  FetchAdsListingSubscriptionPackagesSuccess({
    required this.subscriptionPackages,
  });
}

class FetchAdsListingSubscriptionPackagesFailure
    extends FetchAdsListingSubscriptionPackagesState {
  final dynamic errorMessage;

  FetchAdsListingSubscriptionPackagesFailure(this.errorMessage);
}

class FetchAdsListingSubscriptionPackagesCubit
    extends Cubit<FetchAdsListingSubscriptionPackagesState> {
  FetchAdsListingSubscriptionPackagesCubit()
      : super(FetchAdsListingSubscriptionPackagesInitial());
  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository();
  Future<void> fetchPackages() async {
    try {
      emit(FetchAdsListingSubscriptionPackagesInProgress());
      DataOutput<SubscriptionPackageModel> result =
          await _subscriptionRepository.getSubscriptionPacakges(
              type: "item_listing");
      emit(FetchAdsListingSubscriptionPackagesSuccess(
          subscriptionPackages: result.modelList));
    } catch (e) {
      emit(FetchAdsListingSubscriptionPackagesFailure(e));
    }
  }
}
