// Dart imports:
import 'dart:convert';
import 'dart:io';

// Flutter imports:
import 'package:flutter/foundation.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

/// Comprehensive test runner that executes all tests and generates detailed reports
class TestRunner {
  static const String _testDir = 'test';
  static const String _reportDir = 'test_reports';

  /// Main entry point to run all tests
  static Future<void> runAllTests({bool generateReport = true}) async {
    debugPrint('🚀 Starting comprehensive test suite...\n');

    final startTime = DateTime.now();
    final results = <TestSuiteResult>[];

    // Define test categories
    final testSuites = [
      TestSuite(
        name: 'Core Functionality',
        description: 'Database, initialization, and core system tests',
        files: [
          'database_hive_test.dart',
          'core_initialization_test.dart',
          'provider_state_test.dart',
        ],
      ),
      TestSuite(
        name: 'Note Taking Features',
        description: 'Note creation, editing, and management tests',
        files: [
          'note_taking_feature_test.dart',
          'note_reading_feature_test.dart',
        ],
      ),
      TestSuite(
        name: 'Voice Functionality',
        description: 'Voice recording, playback, and processing tests',
        files: [
          'voice_service_test.dart',
          'voice_player_optimization_test.dart',
          'voice_integration_test.dart',
          'voice_export_test.dart',
          'voice_format_test.dart',
          'voice_settings_validation_test.dart',
          'voice_ui_test.dart',
        ],
      ),
      TestSuite(
        name: 'UI & Integration',
        description: 'User interface and end-to-end integration tests',
        files: [
          'integration_test.dart',
          'ui_rendering_test.dart',
          'theme_engine_test.dart',
          'notification_test.dart',
        ],
      ),
    ];

    // Run each test suite
    for (final suite in testSuites) {
      debugPrint('📋 Running ${suite.name} tests...');
      final result = await _runTestSuite(suite);
      results.add(result);

      // Print immediate results
      _printSuiteResult(result);
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    // Generate comprehensive report
    if (generateReport) {
      await _generateReport(results, duration);
    }

    // Print summary
    _printSummary(results, duration);

    // Exit with appropriate code
    final totalFailures =
        results.fold<int>(0, (sum, result) => sum + result.failures);
    exit(totalFailures > 0 ? 1 : 0);
  }

  /// Run a single test suite
  static Future<TestSuiteResult> _runTestSuite(TestSuite suite) async {
    final startTime = DateTime.now();
    final testResults = <TestFileResult>[];

    for (final file in suite.files) {
      final filePath = path.join(_testDir, file);
      if (await File(filePath).exists()) {
        debugPrint('  📄 Running $file...');
        final result = await _runTestFile(filePath);
        testResults.add(result);
      } else {
        debugPrint('  ⚠️  File not found: $file');
        testResults.add(TestFileResult(
          fileName: file,
          passed: false,
          skipped: true,
          error: 'File not found',
        ));
      }
    }

    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);

    return TestSuiteResult(
      name: suite.name,
      description: suite.description,
      duration: duration,
      testResults: testResults,
    );
  }

  /// Run a single test file
  static Future<TestFileResult> _runTestFile(String filePath) async {
    try {
      final process = await Process.start(
        'flutter',
        ['test', filePath, '--reporter', 'json'],
        workingDirectory: Directory.current.path,
      );

      await process.exitCode;
      final stdout = await process.stdout.transform(utf8.decoder).join();
      final stderr = await process.stderr.transform(utf8.decoder).join();

      // Parse JSON output to get test results
      final lines = stdout.split('\n').where((line) => line.trim().isNotEmpty);
      int passed = 0;
      int failed = 0;
      int skipped = 0;
      String? error;

      for (final line in lines) {
        try {
          final json = jsonDecode(line);
          if (json['type'] == 'testDone') {
            final result = json['result'];
            switch (result) {
              case 'success':
                passed++;
                break;
              case 'error':
              case 'failure':
                failed++;
                break;
              case 'skipped':
                skipped++;
                break;
            }
          }
        } catch (e) {
          // Ignore non-JSON lines
        }
      }

      if (stderr.isNotEmpty) {
        error = stderr;
      }

      return TestFileResult(
        fileName: path.basename(filePath),
        passed: failed == 0,
        skipped: skipped > 0 && passed == 0 && failed == 0,
        passedCount: passed,
        failedCount: failed,
        skippedCount: skipped,
        error: error,
      );
    } catch (e) {
      return TestFileResult(
        fileName: path.basename(filePath),
        passed: false,
        skipped: false,
        error: e.toString(),
      );
    }
  }

  /// Generate comprehensive HTML report
  static Future<void> _generateReport(
      List<TestSuiteResult> results, Duration totalDuration) async {
    final reportDir = Directory(_reportDir);
    if (!await reportDir.exists()) {
      await reportDir.create(recursive: true);
    }

    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final reportFile =
        File(path.join(_reportDir, 'test_report_$timestamp.html'));

    final html = _generateHtmlReport(results, totalDuration);
    await reportFile.writeAsString(html);

    debugPrint('\n📊 Detailed report generated: ${reportFile.path}');
  }

  /// Generate HTML report content
  static String _generateHtmlReport(
      List<TestSuiteResult> results, Duration totalDuration) {
    final totalTests =
        results.fold<int>(0, (sum, result) => sum + result.totalTests);
    final totalPassed =
        results.fold<int>(0, (sum, result) => sum + result.passed);
    final totalFailed =
        results.fold<int>(0, (sum, result) => sum + result.failures);
    final totalSkipped =
        results.fold<int>(0, (sum, result) => sum + result.skipped);

    final passRate = totalTests > 0
        ? (totalPassed / totalTests * 100).toStringAsFixed(1)
        : '0.0';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MSBridge Test Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header h1 { margin: 0; font-size: 2.5em; }
        .header .subtitle { margin: 10px 0 0 0; opacity: 0.9; }
        .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; padding: 30px; }
        .stat-card { background: #f8f9fa; padding: 20px; border-radius: 8px; text-align: center; }
        .stat-number { font-size: 2em; font-weight: bold; margin-bottom: 5px; }
        .stat-label { color: #666; font-size: 0.9em; }
        .passed { color: #28a745; }
        .failed { color: #dc3545; }
        .skipped { color: #ffc107; }
        .suite { margin: 20px 0; border: 1px solid #e0e0e0; border-radius: 8px; overflow: hidden; }
        .suite-header { background: #f8f9fa; padding: 15px 20px; border-bottom: 1px solid #e0e0e0; }
        .suite-header h3 { margin: 0; color: #333; }
        .suite-header .description { margin: 5px 0 0 0; color: #666; font-size: 0.9em; }
        .test-file { padding: 15px 20px; border-bottom: 1px solid #f0f0f0; }
        .test-file:last-child { border-bottom: none; }
        .test-file-header { display: flex; justify-content: between; align-items: center; margin-bottom: 10px; }
        .test-file-name { font-weight: 500; color: #333; }
        .test-file-status { padding: 4px 8px; border-radius: 4px; font-size: 0.8em; font-weight: 500; }
        .test-file-status.passed { background: #d4edda; color: #155724; }
        .test-file-status.failed { background: #f8d7da; color: #721c24; }
        .test-file-status.skipped { background: #fff3cd; color: #856404; }
        .test-details { font-size: 0.9em; color: #666; }
        .error { background: #f8d7da; color: #721c24; padding: 10px; border-radius: 4px; margin-top: 10px; font-family: monospace; font-size: 0.8em; }
        .footer { padding: 20px; text-align: center; color: #666; border-top: 1px solid #e0e0e0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🧪 MSBridge Test Report</h1>
            <p class="subtitle">Generated on ${DateTime.now().toLocal().toString().split('.')[0]}</p>
        </div>
        
        <div class="stats">
            <div class="stat-card">
                <div class="stat-number passed">$totalPassed</div>
                <div class="stat-label">Tests Passed</div>
            </div>
            <div class="stat-card">
                <div class="stat-number failed">$totalFailed</div>
                <div class="stat-label">Tests Failed</div>
            </div>
            <div class="stat-card">
                <div class="stat-number skipped">$totalSkipped</div>
                <div class="stat-label">Tests Skipped</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">$passRate%</div>
                <div class="stat-label">Pass Rate</div>
            </div>
            <div class="stat-card">
                <div class="stat-number">${totalDuration.inSeconds}s</div>
                <div class="stat-label">Total Duration</div>
            </div>
        </div>
        
        ${results.map((suite) => _generateSuiteHtml(suite)).join('')}
        
        <div class="footer">
            <p>MSBridge Test Suite • Generated by TestRunner</p>
        </div>
    </div>
</body>
</html>
''';
  }

  /// Generate HTML for a test suite
  static String _generateSuiteHtml(TestSuiteResult suite) {
    return '''
    <div class="suite">
        <div class="suite-header">
            <h3>${suite.name}</h3>
            <p class="description">${suite.description}</p>
            <p class="description">Duration: ${suite.duration.inSeconds}s • Tests: ${suite.totalTests} • Passed: ${suite.passed} • Failed: ${suite.failures} • Skipped: ${suite.skipped}</p>
        </div>
        ${suite.testResults.map((result) => _generateTestFileHtml(result)).join('')}
    </div>
    ''';
  }

  /// Generate HTML for a test file result
  static String _generateTestFileHtml(TestFileResult result) {
    final statusClass =
        result.passed ? 'passed' : (result.skipped ? 'skipped' : 'failed');
    final statusText =
        result.passed ? 'PASSED' : (result.skipped ? 'SKIPPED' : 'FAILED');

    return '''
    <div class="test-file">
        <div class="test-file-header">
            <span class="test-file-name">${result.fileName}</span>
            <span class="test-file-status $statusClass">$statusText</span>
        </div>
        <div class="test-details">
            Passed: ${result.passedCount} • Failed: ${result.failedCount} • Skipped: ${result.skippedCount}
        </div>
        ${result.error != null ? '<div class="error">${result.error}</div>' : ''}
    </div>
    ''';
  }

  /// Print suite result to console
  static void _printSuiteResult(TestSuiteResult result) {
    final status = result.failures == 0 ? '✅' : '❌';
    debugPrint(
        '$status ${result.name}: ${result.passed}/${result.totalTests} passed (${result.duration.inSeconds}s)');

    for (final testResult in result.testResults) {
      final testStatus =
          testResult.passed ? '✅' : (testResult.skipped ? '⏭️' : '❌');
      debugPrint('  $testStatus ${testResult.fileName}');
      if (testResult.error != null && !testResult.skipped) {
        debugPrint('    Error: ${testResult.error}');
      }
    }
    debugPrint('');
  }

  /// Print final summary
  static void _printSummary(List<TestSuiteResult> results, Duration duration) {
    final totalTests =
        results.fold<int>(0, (sum, result) => sum + result.totalTests);
    final totalPassed =
        results.fold<int>(0, (sum, result) => sum + result.passed);
    final totalFailed =
        results.fold<int>(0, (sum, result) => sum + result.failures);
    final totalSkipped =
        results.fold<int>(0, (sum, result) => sum + result.skipped);

    debugPrint('📊 TEST SUMMARY');
    debugPrint('═' * 50);
    debugPrint('Total Tests: $totalTests');
    debugPrint('✅ Passed: $totalPassed');
    debugPrint('❌ Failed: $totalFailed');
    debugPrint('⏭️ Skipped: $totalSkipped');
    debugPrint('⏱️ Duration: ${duration.inSeconds}s');
    debugPrint(
        '📈 Pass Rate: ${totalTests > 0 ? (totalPassed / totalTests * 100).toStringAsFixed(1) : '0.0'}%');
    debugPrint('═' * 50);

    if (totalFailed == 0) {
      debugPrint('🎉 All tests passed!');
    } else {
      debugPrint(
          '⚠️ Some tests failed. Check the detailed report for more information.');
    }
  }
}

/// Test suite configuration
class TestSuite {
  final String name;
  final String description;
  final List<String> files;

  const TestSuite({
    required this.name,
    required this.description,
    required this.files,
  });
}

/// Test suite result
class TestSuiteResult {
  final String name;
  final String description;
  final Duration duration;
  final List<TestFileResult> testResults;

  TestSuiteResult({
    required this.name,
    required this.description,
    required this.duration,
    required this.testResults,
  });

  int get totalTests =>
      testResults.fold<int>(0, (sum, result) => sum + result.totalTests);
  int get passed =>
      testResults.fold<int>(0, (sum, result) => sum + result.passedCount);
  int get failures =>
      testResults.fold<int>(0, (sum, result) => sum + result.failedCount);
  int get skipped =>
      testResults.fold<int>(0, (sum, result) => sum + result.skippedCount);
}

/// Individual test file result
class TestFileResult {
  final String fileName;
  final bool passed;
  final bool skipped;
  final int passedCount;
  final int failedCount;
  final int skippedCount;
  final String? error;

  TestFileResult({
    required this.fileName,
    required this.passed,
    required this.skipped,
    this.passedCount = 0,
    this.failedCount = 0,
    this.skippedCount = 0,
    this.error,
  });

  int get totalTests => passedCount + failedCount + skippedCount;
}

/// Main entry point
void main() async {
  await TestRunner.runAllTests();
}
