import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/maamoune/friendship_viewmodel.dart';
import '../../models/maamoune/friendship.dart';

class FriendshipScreen extends StatelessWidget {
  const FriendshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<FriendshipViewModel>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Friendship Management",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: vm.friendships.length,
                itemBuilder: (context, index) {
                  final friendship = vm.friendships[index];
                  return Card(
                    child: ListTile(
                      title: Text('Friendship: ${friendship.userId} ↔ ${friendship.friendId}'),
                      subtitle: Text('Status: ${friendship.status.name}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          vm.deleteFriendship(friendship.friendshipId);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                vm.sendFriendRequest(Friendship(
                  friendshipId: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: '1',
                  friendId: '2',
                  status: FriendshipStatus.pending,
                ));
              },
              child: const Text("Add Random Friendship"),
            ),
          ],
        ),
      ),
    );
  }
}
