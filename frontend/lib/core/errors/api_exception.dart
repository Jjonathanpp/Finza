class ApiException implements Exception {
  ApiException(this.status, this.message, [this.data]);

  final int? status;
  final String message;
  final dynamic data;

  @override
  String toString() => message;
}
