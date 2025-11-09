import 'package:projetflutteryoussef/Models/maamoune/user.dart';
import 'package:projetflutteryoussef/Models/maamoune/community.dart';
import 'package:projetflutteryoussef/Models/maamoune/friendship.dart';
import 'package:projetflutteryoussef/repositories/maamoune/user_repository.dart';
import 'package:projetflutteryoussef/repositories/maamoune/community_repository.dart';
import 'package:projetflutteryoussef/repositories/maamoune/friendship_repository.dart';
void main() {
  print("CRUD TESTS\n");

  final userRepo = UserRepository();
  final communityRepo = CommunityRepository();
  final friendshipRepo = FriendshipRepository();

  // 👤 USER CRUD TEST

  print("USER TESTS");

  userRepo.addUser(User(
    userId: '1',
    username: 'Maamoune',
    email: 'maamoune@example.com',
    avatarUrl: 'avatar1.png',
  ));

  userRepo.addUser(User(
    userId: '2',
    username: 'Youssef',
    email: 'youssef@example.com',
    avatarUrl: 'avatar2.png',
  ));

  print("All users after creation: ${userRepo.getAllUsers()}");

  // Update
  userRepo.updateUser(User(
    userId: '1',
    username: 'Maamoune Updated',
    email: 'maamoune@updated.com',
    avatarUrl: 'avatar1_new.png',
  ));
  print("Users after update: ${userRepo.getAllUsers()}");

  // Delete
  userRepo.deleteUser('2');
  print("Users after deletion: ${userRepo.getAllUsers()}\n");

  //COMMUNITY CRUD TEST

  print("COMMUNITY TESTS");

  communityRepo.createCommunity(Community(
    communityId: 'c1',
    name: 'Anime Lovers',
    description: 'Discuss anime and manga',
    ownerId: '1',
  ));

  communityRepo.createCommunity(Community(
    communityId: 'c2',
    name: 'Manga Club',
    description: 'All about manga',
    ownerId: '1',
  ));

  print("All communities: ${communityRepo.getAllCommunities()}");

  // Update
  communityRepo.updateCommunity(Community(
    communityId: 'c2',
    name: 'Manga Club Updated',
    description: 'Updated description',
    ownerId: '1',
  ));
  print("Communities after update: ${communityRepo.getAllCommunities()}");

  // Delete
  communityRepo.deleteCommunity('c1');
  print("Communities after deletion: ${communityRepo.getAllCommunities()}\n");

  //FRIENDSHIP CRUD TEST

  print("FRIENDSHIP TESTS");

  friendshipRepo.sendFriendRequest(Friendship(
    friendshipId: 'f1',
    userId: '1',
    friendId: '2',
    status: FriendshipStatus.pending,
  ));

  print("Friend requests: ${friendshipRepo.getAllFriendships()}");

  // Accept
  friendshipRepo.updateFriendshipStatus('f1', FriendshipStatus.accepted);
  print("After accepting: ${friendshipRepo.getAllFriendships()}");

  // Remove
  friendshipRepo.removeFriendship('f1');
  print("After removal: ${friendshipRepo.getAllFriendships()}\n");

}