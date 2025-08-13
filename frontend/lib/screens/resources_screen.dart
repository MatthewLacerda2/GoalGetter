// Resources screen
import 'package:flutter/material.dart';
import '../widgets/screens/resource/resource_tab.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample data - replace with actual data later
  final List<Map<String, String>> books = [
    {'title': 'Atomic Habits', 'description': 'Build good habits and break bad ones'},
    {'title': 'Deep Work', 'description': 'Focus in a distracted world'},
    {'title': 'The Power of Now', 'description': 'Live in the present moment'},
  ];

  final List<Map<String, String>> youtube = [
    {'title': 'Productivity Tips', 'description': 'Task productivity advice'},
    {'title': 'Goal Setting Guide', 'description': 'How to set and achieve goals'},
    {'title': 'Time Management', 'description': 'Master your time effectively'},
  ];

  final List<Map<String, String>> sites = [
    {'title': 'Productivity Blog', 'description': 'Latest productivity insights'},
    {'title': 'Goal Tracker', 'description': 'Online goal tracking tools'},
    {'title': 'Learning Resources', 'description': 'Educational materials and courses'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 16, // Reduced height to eliminate blank space
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(icon: Icon(Icons.book, size: 32)),
              Tab(icon: Icon(Icons.play_circle, size: 32)),
              Tab(icon: Icon(Icons.language, size: 32)),
            ],
          ),
        ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ResourceTab(
            resources: books,
          ),
          ResourceTab(
            resources: youtube,
          ),
          ResourceTab(
            resources: sites,
          ),
        ],
      ),
    );
  }
}