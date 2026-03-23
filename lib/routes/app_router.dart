import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'route_names.dart';

import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/create_account_screen.dart';
import '../screens/onboarding/face_upload_screen.dart';
import '../screens/onboarding/voice_record_screen.dart';
import '../screens/onboarding/behavioral_training_screen.dart';
import '../screens/onboarding/avatar_preview_screen.dart';
import '../screens/onboarding/go_live_screen.dart';

import '../screens/home/home_screen.dart';
import '../screens/conversations/conversation_list_screen.dart';
import '../screens/conversations/live_conversation_screen.dart';
import '../screens/conversations/transcript_detail_screen.dart';

import '../screens/approvals/pending_approvals_screen.dart';
import '../screens/approvals/approval_history_screen.dart';

import '../screens/family/family_members_screen.dart';
import '../screens/family/access_tiers_screen.dart';
import '../screens/family/posthumous_settings_screen.dart';

import '../screens/settings/avatar_setup_screen.dart';
import '../screens/settings/action_policies_screen.dart';
import '../screens/settings/credentials_vault_screen.dart';
import '../screens/settings/integrations_screen.dart';

import '../theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/create-account',
        name: RouteNames.createAccount,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: '/face-upload',
        name: RouteNames.faceUpload,
        builder: (context, state) => const FaceUploadScreen(),
      ),
      GoRoute(
        path: '/voice-record',
        name: RouteNames.voiceRecord,
        builder: (context, state) => const VoiceRecordScreen(),
      ),
      GoRoute(
        path: '/behavioral-training',
        name: RouteNames.behavioralTraining,
        builder: (context, state) => const BehavioralTrainingScreen(),
      ),
      GoRoute(
        path: '/avatar-preview',
        name: RouteNames.avatarPreview,
        builder: (context, state) => const AvatarPreviewScreen(),
      ),
      GoRoute(
        path: '/go-live',
        name: RouteNames.goLive,
        builder: (context, state) => const GoLiveScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Scaffold(
            body: navigationShell,
            bottomNavigationBar: BottomNavigationBar(
              backgroundColor: AppColors.background,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textSecondary,
              currentIndex: navigationShell.currentIndex,
              type: BottomNavigationBarType.fixed,
              onTap: (index) => navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              ),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
                BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Approvals'),
                BottomNavigationBarItem(icon: Icon(Icons.family_restroom), label: 'Family'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conversations',
                name: RouteNames.conversations,
                builder: (context, state) => const ConversationListScreen(),
                routes: [
                  GoRoute(
                    path: 'live',
                    name: RouteNames.liveConversation,
                    builder: (context, state) => const LiveConversationScreen(),
                  ),
                  GoRoute(
                    path: 'transcript/:id',
                    name: RouteNames.transcriptDetail,
                    builder: (context, state) => TranscriptDetailScreen(id: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/approvals',
                name: RouteNames.approvals,
                builder: (context, state) => const PendingApprovalsScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    name: RouteNames.approvalHistory,
                    builder: (context, state) => const ApprovalHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/family',
                name: RouteNames.family,
                builder: (context, state) => const FamilyMembersScreen(),
                routes: [
                  GoRoute(
                    path: 'tiers',
                    name: RouteNames.accessTiers,
                    builder: (context, state) => const AccessTiersScreen(),
                  ),
                  GoRoute(
                    path: 'posthumous',
                    name: RouteNames.posthumousSettings,
                    builder: (context, state) => const PosthumousSettingsScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: RouteNames.settings,
                builder: (context, state) => const AvatarSetupScreen(),
                routes: [
                  GoRoute(
                    path: 'policies',
                    name: RouteNames.actionPolicies,
                    builder: (context, state) => const ActionPoliciesScreen(),
                  ),
                  GoRoute(
                    path: 'vault',
                    name: RouteNames.credentialsVault,
                    builder: (context, state) => const CredentialsVaultScreen(),
                  ),
                  GoRoute(
                    path: 'integrations',
                    name: RouteNames.integrations,
                    builder: (context, state) => const IntegrationsScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
