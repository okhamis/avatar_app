import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/policy_record_model.dart';
import '../models/credential_model.dart';

final policiesProvider = NotifierProvider<PoliciesNotifier, List<PolicyRecord>>(PoliciesNotifier.new);

class PoliciesNotifier extends Notifier<List<PolicyRecord>> {
  @override
  List<PolicyRecord> build() => [];

  void addPolicy(PolicyRecord policy) {
    state = [...state, policy];
  }

  void updatePolicyTier(String recordId, int newTier) {
    state = state.map((p) => p.recordId == recordId ? p.copyWith(userOverrideTier: newTier) : p).toList();
  }
}

final credentialsVaultProvider =
    NotifierProvider<CredentialsNotifier, List<CredentialModel>>(CredentialsNotifier.new);

class CredentialsNotifier extends Notifier<List<CredentialModel>> {
  @override
  List<CredentialModel> build() => [];

  void addCredential(CredentialModel credential) {
    state = [...state, credential];
  }

  void removeCredential(String credentialId) {
    state = state.where((c) => c.credentialId != credentialId).toList();
  }
}
