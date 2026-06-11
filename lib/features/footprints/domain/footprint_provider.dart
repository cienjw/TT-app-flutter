import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/footprint_repository.dart';

final footprintRepoProvider = Provider((_) => FootprintRepository());

final footprintsProvider = FutureProvider<List<Footprint>>((ref) async {
  return ref.read(footprintRepoProvider).getFootprints();
});