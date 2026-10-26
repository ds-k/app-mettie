import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../widgets/glass_card.dart';

class ProfileAppSettings extends ConsumerWidget {
  const ProfileAppSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '앱 정보 및 설정',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: kCharcoal,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(LucideIcons.info, color: kSlate),
                title: const Text('버전 정보', style: TextStyle(color: kInk)),
                trailing: const Text(
                  '1.0.0',
                  style: TextStyle(color: kSlate, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1, color: kHairline),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: kSlate),
                title: const Text('이용약관', style: TextStyle(color: kInk)),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: kSlate,
                  size: 20,
                ),
                onTap: () async {
                  final baseUrl =
                      dotenv.env['WEB_BASE_URL'] ?? 'https://mettieapp.com';
                  final url = Uri.parse('$baseUrl/terms');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.inAppWebView);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('웹 브라우저를 열 수 없습니다.')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, color: kHairline),
              ListTile(
                leading: const Icon(LucideIcons.shieldAlert, color: kSlate),
                title: const Text('개인정보처리방침', style: TextStyle(color: kInk)),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: kSlate,
                  size: 20,
                ),
                onTap: () async {
                  final baseUrl =
                      dotenv.env['WEB_BASE_URL'] ?? 'https://mettieapp.com';
                  final url = Uri.parse('$baseUrl/privacy');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.inAppWebView);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('웹 브라우저를 열 수 없습니다.')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, color: kHairline),
              ListTile(
                leading: const Icon(LucideIcons.code, color: kSlate),
                title: const Text('오픈소스 라이선스', style: TextStyle(color: kInk)),
                trailing: const Icon(
                  LucideIcons.chevronRight,
                  color: kSlate,
                  size: 20,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Theme(
                        data: Theme.of(context).copyWith(
                          scaffoldBackgroundColor: Colors.white,
                          appBarTheme: const AppBarTheme(
                            backgroundColor: Colors.white,
                            foregroundColor: kInk,
                            elevation: 0,
                          ),
                        ),
                        child: const LicensePage(
                          applicationName: 'Mettie',
                          applicationVersion: '1.0.0',
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 1, color: kHairline),
              ListTile(
                leading: const Icon(LucideIcons.userX, color: kBrandError),
                title: const Text(
                  '회원 탈퇴',
                  style: TextStyle(
                    color: kBrandError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('회원 탈퇴'),
                      content: const Text(
                        '정말로 Mettie 앱을 탈퇴하시겠습니까?\n기록된 모든 반려동물 데이터와 개인정보가 즉시 삭제되며 복구할 수 없습니다.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            '취소',
                            style: TextStyle(color: kSlate),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            try {
                              await ref
                                  .read(authRepositoryProvider)
                                  .deleteAccount();
                              if (context.mounted) {
                                context.go('/login');
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: kBrandError,
                                ),
                              );
                            }
                          },
                          child: const Text(
                            '탈퇴하기',
                            style: TextStyle(
                              color: kBrandError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
