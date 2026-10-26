import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/l10n.dart';
import '../../../../l10n/labels.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../widgets/glass_card.dart';

class ProfileAppSettings extends ConsumerWidget {
  const ProfileAppSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.settingsAppInfo,
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
                title: Text(context.l10n.settingsVersion, style: const TextStyle(color: kInk)),
                trailing: const Text(
                  '1.0.0',
                  style: TextStyle(color: kSlate, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1, color: kHairline),
              ListTile(
                leading: const Icon(LucideIcons.fileText, color: kSlate),
                title: Text(context.l10n.settingsTerms, style: const TextStyle(color: kInk)),
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
                        SnackBar(content: Text(context.l10n.settingsCannotOpenBrowser)),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, color: kHairline),
              ListTile(
                leading: const Icon(LucideIcons.shieldAlert, color: kSlate),
                title: Text(context.l10n.settingsPrivacy, style: const TextStyle(color: kInk)),
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
                        SnackBar(content: Text(context.l10n.settingsCannotOpenBrowser)),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, color: kHairline),
              ListTile(
                leading: const Icon(LucideIcons.code, color: kSlate),
                title: Text(context.l10n.settingsLicenses, style: const TextStyle(color: kInk)),
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
                title: Text(
                  context.l10n.settingsDeleteAccount,
                  style: TextStyle(
                    color: kBrandError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.l10n.settingsDeleteAccount),
                      content: Text(
                        context.l10n.settingsDeleteAccountBody,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            context.l10n.commonCancel,
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
                                  content: Text(errorMessage(context.l10n, e)),
                                  backgroundColor: kBrandError,
                                ),
                              );
                            }
                          },
                          child: Text(
                            context.l10n.settingsDeleteAccountConfirm,
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
