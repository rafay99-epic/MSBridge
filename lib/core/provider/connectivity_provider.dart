import 'package:flutter/material.dart';
import 'package:msbridge/core/provider/notes_api_provider.dart';
import 'package:msbridge/core/services/network/internet_helper.dart';
import 'package:msbridge/core/api/ms_notes_api.dart';
import 'package:msbridge/widgets/snakbar.dart';
import 'package:provider/provider.dart';

class ConnectivityProvider extends ChangeNotifier {
  final InternetHelper _internetHelper = InternetHelper();
  bool _isConnected = false;
  final GlobalKey<NavigatorState> navigatorKey;
  BuildContext? _context;

  ConnectivityProvider({required this.navigatorKey, BuildContext? context})
      : _context = context {
    _listenToConnectivityChanges();
  }

  bool get isConnected => _isConnected;

  void setBuildContext(BuildContext context) {
    _context = context;
  }

  Future<void> _fetchNotes() async {
    if (_context != null) {
      try {
        if (isConnected) {
          await ApiService.fetchAndSaveNotes();
          Provider.of<LectureNotesProvider>(_context!, listen: false)
              .fetchNotes();
          CustomSnackBar.show(
              _context!, "Internet Connected! Fetching new notes...",
              isSuccess: true);
        } else {
          CustomSnackBar.show(_context!, "No internet connection.");
        }
      } catch (e) {
        CustomSnackBar.show(_context!, "Error fetching notes: $e");
      }
    } else {
      CustomSnackBar.show(_context!, "Sorry No  notes are available");
    }
  }

  void _listenToConnectivityChanges() {
    _internetHelper.connectivitySubject.listen((isConnected) async {
      _isConnected = isConnected;
      notifyListeners();

      if (!_isConnected) {
        CustomSnackBar.show(_context!, "No internet connection.");
      } else {
        await _fetchNotes();
      }
    });
  }

  @override
  void dispose() {
    _internetHelper.dispose();
    super.dispose();
  }
}
