import 'package:eClassify/data/repositories/advertisement_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AssignFreePackageState {}

class AssignFreePackageInitial extends AssignFreePackageState {}

class AssignFreePackageInProgress extends AssignFreePackageState {}

class AssignFreePackageInSuccess extends AssignFreePackageState {
  final String responseMessage;

  AssignFreePackageInSuccess(this.responseMessage);
}

class AssignFreePackageFailure extends AssignFreePackageState {
  final dynamic error;

  AssignFreePackageFailure(this.error);
}

class AssignFreePackageCubit extends Cubit<AssignFreePackageState> {
  AssignFreePackageCubit() : super(AssignFreePackageInitial());
  AdvertisementRepository repository = AdvertisementRepository();

  void assignFreePackage({
    required int packageId,
  }) async {
    emit(AssignFreePackageInProgress());

    repository.assignFreePackages(packageId: packageId).then((value) {
      emit(AssignFreePackageInSuccess(value['message']));
    }).catchError((e) {
      emit(AssignFreePackageFailure(e.toString()));
    });
  }
}
