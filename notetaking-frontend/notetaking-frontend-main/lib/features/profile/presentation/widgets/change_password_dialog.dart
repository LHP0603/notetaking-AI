import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/profile_bloc.dart';
import '../bloc/profile_event.dart';

class ChangePasswordDialog extends StatelessWidget {
  const ChangePasswordDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final passwordController = TextEditingController();
    return AlertDialog(
      title: const Text(
        'Change Password',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color(0xFF282E39),
      content: TextField(
        controller: passwordController,
        obscureText: true,
        style: const TextStyle(color: Colors.black),
        decoration: const InputDecoration(
          hintText: 'New Password',
          hintStyle: TextStyle(color: Colors.grey),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (passwordController.text.length >= 6) {
              context.read<ProfileBloc>().add(
                UpdatePasswordRequested(newPassword: passwordController.text),
              );
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password must be at least 6 characters'),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

void showChangePasswordDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => const ChangePasswordDialog(),
  );
}
