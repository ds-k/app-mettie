import 'package:flutter/material.dart';
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
        const SnackBar(
          content: Text('이용약관 및 개인정보처리방침에 동의해주세요.'),
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
                  const Icon(LucideIcons.mailCheck, color: kBrandBlue, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    '이메일 인증 안내',
                    style: kHeading3.copyWith(color: kInk),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '회원가입 링크가 전송되었습니다.',
                    style: kBodyLg.copyWith(fontWeight: FontWeight.bold, color: kInk),
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: kBodyMd.copyWith(color: kCharcoal),
                      children: [
                        TextSpan(
                          text: email,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: kBrandBlueDeep),
                        ),
                        const TextSpan(
                          text: ' 이메일로 가입 승인을 위한 링크를 발송했습니다.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '수신된 이메일의 링크를 클릭하시면 회원가입이 완료됩니다. (스팸 메일함도 함께 확인해주세요.)',
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
                  child: const Text('확인'),
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
        final errorMsg = next.error.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $errorMsg'),
            backgroundColor: kBrandError,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: kInk),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _isSignUpMode ? '이메일 회원가입' : '이메일 로그인',
          style: kHeading3.copyWith(color: kInk, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 배경 그라데이션
          Container(
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
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                              decoration: const InputDecoration(
                                hintText: '이름을 입력하세요',
                                labelText: '이름',
                                prefixIcon: Icon(LucideIcons.user, color: kSlate, size: 20),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return '이름을 입력해주세요.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'example@email.com',
                              labelText: '이메일',
                              prefixIcon: Icon(LucideIcons.mail, color: kSlate, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '이메일을 입력해주세요.';
                              }
                              final emailRegExp = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegExp.hasMatch(value.trim())) {
                                return '올바른 이메일 형식이 아닙니다.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              hintText: '비밀번호를 입력하세요 (6자 이상)',
                              labelText: '비밀번호',
                              prefixIcon: Icon(LucideIcons.lock, color: kSlate, size: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '비밀번호를 입력해주세요.';
                              }
                              if (value.trim().length < 6) {
                                return '비밀번호는 최소 6자 이상이어야 합니다.';
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
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'Mettie의 ',
                                        style: kCaption.copyWith(color: kCharcoal),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final baseUrl = dotenv.env['WEB_BASE_URL'] ?? 'https://mettieapp.com';
                                          final url = Uri.parse('$baseUrl/terms');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.inAppWebView);
                                          }
                                        },
                                        child: Text(
                                          '서비스 이용약관',
                                          style: kCaption.copyWith(
                                            color: kBrandBlue,
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ' 및 ',
                                        style: kCaption.copyWith(color: kCharcoal),
                                      ),
                                      GestureDetector(
                                        onTap: () async {
                                          final baseUrl = dotenv.env['WEB_BASE_URL'] ?? 'https://mettieapp.com';
                                          final url = Uri.parse('$baseUrl/privacy');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.inAppWebView);
                                          }
                                        },
                                        child: Text(
                                          '개인정보처리방침',
                                          style: kCaption.copyWith(
                                            color: kBrandBlue,
                                            decoration: TextDecoration.underline,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '에 동의합니다.',
                                        style: kCaption.copyWith(color: kCharcoal),
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
                            child: Text(_isSignUpMode ? '이메일로 회원가입' : '이메일로 로그인'),
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
                              _isSignUpMode ? '이미 계정이 있으신가요? 로그인' : '계정이 없으신가요? 회원가입',
                              style: kButtonMd.copyWith(color: kBrandBlueDeep),
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
    );
  }
}
