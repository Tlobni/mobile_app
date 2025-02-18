// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eClassify/data/repositories/subscription_repository.dart';
import 'package:eClassify/data/model/data_output.dart';
import 'package:eClassify/data/model/subscription_pacakage_model.dart';

abstract class FetchFeaturedSubscriptionPackagesState {}

class FetchFeaturedSubscriptionPackagesInitial
    extends FetchFeaturedSubscriptionPackagesState {}

class FetchFeaturedSubscriptionPackagesInProgress
    extends FetchFeaturedSubscriptionPackagesState {}

class FetchFeaturedSubscriptionPackagesSuccess
    extends FetchFeaturedSubscriptionPackagesState {
  final List<SubscriptionPackageModel> subscriptionPackages;

  FetchFeaturedSubscriptionPackagesSuccess({
    required this.subscriptionPackages,
  });
}

class FetchFeaturedSubscriptionPackagesFailure
    extends FetchFeaturedSubscriptionPackagesState {
  final dynamic errorMessage;

  FetchFeaturedSubscriptionPackagesFailure(this.errorMessage);
}

class FetchFeaturedSubscriptionPackagesCubit
    extends Cubit<FetchFeaturedSubscriptionPackagesState> {
  FetchFeaturedSubscriptionPackagesCubit()
      : super(FetchFeaturedSubscriptionPackagesInitial());
  final SubscriptionRepository _subscriptionRepository =
      SubscriptionRepository();

  Future<void> fetchPackages() async {
    try {
      emit(FetchFeaturedSubscriptionPackagesInProgress());
      DataOutput<SubscriptionPackageModel> result =
          await _subscriptionRepository.getSubscriptionPacakges(
              type: "advertisement");
      emit(FetchFeaturedSubscriptionPackagesSuccess(
          subscriptionPackages: result.modelList));
    } catch (e) {
      emit(FetchFeaturedSubscriptionPackagesFailure(e));
    }
  }
}
