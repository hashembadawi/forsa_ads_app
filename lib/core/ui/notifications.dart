import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import '../constants/strings.dart';
import '../../shared/widgets/app_button.dart';
import 'app_keys.dart';
import '../theme/app_theme.dart';

enum NotificationType { info, success, error, warning }

class Notifications {
  static bool _isLoadingVisible = false;
  static OverlayEntry? _snackEntry;
  static GlobalKey<_TopSnackWidgetState>? _snackKey;

  static IconData _defaultIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  static Color _backgroundColorForType(NotificationType type, {required BuildContext ctx}) {
    switch (type) {
      case NotificationType.success:
        return AppTheme.successColor.withOpacity(0.1); // أخضر فاتح
      case NotificationType.error:
        return AppTheme.errorColor.withOpacity(0.1); // أحمر فاتح
      case NotificationType.warning:
        return AppTheme.warningColor.withOpacity(0.1); // برتقالي فاتح
      case NotificationType.info:
        return AppTheme.infoColor.withOpacity(0.1); // أزرق فاتح
    }
  }

  static Color _iconColorForType(NotificationType type) {
    switch (type) {
      case NotificationType.success:
        return AppTheme.successColor; // أخضر
      case NotificationType.error:
        return AppTheme.errorColor; // أحمر
      case NotificationType.warning:
        return AppTheme.warningColor; // برتقالي
      case NotificationType.info:
        return AppTheme.infoColor; // أزرق فاتح
    }
  }
  static const Duration _defaultDuration = Duration(seconds: 3);
  // prettier loading: frosted blur + scale card
  static void showLoading(BuildContext context, {String? message}) {
    if (_isLoadingVisible) return;
    _isLoadingVisible = true;

    showGeneralDialog(
      barrierDismissible: false,
      barrierLabel: 'loading',
      context: context,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, a1, a2) {
        // WillPopScope is deprecated in newer Flutter versions; PopScope is the replacement.
        // PopScope/PopDisposition may not be available on the project's Flutter SDK. Keep WillPopScope
        // for compatibility and ignore the deprecation locally until an SDK upgrade allows a full migration.
        // ignore: deprecated_member_use
        return WillPopScope(
          onWillPop: () async => false,
          child: Stack(
            children: [
              // Frosted blur backdrop
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
              Center(
                child: ScaleTransition(
                  scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).dialogTheme.backgroundColor ?? Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.14), blurRadius: 18)],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      // soft animated indicator
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.9), AppTheme.primaryDarkColor.withOpacity(0.9)]),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Flexible(child: Text(message ?? AppStrings.defaultLoading, style: Theme.of(context).textTheme.bodyLarge)),
                    ]),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (ctx, a1, a2, child) => FadeTransition(opacity: a1, child: child),
    );
  }

  static void hideLoading(BuildContext context) {
    try {
      if (!_isLoadingVisible) return;
      // Navigator may not be available on the provided context (e.g. app-level
      // context before MaterialApp's navigator is attached). Try the provided
      // context first, then fall back to the global navigator key.
      final nav = Navigator.maybeOf(context) ?? appNavigatorKey.currentState;
      if (nav != null) {
        try {
          // Pop without checking canPop() because dialogs presented by
          // showGeneralDialog may not be considered a regular route to
          // canPop(), but a direct pop will still close it.
          nav.pop();
        } catch (_) {
          // ignore
        }
      } else {
        // As a last resort, ensure any overlay snack/entries are removed so
        // the UI is not blocked.
        try {
          _removeSnack();
        } catch (_) {}
      }
      _isLoadingVisible = false;
    } catch (_) {}
  }

  // Dialogs: success / error / confirm use a consistent modal with icon
  static void showSuccess(BuildContext context, String message, {String? okText, VoidCallback? onOk}) {
  _showIconDialog(context, message: message, icon: Icons.check_circle, iconColor: AppTheme.successColor, okText: okText ?? AppStrings.ok, onOk: onOk);
  }

  static void showError(BuildContext context, String message, {String? okText, VoidCallback? onOk}) {
  _showIconDialog(context, message: message, icon: Icons.error, iconColor: AppTheme.errorColor, okText: okText ?? AppStrings.ok, onOk: onOk);
  }

  static Future<bool?> showConfirm(BuildContext context, String message, {String? confirmText, String? cancelText}) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => _buildConfirmDialog(dialogContext, message, confirmText: confirmText ?? AppStrings.yes, cancelText: cancelText ?? AppStrings.cancel),
    );
  }

  // Top sliding overlay snack (more visible and pretty)
  static void showSnack(
    BuildContext context,
    String msg, {
    Duration duration = _defaultDuration,
    IconData? icon,
    NotificationType type = NotificationType.info,
    String? actionText,
    VoidCallback? onAction,
  }) {
    // remove existing gracefully
    if (_snackKey != null) {
      try {
        _snackKey?.currentState?.dismiss();
      } catch (_) {}
    }

    // Try to obtain an OverlayState safely. Fall back to global navigator overlay.
    OverlayState? overlayState;
    try {
      overlayState = Overlay.of(context);
    } catch (_) {
      overlayState = null;
    }
    overlayState ??= appNavigatorKey.currentState?.overlay;

  _snackKey = GlobalKey<_TopSnackWidgetState>();
  final typeIcon = icon ?? _defaultIconForType(type);
  final bgColor = _backgroundColorForType(type, ctx: context);
  final iconColor = _iconColorForType(type);

    final entry = OverlayEntry(builder: (ctx) {
      return _TopSnackWidget(
        key: _snackKey,
        message: msg,
        icon: typeIcon,
        backgroundColor: bgColor,
        iconColor: iconColor,
        duration: duration,
        actionText: actionText,
        onAction: onAction,
        onDismissed: () {
          try {
            _snackEntry?.remove();
          } catch (_) {}
          _snackEntry = null;
          _snackKey = null;
        },
      );
    });

    _snackEntry = entry;
    if (overlayState != null) {
      try {
        overlayState.insert(entry);
        return;
      } catch (_) {
        // fall through to dialog fallback
      }
    }

  // Fallback: show a dialog so the user still receives feedback.
  try {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        content: Text(msg),
        actions: [TextButton(onPressed: () => Navigator.maybeOf(dialogCtx)?.pop(), child: const Text('OK'))],
      ),
    );
  } catch (_) {
    // Try global context as a last resort
    try {
      final globalContext = appNavigatorKey.currentContext;
      if (globalContext != null) {
        showDialog<void>(
          context: globalContext,
          builder: (dialogCtx) => AlertDialog(
            content: Text(msg),
            actions: [TextButton(onPressed: () => Navigator.maybeOf(dialogCtx)?.pop(), child: const Text('OK'))],
          ),
        );
      }
    } catch (_) {}
  }
  }

  static void _removeSnack() {
    try {
      // Request widget to animate out then remove. If key/state missing,
      // remove immediately.
      if (_snackKey != null) {
        _snackKey?.currentState?.dismiss();
      } else {
        _snackEntry?.remove();
        _snackEntry = null;
      }
    } catch (_) {}
  }

  // Helpers
  static void _showIconDialog(BuildContext context, {required String message, required IconData icon, required Color iconColor, required String okText, VoidCallback? onOk}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 42, color: iconColor),
              const SizedBox(height: 12),
              // Title removed intentionally (icon-only header)
              Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: okText,
                  onPressed: () {
                    Navigator.maybeOf(dialogContext)?.pop();
                    if (onOk != null) onOk();
                  },
                  fullWidth: true,
                  size: AppButtonSize.medium,
                  variant: AppButtonVariant.filled,
                ),
              ),
            ]),
          ),
        );
      },
    );
  }

  static Widget _buildConfirmDialog(BuildContext context, String message, {required String confirmText, required String cancelText}) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.help_outline, size: 36, color: AppTheme.infoColor),
          const SizedBox(height: 10),
          // Title removed intentionally (icon-only header)
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: AppButton.outlined(
                text: cancelText,
                    onPressed: () => Navigator.maybeOf(context)?.pop(false),
                fullWidth: true,
                size: AppButtonSize.medium,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                text: confirmText,
                    onPressed: () => Navigator.maybeOf(context)?.pop(true),
                fullWidth: true,
                size: AppButtonSize.medium,
                variant: AppButtonVariant.filled,
              ),
            ),
          ])
        ]),
      ),
    );
  }
}

// A compact top snack widget that slides from the top and auto-dismisses
class _TopSnackWidget extends StatefulWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Duration? duration;
  final String? actionText;
  final VoidCallback? onAction;
  final VoidCallback? onDismissed;

  const _TopSnackWidget({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.iconColor,
    this.duration,
    this.actionText,
    this.onAction,
    this.onDismissed,
  });

  @override
  State<_TopSnackWidget> createState() => _TopSnackWidgetState();
}

class _TopSnackWidgetState extends State<_TopSnackWidget> with SingleTickerProviderStateMixin {
  late final AnimationController ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 360));
  late final Animation<Offset> offset = Tween(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOutCubic));

  bool dismissing = false;
  Timer? autoTimer;
  Timer? progressTimer;
  late final Duration durationValue;
  double progress = 0.0;

  @override
  void initState() {
  super.initState();
  ctrl.forward();
  durationValue = widget.duration ?? Notifications._defaultDuration;

    // progress ticker updates _progress until duration elapses
    int totalMs = durationValue.inMilliseconds;
    int elapsed = 0;
    const tickMs = 50;
    progressTimer = Timer.periodic(const Duration(milliseconds: tickMs), (t) {
      elapsed += tickMs;
      setState(() {
        progress = (elapsed / totalMs).clamp(0.0, 1.0);
      });
      if (elapsed >= totalMs) {
        t.cancel();
      }
    });

    autoTimer = Timer(durationValue, () => dismiss());
  }

  @override
  void dispose() {
    ctrl.dispose();
    autoTimer?.cancel();
    progressTimer?.cancel();
    super.dispose();
  }

  /// Animate out then call the onDismissed callback so the overlay entry can be removed.
  Future<void> dismiss() async {
    if (dismissing) return;
    dismissing = true;
    try {
      await ctrl.reverse().orCancel;
    } catch (_) {}
    try {
      widget.onDismissed?.call();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: offset,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy < -6) {
                  // swipe up -> dismiss
                  dismiss();
                }
              },
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: widget.backgroundColor ?? Theme.of(context).snackBarTheme.backgroundColor ?? Theme.of(context).colorScheme.surface),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      if (widget.icon != null) Icon(widget.icon, size: 20, color: widget.iconColor ?? Theme.of(context).colorScheme.primary),
                      if (widget.icon != null) const SizedBox(width: 10),
                      Expanded(child: Text(widget.message, style: Theme.of(context).textTheme.bodyMedium)),
                      const SizedBox(width: 8),
                      if (widget.actionText != null && widget.onAction != null)
                        TextButton(onPressed: widget.onAction, child: Text(widget.actionText!)),
                      GestureDetector(onTap: () => dismiss(), child: Icon(Icons.close, size: 18, color: AppTheme.textSecondaryColor)),
                    ]),
                    // Progress bar
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress, backgroundColor: Colors.transparent, valueColor: AlwaysStoppedAnimation<Color>(widget.iconColor ?? Theme.of(context).colorScheme.primary)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
