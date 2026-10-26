import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../l10n/labels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../view_models/login_view_model.dart';

class EmailLoginView extends ConsumerStatefulWidget {
  const EmailLoginView({super.key});

  @override
  ConsumerState<EmailLoginView> createState() => _EmailLoginViewState();
}

class _EmailLoginViewState extends ConsumerState<EmailLoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUpMode = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_isSignUpMode && !_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.emailAgreeRequired),
          backgroundColor: kBrandError,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    final model = ref.read(loginViewModelProvider.notifier);

    bool success;
    if (_isSignUpMode) {
      success = await model.signUp(
        email,
        password,
        fullName: name.isNotEmpty ? name : null,
      );
      if (success && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: kCanvas,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(kRadiusLg),
                side: const BorderSide(color: kHairline),
              ),
              title: Row(
                children: [
                  const Icon(
                    LucideIcons.mailCheck,
                    color: kBrandBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(context.l10n.emailVerifyTitle, style: kHeading3.copyWith(color: kInk)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.emailLinkSent,
                    style: kBodyLg.copyWith(
                      fontWeight: FontWeight.bold,
                      color: kInk,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      // 언어마다 이메일 위치가 달라서, 자리 표시자로 문장을 나눠 이메일만 굵게 표시한다
                      final parts = context.l10n.emailSentTo('\u0000').split('\u0000');
                      return RichText(
                        text: TextSpan(
                          style: kBodyMd.copyWith(color: kCharcoal),
                          children: [
                            TextSpan(text: parts.first),
                            TextSpan(
                              text: email,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: kBrandBlueDeep,
                              ),
                            ),
                            TextSpan(text: parts.last),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.l10n.emailCheckInbox,
                    style: kBodyMd.copyWith(color: kSlate),
                  ),
                ],
              ),
              actions: [
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: kBrandBlue,
                    foregroundColor: kOnDark,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _isSignUpMode = false;
                    });
                  },
                  child: Text(context.l10n.commonConfirm),
                ),
              ],
            );
          },
        );
      }
    } else {
      success = await model.signIn(email, password);
      if (success && mounted) {
        // 로그인 성공 시 router가 감지하고 자동으로 /home으로 리다이렉트하나,
        // 혹시 모를 로컬 화면 정리를 대비할 수 있음.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);
    final isLoading = loginState.isLoading;

    ref.listen<AsyncValue<void>>(loginViewModelProvider, (previous, next) {
      if (next is AsyncError) {
        final errorMsg = errorMessage(context.l10n, next.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: kBrandError,
          ),
        );
      }
    });

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kHeroSkyFrom, kCanvas],
            stops: [0.0, 0.4],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft, color: kInk),
              onPressed: () => context.pop(),
            ),
            title: Text(
              _isSignUpMode ? context.l10n.emailSignUpTitle : context.l10n.emailSignInTitle,
              style: kHeading3.copyWith(
                color: kInk,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          extendBodyBehindAppBar: true,
          body: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      // Mettie 브랜드 타이틀 재확인
                      Text(
                        'Mettie',
                        textAlign: TextAlign.center,
                        style: kDisplay.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: kInk,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // 이메일 양식 카드
                      Container(
                        decoration: BoxDecoration(
                          color: kCanvas,
                          borderRadius: BorderRadius.circular(kRadiusLg),
                          border: Border.all(color: kHairline),
                        ),
                        padding: const EdgeInsets.all(20.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_isSignUpMode) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    hintText: context.l10n.emailNameHint,
                                    labelText: context.l10n.emailName,
                                    prefixIcon: Icon(
                                      LucideIcons.user,
                                      color: kSlate,
                                      size: 20,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return context.l10n.emailNameRequired;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  hintText: 'example@email.com',
                                  labelText: context.l10n.emailEmail,
                                  prefixIcon: Icon(
                                    LucideIcons.mail,
                                    color: kSlate,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return context.l10n.emailEmailRequired;
                                  }
                                  final emailRegExp = RegExp(
                                    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                                  );
                                  if (!emailRegExp.hasMatch(value.trim())) {
                                    return context.l10n.emailEmailInvalid;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: context.l10n.emailPasswordHint,
                                  labelText: context.l10n.emailPassword,
                                  prefixIcon: Icon(
                                    LucideIcons.lock,
                                    color: kSlate,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return context.l10n.emailPasswordRequired;
                                  }
                                  if (value.trim().length < 6) {
                                    return context.l10n.emailPasswordTooShort;
                                  }
                                  return null;
                                },
                              ),
                              if (_isSignUpMode) ...[
                                const SizedBox(height: 16),
                                // 개인정보처리방침 & 서비스 이용약관 동의 UI
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: Checkbox(
                                        value: _agreeToTerms,
                                        activeColor: kBrandBlue,
                                        onChanged: (value) {
                                          setState(() {
                                            _agreeToTerms = value ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text(
                                            _agreeParts(context)[0],
                                            style: kCaption.copyWith(
                                              color: kCharcoal,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              final baseUrl =
                                                  dotenv.env['WEB_BASE_URL'] ??
                                                  'https://mettieapp.com';
                                              final url = Uri.parse(
                                                '$baseUrl/terms',
                                              );
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(
                                                  url,
                                                  mode: LaunchMode.inAppWebView,
                                                );
                                              }
                                            },
                                            child: Text(
                                              context.l10n.settingsTerms,
                                              style: kCaption.copyWith(
                                                color: kBrandBlue,
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _agreeParts(context)[1],
                                            style: kCaption.copyWith(
                                              color: kCharcoal,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () async {
                                              final baseUrl =
                                                  dotenv.env['WEB_BASE_URL'] ??
                                                  'https://mettieapp.com';
                                              final url = Uri.parse(
                                                '$baseUrl/privacy',
                                              );
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(
                                                  url,
                                                  mode: LaunchMode.inAppWebView,
                                                );
                                              }
                                            },
                                            child: Text(
                                              context.l10n.settingsPrivacy,
                                              style: kCaption.copyWith(
                                                color: kBrandBlue,
                                                decoration:
                                                    TextDecoration.underline,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            _agreeParts(context)[2],
                                            style: kCaption.copyWith(
                                              color: kCharcoal,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 24),
                              // 로그인 / 가입 버튼 (Black-pill)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                  backgroundColor: kInk,
                                  foregroundColor: kOnDark,
                                  shape: const StadiumBorder(),
                                ),
                                child: Text(
                                  _isSignUpMode ? context.l10n.emailSignUpButton : context.l10n.emailSignInButton,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // 로그인 모드 스위치 버튼
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isSignUpMode = !_isSignUpMode;
                                    _agreeToTerms = false;
                                    _formKey.currentState?.reset();
                                  });
                                },
                                child: Text(
                                  _isSignUpMode
                                      ? context.l10n.emailHaveAccount
                                      : context.l10n.emailNoAccount,
                                  style: kButtonMd.copyWith(
                                    color: kBrandBlueDeep,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 로딩 오버레이
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(kBrandBlue),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 약관 동의 문장을 [앞, 가운데, 뒤]로 나눈다. 두 링크는 앞·가운데 뒤에 각각 붙는다.
  List<String> _agreeParts(BuildContext context) {
    final sentence = context.l10n.termsAgreement('\u0001', '\u0002');
    final first = sentence.split('\u0001');
    final second = first.last.split('\u0002');
    return [first.first, second.first, second.last];
  }
}
