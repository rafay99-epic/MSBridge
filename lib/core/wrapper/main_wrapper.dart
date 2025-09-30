// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:provider/provider.dart';

// Project imports:
import 'package:msbridge/core/provider/lock_provider/app_pin_lock_provider.dart';
import 'package:msbridge/core/provider/lock_provider/fingerprint_provider.dart';
import 'package:msbridge/core/wrapper/app_pin_lock_wrapper.dart';
import 'package:msbridge/core/wrapper/fingerprint_wrapper.dart';

class SecurityWrapper extends StatelessWidget {
  final Widget child;

  const SecurityWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppPinLockProvider, FingerprintAuthProvider>(
      builder: (context, pinProvider, fingerprintProvider, _) {
        final Widget pinWrapped = AppPinLockWrapper(child: child);

        if (fingerprintProvider.isFingerprintEnabled) {
          return FingerprintAuthWrapper(child: pinWrapped);
        }

        return pinWrapped;
      },
    );
  }
}
