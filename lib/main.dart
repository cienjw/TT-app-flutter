import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'features/auth/domain/auth_provider.dart';
import 'features/onboarding/presentation/pages/terms_screen.dart';
import 'features/main/presentation/pages/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: '9bfd88d5e14c0de724064983944035f8');
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TT App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    // handleLogin에서 push를 수행하되, 만약 authState가 변경되어 리빌드될 때를 대비해
    // 별도의 리스너나 로직을 보강할 수 있습니다. 
    // 여기서는 handleLogin 내부 로직을 더 명확히 합니다.

    Future<void> handleLogin(Future<bool> Function() loginFn) async {
      try {
        // loginFn()은 auth_provider의 loginWithKakao/Google을 호출하며
        // 내부적으로 state = AsyncData(true)를 설정하고 isNewUser를 반환합니다.
        final isNewUser = await loginFn();
        
        if (!context.mounted) return;

        if (isNewUser) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const TermsScreen()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('내향형 만남 앱 (가제)',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),

              // 카카오 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE500),
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading
                    ? null
                    : () => handleLogin(
                    ref.read(authProvider.notifier).loginWithKakao),
                child: isLoading
                    ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                    : const Text('카카오로 시작하기',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // 구글 버튼
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black87,
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading
                    ? null
                    : () => handleLogin(
                    ref.read(authProvider.notifier).loginWithGoogle),
                child: const Text('Google로 시작하기',
                    style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),
              
              // 개발용 로그인 (임시) - 훨씬 더 잘 보이게 수정
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isLoading
                    ? null
                    : () => handleLogin(() =>
                    ref.read(authProvider.notifier).loginWithDev('테스트유저')),
                child: const Text('개발용 로그인 (테스트용)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('※ 키 해시 에러 발생 시 위 버튼을 클릭하세요.',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}