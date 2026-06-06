import 'package:openapi/api.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'openapi_client_factory.dart';

part 'api_client_provider.g.dart';

@riverpod
Future<ApiClient> apiClient(ApiClientRef ref) async {
  final factory = ref.watch(openApiClientFactoryProvider);
  return factory.createAuthorized();
}
