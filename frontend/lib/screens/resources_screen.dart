import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../widgets/screens/resource/resource_tab.dart';

class ResourcesScreen extends StatefulWidget {
  ResourcesScreen({super.key});

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
      final apiClient = await OpenApiClientFactory(
        authService: _authService,
      ).createWithAccessToken();

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
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              SizedBox(height: 16.0),
              Text(
                'Error loading resources',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 8.0),
              Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 24.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _loadResources,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          dividerHeight: 4,
          dividerColor: Theme.of(context).colorScheme.primary,
          indicatorColor: Theme.of(context).colorScheme.primary,
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
