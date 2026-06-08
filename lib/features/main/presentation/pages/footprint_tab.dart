import 'package:flutter/material.dart';
import 'place_detail_screen.dart';

class FootprintTab extends StatelessWidget {
  const FootprintTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('발자취'),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(child: Text('지도 영역')),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('최근 방문 장소', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: 3,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.redAccent),
                  title: Text('장소 이름 ${index + 1}'),
                  subtitle: const Text('시흥 정왕동'),
                  trailing: const Text('오후 2:30'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlaceDetailScreen(name: '장소 이름 ${index + 1}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
