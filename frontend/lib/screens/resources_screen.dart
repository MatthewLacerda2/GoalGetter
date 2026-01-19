import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../config/app_config.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../widgets/screens/resource/resource_tab.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, String>> _books = [];
  List<Map<String, String>> _youtube = [];
  List<Map<String, String>> _sites = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadResources();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadResources() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final accessToken = await _authService.getStoredAccessToken();
      if (accessToken == null) {
        throw Exception('No access token available. Please sign in again.');
      }

      final apiClient = ApiClient(basePath: AppConfig.baseUrl);
      apiClient.addDefaultHeader('Authorization', 'Bearer $accessToken');

      // Get student status to get goalId
      final studentApi = StudentApi(apiClient);
      final studentResponse = await studentApi
          .getStudentCurrentStatusApiV1StudentGet();

      if (studentResponse == null || studentResponse.goalId == null) {
        throw Exception('Failed to fetch student status');
      }

      // Fetch resources
      final resourcesApi = ResourcesApi(apiClient);
      final resourcesResponse = await resourcesApi
          .getResourcesApiV1ResourcesGet(studentResponse.goalId!);

      if (resourcesResponse != null && mounted) {
        // Group resources by type and convert to Map format
        final books = <Map<String, String>>[];
        final youtube = <Map<String, String>>[];
        final sites = <Map<String, String>>[];

        for (final resource in resourcesResponse.resources) {
          final resourceMap = <String, String>{
            'title': resource.name,
            'description': resource.description,
            'link': resource.link,
          };

          if (resource.imageUrl != null && resource.imageUrl!.isNotEmpty) {
            resourceMap['image'] = resource.imageUrl!;
          }

          if (resource.resourceType == StudyResourceType.pdf) {
            books.add(resourceMap);
          } else if (resource.resourceType == StudyResourceType.youtube) {
            youtube.add(resourceMap);
          } else if (resource.resourceType == StudyResourceType.webpage) {
            sites.add(resourceMap);
          }
        }

        setState(() {
          _books = books;
          _youtube = youtube;
          _sites = sites;
          _isLoading = false;
        });
      } else {
        setState(() {
          _books = [];
          _youtube = [];
          _sites = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.blue)),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Error loading resources',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(onPressed: _loadResources, child: Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          dividerHeight: 4,
          tabs: [
            Tab(
              icon: Icon(Icons.play_circle, size: 28),
              text: AppLocalizations.of(context)!.youtube,
            ),
            Tab(
              icon: Icon(Icons.language, size: 28),
              text: AppLocalizations.of(context)!.sites,
            ),
            Tab(
              icon: Icon(Icons.book, size: 24),
              text: AppLocalizations.of(context)!.book,
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ResourceTab(resources: _youtube),
          ResourceTab(resources: _sites),
          ResourceTab(resources: _books),
        ],
      ),
    );
  }
}
