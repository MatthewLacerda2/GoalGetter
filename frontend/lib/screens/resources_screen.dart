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

  final List<Map<String, String>> books = [
    {'title': 'Atomic Habits', 'description': 'Build good habits and break bad ones'},
    {'title': 'Deep Work', 'description': 'Focus in a distracted world'},
    {'title': 'The Power of Now', 'description': 'Live in the present moment'},
  ];

  final List<Map<String, String>> youtube = [
    {'title': 'Agadmator', 'description': 'Game being told with a lot of tactic analysis, but also a lot of story behind them', 'image': 'https://yt3.googleusercontent.com/7vCbvtCqtjQ3YLgsJt7Y952MQV1sBvhllSCSxHP8_sVZdcPCBrITfhkN2RdyCuwPnsByq-1GoA=s160-c-k-c0x00ffffff-no-rj'},
    {'title': 'Gothan Chess', 'description': 'Chess analysis in general but with a good didatic approach'},
    {'title': 'Anna Hudolph', 'description': 'Game analysis made fun, as chess should be'},
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
          toolbarHeight: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.grey[900],
            unselectedLabelColor: Colors.grey[700],
            dividerHeight: 4,
            tabs: const [
              Tab(icon: Icon(Icons.book, size: 24), text: 'Book'),
              Tab(icon: Icon(Icons.play_circle, size: 28), text: 'Youtube'),
              Tab(icon: Icon(Icons.language, size: 28), text: 'Sites'),
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