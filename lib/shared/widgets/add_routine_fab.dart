import 'package:flutter/material.dart';

class AddRoutineFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AddRoutineFab({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: 'Add Routine',
      child: const Icon(Icons.add),
    );
  }
}
