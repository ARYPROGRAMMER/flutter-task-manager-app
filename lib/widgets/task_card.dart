import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';

typedef VoidCardCallback = void Function();

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCardCallback onTap;
  final Future<void> Function(bool isCompleted) onStatusChanged;
  final Future<void> Function() onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
  });

  Color _priorityColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (task.priority) {
      case TaskModel.highPriority:
        return colorScheme.error;
      case TaskModel.mediumPriority:
        return colorScheme.tertiary;
      case TaskModel.lowPriority:
        return colorScheme.secondary;
      default:
        return colorScheme.primary;
    }
  }

  String get _priorityLabel {
    if (task.priority.isEmpty) {
      return 'Priority';
    }

    return '${task.priority[0].toUpperCase()}${task.priority.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskModel.completedStatus;
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDay = DateUtils.dateOnly(task.dueDate);
    final isOverdue = !isCompleted && dueDay.isBefore(today);
    final priorityColor = _priorityColor(context);

    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (shouldDelete != true) {
          return false;
        }

        try {
          await onDelete();
          return true;
        } catch (_) {
          return false;
        }
      },
      background: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Icon(Icons.delete, color: theme.colorScheme.onError),
            ),
          ),
        ),
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 260),
        opacity: isCompleted ? 0.6 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Hero(
            tag: 'task_card_${task.id}',
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isOverdue
                          ? theme.colorScheme.error.withValues(alpha: 0.56)
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.66,
                            ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Transform.scale(
                        scale: 1.08,
                        child: Checkbox(
                          value: isCompleted,
                          onChanged: (value) {
                            if (value != null) {
                              onStatusChanged(value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 260),
                                    style: theme.textTheme.titleMedium!
                                        .copyWith(
                                          decoration: isCompleted
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w900,
                                          height: 1.18,
                                        ),
                                    child: Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withValues(
                                      alpha: 0.14,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _priorityLabel,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: priorityColor,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 260),
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                height: 1.35,
                              ),
                              child: Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Icon(
                                  Icons.event_available,
                                  size: 17,
                                  color: isOverdue
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  DateFormat.yMMMd().format(task.dueDate),
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: isOverdue
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
