import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_member_model.dart';
import '../models/posthumous_consent_model.dart';
import '../providers/auth_provider.dart';
import '../core/providers/service_providers.dart';

final familyMembersProvider =
    NotifierProvider<FamilyNotifier, List<FamilyMember>>(FamilyNotifier.new);

class FamilyNotifier extends Notifier<List<FamilyMember>> {
  @override
  List<FamilyMember> build() {
    final user = ref.watch(authProvider);
    if (user != null) _load(user.uid);
    return [];
  }

  Future<void> _load(String accountId) async {
    try {
      final members = await ref.read(firebaseServiceProvider).getFamilyMembers(accountId);
      state = members;
    } catch (e) {
      debugPrint('Failed to load family members: $e');
    }
  }

  Future<void> addMember(FamilyMember member) async {
    state = [...state, member];
    try {
      await ref.read(firebaseServiceProvider).saveFamilyMember(member.accountId, member);
    } catch (e) {
      debugPrint('Failed to persist family member: $e');
    }
  }
}

final posthumousSettingsProvider =
    NotifierProvider<PosthumousNotifier, PosthumousConsentRecord?>(PosthumousNotifier.new);

class PosthumousNotifier extends Notifier<PosthumousConsentRecord?> {
  @override
  PosthumousConsentRecord? build() => null;

  void updateSettings(PosthumousConsentRecord record) {
    state = record;
  }
}
