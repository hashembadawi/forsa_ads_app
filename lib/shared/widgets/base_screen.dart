import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base class for all stateless screens in the app
abstract class BaseScreen extends ConsumerWidget {
  const BaseScreen({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: buildAppBar(context, ref),
      body: buildBody(context, ref),
      bottomNavigationBar: buildBottomNavigationBar(context, ref),
      floatingActionButton: buildFloatingActionButton(context, ref),
    );
  }
  
  /// Override this method to build the app bar
  PreferredSizeWidget? buildAppBar(BuildContext context, WidgetRef ref) => null;
  
  /// Override this method to build the main body
  Widget buildBody(BuildContext context, WidgetRef ref);
  
  /// Override this method to build bottom navigation bar
  Widget? buildBottomNavigationBar(BuildContext context, WidgetRef ref) => null;
  
  /// Override this method to build floating action button
  Widget? buildFloatingActionButton(BuildContext context, WidgetRef ref) => null;
}

/// Base class for all stateful screens in the app
abstract class BaseStatefulScreen extends ConsumerStatefulWidget {
  const BaseStatefulScreen({super.key});
}

abstract class BaseStatefulScreenState<T extends BaseStatefulScreen> 
    extends ConsumerState<T> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, ref),
      body: buildBody(context, ref),
      bottomNavigationBar: buildBottomNavigationBar(context, ref),
      floatingActionButton: buildFloatingActionButton(context, ref),
    );
  }
  
  /// Override this method to build the app bar
  PreferredSizeWidget? buildAppBar(BuildContext context, WidgetRef ref) => null;
  
  /// Override this method to build the main body
  Widget buildBody(BuildContext context, WidgetRef ref);
  
  /// Override this method to build bottom navigation bar
  Widget? buildBottomNavigationBar(BuildContext context, WidgetRef ref) => null;
  
  /// Override this method to build floating action button
  Widget? buildFloatingActionButton(BuildContext context, WidgetRef ref) => null;
}