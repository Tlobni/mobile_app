import 'package:eClassify/data/repositories/item/item_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class CreateFeaturedAdState {}

class CreateFeaturedAdInitial extends CreateFeaturedAdState {}

class CreateFeaturedAdInProgress extends CreateFeaturedAdState {}

class CreateFeaturedAdInSuccess extends CreateFeaturedAdState {
  final String responseMessage;

  CreateFeaturedAdInSuccess(this.responseMessage);
}

class CreateFeaturedAdFailure extends CreateFeaturedAdState {
  final dynamic error;

  CreateFeaturedAdFailure(this.error);
}

class CreateFeaturedAdCubit extends Cubit<CreateFeaturedAdState> {
  CreateFeaturedAdCubit() : super(CreateFeaturedAdInitial());
  ItemRepository repository = ItemRepository();

  void createFeaturedAds({
    required int itemId,
  }) async {
    emit(CreateFeaturedAdInProgress());

    repository.createFeaturedAds(itemId: itemId).then((value) {
      emit(CreateFeaturedAdInSuccess(value['message']));
    }).catchError((e) {
      emit(CreateFeaturedAdFailure(e.toString()));
    });
  }
}
