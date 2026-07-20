import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import 'activity_log_service.dart';
import 'paged_result.dart';
import 'student_filter.dart';

const int defaultPageSize = 20;

/// What deleting a student would take with it, shown in the confirmation
/// dialog before [StudentService.deleteStudent] actually cascades.
class StudentDeletionImpact {
  final int paymentCount;
  final double totalPaymentAmount;
  final int activityLogCount;

  const StudentDeletionImpact({
    required this.paymentCount,
    required this.totalPaymentAmount,
    required this.activityLogCount,
  });
}

class StudentService {
  StudentService({FirebaseFirestore? firestore, ActivityLogService? activityLogService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _activityLogService = activityLogService ?? ActivityLogService();

  final FirebaseFirestore _firestore;
  final ActivityLogService _activityLogService;

  CollectionReference<Map<String, dynamic>> get _students => _firestore.collection('students');

  /// Builds the Firestore query for the given filters. Both Admin and Staff
  /// see every student regardless of who added them; `filter.addedByUid`
  /// lets either role narrow the list down to one staff member's students.
  Query<Map<String, dynamic>> _buildQuery({required StudentFilter filter}) {
    Query<Map<String, dynamic>> query = _students;

    if (filter.addedByUid != null) {
      query = query.where('addedBy', isEqualTo: filter.addedByUid);
    }

    if (filter.courseType != null) {
      query = query.where('courseTypes', arrayContains: filter.courseType!.name);
    }
    if (filter.feeStatus != null) {
      query = query.where('feeStatus', isEqualTo: filter.feeStatus!.name);
    }

    if (filter.hasSearch) {
      final term = filter.searchTerm.trim().toLowerCase();
      query = query
          .orderBy('fullNameLower')
          .where('fullNameLower', isGreaterThanOrEqualTo: term)
          .where('fullNameLower', isLessThan: '$term');
    } else if (filter.hasDateRange) {
      query = query.orderBy('joiningDate');
      if (filter.joiningFrom != null) {
        query = query.where('joiningDate', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.joiningFrom!));
      }
      if (filter.joiningTo != null) {
        query = query.where('joiningDate', isLessThanOrEqualTo: Timestamp.fromDate(filter.joiningTo!));
      }
    } else {
      query = query.orderBy('createdAt', descending: true);
    }

    return query;
  }

  Future<PagedResult<Student>> fetchPage({
    required StudentFilter filter,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = defaultPageSize,
  }) async {
    var query = _buildQuery(filter: filter).limit(pageSize + 1);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;

    return PagedResult<Student>(
      items: pageDocs.map(Student.fromDoc).toList(),
      lastDocument: pageDocs.isEmpty ? startAfter : pageDocs.last,
      hasMore: hasMore,
    );
  }

  Stream<Student> watchStudent(String studentId) {
    return _students.doc(studentId).snapshots().map(Student.fromDoc);
  }

  /// Resolves a handful of student IDs to display names, e.g. for repairing
  /// legacy activity-log text at render time. Batches lookups via
  /// `whereIn` (max 30 IDs per query) instead of one round-trip per ID.
  Future<Map<String, String>> fetchNamesById(Iterable<String> ids) async {
    final idList = ids.toSet().toList();
    if (idList.isEmpty) return {};

    final result = <String, String>{};
    for (var i = 0; i < idList.length; i += 30) {
      final chunk = idList.sublist(i, i + 30 > idList.length ? idList.length : i + 30);
      final snapshot = await _students.where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        result[doc.id] = Student.fromDoc(doc).fullName;
      }
    }
    return result;
  }

  Future<String> addStudent(Student student, {required String performedByUid, required String performedByName}) async {
    final doc = await _students.add(student.toMap()..['createdAt'] = FieldValue.serverTimestamp());
    await _activityLogService.log(
      action: 'student_added',
      entity: 'student',
      entityId: doc.id,
      performedBy: performedByUid,
      performedByName: performedByName,
      details: 'Added student ${student.fullName}',
    );
    return doc.id;
  }

  Future<void> updateStudent(Student student, {required String performedByUid, required String performedByName}) async {
    await _students.doc(student.id).update(student.toMap());
    await _activityLogService.log(
      action: 'student_updated',
      entity: 'student',
      entityId: student.id,
      performedBy: performedByUid,
      performedByName: performedByName,
      details: 'Updated student ${student.fullName}',
    );
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _feesFor(String studentId) async {
    final snapshot = await _firestore.collection('fees').where('studentId', isEqualTo: studentId).get();
    return snapshot.docs;
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> _activityLogsFor(
    String studentId,
    List<String> feeIds,
  ) async {
    final logs = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final studentLogs = await _firestore
        .collection('activityLogs')
        .where('entity', isEqualTo: 'student')
        .where('entityId', isEqualTo: studentId)
        .get();
    logs.addAll(studentLogs.docs);

    for (var i = 0; i < feeIds.length; i += 30) {
      final chunk = feeIds.sublist(i, i + 30 > feeIds.length ? feeIds.length : i + 30);
      if (chunk.isEmpty) continue;
      final feeLogs = await _firestore
          .collection('activityLogs')
          .where('entity', isEqualTo: 'fee')
          .where('entityId', whereIn: chunk)
          .get();
      logs.addAll(feeLogs.docs);
    }
    return logs;
  }

  /// Previews what [deleteStudent] would take with it, for the confirmation
  /// dialog shown before the (irreversible) cascade delete runs.
  Future<StudentDeletionImpact> previewDeletionImpact(String studentId) async {
    final fees = await _feesFor(studentId);
    final logs = await _activityLogsFor(studentId, fees.map((d) => d.id).toList());
    final total = fees.fold<double>(0, (acc, d) => acc + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
    return StudentDeletionImpact(paymentCount: fees.length, totalPaymentAmount: total, activityLogCount: logs.length);
  }

  /// Deletes a student along with every fee/payment record and activity-log
  /// entry tied to them, so no orphaned "Unknown student" payments are left
  /// behind. Irreversible; callers must confirm with [previewDeletionImpact]
  /// first. Fees/logs are deleted before the student document itself, since
  /// the security rules re-verify student ownership while it still exists.
  Future<void> deleteStudent(String studentId, String studentName,
      {required String performedByUid, required String performedByName}) async {
    final fees = await _feesFor(studentId);
    final feeIds = fees.map((d) => d.id).toList();
    final logs = await _activityLogsFor(studentId, feeIds);

    final batch = _firestore.batch();
    for (final doc in fees) {
      batch.delete(doc.reference);
    }
    for (final doc in logs) {
      batch.delete(doc.reference);
    }
    batch.delete(_students.doc(studentId));
    await batch.commit();

    await _activityLogService.log(
      action: 'student_deleted',
      entity: 'student',
      entityId: studentId,
      performedBy: performedByUid,
      performedByName: performedByName,
      details:
          'Deleted student $studentName (also removed ${fees.length} payment(s) and ${logs.length} activity log entr${logs.length == 1 ? 'y' : 'ies'})',
    );
  }
}
