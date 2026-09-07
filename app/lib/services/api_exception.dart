class ApiException implements Exception {
  final int statusCode;
  final String message;
  final int? retryAfterSeconds;

  ApiException(this.statusCode, this.message, {this.retryAfterSeconds});
}