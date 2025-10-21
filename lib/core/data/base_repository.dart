import 'result.dart';

/// واجهة أساسية لمصادر البيانات
abstract class DataSource {
  /// اسم مصدر البيانات للتسجيل
  String get name;
}

/// واجهة لمصادر البيانات المحلية
abstract class LocalDataSource extends DataSource {
  /// مسح جميع البيانات المحلية
  Future<void> clearAll();
  
  /// التحقق من وجود بيانات محلية
  Future<bool> hasData();
  
  /// الحصول على حجم البيانات المخزنة
  Future<int> getDataSize();
}

/// واجهة لمصادر البيانات البعيدة
abstract class RemoteDataSource extends DataSource {
  /// التحقق من اتصال الإنترنت
  Future<bool> get isConnected;
  
  /// إعادة المحاولة عند فشل الطلب
  Future<Result<T>> retry<T>(
    Future<Result<T>> Function() operation, {
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  });
}

/// نموذج أساسي للبيانات
abstract class BaseModel {
  /// معرف فريد للعنصر
  String get id;
  
  /// وقت الإنشاء
  DateTime get createdAt;
  
  /// وقت آخر تحديث
  DateTime get updatedAt;
  
  /// تحويل إلى Map
  Map<String, dynamic> toMap();
  
  /// التحقق من صحة البيانات
  bool isValid();
}

/// واجهة للعمليات الأساسية على البيانات
abstract class Repository<T extends BaseModel> {
  /// الحصول على جميع العناصر
  Future<Result<List<T>>> getAll();
  
  /// الحصول على عنصر بمعرفه
  Future<Result<T>> getById(String id);
  
  /// إضافة عنصر جديد
  Future<Result<T>> create(T item);
  
  /// تحديث عنصر موجود
  Future<Result<T>> update(String id, T item);
  
  /// حذف عنصر
  Future<Result<void>> delete(String id);
  
  /// البحث في العناصر
  Future<Result<List<T>>> search(String query);
  
  /// الحصول على عناصر بشروط معينة
  Future<Result<List<T>>> getWhere(Map<String, dynamic> conditions);
}

/// Repository مع دعم التخزين المؤقت والمزامنة
abstract class CachedRepository<T extends BaseModel> extends Repository<T> {
  /// الحصول على البيانات من التخزين المؤقت أولاً
  Future<Result<List<T>>> getAllCached({bool forceRefresh = false});
  
  /// الحصول على عنصر من التخزين المؤقت
  Future<Result<T>> getByIdCached(String id, {bool forceRefresh = false});
  
  /// مزامنة البيانات مع الخادم
  Future<Result<void>> sync();
  
  /// مسح التخزين المؤقت
  Future<void> clearCache();
  
  /// التحقق من وجود بيانات في التخزين المؤقت
  Future<bool> hasCachedData();
  
  /// الحصول على وقت آخر مزامنة
  Future<DateTime?> getLastSyncTime();
}

/// نموذج للصفحات (Pagination)
class PageRequest {
  final int page;
  final int limit;
  final String? sortBy;
  final bool ascending;
  final Map<String, dynamic>? filters;

  const PageRequest({
    this.page = 1,
    this.limit = 20,
    this.sortBy,
    this.ascending = true,
    this.filters,
  });

  PageRequest copyWith({
    int? page,
    int? limit,
    String? sortBy,
    bool? ascending,
    Map<String, dynamic>? filters,
  }) {
    return PageRequest(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      sortBy: sortBy ?? this.sortBy,
      ascending: ascending ?? this.ascending,
      filters: filters ?? this.filters,
    );
  }

  /// تحويل إلى معاملات استعلام
  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      'sort_ascending': ascending,
    };
    
    if (sortBy != null) params['sort_by'] = sortBy;
    if (filters != null) params.addAll(filters!);
    
    return params;
  }

  @override
  String toString() => 'PageRequest(page: $page, limit: $limit, sortBy: $sortBy)';
}

/// نموذج للنتائج المقسمة إلى صفحات
class PagedResult<T> {
  final List<T> items;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  const PagedResult({
    required this.items,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PagedResult.empty() {
    return const PagedResult(
      items: [],
      totalCount: 0,
      currentPage: 1,
      totalPages: 0,
      hasNext: false,
      hasPrevious: false,
    );
  }

  @override
  String toString() => 'PagedResult(items: ${items.length}, total: $totalCount, page: $currentPage/$totalPages)';
}

/// Repository مع دعم الصفحات
abstract class PagedRepository<T extends BaseModel> extends CachedRepository<T> {
  /// الحصول على صفحة من البيانات
  Future<Result<PagedResult<T>>> getPage(PageRequest request);
  
  /// البحث مع الصفحات
  Future<Result<PagedResult<T>>> searchPaged(String query, PageRequest request);
}