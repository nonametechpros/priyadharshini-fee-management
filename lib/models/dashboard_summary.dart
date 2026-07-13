import 'course_type.dart';

class CourseTypeBreakdown {
  final int count;
  final double collected;
  final double pending;

  const CourseTypeBreakdown({required this.count, required this.collected, required this.pending});

  static const empty = CourseTypeBreakdown(count: 0, collected: 0, pending: 0);
}

class DashboardSummary {
  final int totalStudents;
  final int totalStaff;
  final double totalCollected;
  final double totalPending;
  final CourseTypeBreakdown mcwg;
  final CourseTypeBreakdown mcwog;
  final CourseTypeBreakdown lmv;

  const DashboardSummary({
    required this.totalStudents,
    required this.totalStaff,
    required this.totalCollected,
    required this.totalPending,
    required this.mcwg,
    required this.mcwog,
    required this.lmv,
  });

  static const empty = DashboardSummary(
    totalStudents: 0,
    totalStaff: 0,
    totalCollected: 0,
    totalPending: 0,
    mcwg: CourseTypeBreakdown.empty,
    mcwog: CourseTypeBreakdown.empty,
    lmv: CourseTypeBreakdown.empty,
  );
}

/// One point on the "monthly collections" line chart: total fee amount
/// collected during [month] (normalized to the 1st).
class MonthlyCollection {
  final DateTime month;
  final double amount;

  const MonthlyCollection({required this.month, required this.amount});
}

/// One row of the Reports page's "Monthly Fee Summary" table: for [month]
/// and [course], the amount collected from that course's students during the
/// month, plus the outstanding balance of that course's students whose
/// joining date falls in the month. A student with more than one course
/// contributes their full amounts to each course, matching how the
/// "Collection & Pending Dues" breakdown already counts multi-course
/// students.
class MonthlyFeeSummary {
  final DateTime month;
  final CourseType course;
  final double collected;
  final double pending;

  const MonthlyFeeSummary({required this.month, required this.course, required this.collected, required this.pending});
}
