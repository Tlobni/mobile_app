import 'package:tlobni/data/repositories/advertisement_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchUserPackageLimitState {}

class FetchUserPackageLimitInitial extends FetchUserPackageLimitState {}

class FetchUserPackageLimitInProgress extends FetchUserPackageLimitState {}

class FetchUserPackageLimitInSuccess extends FetchUserPackageLimitState {
  final String responseMessage;

  FetchUserPackageLimitInSuccess(this.responseMessage);
}

class FetchUserPackageLimitFailure extends FetchUserPackageLimitState {
  final dynamic error;

  FetchUserPackageLimitFailure(this.error);
}

class FetchUserPackageLimitPending extends FetchUserPackageLimitState {
  final String message;

  FetchUserPackageLimitPending(this.message);
}

class FetchUserPackageLimitCubit extends Cubit<FetchUserPackageLimitState> {
  FetchUserPackageLimitCubit() : super(FetchUserPackageLimitInitial());
  AdvertisementRepository repository = AdvertisementRepository();

  void fetchUserPackageLimit({required String packageType}) async {
    emit(FetchUserPackageLimitInProgress());

    repository.fetchUserPackageLimit(packageType: packageType).then((value) {
      // Check if status is 0, which means pending
      if (value['status'] == 0) {
        emit(FetchUserPackageLimitPending(
            value['message'] ?? 'Your request is pending'));
      } else {
        emit(FetchUserPackageLimitInSuccess(value['message']));
      }
    }).catchError((e) {
      emit(FetchUserPackageLimitFailure(e.toString()));
    });
  }
}
