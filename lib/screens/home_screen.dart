import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/quote_banner.dart';
import '../widgets/task_card.dart';
import 'profile_screen.dart';
import 'task_detail_screen.dart';

enum _TaskFilter { all, pending, completed, highPriority }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    _HomeTab(),
    _SearchTab(),
    ProfileScreen(),
  ];

  void _onTabSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: PageTransitionSwitcher(
        duration: const Duration(milliseconds: 360),
        transitionBuilder: (child, animation, secondaryAnimation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onTabSelected,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded),
              selectedIcon: Icon(Icons.dashboard_customize_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.manage_search_rounded),
              selectedIcon: Icon(Icons.saved_search_rounded),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  _TaskFilter _selectedFilter = _TaskFilter.all;

  Future<void> _handleRefresh() async {
    await HapticFeedback.selectionClick();
    await Future<void>.delayed(const Duration(milliseconds: 420));
  }

  Future<void> _toggleTaskStatus(TaskModel task, bool isCompleted) async {
    final firestoreService = context.read<FirestoreService>();
    final status = isCompleted
        ? TaskModel.completedStatus
        : TaskModel.pendingStatus;

    try {
      await firestoreService.updateTaskStatus(task, status);
    } catch (error) {
      _showOperationError(error.toString());
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    try {
      await context.read<FirestoreService>().deleteTask(task.id);
    } catch (error) {
      _showOperationError(error.toString());
      rethrow;
    }
  }

  void _showOperationError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    switch (_selectedFilter) {
      case _TaskFilter.pending:
        return tasks
            .where((task) => task.status == TaskModel.pendingStatus)
            .toList();
      case _TaskFilter.completed:
        return tasks
            .where((task) => task.status == TaskModel.completedStatus)
            .toList();
      case _TaskFilter.highPriority:
        return tasks
            .where((task) => task.priority == TaskModel.highPriority)
            .toList();
      case _TaskFilter.all:
        return tasks;
    }
  }

  _TaskStats _statsFor(List<TaskModel> tasks) {
    final completedCount = tasks
        .where((task) => task.status == TaskModel.completedStatus)
        .length;
    final pendingCount = tasks
        .where((task) => task.status == TaskModel.pendingStatus)
        .length;
    final highPriorityCount = tasks
        .where((task) => task.priority == TaskModel.highPriority)
        .length;
    final overdueCount = tasks.where(_isTaskOverdue).length;

    return _TaskStats(
      totalCount: tasks.length,
      completedCount: completedCount,
      pendingCount: pendingCount,
      highPriorityCount: highPriorityCount,
      overdueCount: overdueCount,
    );
  }

  bool _isTaskOverdue(TaskModel task) {
    final today = DateUtils.dateOnly(DateTime.now());
    final dueDay = DateUtils.dateOnly(task.dueDate);
    return task.status != TaskModel.completedStatus && dueDay.isBefore(today);
  }

  TaskModel? _nextTask(List<TaskModel> tasks) {
    final pendingTasks =
        tasks.where((task) => task.status == TaskModel.pendingStatus).toList()
          ..sort((firstTask, secondTask) {
            final dateComparison = firstTask.dueDate.compareTo(
              secondTask.dueDate,
            );
            if (dateComparison != 0) {
              return dateComparison;
            }
            return _priorityWeight(
              secondTask.priority,
            ).compareTo(_priorityWeight(firstTask.priority));
          });

    return pendingTasks.isEmpty ? null : pendingTasks.first;
  }

  int _priorityWeight(String priority) {
    switch (priority) {
      case TaskModel.highPriority:
        return 3;
      case TaskModel.mediumPriority:
        return 2;
      case TaskModel.lowPriority:
        return 1;
      default:
        return 0;
    }
  }

  void _openTaskDetail([TaskModel? task]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  void _showTaskActions(TaskModel task) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskModel.completedStatus;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                _QuickActionButton(
                  icon: isCompleted
                      ? Icons.undo_rounded
                      : Icons.check_circle_rounded,
                  label: isCompleted ? 'Reopen task' : 'Mark complete',
                  color: theme.colorScheme.secondary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _toggleTaskStatus(task, !isCompleted);
                  },
                ),
                _QuickActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit task',
                  color: theme.colorScheme.tertiary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openTaskDetail(task);
                  },
                ),
                _QuickActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Delete task',
                  color: theme.colorScheme.error,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteTask(task);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Authentication Error')));
    }

    return Scaffold(
      floatingActionButton: OpenContainer<void>(
        closedElevation: 8,
        openElevation: 0,
        closedShape: const CircleBorder(),
        closedColor: Theme.of(context).colorScheme.primary,
        openColor: Theme.of(context).colorScheme.surface,
        transitionDuration: const Duration(milliseconds: 420),
        openBuilder: (context, action) => const TaskDetailScreen(),
        closedBuilder: (context, openContainer) {
          return FloatingActionButton(
            onPressed: () {
              HapticFeedback.mediumImpact();
              openContainer();
            },
            tooltip: 'Add task',
            child: const Icon(Icons.add_rounded),
          );
        },
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: StreamBuilder<List<TaskModel>>(
          stream: firestoreService.userTasksStream(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _SkeletonLoader();
            }

            if (snapshot.hasError) {
              return _ErrorState(message: snapshot.error.toString());
            }

            final allTasks = snapshot.data ?? [];
            final filteredTasks = _filterTasks(allTasks);
            final taskStats = _statsFor(allTasks);
            final nextTask = _nextTask(allTasks);

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _HeroOverview(
                    displayName: currentUser.displayName,
                    stats: taskStats,
                    nextTask: nextTask,
                  ),
                ),
                const SliverToBoxAdapter(child: QuoteBanner()),
                SliverToBoxAdapter(
                  child: _InsightGrid(
                    stats: taskStats,
                    selectedFilter: _selectedFilter,
                    onSelected: (filter) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _FilterBar(
                    selectedFilter: _selectedFilter,
                    onSelected: (filter) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    count: filteredTasks.length,
                    filter: _selectedFilter,
                  ),
                ),
                if (filteredTasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyStateIllustration(
                      icon: Icons.task_alt_rounded,
                      title: _selectedFilter == _TaskFilter.all
                          ? 'No tasks yet'
                          : 'No tasks match this view',
                      message: _selectedFilter == _TaskFilter.all
                          ? 'Tap the add button to shape your first focus block.'
                          : 'Try another filter or create a new task for this lane.',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = filteredTasks[index];
                      final theme = Theme.of(context);
                      return OpenContainer<void>(
                        closedElevation: 0,
                        openElevation: 0,
                        closedColor: theme.colorScheme.surface.withValues(
                          alpha: 0,
                        ),
                        middleColor: theme.colorScheme.surface,
                        openColor: theme.colorScheme.surface,
                        closedShape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        transitionDuration: const Duration(milliseconds: 380),
                        openBuilder: (context, action) =>
                            TaskDetailScreen(task: task),
                        closedBuilder: (context, openContainer) {
                          return TaskCard(
                            task: task,
                            index: index,
                            onTap: openContainer,
                            onEdit: () => _openTaskDetail(task),
                            onLongPress: () => _showTaskActions(task),
                            onStatusChanged: (isCompleted) {
                              return _toggleTaskStatus(task, isCompleted);
                            },
                            onDelete: () => _deleteTask(task),
                          );
                        },
                      );
                    }, childCount: filteredTasks.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 104)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab();

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleTaskStatus(TaskModel task, bool isCompleted) async {
    final firestoreService = context.read<FirestoreService>();
    final status = isCompleted
        ? TaskModel.completedStatus
        : TaskModel.pendingStatus;

    try {
      await firestoreService.updateTaskStatus(task, status);
    } catch (error) {
      _showOperationError(error.toString());
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    try {
      await context.read<FirestoreService>().deleteTask(task.id);
    } catch (error) {
      _showOperationError(error.toString());
      rethrow;
    }
  }

  void _showOperationError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  List<TaskModel> _searchTasks(List<TaskModel> tasks) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();

    if (normalizedQuery.isEmpty) {
      return [];
    }

    return tasks.where((task) {
      final title = task.title.toLowerCase();
      final description = task.description.toLowerCase();
      return title.contains(normalizedQuery) ||
          description.contains(normalizedQuery);
    }).toList();
  }

  void _openTaskDetail(TaskModel task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  void _showTaskActions(TaskModel task) {
    final theme = Theme.of(context);
    final isCompleted = task.status == TaskModel.completedStatus;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _QuickActionButton(
                  icon: isCompleted
                      ? Icons.undo_rounded
                      : Icons.check_circle_rounded,
                  label: isCompleted ? 'Reopen task' : 'Mark complete',
                  color: theme.colorScheme.secondary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _toggleTaskStatus(task, !isCompleted);
                  },
                ),
                _QuickActionButton(
                  icon: Icons.edit_rounded,
                  label: 'Edit task',
                  color: theme.colorScheme.tertiary,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _openTaskDetail(task);
                  },
                ),
                _QuickActionButton(
                  icon: Icons.delete_rounded,
                  label: 'Delete task',
                  color: theme.colorScheme.error,
                  onPressed: () {
                    Navigator.of(context).pop();
                    _deleteTask(task);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final firestoreService = context.read<FirestoreService>();
    final currentUser = authService.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Authentication Error')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search titles or descriptions',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<TaskModel>>(
              stream: firestoreService.userTasksStream(currentUser.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SkeletonLoader();
                }

                if (snapshot.hasError) {
                  return _ErrorState(message: snapshot.error.toString());
                }

                final searchResults = _searchTasks(snapshot.data ?? []);

                if (_searchQuery.trim().isEmpty) {
                  return const _EmptyStateIllustration(
                    icon: Icons.search_rounded,
                    title: 'Search your tasks',
                    message: 'Type a title or detail to find it instantly.',
                  );
                }

                if (searchResults.isEmpty) {
                  return const _EmptyStateIllustration(
                    icon: Icons.manage_search_rounded,
                    title: 'No matches',
                    message: 'Try another keyword or clear the search.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 96),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final task = searchResults[index];
                    return TaskCard(
                      task: task,
                      index: index,
                      onTap: () => _openTaskDetail(task),
                      onEdit: () => _openTaskDetail(task),
                      onLongPress: () => _showTaskActions(task),
                      onStatusChanged: (isCompleted) {
                        return _toggleTaskStatus(task, isCompleted);
                      },
                      onDelete: () => _deleteTask(task),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskStats {
  final int totalCount;
  final int completedCount;
  final int pendingCount;
  final int highPriorityCount;
  final int overdueCount;

  const _TaskStats({
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
    required this.highPriorityCount,
    required this.overdueCount,
  });

  double get completionRatio {
    if (totalCount == 0) {
      return 0;
    }

    return completedCount / totalCount;
  }
}

class _HeroOverview extends StatelessWidget {
  final String? displayName;
  final _TaskStats stats;
  final TaskModel? nextTask;

  const _HeroOverview({
    required this.displayName,
    required this.stats,
    required this.nextTask,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim().split(' ').first
        : 'there';
    final dateText = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 16,
        16,
        10,
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(34),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.24),
              blurRadius: 36,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateText,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.72,
                          ),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hi, $name',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.02,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Shape the day before it shapes you.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.78,
                          ),
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
                _FocusRing(stats: stats),
              ],
            ),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: nextTask == null
                  ? _NextFocusEmpty(key: const ValueKey('empty'))
                  : _NextFocusTask(
                      task: nextTask!,
                      key: ValueKey(nextTask!.id),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusRing extends StatelessWidget {
  final _TaskStats stats;

  const _FocusRing({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 94,
      height: 94,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 850),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: stats.completionRatio),
            builder: (context, value, child) {
              return CustomPaint(
                size: const Size.square(94),
                painter: _RingPainter(
                  value: value,
                  color: theme.colorScheme.onPrimary,
                  trackColor: theme.colorScheme.onPrimary.withValues(
                    alpha: 0.18,
                  ),
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(stats.completionRatio * 100).round()}%',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'done',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.74),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final Color color;
  final Color trackColor;

  const _RingPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 5;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0, 1),
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}

class _NextFocusTask extends StatelessWidget {
  final TaskModel task;

  const _NextFocusTask({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.bolt_rounded, color: theme.colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next focus',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextFocusEmpty extends StatelessWidget {
  const _NextFocusEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(Icons.celebration_rounded, color: theme.colorScheme.onPrimary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All clear. Create a new focus when you are ready.',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightGrid extends StatelessWidget {
  final _TaskStats stats;
  final _TaskFilter selectedFilter;
  final ValueChanged<_TaskFilter> onSelected;

  const _InsightGrid({
    required this.stats,
    required this.selectedFilter,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: _InsightTile(
              label: 'Pending',
              value: stats.pendingCount,
              icon: Icons.pending_actions_rounded,
              color: theme.colorScheme.primary,
              isSelected: selectedFilter == _TaskFilter.pending,
              onTap: () => onSelected(_TaskFilter.pending),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightTile(
              label: 'High',
              value: stats.highPriorityCount,
              icon: Icons.priority_high_rounded,
              color: theme.colorScheme.error,
              isSelected: selectedFilter == _TaskFilter.highPriority,
              onTap: () => onSelected(_TaskFilter.highPriority),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _InsightTile(
              label: 'Overdue',
              value: stats.overdueCount,
              icon: Icons.warning_rounded,
              color: theme.colorScheme.tertiary,
              isSelected: false,
              onTap: () => onSelected(_TaskFilter.pending),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _InsightTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.13)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.42)
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              '$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final int count;
  final _TaskFilter filter;

  const _SectionHeader({required this.count, required this.filter});

  String get _title {
    switch (filter) {
      case _TaskFilter.pending:
        return 'Pending queue';
      case _TaskFilter.completed:
        return 'Completed work';
      case _TaskFilter.highPriority:
        return 'High priority';
      case _TaskFilter.all:
        return 'Today board';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final _TaskFilter selectedFilter;
  final ValueChanged<_TaskFilter> onSelected;

  const _FilterBar({required this.selectedFilter, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Row(
        children: _TaskFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_labelForFilter(filter)),
              selected: selectedFilter == filter,
              avatar: Icon(_iconForFilter(filter), size: 18),
              onSelected: (isSelected) {
                if (isSelected) {
                  onSelected(filter);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _labelForFilter(_TaskFilter filter) {
    switch (filter) {
      case _TaskFilter.pending:
        return 'Pending';
      case _TaskFilter.completed:
        return 'Completed';
      case _TaskFilter.highPriority:
        return 'High Priority';
      case _TaskFilter.all:
        return 'All';
    }
  }

  IconData _iconForFilter(_TaskFilter filter) {
    switch (filter) {
      case _TaskFilter.pending:
        return Icons.timelapse_rounded;
      case _TaskFilter.completed:
        return Icons.done_all_rounded;
      case _TaskFilter.highPriority:
        return Icons.priority_high_rounded;
      case _TaskFilter.all:
        return Icons.view_list_rounded;
    }
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: FilledButton.tonalIcon(
        onPressed: () {
          HapticFeedback.selectionClick();
          onPressed();
        },
        icon: Icon(icon, color: color),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          alignment: Alignment.centerLeft,
          textStyle: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(
      begin: 0.38,
      end: 0.88,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: 5,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 126,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EmptyStateIllustration extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyStateIllustration({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ],
                ),
                borderRadius: BorderRadius.circular(42),
              ),
              child: Icon(
                icon,
                size: 60,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 14),
            Text(
              'Could not load tasks',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
