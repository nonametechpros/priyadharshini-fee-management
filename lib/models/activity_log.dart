import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLog {
  final String id;
  final String action;
  final String entity;
  final String entityId;
  final String performedBy;
  final String performedByName;
  final String details;
  final DateTime? timestamp;

  const ActivityLog({
    required this.id,
    required this.action,
    required this.entity,
    required this.entityId,
    required this.performedBy,
    required this.performedByName,
    required this.details,
    this.timestamp,
  });

  factory ActivityLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ActivityLog(
      id: doc.id,
      action: data['action'] as String? ?? '',
      entity: data['entity'] as String? ?? '',
      entityId: data['entityId'] as String? ?? '',
      performedBy: data['performedBy'] as String? ?? '',
      performedByName: data['performedByName'] as String? ?? '',
      details: data['details'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'action': action,
      'entity': entity,
      'entityId': entityId,
      'performedBy': performedBy,
      'performedByName': performedByName,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}
