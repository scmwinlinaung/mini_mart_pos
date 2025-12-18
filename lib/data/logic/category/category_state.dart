part of 'category_cubit.dart';

class CategoryState {
  final List<Category> categories;
  final Category? selectedCategory;
  final bool isLoading;
  final String? error;
  final bool isEditing;
  final List<Map<String, dynamic>> categoryStatistics;

  // Form fields
  final String name;
  final String description;

  // Form errors
  final String? nameError;
  final String? descriptionError;

  // Search state
  final String searchTerm;
  final bool isSearching;

  // Statistics loading
  final bool isLoadingStatistics;

  const CategoryState({
    this.categories = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
    this.isEditing = false,
    this.categoryStatistics = const [],
    this.name = '',
    this.description = '',
    this.nameError,
    this.descriptionError,
    this.searchTerm = '',
    this.isSearching = false,
    this.isLoadingStatistics = false,
  });

  CategoryState copyWith({
    List<Category>? categories,
    Category? selectedCategory,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? isEditing,
    List<Map<String, dynamic>>? categoryStatistics,
    String? name,
    String? description,
    String? nameError,
    String? descriptionError,
    String? searchTerm,
    bool? isSearching,
    bool? isLoadingStatistics,
    bool clearNameError = false,
    bool clearDescriptionError = false,
    bool clearAllErrors = false,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isEditing: isEditing ?? this.isEditing,
      categoryStatistics: categoryStatistics ?? this.categoryStatistics,
      name: name ?? this.name,
      description: description ?? this.description,
      nameError: clearNameError || clearAllErrors ? null : (nameError ?? this.nameError),
      descriptionError: clearDescriptionError || clearAllErrors ? null : (descriptionError ?? this.descriptionError),
      searchTerm: searchTerm ?? this.searchTerm,
      isSearching: isSearching ?? this.isSearching,
      isLoadingStatistics: isLoadingStatistics ?? this.isLoadingStatistics,
    );
  }

  bool get isFormValid {
    return name.isNotEmpty &&
        nameError == null &&
        descriptionError == null;
  }

  List<Category> get filteredCategories {
    if (searchTerm.isEmpty) {
      return categories;
    }

    return categories.where((category) {
      return category.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
          (category.description?.toLowerCase().contains(searchTerm.toLowerCase()) ?? false);
    }).toList();
  }

  int get totalCategories {
    return categories.length;
  }

  int get totalProducts {
    return categoryStatistics.fold(0, (sum, stat) => sum + (stat['productCount'] as int));
  }

  int get categoriesWithProducts {
    return categoryStatistics.where((stat) => (stat['productCount'] as int) > 0).length;
  }

  int get totalLowStockItems {
    return categoryStatistics.fold(0, (sum, stat) => sum + (stat['lowStockCount'] as int));
  }
}