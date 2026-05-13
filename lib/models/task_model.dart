import 'package:cloud_firestore/cloud_firestore.dart';

class TaskModel {
  static const String pendingStatus = 'pending';
  static const String completedStatus = 'completed';
  static const String lowPriority = 'low';
  static const String mediumPriority = 'medium';
  static const String highPriority = 'high';

  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final String status;
  final DateTime createdAt;
  final String priority;
  final String userId;

  const TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.priority,
    required this.userId,
  });

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? status,
    DateTime? createdAt,
    String? priority,
    String? userId,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      priority: priority ?? this.priority,
      userId: userId ?? this.userId,
    );
  }

  factory TaskModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> documentSnapshot,
  ) {
    final data = documentSnapshot.data() ?? <String, dynamic>{};
    return TaskModel(
      id: documentSnapshot.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      dueDate: _readDate(data['dueDate'], DateTime.now()),
      status: data['status'] ?? pendingStatus,
      createdAt: _readDate(data['createdAt'], DateTime.now()),
      priority: data['priority'] ?? mediumPriority,
      userId: data['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'priority': priority,
      'userId': userId,
    };
  }

  static DateTime _readDate(Object? value, DateTime fallbackDate) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return fallbackDate;
  }
}
