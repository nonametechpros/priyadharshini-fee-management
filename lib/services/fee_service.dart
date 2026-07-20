import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_payment.dart';
import '../models/fee_status.dart';
import 'activity_log_service.dart';
import 'paged_result.dart';
import 'payment_filter.dart';

class FeeService {
  FeeService({FirebaseFirestore? firestore, ActivityLogService? activityLogService})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _activityLogService = activityLogService ?? ActivityLogService();

  final FirebaseFirestore _firestore;
  final ActivityLogService _activityLogService;

  CollectionReference<Map<String, dynamic>> get _fees => _firestore.collection('fees');

  Stream<List<FeePayment>> watchPaymentsForStudent(String studentId) {
    return _fees
        .where('studentId', isEqualTo: studentId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(FeePayment.fromDoc).toList());
  }

  /// Most recent payments across all students, for the Admin dashboard.
  Stream<List<FeePayment>> watchRecentPayments({int limit = 10}) {
    return _fees
        .orderBy('paymentDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(FeePayment.fromDoc).toList());
  }

  /// Paginated, date-range-filterable payments for the "All Payments" screen.
  Future<PagedResult<FeePayment>> fetchPaymentsPage({
    required PaymentFilter filter,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 20,
  }) async {
    Query<Map<String, dynamic>> query = _fees;
    if (filter.from != null) {
      query = query.where('paymentDate', isGreaterThanOrEqualTo: Timestamp.fromDate(filter.from!));
    }
    if (filter.to != null) {
      query = query.where('paymentDate', isLessThanOrEqualTo: Timestamp.fromDate(filter.to!));
    }
    query = query.orderBy('paymentDate', descending: true).limit(pageSize + 1);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final hasMore = docs.length > pageSize;
    final pageDocs = hasMore ? docs.sublist(0, pageSize) : docs;

    return PagedResult<FeePayment>(
      items: pageDocs.map(FeePayment.fromDoc).toList(),
      lastDocument: pageDocs.isEmpty ? startAfter : pageDocs.last,
      hasMore: hasMore,
    );
  }

  /// Records a payment and atomically recalculates the student's
  /// amountPaid / feeStatus so the two never drift apart.
  Future<void> recordPayment({
    required String studentId,
    required String studentName,
    required double amount,
    required DateTime paymentDate,
    required PaymentMode mode,
    required String recordedByUid,
    required String recordedByName,
  }) async {
    final studentRef = _firestore.collection('students').doc(studentId);
    final feeRef = _fees.doc();

    await _firestore.runTransaction((tx) async {
      final studentSnap = await tx.get(studentRef);
      if (!studentSnap.exists) {
        throw StateError('Student not found');
      }
      final data = studentSnap.data()!;
      final totalAmount = (data['totalAmount'] as num?)?.toDouble() ?? 0;
      final currentPaid = (data['amountPaid'] as num?)?.toDouble() ?? 0;
      final newPaid = currentPaid + amount;
      final newStatus = feeStatusFor(totalAmount: totalAmount, amountPaid: newPaid);

      tx.set(feeRef, {
        'studentId': studentId,
        'studentName': studentName,
        'amount': amount,
        'paymentDate': Timestamp.fromDate(paymentDate),
        'mode': mode.name,
        'recordedBy': recordedByUid,
        'recordedByName': recordedByName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(studentRef, {
        'amountPaid': newPaid,
        'feeStatus': newStatus.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _activityLogService.log(
      action: 'payment_recorded',
      entity: 'fee',
      entityId: feeRef.id,
      performedBy: recordedByUid,
      performedByName: recordedByName,
      details: 'Recorded payment of ₹$amount for $studentName',
    );
  }
}
