import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_type.dart';
import 'fee_status.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String emailId;
  final String phoneNumber;
  final DateTime joiningDate;
  final Set<CourseType> courseTypes;
  final double totalAmount;
  final double amountPaid;
  final String addedBy;
  final String addedByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    required this.emailId,
    required this.phoneNumber,
    required this.joiningDate,
    required this.courseTypes,
    required this.totalAmount,
    required this.amountPaid,
    required this.addedBy,
    required this.addedByName,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => [firstName, lastName].where((s) => s.isNotEmpty).join(' ');

  /// e.g. "2W, 4W".
  String get courseTypesLabel => courseTypes.map((c) => c.label).join(', ');

  double get amountPending => (totalAmount - amountPaid).clamp(0, double.infinity);

  FeeStatus get feeStatus => feeStatusFor(totalAmount: totalAmount, amountPaid: amountPaid);

  /// Lowercased full name, used for `>=`/`<` prefix-range search on Firestore.
  String get fullNameLower => fullName.toLowerCase();

  String get emailLower => emailId.toLowerCase();

  factory Student.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final courseTypesList = data['courseTypes'] as List<dynamic>?;
    return Student(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp?)?.toDate() ?? DateTime(2000),
      emailId: data['emailId'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      joiningDate: (data['joiningDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Falls back to the legacy single `courseType` field for documents
      // written before multi-select course types were supported.
      courseTypes: courseTypesList != null
          ? courseTypesList.map((c) => courseTypeFromString(c as String)).toSet()
          : {courseTypeFromString(data['courseType'] as String? ?? 'twoWheeler')},
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0,
      addedBy: data['addedBy'] as String? ?? '',
      addedByName: data['addedByName'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'emailId': emailId,
      'phoneNumber': phoneNumber,
      'joiningDate': Timestamp.fromDate(joiningDate),
      'courseTypes': courseTypes.map((c) => c.name).toList(),
      'totalAmount': totalAmount,
      'amountPaid': amountPaid,
      // Denormalized so list queries can filter by fee status directly.
      'feeStatus': feeStatus.name,
      'addedBy': addedBy,
      'addedByName': addedByName,
      'fullNameLower': fullNameLower,
      'emailLower': emailLower,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
