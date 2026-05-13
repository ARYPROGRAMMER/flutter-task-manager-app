import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionPath = 'tasks';

  Stream<List<TaskModel>> userTasksStream(String userId) {
    try {
      return _firestore
          .collection(_collectionPath)
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final taskList = snapshot.docs
                .map((doc) => TaskModel.fromFirestore(doc))
                .toList();
            taskList.sort((firstTask, secondTask) {
              return secondTask.createdAt.compareTo(firstTask.createdAt);
            });
            return taskList;
          })
          .handleError((Object error) {
            throw FirestoreServiceException(
              'Unable to load tasks. ${error.toString()}',
            );
          });
    } catch (error) {
      return Stream.error(
        FirestoreServiceException('Unable to load tasks. ${error.toString()}'),
      );
    }
  }

  Future<void> addTask(TaskModel task) async {
    try {
      await _firestore.collection(_collectionPath).add(task.toMap());
    } catch (error) {
      throw FirestoreServiceException(
        'Unable to add task. ${error.toString()}',
      );
    }
  }

  Future<void> updateTask(TaskModel task) async {
    try {
      await _firestore
          .collection(_collectionPath)
          .doc(task.id)
          .update(task.toMap());
    } catch (error) {
      throw FirestoreServiceException(
        'Unable to update task. ${error.toString()}',
      );
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await _firestore.collection(_collectionPath).doc(taskId).delete();
    } catch (error) {
      throw FirestoreServiceException(
        'Unable to delete task. ${error.toString()}',
      );
    }
  }

  Future<void> updateTaskStatus(TaskModel task, String status) async {
    await updateTask(task.copyWith(status: status));
  }
}

class FirestoreServiceException implements Exception {
  final String message;

  const FirestoreServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
