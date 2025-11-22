bool looksLikeNoInternet(String? msg) {
  if (msg == null) return false;
  final lower = msg.toLowerCase();
  return lower.contains('failed host lookup') ||
      lower.contains('name or service not known') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('enetunreach') ||
      lower.contains('socketexception') ||
      lower.contains('connection timed out') ||
      lower.contains('connection timeout') ||
  lower.contains('no internet') ||
  // Arabic phrases commonly observed in message strings
  lower.contains('لا يوجد اتصال') ||
  lower.contains('لا يوجد اتصال بالإنترنت') ||
  lower.contains('تحقق من اتصالك') ||
  lower.contains('تحقق من اتصال الشبكة');
}
