import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:go_router/go_router.dart';

import '../../api/providers.dart';
import '../../common/app_theme.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _loading = false;

  Future<void> _login() async {
    setState(() => _loading = true);
    try {
      final callback = await FlutterWebAuth2.authenticate(
        url: ref.read(authRepositoryProvider).authorizeUri().toString(),
        callbackUrlScheme: 'intangibletrack',
      );
      await ref
          .read(sessionProvider.notifier)
          .completeDeepLink(Uri.parse(callback));
      if (mounted) {
        context.goNamed('profile');
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('登录未完成：$error')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        children: [
          const SizedBox(height: 80),
          Image.asset('assets/山.png', width: 120, height: 120),
          const SizedBox(height: 20),
          const Text(
            '非遗方舟',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '传承千年文化，守护非遗记忆',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
          const SizedBox(height: 48),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '将跳转至山东大学统一认证平台完成身份验证；本应用不会收集或保存你的账号密码。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textHint,
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _loading ? null : _login,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('山东大学统一认证登录', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    ),
  );
}
