import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/maamoune/user_viewmodel.dart';
import '../../models/maamoune/user.dart';

class UserScreen extends StatelessWidget {
  const UserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<UserViewModel>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Users Management",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: vm.users.length,
                itemBuilder: (context, index) {
                  final user = vm.users[index];
                  return Card(
                    child: ListTile(
                      title: Text(user.username),
                      subtitle: Text(user.email),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          vm.deleteUser(user.userId);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                vm.addUser(User(
                  userId: DateTime.now().millisecondsSinceEpoch.toString(),
                  username: 'User ${vm.users.length + 1}',
                  email: 'user${vm.users.length + 1}@example.com',
                  avatarUrl: 'avatar.png',
                ));
              },
              child: const Text("Add Random User"),
            ),
          ],
        ),
      ),
    );
  }
}
