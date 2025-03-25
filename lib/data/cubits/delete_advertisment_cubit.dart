import 'package:tlobni/data/repositories/advertisement_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class DeleteAdvertisementState {}

class DeleteAdvertisementInitial extends DeleteAdvertisementState {}

class DeleteAdvertisementInProgress extends DeleteAdvertisementState {}

class DeleteAdvertisementSuccess extends DeleteAdvertisementState {}

class DeleteAdvertisementFailure extends DeleteAdvertisementState {
  final String errorMessage;

  DeleteAdvertisementFailure(this.errorMessage);
}

class DeleteAdvertisementCubit extends Cubit<DeleteAdvertisementState> {
  final AdvertisementRepository _advertisementRepository;

  DeleteAdvertisementCubit(this._advertisementRepository)
      : super(DeleteAdvertisementInitial());

  void delete(dynamic id) async {
    try {
      emit(DeleteAdvertisementInProgress());
      await _advertisementRepository.deleteAdvertisment(id);
      emit(DeleteAdvertisementSuccess());
    } catch (e) {
      emit(DeleteAdvertisementFailure(e.toString()));
    }
  }
}
