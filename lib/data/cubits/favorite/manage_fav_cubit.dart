// ignore_for_file: file_names

// import 'package:flutter/material.dart';
import 'package:eClassify/data/model/item/item_model.dart';
import 'package:eClassify/data/repositories/favourites_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class UpdateFavoriteState {}

class UpdateFavoriteInitial extends UpdateFavoriteState {}

class UpdateFavoriteInProgress extends UpdateFavoriteState {}

class UpdateFavoriteSuccess extends UpdateFavoriteState {
  final ItemModel item;
  final bool wasProcess; //to check that process of Favorite done or not
  UpdateFavoriteSuccess(this.item, this.wasProcess);
}

class UpdateFavoriteFailure extends UpdateFavoriteState {
  final String errorMessage;

  UpdateFavoriteFailure(this.errorMessage);
}

class UpdateFavoriteCubit extends Cubit<UpdateFavoriteState> {
  final FavoriteRepository favoriteRepository;

  UpdateFavoriteCubit(this.favoriteRepository) : super(UpdateFavoriteInitial());

  void setFavoriteItem({required ItemModel item, required int type}) {
    emit(UpdateFavoriteInProgress());
    favoriteRepository.manageFavorites(item.id!).then((value) {
      emit(UpdateFavoriteSuccess(item, type == 1 ? true : false));
    }).catchError((e) {
      emit(UpdateFavoriteFailure(e.toString()));
    });
  }
}
