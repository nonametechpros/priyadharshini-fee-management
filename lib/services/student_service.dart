import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';
import 'activity_log_service.dart';
import 'paged_result.dart';
import 'student_filter.dart';

const int defaultPageSize = 15;

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
  /// legacy activity-log text at render time.
  Future<Map<String, String>> fetchNamesById(Iterable<String> ids) async {
    final result = <String, String>{};
    for (final id in ids) {
      final doc = await _students.doc(id).get();
      if (doc.exists) result[id] = Student.fromDoc(doc).fullName;
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

  Future<void> deleteStudent(String studentId, String studentName,
      {required String performedByUid, required String performedByName}) async {
    await _students.doc(studentId).delete();
    await _activityLogService.log(
      action: 'student_deleted',
      entity: 'student',
      entityId: studentId,
      performedBy: performedByUid,
      performedByName: performedByName,
      details: 'Deleted student $studentName',
    );
  }
}
