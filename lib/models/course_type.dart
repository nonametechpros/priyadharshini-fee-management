import 'package:flutter/material.dart';

enum CourseType { mcwg, mcwog, lmv, heavy }

extension CourseTypeLabel on CourseType {
  String get label {
    switch (this) {
      case CourseType.mcwg:
        return 'MCWG';
      case CourseType.mcwog:
        return 'MCWOG';
      case CourseType.lmv:
        return 'LMV';
      case CourseType.heavy:
        return 'Heavy Vehicle';
    }
  }

  IconData get icon {
    switch (this) {
      case CourseType.mcwg:
      case CourseType.mcwog:
        return Icons.two_wheeler;
      case CourseType.lmv:
        return Icons.directions_car;
      case CourseType.heavy:
        return Icons.local_shipping;
    }
  }
}

/// Course types offered to new/edited students. Heavy Vehicle is retired
/// from new entries but stays in [CourseType] so older student records that
/// still have it keep displaying correctly.
const List<CourseType> selectableCourseTypes = [CourseType.mcwg, CourseType.mcwog, CourseType.lmv];

CourseType courseTypeFromString(String value) {
  switch (value) {
    // Pre-MCWG/MCWOG split naming, kept so older documents still resolve.
    case 'twoWheeler':
      return CourseType.mcwg;
    case 'fourWheeler':
      return CourseType.lmv;
  }
  return CourseType.values.firstWhere(
    (c) => c.name == value,
    orElse: () => CourseType.mcwg,
  );
}
