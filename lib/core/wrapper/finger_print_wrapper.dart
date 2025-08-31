// import 'package:flutter/material.dart';
// import 'package:msbridge/core/provider/lock_app/fingerprint_provider.dart';
// import 'package:msbridge/core/wrapper/pin_wrapper.dart';
// import 'package:provider/provider.dart';
// import 'package:msbridge/core/repo/auth_gate.dart';
// import 'package:msbridge/core/provider/lock_app/app_pin_lock_provider.dart';

// class FingerprintAuthWrapper extends StatefulWidget {
//   const FingerprintAuthWrapper({super.key});

//   @override
//   State<FingerprintAuthWrapper> createState() => _FingerprintAuthWrapperState();
// }

// class _FingerprintAuthWrapperState extends State<FingerprintAuthWrapper>
//     with WidgetsBindingObserver {
//   bool _isAuthenticated = false;
//   bool _isAuthenticating = false;
//   bool _isLoading = true;
//   bool _shouldReauthenticate = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _loadAndAuthenticate();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     if (state == AppLifecycleState.resumed) {
//       final fingerprintProvider =
//           Provider.of<FingerprintAuthProvider>(context, listen: false);

//       // Check if we need to re-authenticate
//       if (fingerprintProvider.isFingerprintEnabled &&
//           fingerprintProvider.wasRecentlyInBackground) {
//         setState(() {
//           _isAuthenticated = false;
//           _shouldReauthenticate = true;
//         });
//         _loadAndAuthenticate();
//       }
//     } else if (state == AppLifecycleState.paused) {
//       // App going to background
//       final fingerprintProvider =
//           Provider.of<FingerprintAuthProvider>(context, listen: false);
//       fingerprintProvider
//           .onFingerprintVerificationSuccess(); // Reset background time
//     }
//   }

//   Future<void> _loadAndAuthenticate() async {
//     if (!mounted) return;

//     final fingerprintProvider =
//         Provider.of<FingerprintAuthProvider>(context, listen: false);

//     await Future.delayed(const Duration(milliseconds: 100));

//     if (fingerprintProvider.isFingerprintEnabled) {
//       // Always show authentication screen when fingerprint is enabled
//       if (!_isAuthenticated && !_isAuthenticating) {
//         setState(() {
//           _isAuthenticating = true;
//           _isLoading = false;
//         });
//         bool authenticated = await fingerprintProvider.authenticate(context);
//         if (mounted) {
//           setState(() {
//             _isAuthenticated = authenticated;
//             _isAuthenticating = false;
//             _shouldReauthenticate = false;
//           });
//         }
//       } else {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     } else {
//       // Check if PIN is enabled as fallback
//       final pinProvider =
//           Provider.of<AppPinLockProvider>(context, listen: false);
//       await pinProvider.refreshPinLockState();

//       if (pinProvider.enabled && await pinProvider.hasPin()) {
//         // Switch to PIN authentication
//         if (mounted) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             Navigator.pushReplacement(
//               context,
//               MaterialPageRoute(
//                 builder: (context) =>
//                     const AppPinLockWrapper(child: AuthGate()),
//               ),
//             );
//           });
//         }
//       } else {
//         if (mounted) {
//           setState(() {
//             _isAuthenticated = true;
//             _isLoading = false;
//           });
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final fingerprintProvider = Provider.of<FingerprintAuthProvider>(context);
//     final theme = Theme.of(context);

//     if (_isLoading) {
//       return const LoadingScreen();
//     }

//     if ((fingerprintProvider.isFingerprintEnabled &&
//             (!_isAuthenticated || _shouldReauthenticate)) ||
//         _shouldReauthenticate) {
//       return Scaffold(
//         backgroundColor: theme.colorScheme.surface,
//         body: Center(
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.fingerprint_rounded,
//                   size: 80,
//                   color: theme.colorScheme.secondary,
//                 ),
//                 const SizedBox(height: 20),
//                 Text(
//                   "Authenticate to Access the App",
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w500,
//                     color: theme.colorScheme.primary,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 32),
//                 ElevatedButton.icon(
//                   onPressed: _isAuthenticating
//                       ? null
//                       : () async {
//                           setState(() {
//                             _isAuthenticating = true;
//                           });
//                           bool authenticated =
//                               await fingerprintProvider.authenticate(context);
//                           if (mounted) {
//                             setState(() {
//                               _isAuthenticated = authenticated;
//                               _isAuthenticating = false;
//                               _shouldReauthenticate = false;
//                             });
//                           }
//                         },
//                   icon: _isAuthenticating
//                       ? const SizedBox(
//                           width: 20,
//                           height: 20,
//                           child: CircularProgressIndicator(
//                             color: Colors.white,
//                             strokeWidth: 2,
//                           ),
//                         )
//                       : const Icon(Icons.fingerprint),
//                   label: Text(
//                     _isAuthenticating
//                         ? "Authenticating..."
//                         : "Authenticate with Fingerprint",
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 32, vertical: 14),
//                     textStyle: const TextStyle(
//                         fontSize: 16, fontWeight: FontWeight.w500),
//                     backgroundColor: theme.colorScheme.secondary,
//                     foregroundColor: theme.colorScheme.primary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     } else {
//       return const AuthGate();
//     }
//   }
// }

// class LoadingScreen extends StatelessWidget {
//   const LoadingScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);

//     return Scaffold(
//       backgroundColor: theme.colorScheme.surface,
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         alignment: Alignment.center,
//         child: FractionallySizedBox(
//           widthFactor: 0.8,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               ShaderMask(
//                 shaderCallback: (Rect bounds) {
//                   return LinearGradient(
//                     colors: [
//                       theme.colorScheme.secondary,
//                       theme.colorScheme.primary
//                     ],
//                     stops: const [0.4, 1.0],
//                   ).createShader(bounds);
//                 },
//                 child: const Icon(
//                   Icons.fingerprint_rounded,
//                   size: 80,
//                   color: Colors.white,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               TweenAnimationBuilder<double>(
//                 tween: Tween<double>(begin: 0.3, end: 1.0),
//                 duration: const Duration(seconds: 1),
//                 curve: Curves.easeInOut,
//                 builder: (context, opacity, child) {
//                   return Opacity(
//                     opacity: opacity,
//                     child: Text(
//                       "Authenticating...",
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: theme.colorScheme.primary,
//                         letterSpacing: 1.2,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   );
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/lock_app/fingerprint_provider.dart';
import 'package:msbridge/core/wrapper/pin_wrapper.dart';
import 'package:msbridge/features/lock/fingerprint/fingerprint_auth.dart';
import 'package:provider/provider.dart';
import 'package:msbridge/core/provider/lock_app/app_pin_lock_provider.dart';

class FingerprintAuthWrapper extends StatefulWidget {
  final Widget child;

  const FingerprintAuthWrapper({
    super.key,
    required this.child,
  });

  @override
  State<FingerprintAuthWrapper> createState() => _FingerprintAuthWrapperState();
}

class _FingerprintAuthWrapperState extends State<FingerprintAuthWrapper>
    with WidgetsBindingObserver {
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;
  bool _isLoading = true;
  bool _shouldReauthenticate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAndAuthenticate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      final fingerprintProvider =
          Provider.of<FingerprintAuthProvider>(context, listen: false);

      // Check if we need to re-authenticate
      if (fingerprintProvider.isFingerprintEnabled &&
          fingerprintProvider.wasRecentlyInBackground) {
        setState(() {
          _isAuthenticated = false;
          _shouldReauthenticate = true;
        });
        _loadAndAuthenticate();
      }
    } else if (state == AppLifecycleState.paused) {
      // App going to background
      final fingerprintProvider =
          Provider.of<FingerprintAuthProvider>(context, listen: false);
      fingerprintProvider
          .onFingerprintVerificationSuccess(); // Reset background time
    }
  }

  Future<void> _loadAndAuthenticate() async {
    if (!mounted) return;

    final fingerprintProvider =
        Provider.of<FingerprintAuthProvider>(context, listen: false);

    await Future.delayed(const Duration(milliseconds: 100));

    if (fingerprintProvider.isFingerprintEnabled) {
      // Always show authentication screen when fingerprint is enabled
      if (!_isAuthenticated && !_isAuthenticating) {
        setState(() {
          _isAuthenticating = true;
          _isLoading = false;
        });
        bool authenticated = await fingerprintProvider.authenticate(context);
        if (mounted) {
          setState(() {
            _isAuthenticated = authenticated;
            _isAuthenticating = false;
            _shouldReauthenticate = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Check if PIN is enabled as fallback
      final pinProvider =
          Provider.of<AppPinLockProvider>(context, listen: false);
      await pinProvider.refreshPinLockState();

      if (pinProvider.enabled && await pinProvider.hasPin()) {
        // Switch to PIN authentication
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AppPinLockWrapper(child: widget.child),
              ),
            );
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isAuthenticated = true;
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    final fingerprintProvider = Provider.of<FingerprintAuthProvider>(context);

    if ((fingerprintProvider.isFingerprintEnabled &&
            (!_isAuthenticated || _shouldReauthenticate)) ||
        _shouldReauthenticate) {
      return FingerprintAuthScreen(
        isAuthenticating: _isAuthenticating,
        onAuthenticate: () async {
          setState(() {
            _isAuthenticating = true;
          });
          bool authenticated = await fingerprintProvider.authenticate(context);
          if (mounted) {
            setState(() {
              _isAuthenticated = authenticated;
              _isAuthenticating = false;
              _shouldReauthenticate = false;
            });
          }
        },
      );
    } else {
      return widget.child;
    }
  }
}
