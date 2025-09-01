import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FingerprintAuthProvider with ChangeNotifier {
  bool _isFingerprintEnabled = false;
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _fingerprintKey = 'fingerprintEnabled';

  FingerprintAuthProvider() {
    _loadFingerprintStatus();
  }

  bool get isFingerprintEnabled => _isFingerprintEnabled;

  Future<void> _loadFingerprintStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = prefs.getBool(_fingerprintKey) ?? false;
    notifyListeners();
  }

  Future<void> setFingerprintEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isFingerprintEnabled = value;
    await prefs.setBool(_fingerprintKey, value);
    notifyListeners();
  }

  Future<bool> authenticate(BuildContext context) async {
    try {
      bool canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!canCheckBiometrics) {
        CustomSnackBar.show(context, "Device doesn't support biometrics");
        return false;
      }

      List<BiometricType> availableBiometrics =
          await _auth.getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        CustomSnackBar.show(context, "No biometrics are available.");

        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to access the app',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      return didAuthenticate;
    } catch (e) {
      String errorMessage = "Authentication failed: $e";
      if (e is PlatformException) {
        switch (e.code) {
          case 'AuthenticationCanceled':
            errorMessage = "Authentication canceled by user.";
            break;
          case 'AuthenticationFailed':
            errorMessage = "Authentication failed.";
            break;
          case 'NotEnrolled':
            errorMessage = "No biometrics enrolled on this device.";
            break;
          case 'LockedOut':
            errorMessage = "Too many failed attempts. Biometrics locked out.";
            break;
          case 'PermanentlyLockedOut':
            errorMessage = "Biometrics permanently locked out.";
            break;
          case 'NotAvailable':
            errorMessage = "Biometric authentication is not available.";
            break;
          default:
            errorMessage = "Authentication error: ${e.message}";
            break;
        }
      }
      if (kDebugMode) {
        print(errorMessage);
      }
      CustomSnackBar.show(context, errorMessage);
      return false;
    }
  }
}
