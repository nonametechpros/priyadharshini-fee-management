import '../models/course_type.dart';
import '../models/fee_status.dart';

/// Filter/search criteria for the Student List screens (shared by Admin &
/// Staff). At most one range condition (search prefix OR joining-date range)
/// is applied at a time, matching what a single Firestore query can express.
class StudentFilter {
  final String searchTerm;
  final CourseType? courseType;
  final FeeStatus? feeStatus;
  final String? addedByUid; // Admin-only: view students added by one staff member.
  final DateTime? joiningFrom;
  final DateTime? joiningTo;

  const StudentFilter({
    this.searchTerm = '',
    this.courseType,
    this.feeStatus,
    this.addedByUid,
    this.joiningFrom,
    this.joiningTo,
  });

  bool get hasSearch => searchTerm.trim().isNotEmpty;
  bool get hasDateRange => joiningFrom != null || joiningTo != null;
  bool get isEmpty =>
      !hasSearch && courseType == null && feeStatus == null && addedByUid == null && !hasDateRange;

  StudentFilter copyWith({
    String? searchTerm,
    CourseType? courseType,
    bool clearCourseType = false,
    FeeStatus? feeStatus,
    bool clearFeeStatus = false,
    String? addedByUid,
    bool clearAddedByUid = false,
    DateTime? joiningFrom,
    DateTime? joiningTo,
    bool clearDateRange = false,
  }) {
    return StudentFilter(
      searchTerm: searchTerm ?? this.searchTerm,
      courseType: clearCourseType ? null : (courseType ?? this.courseType),
      feeStatus: clearFeeStatus ? null : (feeStatus ?? this.feeStatus),
      addedByUid: clearAddedByUid ? null : (addedByUid ?? this.addedByUid),
      joiningFrom: clearDateRange ? null : (joiningFrom ?? this.joiningFrom),
      joiningTo: clearDateRange ? null : (joiningTo ?? this.joiningTo),
    );
  }
}
