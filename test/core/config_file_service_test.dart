import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_studio/src/shared/models/records/settings_record.dart';
import 'package:terminal_studio/src/features/settings/infrastructure/config_file_repository.dart';

void main() {
  group('stripJsoncComments', () {
    test('removes single-line comments', () {
      const input = '''
{
  "key": "value", // this is a comment
  "num": 42
}
''';
      final result = ConfigFileService.stripJsoncComments(input);
      expect(result, contains('"key": "value"'));
      expect(result, isNot(contains('this is a comment')));
    });

    test('removes multi-line comments', () {
      const input = '''
{
  /* multi-line
     comment */
  "key": "value"
}
''';
      final result = ConfigFileService.stripJsoncComments(input);
      expect(result, contains('"key": "value"'));
      expect(result, isNot(contains('multi-line')));
    });

    test('preserves // inside strings', () {
      const input = '''
{
  "url": "https://example.com", // real comment
  "path": "C:\\\\Users"
}
''';
      final result = ConfigFileService.stripJsoncComments(input);
      expect(result, contains('"https://example.com"'));
      expect(result, isNot(contains('real comment')));
    });

    test('handles escaped quotes in strings', () {
      const input = r'''
{
  "msg": "say \"hello\"", // comment
  "ok": true
}
''';
      final result = ConfigFileService.stripJsoncComments(input);
      expect(result, contains(r'"say \"hello\""'));
      expect(result, isNot(contains('comment')));
    });
  });

  group('parseJsonc', () {
    test('parses valid JSONC with comments', () {
      const input = '''
{
  // Terminal configuration
  "terminal": {
    "font_size": 16.0,
    "font_family": "Fira Code" /* inline comment */
  }
}
''';
      final map = ConfigFileService.parseJsonc(input);
      expect(map['terminal']['font_size'], 16.0);
      expect(map['terminal']['font_family'], 'Fira Code');
    });

    test('handles trailing commas', () {
      const input = '''
{
  "a": 1,
  "b": 2,
}
''';
      final map = ConfigFileService.parseJsonc(input);
      expect(map['a'], 1);
      expect(map['b'], 2);
    });

    test('parses nested objects', () {
      const input = '''
{
  "terminal": {
    "cursor": {
      "shape": "beam",
      "blink": false,
    },
  },
}
''';
      final map = ConfigFileService.parseJsonc(input);
      expect(map['terminal']['cursor']['shape'], 'beam');
      expect(map['terminal']['cursor']['blink'], false);
    });
  });

  group('settingsToJsonc', () {
    test('generates valid JSONC from default settings', () {
      final settings = SettingsRecord();
      final jsonc = ConfigFileService.settingsToJsonc(settings);

      // Should be parseable as JSONC
      final map = ConfigFileService.parseJsonc(jsonc);
      expect(map['terminal']['font_size'], 14.0);
      expect(map['terminal']['font_family'], 'Hack Nerd Font Mono');
      expect(map['terminal']['scrollback'], 10000);
      expect(map['terminal']['cursor']['shape'], 'block');
      expect(map['appearance']['theme'], 'dark');
      expect(map['shell']['preserve_cwd'], true);
      expect(map['ai']['provider'], 'openrouter');
    });

    test('round-trips through parse → generate → parse', () {
      final original = SettingsRecord(
        terminalFontSize: 18.0,
        terminalFontFamily: 'JetBrains Mono',
        cursorShape: 'beam',
        cursorBlink: false,
        scrollback: 5000,
        lineHeight: 1.5,
        letterSpacing: 1.0,
        backgroundOpacity: 0.9,
        padding: 8.0,
        copyOnSelect: true,
        preserveCWD: false,
        themeId: 'one-dark',
        aiProvider: 'openai',
        aiModel: 'gpt-4',
      );

      final jsonc = ConfigFileService.settingsToJsonc(original);
      final map = ConfigFileService.parseJsonc(jsonc);

      expect(map['terminal']['font_size'], 18.0);
      expect(map['terminal']['font_family'], 'JetBrains Mono');
      expect(map['terminal']['cursor']['shape'], 'beam');
      expect(map['terminal']['cursor']['blink'], false);
      expect(map['terminal']['scrollback'], 5000);
      expect(map['appearance']['theme'], 'one-dark');
      expect(map['appearance']['background_opacity'], 0.9);
      expect(map['shell']['copy_on_select'], true);
      expect(map['shell']['preserve_cwd'], false);
      expect(map['ai']['provider'], 'openai');
      expect(map['ai']['model'], 'gpt-4');
    });

    test('includes optional fields when set', () {
      final settings = SettingsRecord(
        shell: '/bin/bash',
        shellArgs: ['--login', '-i'],
        workingDirectory: '/tmp',
        cursorColor: '#FF0000',
        backgroundColor: '#1E1E2E',
        aiApiKey: 'sk-test',
        env: {'LANG': 'en_US.UTF-8'},
      );
      final jsonc = ConfigFileService.settingsToJsonc(settings);
      final map = ConfigFileService.parseJsonc(jsonc);

      expect(map['shell']['path'], '/bin/bash');
      expect(map['shell']['args'], ['--login', '-i']);
      expect(map['shell']['working_directory'], '/tmp');
      expect(map['terminal']['cursor']['color'], '#FF0000');
      expect(map['appearance']['background_color'], '#1E1E2E');
      expect(map['ai']['api_key'], 'sk-test');
      expect(map['shell']['env']['LANG'], 'en_US.UTF-8');
    });
  });
}
