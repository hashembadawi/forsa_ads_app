import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        if (mounted) {
          Navigator.of(context).push<int>(
            MaterialPageRoute(builder: (context) => const AddAdScreen()),
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
        }
      });
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
