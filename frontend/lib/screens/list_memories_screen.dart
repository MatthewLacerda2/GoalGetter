import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:openapi/api.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/openapi_client_factory.dart';
import '../theme/app_theme.dart';

class ListMemoriesScreen extends StatefulWidget {
  const ListMemoriesScreen({super.key});

  @override
  State<ListMemoriesScreen> createState() => _ListMemoriesScreenState();
}

class _ListMemoriesScreenState extends State<ListMemoriesScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<StudentContextItem> _memories = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMemories();
  }

  Future<StudentContextApi> _buildStudentContextApi() async {
    final apiClient = await OpenApiClientFactory(
      authService: _authService,
    ).createAuthorized();
    return StudentContextApi(apiClient);
  }

  Future<void> _loadMemories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final studentContextApi = await _buildStudentContextApi();
      final memoriesResponse = await studentContextApi
          .getStudentContextsApiV1StudentContextGet();

      if (memoriesResponse != null) {
        setState(() {
          _memories = memoriesResponse.contexts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _memories = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _showAddMemoryDialog() async {
    final screenContext = context;
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        var isSending = false;
        return StatefulBuilder(
          builder: (context, setState) {
            // Keep local rebuilds cheap + reliable
            void setSending(bool value) => setState(() => isSending = value);

            Future<void> submitWrapped() async {
              final text = controller.text.trim();
              if (text.isEmpty || isSending) return;
              setSending(true);
              final navigator = Navigator.of(dialogContext);
              final messenger = ScaffoldMessenger.of(screenContext);
              try {
                final studentContextApi = await _buildStudentContextApi();
                await studentContextApi
                    .createStudentContextApiV1StudentContextPost(
                      CreateStudentContextRequest(context: text),
                    );
                if (!mounted) return;
                navigator.pop();
                await _loadMemories();
              } catch (e) {
                setSending(false);
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error adding memory: ${e.toString()}'),
                    backgroundColor: AppTheme.error,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('+ Add'),
              content: TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.writeYourMemory,
                ),
                onSubmitted: (_) => submitWrapped(),
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                TextButton(
                  onPressed: isSending ? null : submitWrapped,
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.send),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
  }

  Future<void> _deleteMemory(StudentContextItem memory) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.areYouSure),
          content: Text(AppLocalizations.of(context)!.areYouSure),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppTheme.error),
              child: Text(AppLocalizations.of(context)!.delete),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        final studentContextApi = await _buildStudentContextApi();
        await studentContextApi
            .deleteStudentContextApiV1StudentContextContextIdDelete(memory.id);

        // Reload memories after deletion
        await _loadMemories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting memory: ${e.toString()}'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.listMemories),
        backgroundColor: AppTheme.surfaceVariant,
        foregroundColor: AppTheme.textPrimary,
        actions: [
          TextButton(
            onPressed: _showAddMemoryDialog,
            child: Text(
              '+ Add',
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.accentPrimary,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_errorMessage',
                        style: const TextStyle(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppTheme.spacing16),
                      ElevatedButton(
                        onPressed: _loadMemories,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _memories.isEmpty
                  ? Center(
                      child: Text(
                        AppLocalizations.of(context)!.noMemories,
                        style: const TextStyle(
                          fontSize: AppTheme.fontSize18,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(AppTheme.edgePadding),
                      child: ListView.builder(
                        itemCount: _memories.length,
                        itemBuilder: (context, index) {
                          final memory = _memories[index];
                          return Container(
                            margin: const EdgeInsets.only(
                                bottom: AppTheme.spacing12),
                            padding: const EdgeInsets.all(
                                AppTheme.spacing16),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBackground,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.spacing8),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        memory.state,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: AppTheme.fontSize16,
                                        ),
                                      ),
                                      if (memory.metacognition
                                          .isNotEmpty) ...[
                                        const SizedBox(
                                            height: AppTheme.spacing8),
                                        Text(
                                          memory.metacognition,
                                          style: const TextStyle(
                                            color: AppTheme.textSecondary,
                                            fontSize: AppTheme.fontSize14,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(
                                          height: AppTheme.spacing8),
                                      Text(
                                        '${AppLocalizations.of(context)!.createdAt} ${_formatDate(memory.createdAt)}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: AppTheme.fontSize12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: AppTheme.error,
                                  ),
                                  onPressed: () =>
                                      _deleteMemory(memory),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
