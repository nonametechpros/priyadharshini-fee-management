import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_log.dart';

class ActivityLogService {
  ActivityLogService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs => _firestore.collection('activityLogs');

  Future<void> log({
    required String action,
    required String entity,
    required String entityId,
    required String performedBy,
    required String performedByName,
    String details = '',
  }) async {
    final entry = ActivityLog(
      id: '',
      action: action,
      entity: entity,
      entityId: entityId,
      performedBy: performedBy,
      performedByName: performedByName,
      details: details,
    );
    await _logs.add(entry.toMap());
  }

  Stream<List<ActivityLog>> watchRecent({int limit = 25}) {
    return _logs
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityLog.fromDoc).toList());
  }
}

/// Matches the tail of `payment_recorded` details logged before the message
/// included the student's name, e.g. "Recorded payment of 2000 for student
/// 4y0k1DaaOVSTD2np80if" — the trailing token is the raw student doc ID.
final RegExp legacyPaymentLogIdPattern = RegExp(r'^(.*\bfor student )([A-Za-z0-9]{10,})$');

/// `activityLogs` is an append-only audit trail (Firestore rules forbid
/// updates to it), so old entries can't be rewritten in place. This resolves
/// the legacy "for student" plus a raw ID text to a name at display time
/// instead, using an already-fetched id-to-name lookup.
String displayDetailsFor(ActivityLog log, Map<String, String> studentNamesById) {
  final match = legacyPaymentLogIdPattern.firstMatch(log.details);
  if (match == null) return log.details;
  final name = studentNamesById[match.group(2)];
  if (name == null || name.isEmpty) return log.details;
  return '${match.group(1)}$name';
}
