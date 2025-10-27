import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/maamoune/community_viewmodel.dart';
import '../../models/maamoune/community.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CommunityViewModel>(context);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Community Management",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: vm.communities.length,
                itemBuilder: (context, index) {
                  final community = vm.communities[index];
                  return Card(
                    child: ListTile(
                      title: Text(community.name),
                      subtitle: Text(community.description),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          vm.deleteCommunity(community.communityId);
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                vm.createCommunity(Community(
                  communityId: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: 'Community ${vm.communities.length + 1}',
                  description: 'Auto-created community',
                  ownerId: '1',
                ));
              },
              child: const Text("Add Random Community"),
            ),
          ],
        ),
      ),
    );
  }
}
