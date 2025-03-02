// import 'package:flutter/material.dart';

// void showCustomSnackBar(BuildContext context, String message,
//     {required bool isSuccess}) {
//   final snackBar = SnackBar(
//     content: Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         Expanded(
//           child: Text(
//             message,
//             style: const TextStyle(
//                 fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
//           ),
//         ),
//         IconButton(
//           icon: const Icon(Icons.close, color: Colors.red),
//           onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
//         ),
//       ],
//     ),
//     backgroundColor: Theme.of(context).colorScheme.primary,
//     behavior: SnackBarBehavior.floating,
//     elevation: 6.0,
//     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//     duration: const Duration(seconds: 5),
//   );

//   ScaffoldMessenger.of(context).showSnackBar(snackBar);
// }

import 'package:flutter/material.dart';

class CustomSnackBar {
  static void show(
    BuildContext context,
    String message, {
    bool? isSuccess,
  }) {
    final snackBar = SnackBar(
      closeIconColor: Colors.red,
      showCloseIcon: true,
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: isSuccess == true
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
      elevation: 6.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 5),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
