import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/models/task_model.dart';

void main() {
  test('TaskModel copyWith keeps unchanged fields', () {
    final createdAt = DateTime(2026, 5, 13);
    final dueDate = DateTime(2026, 5, 14);
    final task = TaskModel(
      id: 'task-1',
      title: 'Plan sprint',
      description: 'Choose the most valuable work',
      dueDate: dueDate,
      status: TaskModel.pendingStatus,
      createdAt: createdAt,
      priority: TaskModel.mediumPriority,
      userId: 'user-1',
    );

    final updatedTask = task.copyWith(
      status: TaskModel.completedStatus,
      priority: TaskModel.highPriority,
    );

    expect(updatedTask.title, task.title);
    expect(updatedTask.description, task.description);
    expect(updatedTask.status, TaskModel.completedStatus);
    expect(updatedTask.priority, TaskModel.highPriority);
    expect(updatedTask.createdAt, createdAt);
    expect(updatedTask.dueDate, dueDate);
  });
}
