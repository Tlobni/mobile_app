import 'package:eClassify/data/repositories/advertisement_repository.dart';
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

class FetchUserPackageLimitCubit extends Cubit<FetchUserPackageLimitState> {
  FetchUserPackageLimitCubit() : super(FetchUserPackageLimitInitial());
  AdvertisementRepository repository = AdvertisementRepository();

  void fetchUserPackageLimit({required String packageType}) async {
    emit(FetchUserPackageLimitInProgress());

    repository.fetchUserPackageLimit(packageType: packageType).then((value) {
      emit(FetchUserPackageLimitInSuccess(value['message']));
    }).catchError((e) {
      emit(FetchUserPackageLimitFailure(e.toString()));
    });
  }
}
