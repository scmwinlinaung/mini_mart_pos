import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/product.dart';
import '../../repositories/category_repository.dart';
import '../../../core/service_locator.dart';
import '../../../core/services/database_service.dart';

part 'category_state.dart';

class CategoryCubit extends Cubit<CategoryState> {
  late final CategoryRepository _categoryRepository;

  CategoryCubit() : super(const CategoryState()) {
    _categoryRepository = CategoryRepository(sl<DatabaseService>());
    loadInitialData();
  }

  Future<void> loadInitialData() async {
    await Future.wait([
      loadCategories(),
      loadCategoryStatistics(),
    ]);
  }

  Future<void> loadCategories() async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final categories = await _categoryRepository.getAllCategories();

      emit(state.copyWith(
        categories: categories,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> loadCategoryStatistics() async {
    try {
      emit(state.copyWith(isLoadingStatistics: true));

      final allStats = await _categoryRepository.getAllCategoryStatistics();
      final categoryStats = allStats['categoryStatistics'] as List<Map<String, dynamic>>;

      emit(state.copyWith(
        categoryStatistics: categoryStats,
        isLoadingStatistics: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingStatistics: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> searchCategories(String searchTerm) async {
    try {
      emit(state.copyWith(isSearching: true, searchTerm: searchTerm));

      if (searchTerm.trim().isEmpty) {
        await loadCategories();
        emit(state.copyWith(isSearching: false));
        return;
      }

      final searchResults = await _categoryRepository.searchCategories(searchTerm);

      emit(state.copyWith(
        categories: searchResults,
        isSearching: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isSearching: false,
        error: e.toString(),
      ));
    }
  }

  void selectCategory(Category? category) {
    if (category != null) {
      emit(state.copyWith(
        selectedCategory: category,
        isEditing: true,
        name: category.name,
        description: category.description ?? '',
        clearAllErrors: true,
      ));
    } else {
      emit(state.copyWith(
        selectedCategory: null,
        isEditing: false,
        name: '',
        description: '',
        clearAllErrors: true,
      ));
    }
  }

  void updateName(String value) {
    emit(state.copyWith(name: value));
    _validateName();
  }

  void updateDescription(String value) {
    emit(state.copyWith(description: value));
    _validateDescription();
  }

  Future<void> saveCategory() async {
    try {
      // Validate all fields
      if (!_validateAllFields()) {
        return;
      }

      emit(state.copyWith(isLoading: true, clearError: true));

      if (state.isEditing && state.selectedCategory != null) {
        // Update existing category
        await _categoryRepository.updateCategory(
          state.selectedCategory!.id,
          name: state.name,
          description: state.description.isEmpty ? null : state.description,
        );
      } else {
        // Create new category
        await _categoryRepository.createCategory(
          name: state.name,
          description: state.description.isEmpty ? null : state.description,
        );
      }

      // Reload categories and statistics, then reset form
      await loadInitialData();
      selectCategory(null);

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> deleteCategory(int categoryId) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      await _categoryRepository.deleteCategory(categoryId);

      await loadInitialData();

      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> refreshData() async {
    await loadInitialData();
  }

  void clearForm() {
    selectCategory(null);
  }

  void clearSearch() {
    emit(state.copyWith(searchTerm: ''));
    loadCategories();
  }

  void clearError() {
    emit(state.copyWith(clearError: true));
  }

  bool _validateAllFields() {
    var isValid = true;

    isValid &= _validateName();
    isValid &= _validateDescription();

    return isValid;
  }

  bool _validateName() {
    final name = state.name;
    if (name.trim().isEmpty) {
      emit(state.copyWith(nameError: 'Category name is required'));
      return false;
    }
    if (name.length > 100) {
      emit(state.copyWith(nameError: 'Category name must be less than 100 characters'));
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9\s\-&().]+$').hasMatch(name)) {
      emit(state.copyWith(nameError: 'Category name can only contain letters, numbers, spaces, and common symbols'));
      return false;
    }

    emit(state.copyWith(clearNameError: true));
    return true;
  }

  bool _validateDescription() {
    final description = state.description;
    if (description.isNotEmpty && description.length > 500) {
      emit(state.copyWith(descriptionError: 'Description must be less than 500 characters'));
      return false;
    }

    emit(state.copyWith(clearDescriptionError: true));
    return true;
  }

  Future<Map<String, dynamic>> getCategoryDetails(int categoryId) async {
    try {
      final category = await _categoryRepository.getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Category not found');
      }

      final statistics = await _categoryRepository.getCategoryStatistics(categoryId);

      return {
        'category': category,
        'statistics': statistics,
      };
    } catch (e) {
      throw Exception('Failed to get category details: $e');
    }
  }

  Future<bool> canDeleteCategory(int categoryId) async {
    try {
      return await _categoryRepository.canDeleteCategory(categoryId);
    } catch (e) {
      throw Exception('Failed to check if category can be deleted: $e');
    }
  }
}