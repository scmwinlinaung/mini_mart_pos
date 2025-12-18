import 'dart:io';
import 'package:process_run/shell.dart';

class DockerService {
  static final DockerService _instance = DockerService._internal();
  factory DockerService() => _instance;
  DockerService._internal();

  bool _isDockerChecked = false;
  bool _isDockerAvailable = false;

  /// Check if Docker is available and running
  Future<bool> isDockerAvailable() async {
    if (_isDockerChecked) return _isDockerAvailable;

    try {
      // Check if Docker is installed and running
      final shell = Shell();
      final results = await shell.run('docker version');
      _isDockerAvailable = results.first.exitCode == 0;
      _isDockerChecked = true;

      if (_isDockerAvailable) {
        print('✅ Docker is available and running');
      } else {
        print('❌ Docker is not available or not running');
      }

      return _isDockerAvailable;
    } catch (e) {
      print('❌ Docker check failed: $e');
      _isDockerAvailable = false;
      _isDockerChecked = true;
      return false;
    }
  }

  /// Check if PostgreSQL container is running
  Future<bool> isPostgresContainerRunning() async {
    if (!await isDockerAvailable()) return false;

    try {
      final shell = Shell();
      final results = await shell.run(
          'docker ps --filter name=mini_mart_pos_db --format "{{.Names}}"');

      return results.first.stdout.toString().trim().contains('mini_mart_pos_db');
    } catch (e) {
      print('❌ Error checking PostgreSQL container: $e');
      return false;
    }
  }

  /// Start PostgreSQL container using Docker Compose
  Future<bool> startPostgresContainer() async {
    if (!await isDockerAvailable()) {
      print('❌ Docker is not available. Cannot start PostgreSQL container.');
      return false;
    }

    try {
      print('🐳 Starting PostgreSQL container...');

      // Check if docker-compose.yml exists
      final composeFile = File('docker-compose.yml');
      if (!await composeFile.exists()) {
        print('❌ docker-compose.yml not found');
        return false;
      }

      // Start the container
      final shell = Shell(workingDirectory: Directory.current.path);
      final results = await shell.run('$dockerComposeCommand up -d postgres');

      if (results.first.exitCode == 0) {
        print('✅ PostgreSQL container started successfully');

        // Wait for database to be ready
        await _waitForDatabase();
        return true;
      } else {
        print('❌ Failed to start PostgreSQL container: ${results.first.stderr}');
        return false;
      }
    } catch (e) {
      print('❌ Error starting PostgreSQL container: $e');
      return false;
    }
  }

  /// Wait for PostgreSQL database to be ready
  Future<void> _waitForDatabase({int maxAttempts = 30}) async {
    print('⏳ Waiting for PostgreSQL database to be ready...');

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final shell = Shell();
        final results = await shell.run(
            'docker exec mini_mart_pos_db pg_isready -U postgres -d mini_mart_pos');

        if (results.first.exitCode == 0) {
          print('✅ PostgreSQL database is ready!');
          return;
        }
      } catch (e) {
        // Database not ready yet, continue waiting
      }

      print('⏳ Attempt $attempt/$maxAttempts: Database not ready yet...');
      await Future.delayed(Duration(seconds: 2));
    }

    print('⚠️  Database may not be fully ready, but continuing...');
  }

  /// Stop PostgreSQL container
  Future<bool> stopPostgresContainer() async {
    if (!await isDockerAvailable()) return false;

    try {
      print('🛑 Stopping PostgreSQL container...');

      final shell = Shell(workingDirectory: Directory.current.path);
      final results = await shell.run('$dockerComposeCommand down');

      if (results.first.exitCode == 0) {
        print('✅ PostgreSQL container stopped successfully');
        return true;
      } else {
        print('❌ Failed to stop PostgreSQL container: ${results.first.stderr}');
        return false;
      }
    } catch (e) {
      print('❌ Error stopping PostgreSQL container: $e');
      return false;
    }
  }

  /// Initialize PostgreSQL container if needed
  Future<bool> initializeDatabase() async {
    // First, try to connect to existing database
    if (await _canConnectToDatabase()) {
      print('✅ Database is already running and accessible');
      return true;
    }

    // If not connected, try to start Docker container
    if (await isPostgresContainerRunning()) {
      print('📦 PostgreSQL container is already running, checking connection...');
      await _waitForDatabase();
      return await _canConnectToDatabase();
    }

    // Start the container
    final started = await startPostgresContainer();
    if (started) {
      return await _canConnectToDatabase();
    }

    return false;
  }

  /// Test if we can connect to the database
  Future<bool> _canConnectToDatabase() async {
    try {
      // This will be called from DatabaseService
      // For now, we'll just check if the container responds to pg_isready
      if (!await isPostgresContainerRunning()) {
        return false;
      }

      final shell = Shell();
      final results = await shell.run(
          'docker exec mini_mart_pos_db pg_isready -U postgres -d mini_mart_pos');

      return results.first.exitCode == 0;
    } catch (e) {
      return false;
    }
  }

  /// Get the appropriate docker-compose command based on platform
  String get dockerComposeCommand {
    if (Platform.isWindows) {
      return 'docker-compose';
    } else {
      // On Linux/macOS, try docker-compose first, then docker compose
      return 'docker-compose';
    }
  }
}