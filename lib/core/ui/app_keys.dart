import 'package:flutter/material.dart';

// Global keys for navigator and scaffold messenger so notifications can be
// shown from anywhere (including early init code) without depending on a
// BuildContext that must contain a Navigator/Overlay.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
