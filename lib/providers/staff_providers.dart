import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import 'service_providers.dart';

final staffListProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  return ref.watch(staffServiceProvider).watchStaff();
});
