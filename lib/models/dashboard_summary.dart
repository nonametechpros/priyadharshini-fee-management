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

/// One payment row in a [FeeSummary]'s date range, for the Reports page's
/// PDF export bill: the payment itself ([date], [studentName], [collected])
/// alongside that student's current overall outstanding balance ([pending]).
class FeeSummaryRow {
  final DateTime date;
  final String studentName;
  final double collected;
  final double pending;

  const FeeSummaryRow({
    required this.date,
    required this.studentName,
    required this.collected,
    required this.pending,
  });
}

/// The Reports page's "Fee Summary" card and PDF export bill, for a selected
/// date range. [collected]/[pending] are the on-screen card's totals;
/// [pending] is the outstanding balance of students whose joining date falls
/// within the range (there's no separate due-date field in the schema).
/// [rows] is one entry per payment made in the range, for the PDF's
/// itemized table.
class FeeSummary {
  final DateTime start;
  final DateTime end;
  final double collected;
  final double pending;
  final List<FeeSummaryRow> rows;

  const FeeSummary({
    required this.start,
    required this.end,
    required this.collected,
    required this.pending,
    required this.rows,
  });
}
