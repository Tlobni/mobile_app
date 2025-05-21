// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/repositories/category_repository.dart';

abstract class FetchAllCategoriesState {}

class FetchAllCategoriesInitial extends FetchAllCategoriesState {}

class FetchAllCategoriesInProgress extends FetchAllCategoriesState {}

class FetchAllCategoriesSuccess extends FetchAllCategoriesState {
  final bool hasError;
  final List<CategoryModel> categories;

  FetchAllCategoriesSuccess({
    required this.hasError,
    required this.categories,
  });

  FetchAllCategoriesSuccess copyWith({
    bool? hasError,
    List<CategoryModel>? categories,
  }) {
    return FetchAllCategoriesSuccess(
      hasError: hasError ?? this.hasError,
      categories: categories ?? this.categories,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hasError': hasError,
      'categories': categories.map((x) => x.toJson()).toList(),
    };
  }

  factory FetchAllCategoriesSuccess.fromMap(Map<String, dynamic> map) {
    return FetchAllCategoriesSuccess(
      hasError: map['hasError'] as bool,
      categories: List<CategoryModel>.from(
        (map['categories']).map<CategoryModel>(
          (x) => CategoryModel.fromJson(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory FetchAllCategoriesSuccess.fromJson(String source) =>
      FetchAllCategoriesSuccess.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FetchAllCategoriesSuccess(hasError: $hasError, categories: $categories)';
  }
}

class FetchAllCategoriesFailure extends FetchAllCategoriesState {
  final String errorMessage;
  final StackTrace trace;

  FetchAllCategoriesFailure(this.errorMessage, this.trace);
}

class FetchAllCategoriesCubit extends Cubit<FetchAllCategoriesState> {
  FetchAllCategoriesCubit() : super(FetchAllCategoriesInitial());

  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<void> fetchCategories() async {
    try {
      emit(FetchAllCategoriesInProgress());

      DataOutput<CategoryModel> categories = await _categoryRepository.fetchAllCategories();

      emit(FetchAllCategoriesSuccess(
        categories: categories.modelList,
        hasError: false,
      ));
    } catch (e, s) {
      emit(FetchAllCategoriesFailure(e.toString(), s));
    }
  }

  List<CategoryModel> getCategories() {
    if (state is FetchAllCategoriesSuccess) {
      return (state as FetchAllCategoriesSuccess).categories;
    }

    return <CategoryModel>[];
  }
}
