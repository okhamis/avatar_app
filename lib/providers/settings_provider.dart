import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/policy_record_model.dart';
import '../models/credential_model.dart';
import '../providers/auth_provider.dart';
import '../core/providers/service_providers.dart';

final policiesProvider =
    NotifierProvider<PoliciesNotifier, List<PolicyRecord>>(PoliciesNotifier.new);

class PoliciesNotifier extends Notifier<List<PolicyRecord>> {
  @override
  List<PolicyRecord> build() {
    final user = ref.watch(authProvider);
    if (user != null) _load(user.uid);
    return [];
  }

  Future<void> _load(String accountId) async {
    try {
      final policies = await ref.read(firebaseServiceProvider).getPolicies(accountId);
      state = policies;
    } catch (e) {
      debugPrint('Failed to load policies: $e');
    }
  }

  Future<void> addPolicy(PolicyRecord policy) async {
    state = [...state, policy];
    try {
      await ref.read(firebaseServiceProvider).savePolicy(policy.accountId, policy);
    } catch (e) {
      debugPrint('Failed to persist policy: $e');
    }
  }

  Future<void> updatePolicyTier(String recordId, int newTier) async {
    state = state.map((p) => p.recordId == recordId ? p.copyWith(userOverrideTier: newTier) : p).toList();
    final updated = state.firstWhere((p) => p.recordId == recordId);
    try {
      await ref.read(firebaseServiceProvider).savePolicy(updated.accountId, updated);
    } catch (e) {
      debugPrint('Failed to persist policy tier update: $e');
    }
  }
}

final credentialsVaultProvider =
    NotifierProvider<CredentialsNotifier, List<CredentialModel>>(CredentialsNotifier.new);

class CredentialsNotifier extends Notifier<List<CredentialModel>> {
  @override
  List<CredentialModel> build() {
    final user = ref.watch(authProvider);
    if (user != null) _load(user.uid);
    return [];
  }

  Future<void> _load(String accountId) async {
    try {
      final creds = await ref.read(firebaseServiceProvider).getCredentials(accountId);
      state = creds;
    } catch (e) {
      debugPrint('Failed to load credentials: $e');
    }
  }

  Future<void> addCredential(CredentialModel credential) async {
    state = [...state, credential];
    try {
      await ref.read(firebaseServiceProvider).saveCredential(credential.accountId, credential);
    } catch (e) {
      debugPrint('Failed to persist credential: $e');
    }
  }

  Future<void> removeCredential(String credentialId) async {
    final cred = state.firstWhere((c) => c.credentialId == credentialId);
    state = state.where((c) => c.credentialId != credentialId).toList();
    try {
      await ref.read(firebaseServiceProvider).deleteCredential(cred.accountId, credentialId);
    } catch (e) {
      debugPrint('Failed to delete credential: $e');
    }
  }
}
