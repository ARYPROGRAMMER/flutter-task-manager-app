import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';

typedef VoidCardCallback = void Function();

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final VoidCardCallback onTap;
  final Future<void> Function(bool isCompleted) onStatusChanged;
  final Future<void> Function() onDelete;
  final VoidCardCallback? onEdit;
  final VoidCardCallback? onLongPress;
  final int index;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    required this.onDelete,
    this.onEdit,
    this.onLongPress,
    this.index = 0,
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

  String _dueLabel(DateTime dueDate) {
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDay = DateUtils.dateOnly(dueDate);
    final difference = dueDay.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    }

    if (difference == 1) {
      return 'Tomorrow';
    }

    if (difference == -1) {
      return 'Yesterday';
    }

    return DateFormat.MMMd().format(dueDate);
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final theme = Theme.of(context);
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

    if (shouldDelete == true) {
      await HapticFeedback.heavyImpact();
      await onDelete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskModel.completedStatus;
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDay = DateUtils.dateOnly(task.dueDate);
    final isOverdue = !isCompleted && dueDay.isBefore(today);
    final priorityColor = _priorityColor(context);
    final animationDelay = Duration(milliseconds: (index % 8) * 42);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 320 + animationDelay.inMilliseconds),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 22 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        child: Slidable(
          key: ValueKey(task.id),
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.3,
            children: [
              SlidableAction(
                onPressed: (_) async {
                  await HapticFeedback.selectionClick();
                  await onStatusChanged(!isCompleted);
                },
                icon: isCompleted
                    ? Icons.undo_rounded
                    : Icons.check_circle_rounded,
                label: isCompleted ? 'Reopen' : 'Done',
                borderRadius: BorderRadius.circular(24),
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ],
          ),
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.58,
            children: [
              SlidableAction(
                onPressed: (_) {
                  HapticFeedback.selectionClick();
                  onEdit?.call();
                },
                icon: Icons.edit_rounded,
                label: 'Edit',
                borderRadius: BorderRadius.circular(24),
                backgroundColor: theme.colorScheme.tertiaryContainer,
                foregroundColor: theme.colorScheme.onTertiaryContainer,
              ),
              SlidableAction(
                onPressed: (_) => _confirmAndDelete(context),
                icon: Icons.delete_rounded,
                label: 'Delete',
                borderRadius: BorderRadius.circular(24),
                backgroundColor: theme.colorScheme.errorContainer,
                foregroundColor: theme.colorScheme.onErrorContainer,
              ),
            ],
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 260),
            opacity: isCompleted ? 0.64 : 1,
            child: Material(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onTap();
                },
                onLongPress: () {
                  HapticFeedback.mediumImpact();
                  onLongPress?.call();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: isOverdue
                          ? theme.colorScheme.error.withValues(alpha: 0.54)
                          : theme.colorScheme.outlineVariant.withValues(
                              alpha: 0.7,
                            ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusButton(
                        isCompleted: isCompleted,
                        onPressed: () => onStatusChanged(!isCompleted),
                      ),
                      const SizedBox(width: 14),
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
                                          height: 1.16,
                                        ),
                                    child: Text(
                                      task.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _PriorityBadge(
                                  label: _priorityLabel,
                                  color: priorityColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 260),
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                                height: 1.34,
                              ),
                              child: Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                _DueBadge(
                                  label: _dueLabel(task.dueDate),
                                  isOverdue: isOverdue,
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.swipe_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.62),
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

class _StatusButton extends StatelessWidget {
  final bool isCompleted;
  final VoidCallback onPressed;

  const _StatusButton({required this.isCompleted, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkResponse(
      onTap: () async {
        await HapticFeedback.selectionClick();
        onPressed();
      },
      radius: 26,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCompleted
              ? theme.colorScheme.secondary
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: isCompleted
                ? theme.colorScheme.secondary
                : theme.colorScheme.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Icon(
          isCompleted ? Icons.done_rounded : Icons.circle_outlined,
          size: 22,
          color: isCompleted
              ? theme.colorScheme.onSecondary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _PriorityBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DueBadge extends StatelessWidget {
  final String label;
  final bool isOverdue;

  const _DueBadge({required this.label, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.event_rounded,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
