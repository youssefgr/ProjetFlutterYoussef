import 'dart:io';

import 'package:projetflutteryoussef/Models/Youssef/subscription_template.dart';
import 'package:projetflutteryoussef/Models/Youssef/user_subscription.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class SubscriptionRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Récupérer tous les templates
  Future<List<SubscriptionTemplate>> getTemplates() async {
    try {
      final response = await _supabase
          .from('subscription_templates')
          .select()
          .order('name');

      return (response as List)
          .map((json) => SubscriptionTemplate.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading templates: $e');
      return [];
    }
  }

  // Récupérer les subscriptions de l'utilisateur
  Future<List<UserSubscription>> getUserSubscriptions(String userId) async {
    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserSubscription.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Error loading user subscriptions: $e');
      return [];
    }
  }

  // Ajouter une subscription
  Future<bool> addSubscription(UserSubscription subscription) async {
    try {
      await _supabase.from('user_subscriptions').insert(subscription.toJson());
      print('✅ Subscription added successfully');
      return true;
    } catch (e) {
      print('❌ Error adding subscription: $e');
      return false;
    }
  }

  // Mettre à jour une subscription
  Future<bool> updateSubscription(UserSubscription subscription) async {
    try {
      await _supabase
          .from('user_subscriptions')
          .update(subscription.toJson())
          .eq('id', subscription.id);
      print('✅ Subscription updated successfully');
      return true;
    } catch (e) {
      print('❌ Error updating subscription: $e');
      return false;
    }
  }

  // Supprimer une subscription
  Future<bool> deleteSubscription(String id) async {
    try {
      await _supabase.from('user_subscriptions').delete().eq('id', id);
      print('✅ Subscription deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting subscription: $e');
      return false;
    }
  }

  // Uploader une image custom vers Supabase Storage
  Future<String?> uploadCustomImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();

      final path = 'subscription_images/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage
          .from('subscriptions')
          .uploadBinary(path, bytes);

      final url = _supabase.storage
          .from('subscriptions')
          .getPublicUrl(path);

      print('✅ Image uploaded: $url');
      return url;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }
  // Dans subscription_repository.dart
  Future<List<UserSubscription>> getAllSubscriptions() async {
    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserSubscription.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Erreur lors du chargement de tous les abonnements: $e');
      return [];
    }
  }

}