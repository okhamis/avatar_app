import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/approval_token_model.dart';
import '../services/token_service.dart';
import '../services/biometric_service.dart';
import '../providers/auth_provider.dart';
import '../core/providers/service_providers.dart';

final tokenServiceProvider = Provider((ref) => TokenService());
final biometricServiceProvider = Provider((ref) => BiometricService());

final pendingApprovalsProvider =
    NotifierProvider<ApprovalNotifier, List<AuthorizationToken>>(ApprovalNotifier.new);

class ApprovalNotifier extends Notifier<List<AuthorizationToken>> {
  TokenService get _tokenService => ref.read(tokenServiceProvider);
  BiometricService get _biometricService => ref.read(biometricServiceProvider);

  @override
  List<AuthorizationToken> build() {
    final user = ref.watch(authProvider);
    if (user != null) _load(user.uid);
    return [];
  }

  Future<void> _load(String accountId) async {
    try {
      final tokens = await ref.read(firebaseServiceProvider).getApprovals(accountId);
      state = tokens;
    } catch (e) {
      debugPrint('Failed to load approvals: $e');
    }
  }

  Future<void> mockIncomingRequest(String accountId, String sessionId, String credentialType) async {
    final token = await _tokenService.generateToken(accountId, sessionId, credentialType);
    state = [...state, token];
    try {
      await ref.read(firebaseServiceProvider).saveApproval(accountId, token);
    } catch (e) {
      debugPrint('Failed to persist approval token: $e');
    }
  }

  Future<bool> approveRequest(String tokenId, String reason) async {
    final authSuccess = await _biometricService.authenticate(reason);
    if (authSuccess) {
      state = state.map((t) {
        if (t.tokenId != tokenId) return t;
        return AuthorizationToken(
          tokenId: t.tokenId,
          accountId: t.accountId,
          sessionId: t.sessionId,
          credentialType: t.credentialType,
          issuedAt: t.issuedAt,
          expiresAt: t.expiresAt,
          timeoutSeconds: t.timeoutSeconds,
          used: true,
          invalidated: t.invalidated,
          biometricRef: t.biometricRef,
        );
      }).toList();
      final updated = state.firstWhere((t) => t.tokenId == tokenId);
      try {
        await ref.read(firebaseServiceProvider).saveApproval(updated.accountId, updated);
      } catch (e) {
        debugPrint('Failed to persist approval update: $e');
      }
      return true;
    }
    return false;
  }

  Future<void> denyRequest(String tokenId) async {
    AuthorizationToken? denied;
    state = state.map((t) {
      if (t.tokenId != tokenId) return t;
      denied = AuthorizationToken(
        tokenId: t.tokenId,
        accountId: t.accountId,
        sessionId: t.sessionId,
        credentialType: t.credentialType,
        issuedAt: t.issuedAt,
        expiresAt: t.expiresAt,
        timeoutSeconds: t.timeoutSeconds,
        used: false,
        invalidated: true,
        biometricRef: t.biometricRef,
      );
      return denied!;
    }).toList();
    if (denied != null) {
      try {
        await ref.read(firebaseServiceProvider).saveApproval(denied!.accountId, denied!);
      } catch (e) {
        debugPrint('Failed to persist denial: $e');
      }
    }
  }
}
