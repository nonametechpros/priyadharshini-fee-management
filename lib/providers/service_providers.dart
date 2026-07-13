import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/activity_log_service.dart';
import '../services/auth_service.dart';
import '../services/dashboard_service.dart';
import '../services/fee_service.dart';
import '../services/staff_service.dart';
import '../services/student_service.dart';

final activityLogServiceProvider = Provider<ActivityLogService>((ref) => ActivityLogService());

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final dashboardServiceProvider = Provider<DashboardService>((ref) => DashboardService());

final feeServiceProvider = Provider<FeeService>(
  (ref) => FeeService(activityLogService: ref.watch(activityLogServiceProvider)),
);

final staffServiceProvider = Provider<StaffService>(
  (ref) => StaffService(activityLogService: ref.watch(activityLogServiceProvider)),
);

final studentServiceProvider = Provider<StudentService>(
  (ref) => StudentService(activityLogService: ref.watch(activityLogServiceProvider)),
);
