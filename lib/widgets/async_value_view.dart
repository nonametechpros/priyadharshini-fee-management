import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Collapses the loading/error/data states of an [AsyncValue] into a single
/// widget, so screens don't repeat the same `.when(...)` boilerplate.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(BuildContext context, T data) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) => data(context, d),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) {
        debugPrint('DBG AsyncValueView error: $error');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Something went wrong: $error', textAlign: TextAlign.center),
          ),
        );
      },
    );
  }
}
