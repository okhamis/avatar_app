import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/family_member_model.dart';
import '../models/posthumous_consent_model.dart';

final familyMembersProvider = NotifierProvider<FamilyNotifier, List<FamilyMember>>(FamilyNotifier.new);

class FamilyNotifier extends Notifier<List<FamilyMember>> {
  @override
  List<FamilyMember> build() => [];

  void addMember(FamilyMember member) {
    state = [...state, member];
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
