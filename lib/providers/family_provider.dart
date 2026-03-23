import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_member_model.dart';
import '../models/posthumous_consent_model.dart';

final familyMembersProvider = StateNotifierProvider<FamilyNotifier, List<FamilyMember>>((ref) {
  return FamilyNotifier();
});

class FamilyNotifier extends StateNotifier<List<FamilyMember>> {
  FamilyNotifier() : super([]);

  void addMember(FamilyMember member) {
    state = [...state, member];
  }
}

final posthumousSettingsProvider = StateNotifierProvider<PosthumousNotifier, PosthumousConsentRecord?>((ref) {
  return PosthumousNotifier();
});

class PosthumousNotifier extends StateNotifier<PosthumousConsentRecord?> {
  PosthumousNotifier() : super(null);

  void updateSettings(PosthumousConsentRecord record) {
    state = record;
  }
}
