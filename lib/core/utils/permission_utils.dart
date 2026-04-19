import 'package:flutter/material.dart';

void showNoPermissionSnack(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: const Row(
        children: [
          Icon(Icons.lock_outline, color: Colors.white, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No permission.! Only Manager can do this',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.red.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
