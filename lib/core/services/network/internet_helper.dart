import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

class InternetHelper {
  final BehaviorSubject<bool> connectivitySubject = BehaviorSubject<bool>();
  Timer? timer;

  InternetHelper() {
    startChecking();
  }

  Future<void> checkInternet() async {
    var result = await Connectivity().checkConnectivity();
    bool connected = result.contains(ConnectivityResult.mobile) ||
        result.contains(ConnectivityResult.wifi);
    connectivitySubject.add(connected);
  }

  void startChecking() {
    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      checkInternet();
    });
    checkInternet();
  }

  void dispose() {
    timer?.cancel();
    connectivitySubject.close();
  }
}
