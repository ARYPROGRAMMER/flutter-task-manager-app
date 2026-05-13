import 'package:flutter/material.dart';
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
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
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

    return _TaskStats(
      totalCount: tasks.length,
      completedCount: completedCount,
      pendingCount: pendingCount,
    );
  }

  void _openTaskDetail([TaskModel? task]) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TaskDetailScreen(task: task),
      ),
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
      appBar: AppBar(title: const Text('TaskFlow')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openTaskDetail(),
        tooltip: 'Add task',
        child: const Icon(Icons.add_rounded),
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

            return CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _DashboardHeader(displayName: currentUser.displayName),
                ),
                const SliverToBoxAdapter(child: QuoteBanner()),
                SliverToBoxAdapter(child: _StatisticsBanner(stats: taskStats)),
                SliverToBoxAdapter(
                  child: _FilterBar(
                    selectedFilter: _selectedFilter,
                    onSelected: (filter) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                ),
                if (filteredTasks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyStateIllustration(
                      icon: Icons.task_alt_rounded,
                      title: _selectedFilter == _TaskFilter.all
                          ? 'No tasks yet'
                          : 'No tasks match this filter',
                      message: _selectedFilter == _TaskFilter.all
                          ? 'Tap the add button to create your first task.'
                          : 'Try another filter or add a task for this list.',
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final task = filteredTasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () => _openTaskDetail(task),
                        onStatusChanged: (isCompleted) {
                          return _toggleTaskStatus(task, isCompleted);
                        },
                        onDelete: () => _deleteTask(task),
                      );
                    }, childCount: filteredTasks.length),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 92)),
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
                      onTap: () => _openTaskDetail(task),
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

  const _TaskStats({
    required this.totalCount,
    required this.completedCount,
    required this.pendingCount,
  });
}

class _DashboardHeader extends StatelessWidget {
  final String? displayName;

  const _DashboardHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = displayName?.trim().isNotEmpty == true
        ? displayName!.trim().split(' ').first
        : 'there';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, $name',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose the few tasks that matter most today.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatisticsBanner extends StatelessWidget {
  final _TaskStats stats;

  const _StatisticsBanner({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Expanded(
              child: _StatisticTile(
                label: 'Total',
                value: stats.totalCount,
                icon: Icons.inventory_2_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            _StatisticDivider(color: theme.colorScheme.outlineVariant),
            Expanded(
              child: _StatisticTile(
                label: 'Done',
                value: stats.completedCount,
                icon: Icons.verified_rounded,
                color: theme.colorScheme.secondary,
              ),
            ),
            _StatisticDivider(color: theme.colorScheme.outlineVariant),
            Expanded(
              child: _StatisticTile(
                label: 'Pending',
                value: stats.pendingCount,
                icon: Icons.pending_actions_rounded,
                color: theme.colorScheme.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticTile extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _StatisticTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatisticDivider extends StatelessWidget {
  final Color color;

  const _StatisticDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 72, color: color);
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
                height: 112,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                icon,
                size: 58,
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
