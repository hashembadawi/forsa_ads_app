import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/ui/notifications.dart';
import '../../../../core/utils/network_utils.dart';
import '../providers/app_options_provider.dart';
import '../screens/add_ad_screen.dart';

class AddAdTab extends ConsumerStatefulWidget {
  final Function(int index)? onNavigateToTab;
  
  const AddAdTab({super.key, this.onNavigateToTab});

  @override
  ConsumerState<AddAdTab> createState() => _AddAdTabState();
}

class _AddAdTabState extends ConsumerState<AddAdTab> {
  bool _hasNavigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Navigate only once
    if (!_hasNavigated && mounted) {
      _hasNavigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchOptionsAndNavigate();
      });
    }
  }

    Future<void> _fetchOptionsAndNavigate() async {
      if (!mounted) return;
    
      // Check connectivity first (consistent with app-wide pattern)
      final connected = await NetworkUtils.ensureConnected(context);
      if (!connected) {
        if (mounted) {
          setState(() => _hasNavigated = false);
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(0);
          }
        }
        return;
      }
    
      // Show loading
      Notifications.showLoading(context);
    
      try {
        // Fetch options from backend
        final options = await ref.read(appOptionsProvider.notifier).fetchOptions();
      
        if (!mounted) return;
      
        // Hide loading
        Notifications.hideLoading(context);
      
        if (options == null) {
          // Error occurred (already handled by provider)
          Notifications.showError(context, 'فشل تحميل البيانات. يرجى المحاولة مرة أخرى.');
          // Navigate back to home tab
          if (widget.onNavigateToTab != null) {
            widget.onNavigateToTab!(0);
          }
          setState(() => _hasNavigated = false);
          return;
        }
      
        // Navigate to AddAdScreen with options
        Navigator.of(context).push<int>(
          MaterialPageRoute(
            builder: (context) => AddAdScreen(options: options),
          ),
        ).then((returnTabIndex) {
          // Reset flag when returning
          if (mounted) {
            setState(() => _hasNavigated = false);
          
            // If returnTabIndex is provided, navigate to that tab
            if (returnTabIndex != null && widget.onNavigateToTab != null) {
              widget.onNavigateToTab!(returnTabIndex);
            }
          }
        });
      } catch (e) {
        if (!mounted) return;
      
        // Hide loading
        Notifications.hideLoading(context);
      
        // Show error
        Notifications.showError(context, 'حدث خطأ غير متوقع: $e');
      
        // Navigate back to home tab
        if (widget.onNavigateToTab != null) {
          widget.onNavigateToTab!(0);
        }
        setState(() => _hasNavigated = false);
      }
    }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
