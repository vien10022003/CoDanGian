import 'package:co_dan_gian/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FolkGameRegistry extensibility', () {
    test('registers Cờ Chém, Cờ Gánh, and Cờ Ba Tướng', () {
      final registry = FolkGameRegistry();
      final ids = registry.allGames.map((g) => g.id).toList();

      expect(ids, ['co_chem', 'co_ganh', 'co_ba_tuong']);
      expect(registry.findById('co_chem')?.isPlayable, isTrue);
      expect(registry.findById('co_ganh')?.isPlayable, isFalse);
      expect(registry.findById('co_ba_tuong')?.isPlayable, isFalse);
    });

    test('creates functional engine for playable games and guards unimplemented ones', () {
      final registry = FolkGameRegistry();
      final engine = registry.createEngine('co_chem');

      expect(engine.getGameState().gameTypeId, CoChemRules.typeId);
      expect(() => registry.createEngine('co_ganh'), throwsStateError);
      expect(() => registry.createEngine('unknown_game'), throwsArgumentError);
    });
  });
}

