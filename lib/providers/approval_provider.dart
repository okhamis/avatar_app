import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/approval_token_model.dart';
import '../services/token_service.dart';
import '../services/biometric_service.dart';

final tokenServiceProvider = Provider((ref) => TokenService());
final biometricServiceProvider = Provider((ref) => BiometricService());

final pendingApprovalsProvider =
    NotifierProvider<ApprovalNotifier, List<AuthorizationToken>>(ApprovalNotifier.new);

class ApprovalNotifier extends Notifier<List<AuthorizationToken>> {
  late final TokenService _tokenService;
  late final BiometricService _biometricService;

  @override
  List<AuthorizationToken> build() {
    _tokenService = ref.watch(tokenServiceProvider);
    _biometricService = ref.watch(biometricServiceProvider);
    return [];
  }

  Future<void> mockIncomingRequest(String accountId, String sessionId, String credentialType) async {
    final token = await _tokenService.generateToken(accountId, sessionId, credentialType);
    state = [...state, token];
  }

  Future<bool> approveRequest(String tokenId, String reason) async {
    final authSuccess = await _biometricService.authenticate(reason);
    if (authSuccess) {
      state = state.map((t) => t.tokenId == tokenId ? AuthorizationToken(
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
      ) : t).toList();
      return true;
    }
    return false;
  }

  void denyRequest(String tokenId) {
    state = state.map((t) {
      if (t.tokenId != tokenId) {
        return t;
      }
      return AuthorizationToken(
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
    }).toList();
  }
}
