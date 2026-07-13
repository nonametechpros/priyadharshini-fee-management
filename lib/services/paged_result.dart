import 'package:cloud_firestore/cloud_firestore.dart';

/// A single page of results from a Firestore cursor-based query, plus the
/// document cursor needed to fetch the next page (`startAfterDocument`).
class PagedResult<T> {
  final List<T> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDocument;
  final bool hasMore;

  const PagedResult({required this.items, required this.lastDocument, required this.hasMore});

  static const PagedResult empty = PagedResult(items: [], lastDocument: null, hasMore: false);
}
