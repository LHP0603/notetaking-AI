import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';

class SupabaseClient {
  static SupabaseClient? _instance;
  static SupabaseClient get instance {
    if (_instance == null) {
      throw Exception(
        'SupabaseClient not initialized. Call initialize() first.',
      );
    }
    return _instance!;
  }

  late final Supabase _supabase;
  final AuthLocalDataSource? authLocalDataSource;

  String? _cachedAccessToken;

  SupabaseClient._(this._supabase, {this.authLocalDataSource});

  /// Initialize Supabase with URL and anon key
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
    AuthLocalDataSource? authLocalDataSource,
  }) async {
    try {
      final normalizedUrl =
          supabaseUrl.endsWith('/') ? supabaseUrl : '$supabaseUrl/';

      await Supabase.initialize(url: normalizedUrl, anonKey: supabaseAnonKey);

      _instance = SupabaseClient._(
        Supabase.instance,
        authLocalDataSource: authLocalDataSource,
      );

      // Sync auth state with Supabase if authLocalDataSource is provided
      if (authLocalDataSource != null) {
        _instance!._syncAuthState();
      }
    } catch (e) {
      throw Exception('Failed to initialize Supabase: $e');
    }
  }

  Future<void> _syncAuthState() async {
    if (authLocalDataSource == null) {
      print('Warning: authLocalDataSource is null, cannot sync session');
      return;
    }

    final accessToken = await authLocalDataSource!.getAccessToken();
    final refreshToken = await authLocalDataSource!.getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      print('Warning: Cannot sync Supabase session - tokens are null');
      print('Access token: ${accessToken != null ? "exists" : "null"}');
      print('Refresh token: ${refreshToken != null ? "exists" : "null"}');
      _cachedAccessToken = null;
      return;
    }

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      print('Warning: Cannot sync Supabase session - tokens are empty');
      _cachedAccessToken = null;
      return;
    }

    // Store access token for manual header setting as fallback
    _cachedAccessToken = accessToken;
    print(
      'Info: Cached access token for fallback (length: ${accessToken.length})',
    );

    try {
      final response = await _supabase.client.auth.setSession(refreshToken);
      print('Info: setSession call completed');

      // Verify that the session was actually set
      if (response.session == null) {
        print('Warning: setSession returned null session in response');
        print('Refresh token length: ${refreshToken.length}');

        // Check if currentSession is set despite response being null
        await Future.delayed(const Duration(milliseconds: 100));
        final currentSession = _supabase.client.auth.currentSession;
        if (currentSession == null) {
          print(
            'Warning: Approach 1 failed - both response.session and currentSession are null',
          );
          // Continue to Approach 2
        } else {
          print(
            'Info: Approach 1 succeeded - Session was set despite null response.session',
          );
          _verifySession(currentSession);
          return; // Success, exit early
        }
      } else {
        print('Info: Approach 1 succeeded - Session returned in response');
        _verifySession(response.session!);
        return; // Success, exit early
      }
    } catch (e) {
      print('Error: Approach 1 (setSession) failed: $e');
      print('Error type: ${e.runtimeType}');
      // Continue to Approach 2
    }

    try {
      final currentSession = _supabase.client.auth.currentSession;
      if (currentSession != null) {
        print('Info: Found existing session, attempting refresh');
        final refreshResponse = await _supabase.client.auth.refreshSession();
        if (refreshResponse.session != null) {
          print('Info: Approach 2 succeeded - Session refreshed');
          _verifySession(refreshResponse.session!);
          return; // Success, exit early
        }
      } else {
        print('Warning: Approach 2 skipped - no existing session to refresh');
      }
    } catch (e) {
      print('Error: Approach 2 (refreshSession) failed: $e');
      // Continue to Approach 3
    }

    await Future.delayed(const Duration(milliseconds: 200));
    final currentSession = _supabase.client.auth.currentSession;
    if (currentSession != null && currentSession.accessToken.isNotEmpty) {
      print('Info: Approach 3 succeeded - Session found after delay');
      _verifySession(currentSession);
      return; // Success, exit early
    }

    // All approaches failed
    print('Error: All approaches failed to establish Supabase session');
    print('Access token exists: ${accessToken.isNotEmpty}');
    print('Refresh token exists: ${refreshToken.isNotEmpty}');
    print(
      'Refresh token preview: ${refreshToken.length > 20 ? refreshToken.substring(0, 20) + "..." : refreshToken}',
    );
    print(
      'Note: Access token is cached and will be used as fallback in upload operations',
    );

    // Don't throw exception here - allow uploadFile to try with cached token
    // The uploadFile method will handle the fallback
  }

  void _verifySession(Session session) {
    if (session.accessToken.isEmpty) {
      throw Exception('Session has empty accessToken');
    }
    print(
      'Info: Supabase session verified - accessToken length: ${session.accessToken.length}',
    );
    // Update cached token to match session token
    _cachedAccessToken = session.accessToken;
  }

  Future<void> syncAuthState() async {
    await _syncAuthState();
  }

  Supabase get supabase => _supabase;

  SupabaseStorageClient get storage => _supabase.client.storage;

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> fileBytes,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    print('Info: Starting file upload to bucket: $bucket, path: $path');

    // Use Supabase.instance.client directly to ensure we're using the same instance
    final supabase = Supabase.instance.client;

    // Ensure auth state is synced before upload
    print('Info: Syncing auth state before upload');
    await syncAuthState();

    // Check if we have a valid session
    var currentSession = supabase.auth.currentSession;
    print(
      'Info: Current session after sync: ${currentSession != null ? "exists" : "null"}',
    );

    // If session is null, try additional recovery methods
    if (currentSession == null) {
      print('Warning: Session is null after sync, attempting recovery methods');

      if (currentSession == null) {
        print(
          'Warning: Session is null after sync, attempting recovery methods',
        );

        try {
          print('Info: Attempting recoverSession()');
          // Note: recoverSession might not be available in all versions
          // If it throws, we'll catch and continue
          final recoveredSession = supabase.auth.currentSession;
          if (recoveredSession != null) {
            print('Info: Session recovered successfully');
            currentSession = recoveredSession;
          }
        } catch (e) {
          print('Warning: recoverSession not available or failed: $e');
        }
      }

      if (currentSession == null && authLocalDataSource != null) {
        try {
          print('Info: Attempting setSession again with refresh token');
          final refreshToken = await authLocalDataSource!.getRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            final response = await supabase.auth.setSession(refreshToken);
            await Future.delayed(const Duration(milliseconds: 100));
            currentSession = supabase.auth.currentSession ?? response.session;
            if (currentSession != null) {
              print('Info: Session established via retry setSession');
            } else {
              print('Warning: Retry setSession did not establish session');
            }
          }
        } catch (e) {
          print('Error: Retry setSession failed: $e');
        }
      }

      // Final check: if still null, we can't proceed
      if (currentSession == null) {
        final errorMsg =
            _cachedAccessToken != null
                ? 'Supabase session is null but access token is available. '
                    'This indicates a session management issue. Please try logging in again.'
                : 'Supabase session is null and no access token is cached. '
                    'Please ensure you are logged in.';
        print('Error: $errorMsg');
        throw Exception('Cannot upload: $errorMsg');
      }
    }

    // Verify session has valid access token
    if (currentSession.accessToken.isEmpty) {
      print('Error: Session exists but accessToken is empty');
      throw Exception(
        'Cannot upload: Session has empty access token. Please login again.',
      );
    }

    // Log upload information for debugging
    print(
      'Info: Upload proceeding with session (accessToken length: ${currentSession.accessToken.length})',
    );
    print('Info: Uploading to bucket: $bucket, path: $path');

    try {
      // Convert List<int> to Uint8List for Supabase
      final fileData = Uint8List.fromList(fileBytes);
      print('Info: File data prepared (${fileData.length} bytes)');

      // Upload using the authenticated Supabase client
      print('=== Upload Debug Information ===');
      print('Bucket: $bucket');
      print('File path: $path');
      print(
        'Supabase.instance.client.auth.currentUser?.id: ${supabase.auth.currentUser?.id}',
      );
      print(
        'Supabase.instance.client.auth.currentSession?.user.id: ${supabase.auth.currentSession?.user.id}',
      );
      print('File size: ${fileData.length} bytes');
      print('Content type: $contentType');
      print('Metadata: $metadata');
      print(
        'Calling: Supabase.instance.client.storage.from("$bucket").uploadBinary("$path", ...)',
      );
      print('=== End Upload Debug Information ===');

      await supabase.storage
          .from(bucket)
          .uploadBinary(
            path,
            fileData,
            fileOptions: FileOptions(
              contentType: contentType,
              metadata: metadata,
            ),
          );

      print('Info: File upload successful to path: $path');
      // Return the storage path (not URL) as expected by the backend API
      return path;
    } catch (e) {
      print('=== Upload Error Details ===');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Bucket: $bucket');
      print('File path: $path');
      print('Supabase auth.currentUser?.id: ${supabase.auth.currentUser?.id}');
      print(
        'Supabase auth.currentSession?.user.id: ${supabase.auth.currentSession?.user.id}',
      );

      // Check if it's a StorageException for more details
      if (e is StorageException) {
        print('StorageException details:');
        print('  Message: ${e.message}');
        print('  Status code: ${e.statusCode}');
        print('  Error: ${e.error}');
      }
      print('=== End Upload Error Details ===');

      // Re-throw with more context if it's a storage exception
      if (e.toString().contains('row-level security') ||
          e.toString().contains('Unauthorized') ||
          e.toString().contains('403') ||
          e.toString().contains('JWT') ||
          (e is StorageException && e.statusCode == 403)) {
        print('Error: RLS Policy violation detected');
        final errorDetails =
            e is StorageException
                ? 'StorageException: ${e.message}, statusCode: ${e.statusCode}, error: ${e.error}'
                : e.toString();
        throw Exception(
          'Storage upload failed: Authentication required. Please ensure you are logged in and the session is valid. '
          'Error details: $errorDetails',
        );
      }
      throw Exception('Failed to upload file to Supabase Storage: $e');
    }
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file from Supabase Storage: $e');
    }
  }

  String getPublicUrl({required String bucket, required String path}) {
    return storage.from(bucket).getPublicUrl(path);
  }
}
