import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:projetflutteryoussef/Models/Youssef/user_subscription.dart';
import 'package:projetflutteryoussef/Models/Youssef/subscription_template.dart';

class SubscriptionRepository {
  static const String _subscriptionsTable = 'user_subscriptions'; // ✨ User subscriptions
  static const String _templatesTable = 'subscription_templates'; // ✨ Static templates
  static const String _bucketName = 'subscriptions';

  // ✨ 1. LOAD TEMPLATES (SHARED)
  Future<List<SubscriptionTemplate>> getTemplates() async {
    try {
      print('📥 Loading templates...');

      final response = await Supabase.instance.client
          .from(_templatesTable)
          .select();

      if (response == null) return [];

      final templates = (response as List)
          .map((json) => SubscriptionTemplate.fromJson(json))
          .toList();

      print('✅ Loaded ${templates.length} templates');
      return templates;
    } catch (e) {
      print('❌ Error loading templates: $e');
      return [];
    }
  }

  // ✨ 2. LOAD USER SUBSCRIPTIONS (PRIVATE)
  Future<List<UserSubscription>> getUserSubscriptions() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        print('⚠️ No user logged in');
        return [];
      }

      print('📥 Loading subscriptions for user: $userId');

      final response = await Supabase.instance.client
          .from(_subscriptionsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final subscriptions = (response as List?)
          ?.map((json) => UserSubscription.fromJson(json))
          .toList() ??
          [];

      print('✅ Loaded ${subscriptions.length} user subscriptions');
      return subscriptions;
    } catch (e) {
      print('❌ Error loading subscriptions: $e');
      return [];
    }
  }

  // ✨ 3. ADD SUBSCRIPTION (FROM TEMPLATE)
  Future<bool> addSubscriptionFromTemplate(
      SubscriptionTemplate template,
      double cost,
      BillingCycle billingCycle,
      DateTime startDate,
      String? notes,
      ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final nextBillingDate = billingCycle.calculateNextBillingDate(startDate);

      final subscription = UserSubscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: template.name, // ✨ FROM TEMPLATE
        imageUrl: template.imageUrl, // ✨ FROM TEMPLATE
        cost: cost, // ✨ USER ENTERS
        billingCycle: billingCycle, // ✨ USER SELECTS
        startDate: startDate, // ✨ USER SELECTS
        nextBillingDate: nextBillingDate,
        notes: notes,
        isCustom: false, // ✨ NOT CUSTOM
        templateId: template.id, // ✨ LINK TO TEMPLATE
      );

      await Supabase.instance.client
          .from(_subscriptionsTable)
          .insert(subscription.toJson());

      print('✅ Added subscription from template');
      return true;
    } catch (e) {
      print('❌ Error adding subscription: $e');
      return false;
    }
  }

  // ✨ 4. ADD CUSTOM SUBSCRIPTION
  Future<bool> addCustomSubscription(
      String name,
      String imageUrl,
      double cost,
      BillingCycle billingCycle,
      DateTime startDate,
      String? notes,
      ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final nextBillingDate = billingCycle.calculateNextBillingDate(startDate);

      final subscription = UserSubscription(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        name: name, // ✨ USER ENTERS
        imageUrl: imageUrl, // ✨ USER UPLOADS
        cost: cost, // ✨ USER ENTERS
        billingCycle: billingCycle, // ✨ USER SELECTS
        startDate: startDate, // ✨ USER SELECTS
        nextBillingDate: nextBillingDate,
        notes: notes,
        isCustom: true, // ✨ CUSTOM
        templateId: null, // ✨ NO TEMPLATE
      );

      await Supabase.instance.client
          .from(_subscriptionsTable)
          .insert(subscription.toJson());

      print('✅ Added custom subscription');
      return true;
    } catch (e) {
      print('❌ Error adding custom subscription: $e');
      return false;
    }
  }

  // ✨ 5. UPDATE SUBSCRIPTION
  Future<bool> updateSubscription(UserSubscription subscription) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from(_subscriptionsTable)
          .update(subscription.toJson())
          .eq('id', subscription.id)
          .eq('user_id', userId);

      print('✅ Updated subscription');
      return true;
    } catch (e) {
      print('❌ Error updating subscription: $e');
      return false;
    }
  }

  // ✨ 6. DELETE SUBSCRIPTION
  Future<bool> deleteSubscription(String subscriptionId) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await Supabase.instance.client
          .from(_subscriptionsTable)
          .delete()
          .eq('id', subscriptionId)
          .eq('user_id', userId);

      print('✅ Deleted subscription');
      return true;
    } catch (e) {
      print('❌ Error deleting subscription: $e');
      return false;
    }
  }

  // ✨ 7. UPLOAD CUSTOM IMAGE
  Future<String?> uploadCustomImage(String imagePath) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final file = File(imagePath);
      final fileName =
          'custom/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await Supabase.instance.client.storage
          .from(_bucketName)
          .upload(fileName, file);

      final publicUrl = Supabase.instance.client.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      print('✅ Image uploaded: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('❌ Error uploading image: $e');
      return null;
    }
  }
}
