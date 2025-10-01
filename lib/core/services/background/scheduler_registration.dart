// Package imports:
import 'package:workmanager/workmanager.dart';

// Project imports:
import 'package:msbridge/core/services/background/workmanager_dispatcher.dart';

class SchedulerRegistration {
  static Future<void> registerAdaptive() async {
    // Fixed 6-hour cadence per request
    const Duration frequency = Duration(hours: 6);

    await Workmanager().cancelByUniqueName('msbridge.periodic.all.id');
    await Workmanager().registerPeriodicTask(
      'msbridge.periodic.all.id',
      BgTasks.taskPeriodicAll,
      frequency: frequency,
      initialDelay: const Duration(minutes: 20),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
        requiresCharging: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }
}
