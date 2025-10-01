#!/usr/bin/env dart

import 'dart:io';

Future<void> main(List<String> args) async {
  // Allow overriding base branch (default “main”)
  final base = args.isNotEmpty ? args.first : 'main';

  // 1) detect current branch
  final branchRes =
      await Process.run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  if (branchRes.exitCode != 0) {
    stderr.writeln('✖ git error: ${branchRes.stderr}');
    exit(1);
  }
  final branch = (branchRes.stdout as String).trim();

  // 2) commit range from base → HEAD
  final range = '$base..HEAD';

  // 3) grab all commits in that range
  final logRes = await Process.run(
    'git',
    ['log', range, '--pretty=format:%H||%s'],
  );
  if (logRes.exitCode != 0) {
    stderr.writeln('✖ git log error: ${logRes.stderr}');
    exit(1);
  }
  final rawCommits = (logRes.stdout as String).trim();
  final commitLines = rawCommits.isEmpty ? <String>[] : rawCommits.split('\n');

  // 4) categorize commits
  final features = <Map<String, String>>[];
  final fixes = <Map<String, String>>[];
  final perfs = <Map<String, String>>[];
  final others = <Map<String, String>>[];

  for (var line in commitLines) {
    final parts = line.split('||');
    if (parts.length < 2) continue;
    final hash = parts[0].substring(0, 7);
    final msg = parts[1];
    final lower = msg.toLowerCase();
    if (lower.startsWith('feat')) {
      features.add({'h': hash, 'm': msg});
    } else if (lower.startsWith('fix') || lower.startsWith('bugfix')) {
      fixes.add({'h': hash, 'm': msg});
    } else if (lower.startsWith('perf') || lower.contains('optimi')) {
      perfs.add({'h': hash, 'm': msg});
    } else {
      others.add({'h': hash, 'm': msg});
    }
  }

  // 5) get file‐level diff stats
  final diffRes = await Process.run(
    'git',
    ['diff', range, '--numstat'],
  );
  if (diffRes.exitCode != 0) {
    stderr.writeln('✖ git diff error: ${diffRes.stderr}');
    exit(1);
  }
  final rawDiff = (diffRes.stdout as String).trim();
  final diffLines = rawDiff.isEmpty ? <String>[] : rawDiff.split('\n');
  final files = <Map<String, String>>[];
  for (var line in diffLines) {
    final parts = line.split('\t');
    if (parts.length < 3) continue;
    files.add({
      'f': parts[2],
      'in': parts[0],
      'del': parts[1],
    });
  }

  // 6) build markdown
  final date = DateTime.now().toIso8601String().split('T').first;
  final sb = StringBuffer()..writeln('# Change Log for `$branch` ($date)\n');

  void writeSection(String title, List<Map<String, String>> list) {
    if (list.isEmpty) return;
    sb.writeln('## $title\n');
    for (var e in list) {
      sb.writeln('- `${e['h']}` ${e['m']}');
    }
    sb.writeln();
  }

  writeSection('Features', features);
  writeSection('Bug Fixes', fixes);
  writeSection('Optimizations', perfs);
  writeSection('Others', others);

  if (files.isNotEmpty) {
    sb.writeln('## Changed Files\n');
    for (var f in files) {
      sb.writeln('- `${f['f']}`: +${f['in']} −${f['del']}');
    }
    sb.writeln();
  }

  // 7) write to disk
  final out = File('README_REPORT.md');
  out.writeAsStringSync(sb.toString());
  stdout.writeln('✅ README_REPORT.md generated.');
}
