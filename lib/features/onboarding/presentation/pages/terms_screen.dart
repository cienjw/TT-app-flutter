import 'package:flutter/material.dart';
import 'package:tt_app/features/onboarding/presentation/pages/profile_setup_screen.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool allAgreed = false;
  bool termsAgreed = false;
  bool privacyAgreed = false;
  bool marketingAgreed = false;

  void _updateAll(bool? value) {
    setState(() {
      allAgreed = value ?? false;
      termsAgreed = allAgreed;
      privacyAgreed = allAgreed;
      marketingAgreed = allAgreed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('약관 동의')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '약관에 동의해주세요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            CheckboxListTile(
              title: const Text('전체 동의'),
              value: allAgreed,
              onChanged: _updateAll,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Divider(),
            CheckboxListTile(
              title: const Text('(필수) 이용약관'),
              value: termsAgreed,
              onChanged: (v) => setState(() => termsAgreed = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('(필수) 개인정보 처리방침'),
              value: privacyAgreed,
              onChanged: (v) => setState(() => privacyAgreed = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              title: const Text('(선택) 마케팅 정보 수신 동의'),
              value: marketingAgreed,
              onChanged: (v) => setState(() => marketingAgreed = v!),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (termsAgreed && privacyAgreed)
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                child: const Text('다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
