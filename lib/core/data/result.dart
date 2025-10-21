/// Generic result type للتعامل مع العمليات التي قد تفشل
sealed class Result<T> {
  const Result();
  
  /// نجح العملية مع البيانات
  const factory Result.success(T data) = Success<T>;
  
  /// فشلت العملية مع خطأ
  const factory Result.failure(Exception error) = Failure<T>;
  
  /// التحقق من نجاح العملية
  bool get isSuccess => this is Success<T>;
  
  /// التحقق من فشل العملية
  bool get isFailure => this is Failure<T>;
  
  /// الحصول على البيانات (null إذا فشلت)
  T? get data => isSuccess ? (this as Success<T>).data : null;
  
  /// الحصول على الخطأ (null إذا نجحت)
  Exception? get error => isFailure ? (this as Failure<T>).error : null;
  
  /// تطبيق دالة على البيانات إذا نجحت العملية
  Result<R> map<R>(R Function(T data) mapper) {
    return isSuccess 
        ? Result.success(mapper((this as Success<T>).data))
        : Result.failure((this as Failure<T>).error);
  }
  
  /// تطبيق دالة async على البيانات إذا نجحت العملية
  Future<Result<R>> mapAsync<R>(Future<R> Function(T data) mapper) async {
    if (isSuccess) {
      try {
        final result = await mapper((this as Success<T>).data);
        return Result.success(result);
      } catch (e) {
        return Result.failure(e is Exception ? e : Exception(e.toString()));
      }
    } else {
      return Result.failure((this as Failure<T>).error);
    }
  }
  
  /// تطبيق دالة على الخطأ إذا فشلت العملية
  Result<T> mapError(Exception Function(Exception error) mapper) {
    return isFailure 
        ? Result.failure(mapper((this as Failure<T>).error))
        : this;
  }
  
  /// الحصول على البيانات أو قيمة افتراضية
  T getOrElse(T defaultValue) => data ?? defaultValue;
  
  /// الحصول على البيانات أو تشغيل دالة
  T getOrElseThrow([Exception Function()? errorFactory]) {
    if (isSuccess) {
      return data!;
    } else {
      throw errorFactory?.call() ?? error!;
    }
  }
}

/// نجح العملية
final class Success<T> extends Result<T> {
  @override
  final T data;
  
  const Success(this.data);
  
  @override
  String toString() => 'Success(data: $data)';
  
  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
           (other is Success<T> && other.data == data);
  }
  
  @override
  int get hashCode => data.hashCode;
}

/// فشلت العملية
final class Failure<T> extends Result<T> {
  @override
  final Exception error;
  
  const Failure(this.error);
  
  @override
  String toString() => 'Failure(error: $error)';
  
  @override
  bool operator ==(Object other) {
    return identical(this, other) || 
           (other is Failure<T> && other.error == error);
  }
  
  @override
  int get hashCode => error.hashCode;
}

  /// Extensions — مساعدة للتعامل مع `Future<Result<T>>`
extension FutureResultExtension<T> on Future<Result<T>> {
  /// تطبيق دالة على النتيجة
  Future<Result<R>> mapResult<R>(R Function(T data) mapper) async {
    final result = await this;
    return result.map(mapper);
  }
  
  /// تطبيق دالة async على النتيجة
  Future<Result<R>> flatMapResult<R>(Future<Result<R>> Function(T data) mapper) async {
    final result = await this;
    if (result is Success<T>) {
      return await mapper(result.data);
    } else if (result is Failure<T>) {
      return Result.failure(result.error);
    } else {
      // Fallback: treat as failure with a generic exception
      return Result.failure(Exception('Unexpected result state'));
    }
  }
  
  /// التعامل مع النتيجة
  Future<void> handle({
    required void Function(T data) onSuccess,
    required void Function(Exception error) onFailure,
  }) async {
    final result = await this;
    if (result is Success<T>) {
      onSuccess(result.data);
    } else if (result is Failure<T>) {
      onFailure(result.error);
    } else {
      onFailure(Exception('Unexpected result state'));
    }
  }
}