import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

class InternetHelper {
  final BehaviorSubject<bool> connectivitySubject = BehaviorSubject<bool>();
  Timer? timer;
  bool _isDisposed = false;

  InternetHelper() {
    startChecking();
  }

  Future<void> checkInternet() async {
    // Don't add events if the stream is closed or disposed
    if (_isDisposed || connectivitySubject.isClosed) {
      return;
    }

    try {
      var result = await Connectivity().checkConnectivity();
      bool connected = result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);

      // Double-check before adding to stream
      if (!_isDisposed && !connectivitySubject.isClosed) {
        connectivitySubject.add(connected);
      }
    } catch (e) {
      // Handle any connectivity check errors gracefully
      if (!_isDisposed && !connectivitySubject.isClosed) {
        connectivitySubject.add(false);
      }
    }
  }

  void startChecking() {
    if (_isDisposed) return;

    timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isDisposed) {
        checkInternet();
      }
    });
    checkInternet();
  }

  void dispose() {
    _isDisposed = true;
    timer?.cancel();
    timer = null;

    if (!connectivitySubject.isClosed) {
      connectivitySubject.close();
    }
  }

  // Getter to check if helper is disposed
  bool get isDisposed => _isDisposed;
}
