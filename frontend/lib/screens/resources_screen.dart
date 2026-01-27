import 'package:flutter/material.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../theme/app_theme.dart';
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
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.accentPrimary,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.error,
                size: 48,
              ),
              const SizedBox(height: AppTheme.spacing16),
              Text(
                'Error loading resources',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: AppTheme.fontSize18,
                ),
              ),
              const SizedBox(height: AppTheme.spacing8),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing24),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: AppTheme.fontSize14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppTheme.spacing24),
              ElevatedButton(
                onPressed: _loadResources,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppTheme.background,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.accentPrimary,
          unselectedLabelColor: AppTheme.textSecondary,
          dividerHeight: 4,
          dividerColor: AppTheme.accentPrimary,
          indicatorColor: AppTheme.accentPrimary,
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
