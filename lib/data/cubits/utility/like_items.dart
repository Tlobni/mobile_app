/*
// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

class LikedItemsState {
  final Set liked;
  Set? removedLikes;
  LikedItemsState({
    required this.liked,
    this.removedLikes,
  });

  LikedItemsState copyWith({
    Set? liked,
  }) {
    return LikedItemsState(
      liked: liked ?? this.liked,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'liked': liked.toList(),
    };
  }

  factory LikedItemsState.fromMap(Map<String, dynamic> map) {
    return LikedItemsState(
        liked: Set.from(
      (map['liked'] as Set),
    ));
  }

  String toJson() => json.encode(toMap());

  factory LikedItemsState.fromJson(String source) =>
      LikedItemsState.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'LikedItemsState(liked: $liked)';
}

class LikedItemsCubit extends Cubit<LikedItemsState> {
  LikedItemsCubit()
      : super(LikedItemsState(liked: {}, removedLikes: {}));

  void changeLike(dynamic id) {
    bool isAvailable = state.liked.contains(id);

    if (isAvailable) {
      state.liked.remove(id);
      state.removedLikes?.add(id);
    } else {
      state.liked.add(id);
    }

    emit(LikedItemsState(
        liked: state.liked, removedLikes: state.removedLikes));
  }

  void add(id) {
    state.liked.add(id);
    emit(LikedItemsState(
        liked: state.liked, removedLikes: state.removedLikes));
  }

  void clear() {
    state.liked.clear();
    state.removedLikes?.clear();
    emit(LikedItemsState(liked: {}, removedLikes: {}));
  }

//for locally ,
  Set? getRemovedLikes() {
    return state.removedLikes;
  }
}
*/
