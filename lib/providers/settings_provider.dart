import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/policy_record_model.dart';
import '../models/credential_model.dart';

final policiesProvider = StateNotifierProvider<PoliciesNotifier, List<PolicyRecord>>((ref) {
  return PoliciesNotifier();
});

class PoliciesNotifier extends StateNotifier<List<PolicyRecord>> {
  PoliciesNotifier() : super([]);

  void addPolicy(PolicyRecord policy) {
    state = [...state, policy];
  }
}

final credentialsVaultProvider = StateNotifierProvider<CredentialsNotifier, List<CredentialModel>>((ref) {
  return CredentialsNotifier();
});

class CredentialsNotifier extends StateNotifier<List<CredentialModel>> {
  CredentialsNotifier() : super([]);

  void addCredential(CredentialModel credential) {
    state = [...state, credential];
  }
}
