import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../ui/notifications.dart';

/// Lightweight network connectivity helpers.
/// Uses a short TCP connect to a public DNS server to verify internet access.
class NetworkUtils {
  /// Attempts a quick socket connect to a known DNS address (8.8.8.8:53).
  /// Returns true if the connection succeeds within [timeout].
  static Future<bool> hasNetwork({Duration timeout = const Duration(seconds: 2)}) async {
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: timeout);
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Convenience: check connectivity and show a user-friendly notification
  /// if offline. Returns the connectivity boolean.
  static Future<bool> ensureConnected(BuildContext context, {Duration timeout = const Duration(seconds: 2)}) async {
    final ok = await hasNetwork(timeout: timeout);
    if (!ok) {
      // Ensure the context is still valid before showing UI
      if (context.mounted) {
        Notifications.showError(context, AppStrings.noInternet);
      }
    }
    return ok;
  }
}
