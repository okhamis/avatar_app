import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'route_names.dart';

import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/sign_in_screen.dart';
import '../screens/onboarding/create_account_screen.dart';
import '../screens/onboarding/face_upload_screen.dart';
import '../screens/onboarding/voice_record_screen.dart';
import '../screens/onboarding/behavioral_training_screen.dart';
import '../screens/onboarding/avatar_preview_screen.dart';
import '../screens/onboarding/go_live_screen.dart';

import '../screens/conversations/conversation_list_screen.dart';
import '../screens/conversations/live_conversation_screen.dart';
import '../screens/conversations/transcript_detail_screen.dart';

import '../screens/settings/avatar_setup_screen.dart';
import '../screens/debug/log_viewer_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/streaming_settings_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(authProvider);
  // Only watch authProvider for redirect logic. Avatar status is checked via
  // ref.read when needed (live-conversation gate) to avoid recreating the
  // GoRouter on every avatar state change during onboarding.

  return GoRouter(
    initialLocation: '/welcome',
    redirect: (context, state) {
      final path = state.uri.path;
      if (user == null) {
        if (path == '/home' || path.startsWith('/conversations') || path.startsWith('/settings')) {
          return '/welcome';
        }
        return null;
      }

      // Face upload & voice recording are skipped for now — D-ID agent has its
      // own presenter configured in Studio. These steps will be re-enabled when
      // the face-cloning + voice-cloning pipeline is wired up.
      // In Custom mode, require full onboarding (photo → voice → behavioral).
      // In Studio mode, skip straight to home (D-ID agent is pre-configured).
      // Test profile mode skips onboarding screens entirely.
      final avatarMode = ref.read(avatarModeProvider);
      final testProfileEnabled = ref.read(testProfileEnabledProvider);

      if (avatarMode == AvatarMode.custom && !user.isLive) {
        // If test profile is enabled, skip everything and go straight to live conversation
        if (testProfileEnabled) {
          // Allow settings, live conversation, and re-training screens
          if (path == '/conversations/live' || path.startsWith('/settings') || path == '/face-upload' || path == '/voice-record' || path == '/behavioral-training') return null;
          return '/conversations/live';
        }

        // Enforce Custom mode onboarding flow
        if (!user.hasFaceTrained) return path == '/face-upload' ? null : '/face-upload';
        if (!user.hasVoiceCloned) return path == '/voice-record' ? null : '/voice-record';
        if (!user.hasBehaviorTrained) return path == '/behavioral-training' ? null : '/behavioral-training';
        // After all training is complete, show avatar preview
        if (path == '/avatar-preview' || path == '/go-live') return null;
        return '/avatar-preview';
      }
      if (!user.isLive) {
        if (path == '/go-live' || path == '/avatar-preview') return null;
        return '/avatar-preview';
      }

      // Redirect to live conversation for authenticated users
      if (path == '/home' || path == '/welcome' || path == '/sign-in' || path == '/create-account') {
        return '/conversations/live';
      }

      // Only redirect away from first-time-only onboarding pages.
      // /face-upload, /voice-record, /behavioral-training stay accessible
      // so users can re-do them from Settings.
      const firstTimeOnlyPaths = {
        '/avatar-preview',
        '/go-live',
      };
      if (firstTimeOnlyPaths.contains(path)) {
        return '/conversations/live';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        name: RouteNames.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/sign-in',
        name: RouteNames.signIn,
        builder: (context, state) => const SignInScreen(),
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
      // Full-screen live conversation — main experience
      GoRoute(
        path: '/conversations/live',
        name: RouteNames.liveConversation,
        builder: (context, state) => const LiveConversationScreen(),
      ),
      // Chat history — accessible from Settings
      GoRoute(
        path: '/conversations',
        name: RouteNames.conversations,
        builder: (context, state) => const ConversationListScreen(),
        routes: [
          GoRoute(
            path: 'transcript/:id',
            name: RouteNames.transcriptDetail,
            builder: (context, state) => TranscriptDetailScreen(id: state.pathParameters['id']!),
          ),
        ],
      ),
      // Settings
      GoRoute(
        path: '/settings',
        name: RouteNames.settings,
        builder: (context, state) => const AvatarSetupScreen(),
      ),
      // Debug log viewer
      GoRoute(
        path: '/debug/logs',
        name: RouteNames.logViewer,
        builder: (context, state) => const LogViewerScreen(),
      ),
    ],
  );
});
