import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel? task;

  const TaskDetailScreen({super.key, this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedPriority = TaskModel.mediumPriority;
  bool _isLoading = false;
  String? _formErrorMessage;

  bool get _isEditing {
    return widget.task != null;
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );

    final existingTask = widget.task;
    if (existingTask != null) {
      _selectedDate = existingTask.dueDate;
      _selectedPriority = existingTask.priority;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    HapticFeedback.selectionClick();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _selectShortcutDate(Duration offset) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedDate = DateTime.now().add(offset);
    });
  }

  Future<void> _saveTask() async {
    setState(() {
      _formErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();
      final firestoreService = context.read<FirestoreService>();
      final currentUser = authService.currentUser;

      if (currentUser == null) {
        throw Exception('You need to be logged in to save tasks.');
      }

      final existingTask = widget.task;
      if (existingTask == null) {
        final newTask = TaskModel(
          id: '',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _selectedDate,
          status: TaskModel.pendingStatus,
          createdAt: DateTime.now(),
          priority: _selectedPriority,
          userId: currentUser.uid,
        );
        await firestoreService.addTask(newTask);
      } else {
        final updatedTask = existingTask.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          dueDate: _selectedDate,
          priority: _selectedPriority,
        );
        await firestoreService.updateTask(updatedTask);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _formErrorMessage = error.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String? _validateTitle(String? value) {
    final title = value?.trim() ?? '';

    if (title.isEmpty) {
      return 'Title is required';
    }

    if (title.length < 3) {
      return 'Title must be at least 3 characters';
    }

    return null;
  }

  String? _validateDescription(String? value) {
    final description = value?.trim() ?? '';

    if (description.isEmpty) {
      return 'Description is required';
    }

    if (description.length < 3) {
      return 'Description must be at least 3 characters';
    }

    return null;
  }

  bool _isSelectedDateOverdue() {
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(_selectedDate);
    return selectedDay.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Task' : 'Add Task'),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_rounded),
              tooltip: 'Save task',
              onPressed: _isLoading ? null : _saveTask,
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TaskFormHeader(isEditing: _isEditing),
                      if (widget.task != null)
                        _TaskHeroHeader(task: widget.task!),
                      if (_formErrorMessage != null)
                        _TaskFormError(message: _formErrorMessage!),
                      CustomTextField(
                        controller: _titleController,
                        labelText: 'Task Title',
                        prefixIcon: Icons.title_rounded,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                        validator: _validateTitle,
                      ),
                      CustomTextField(
                        controller: _descriptionController,
                        labelText: 'Description',
                        prefixIcon: Icons.notes_rounded,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        minLines: 4,
                        maxLines: 6,
                        validator: _validateDescription,
                      ),
                      const SizedBox(height: 16),
                      _DueDateField(
                        selectedDate: _selectedDate,
                        isOverdue: _isSelectedDateOverdue(),
                        onTap: _selectDate,
                      ),
                      const SizedBox(height: 12),
                      _DateShortcutBar(
                        onToday: () => _selectShortcutDate(Duration.zero),
                        onTomorrow: () =>
                            _selectShortcutDate(const Duration(days: 1)),
                        onNextWeek: () =>
                            _selectShortcutDate(const Duration(days: 7)),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Priority',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment<String>(
                            value: TaskModel.lowPriority,
                            label: Text('Low'),
                            icon: Icon(Icons.arrow_downward_rounded),
                          ),
                          ButtonSegment<String>(
                            value: TaskModel.mediumPriority,
                            label: Text('Medium'),
                            icon: Icon(Icons.drag_handle_rounded),
                          ),
                          ButtonSegment<String>(
                            value: TaskModel.highPriority,
                            label: Text('High'),
                            icon: Icon(Icons.priority_high_rounded),
                          ),
                        ],
                        selected: {_selectedPriority},
                        onSelectionChanged: (selection) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _selectedPriority = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveTask,
                        icon: const Icon(Icons.save_rounded),
                        label: Text(
                          _isEditing ? 'Save Changes' : 'Create Task',
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

class _TaskFormHeader extends StatelessWidget {
  final bool isEditing;

  const _TaskFormHeader({required this.isEditing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.secondaryContainer,
              theme.colorScheme.surfaceContainerHighest,
            ],
          ),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.76),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isEditing ? Icons.edit_note_rounded : Icons.add_task_rounded,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Refine the task' : 'Create a focus block',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Clear title, real deadline, honest priority.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskHeroHeader extends StatelessWidget {
  final TaskModel task;

  const _TaskHeroHeader({required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Hero(
      tag: 'task_card_${task.id}',
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                Icons.edit_note_rounded,
                color: theme.colorScheme.primary,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DueDateField extends StatelessWidget {
  final DateTime selectedDate;
  final bool isOverdue;
  final VoidCallback onTap;

  const _DueDateField({
    required this.selectedDate,
    required this.isOverdue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isOverdue
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Due Date',
          prefixIcon: Icon(Icons.event_rounded, color: color),
          suffixIcon: Icon(Icons.calendar_month_rounded, color: color),
        ),
        child: Text(
          DateFormat.yMMMMd().format(selectedDate),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DateShortcutBar extends StatelessWidget {
  final VoidCallback onToday;
  final VoidCallback onTomorrow;
  final VoidCallback onNextWeek;

  const _DateShortcutBar({
    required this.onToday,
    required this.onTomorrow,
    required this.onNextWeek,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _DateShortcut(
          label: 'Today',
          icon: Icons.today_rounded,
          onTap: onToday,
        ),
        _DateShortcut(
          label: 'Tomorrow',
          icon: Icons.event_available_rounded,
          onTap: onTomorrow,
        ),
        _DateShortcut(
          label: 'Next week',
          icon: Icons.next_week_rounded,
          onTap: onNextWeek,
        ),
      ],
    );
  }
}

class _DateShortcut extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DateShortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.colorScheme.outlineVariant),
    );
  }
}

class _TaskFormError extends StatelessWidget {
  final String message;

  const _TaskFormError({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
