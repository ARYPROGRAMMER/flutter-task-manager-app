import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/quote_banner.dart';
import '../widgets/task_card.dart';
import 'profile_screen.dart';
import 'task_detail_screen.dart';

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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
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
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Pending', 'Completed', 'High Priority'];

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }

  void _toggleTaskStatus(BuildContext context, TaskModel task, bool isCompleted) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final updatedTask = task.copyWith(status: isCompleted ? 'completed' : 'pending');
    await firestoreService.updateTask(updatedTask);
  }

  void _deleteTask(BuildContext context, String taskId) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    await firestoreService.deleteTask(taskId);
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    switch (_selectedFilter) {
      case 'Pending':
        return tasks.where((task) => task.status == 'pending').toList();
      case 'Completed':
        return tasks.where((task) => task.status == 'completed').toList();
      case 'High Priority':
        return tasks.where((task) => task.priority == 'high').toList();
      case 'All':
      default:
        return tasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.currentUser;
    final theme = Theme.of(context);

    if (currentUser == null) {
      return const Center(child: Text('Authentication Error'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskDetailScreen()),
          );
        },
        child: const Icon(Icons.add),
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
              return Center(child: Text('Error loading tasks: ${snapshot.error}'));
            }

            final allTasks = snapshot.data ?? [];
            final filteredTasks = _filterTasks(allTasks);
            
            final totalCount = allTasks.length;
            final pendingCount = allTasks.where((t) => t.status == 'pending').length;
            final completedCount = allTasks.where((t) => t.status == 'completed').length;

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: QuoteBanner()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: [
                        _StatCard(title: 'Total', count: totalCount, color: theme.colorScheme.primary),
                        const SizedBox(width: 8.0),
                        _StatCard(title: 'Pending', count: pendingCount, color: Colors.orange),
                        const SizedBox(width: 8.0),
                        _StatCard(title: 'Done', count: completedCount, color: Colors.green),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      children: _filters.map((filterName) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(filterName),
                            selected: _selectedFilter == filterName,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filterName;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (filteredTasks.isEmpty)
                  const SliverFillRemaining(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: _EmptyStateIllustration(message: 'No tasks found. Time to relax!'),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filteredTasks[index];
                        return TaskCard(
                          task: task,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
                            );
                          },
                          onStatusChanged: (value) => _toggleTaskStatus(context, task, value ?? false),
                          onDelete: () => _deleteTask(context, task.id),
                        );
                      },
                      childCount: filteredTasks.length,
                    ),
                  ),
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

  void _toggleTaskStatus(BuildContext context, TaskModel task, bool isCompleted) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final updatedTask = task.copyWith(status: isCompleted ? 'completed' : 'pending');
    await firestoreService.updateTask(updatedTask);
  }

  void _deleteTask(BuildContext context, String taskId) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    await firestoreService.deleteTask(taskId);
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Authentication Error'));
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search tasks...',
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
      body: StreamBuilder<List<TaskModel>>(
        stream: firestoreService.userTasksStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _SkeletonLoader();
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading tasks: ${snapshot.error}'));
          }

          final allTasks = snapshot.data ?? [];
          final searchResults = _searchQuery.isEmpty
              ? []
              : allTasks.where((task) {
                  final queryLower = _searchQuery.toLowerCase();
                  return task.title.toLowerCase().contains(queryLower) ||
                         task.description.toLowerCase().contains(queryLower);
                }).toList();

          if (_searchQuery.isEmpty) {
            return const Center(
              child: _EmptyStateIllustration(message: 'Enter keywords to search tasks'),
            );
          }

          if (searchResults.isEmpty) {
            return const Center(
              child: _EmptyStateIllustration(message: 'No matching tasks found'),
            );
          }

          return ListView.builder(
            itemCount: searchResults.length,
            itemBuilder: (context, index) {
              final task = searchResults[index];
              return TaskCard(
                task: task,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TaskDetailScreen(task: task)),
                  );
                },
                onStatusChanged: (value) => _toggleTaskStatus(context, task, value ?? false),
                onDelete: () => _deleteTask(context, task.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _StatCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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

class _SkeletonLoaderState extends State<_SkeletonLoader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(_animationController);
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
      itemCount: 5,
      padding: const EdgeInsets.all(16.0),
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _opacityAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12.0),
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
  final String message;

  const _EmptyStateIllustration({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.task_outlined,
          size: 100,
          color: theme.colorScheme.surfaceContainerHighest,
        ),
        const SizedBox(height: 16.0),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
