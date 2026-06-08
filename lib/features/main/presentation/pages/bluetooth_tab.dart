import 'package:flutter/material.dart';

class BluetoothTab extends StatefulWidget {
  const BluetoothTab({super.key});

  @override
  State<BluetoothTab> createState() => _BluetoothTabState();
}

class _BluetoothTabState extends State<BluetoothTab> {
  bool isScanning = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('블루투스')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('블루투스 연결 상태', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Switch(
                  value: isScanning,
                  onChanged: (v) => setState(() => isScanning = v),
                ),
                Text(isScanning ? 'ON' : 'OFF', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 50),
            if (isScanning) ...[
              const Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  Icon(Icons.location_searching, size: 80, color: Colors.deepPurple),
                ],
              ),
              const SizedBox(height: 30),
              const Text('주변 탐색 중...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('주변에 성향이 맞는 사람이 있는지 찾는 중', style: TextStyle(color: Colors.grey)),
            ] else ...[
              const Icon(Icons.bluetooth_disabled, size: 100, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('탐색이 중지되었습니다.'),
            ],
          ],
        ),
      ),
    );
  }
}
