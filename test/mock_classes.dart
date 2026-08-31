import 'package:mocktail/mocktail.dart';
import 'package:my_voice/data/models/frase.dart';
import 'package:my_voice/data/sources/audio_storage.dart';
import 'package:my_voice/data/sources/database.dart';
import 'package:my_voice/logic/interfaces/IFraseRepository.dart';
import 'package:my_voice/logic/interfaces/tts_service_interface.dart';
import 'package:my_voice/logic/services/audio_player_manager.dart';
import 'package:my_voice/core/utils.dart';
import 'package:sqflite_common/sqlite_api.dart';

class MockAppDatabase extends Mock implements AppDatabase {}
class MockAudioStorage extends Mock implements AudioStorage {}
class MockIFraseRepository extends Mock implements IFraseRepository {}
class MockTtsServiceInterface extends Mock implements TtsServiceInterface {}
class MockAudioPlayerManager extends Mock implements AudioPlayerManager {}
class MockUtils extends Mock implements Utils {}
class MockDatabase extends Mock implements Database {}

class FakeFrase extends Fake implements Frase {}

void registerTestFallbacks() {
  registerFallbackValue(FakeFrase());
}
