import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/avatar_provider.dart';
import 'theme/app_theme.dart';

class PresntApp extends ConsumerStatefulWidget {
  const PresntApp({super.key});

  @override
  ConsumerState<PresntApp> createState() => _PresntAppState();
}

class _PresntAppState extends ConsumerState<PresntApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      try {
        await ref.read(authProvider.notifier).restoreSessionUser();
        final user = ref.read(authProvider);
        if (user != null) {
          await ref.read(avatarProvider.notifier).loadAvatar(user.uid);
        }
      } catch (_) {
        // Fail closed in startup bootstrap for tests/non-configured environments.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Presnt',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
