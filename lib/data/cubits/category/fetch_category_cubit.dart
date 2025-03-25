// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:convert';

import 'package:tlobni/data/model/category_model.dart';
import 'package:tlobni/data/model/data_output.dart';
import 'package:tlobni/data/repositories/category_repository.dart';
import 'package:tlobni/utils/helper_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class FetchCategoryState {}

class FetchCategoryInitial extends FetchCategoryState {}

class FetchCategoryInProgress extends FetchCategoryState {}

class FetchCategorySuccess extends FetchCategoryState {
  final int total;
  final int page;
  final bool isLoadingMore;
  final bool hasError;
  final List<CategoryModel> categories;
  final CategoryType? categoryType;

  FetchCategorySuccess({
    required this.total,
    required this.page,
    required this.isLoadingMore,
    required this.hasError,
    required this.categories,
    this.categoryType,
  });

  FetchCategorySuccess copyWith({
    int? total,
    int? page,
    bool? isLoadingMore,
    bool? hasError,
    List<CategoryModel>? categories,
    CategoryType? categoryType,
  }) {
    return FetchCategorySuccess(
      total: total ?? this.total,
      page: page ?? this.page,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasError: hasError ?? this.hasError,
      categories: categories ?? this.categories,
      categoryType: categoryType ?? this.categoryType,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'total': total,
      ' page': page,
      'isLoadingMore': isLoadingMore,
      'hasError': hasError,
      'categories': categories.map((x) => x.toJson()).toList(),
      'categoryType': categoryType?.value,
    };
  }

  factory FetchCategorySuccess.fromMap(Map<String, dynamic> map) {
    return FetchCategorySuccess(
      total: map['total'] as int,
      page: map[' page'] as int,
      isLoadingMore: map['isLoadingMore'] as bool,
      hasError: map['hasError'] as bool,
      categories: List<CategoryModel>.from(
        (map['categories']).map<CategoryModel>(
          (x) => CategoryModel.fromJson(x as Map<String, dynamic>),
        ),
      ),
      categoryType: CategoryType.values[map['categoryType'] as int],
    );
  }

  String toJson() => json.encode(toMap());

  factory FetchCategorySuccess.fromJson(String source) =>
      FetchCategorySuccess.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'FetchCategorySuccess(total: $total,  page: $page, isLoadingMore: $isLoadingMore, hasError: $hasError, categories: $categories, categoryType: $categoryType)';
  }
}

class FetchCategoryFailure extends FetchCategoryState {
  final String errorMessage;

  FetchCategoryFailure(this.errorMessage);
}

class FetchCategoryCubit extends Cubit<FetchCategoryState> {
  FetchCategoryCubit() : super(FetchCategoryInitial());

  final CategoryRepository _categoryRepository = CategoryRepository();

  Future<void> fetchCategories({
    bool? forceRefresh,
    bool? loadWithoutDelay,
    CategoryType? type,
  }) async {
    try {
      emit(FetchCategoryInProgress());

      DataOutput<CategoryModel> categories =
          await _categoryRepository.fetchCategories(page: 1, type: type);

      emit(FetchCategorySuccess(
        total: categories.total,
        categories: categories.modelList,
        page: 1,
        hasError: false,
        isLoadingMore: false,
        categoryType: type,
      ));
    } catch (e) {
      emit(FetchCategoryFailure(e.toString()));
    }
  }

  List<CategoryModel> getCategories() {
    if (state is FetchCategorySuccess) {
      return (state as FetchCategorySuccess).categories;
    }

    return <CategoryModel>[];
  }

  Future<void> fetchCategoriesMore() async {
    try {
      if (state is FetchCategorySuccess) {
        if ((state as FetchCategorySuccess).isLoadingMore) {
          return;
        }
        emit((state as FetchCategorySuccess).copyWith(isLoadingMore: true));

        CategoryType? currentType =
            (state as FetchCategorySuccess).categoryType;

        DataOutput<CategoryModel> result =
            await _categoryRepository.fetchCategories(
          page: (state as FetchCategorySuccess).page + 1,
          type: currentType,
        );

        FetchCategorySuccess categoryState = (state as FetchCategorySuccess);
        categoryState.categories.addAll(result.modelList);

        List<String> list =
            categoryState.categories.map((e) => e.url!).toList();
        await HelperUtils.precacheSVG(list);

        emit(FetchCategorySuccess(
          isLoadingMore: false,
          hasError: false,
          categories: categoryState.categories,
          page: (state as FetchCategorySuccess).page + 1,
          total: result.total,
          categoryType: currentType,
        ));
      }
    } catch (e) {
      emit((state as FetchCategorySuccess)
          .copyWith(isLoadingMore: false, hasError: true));
    }
  }

  bool hasMoreData() {
    if (state is FetchCategorySuccess) {
      return (state as FetchCategorySuccess).categories.length <
          (state as FetchCategorySuccess).total;
    }
    return false;
  }
}
