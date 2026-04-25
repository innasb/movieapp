import 'package:flutter/material.dart';

/// Stub for non-web platforms.
Widget buildWebPlayer(String url) {
  return const Center(child: Text('Web player only available on web'));
}

/// No-op on non-web platforms.
void sendPlayerCommand(String command) {}
