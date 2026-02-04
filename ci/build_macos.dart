import 'dart:io';

void main(List<String> args) async {
  try {
    print('🚀 Starting MacOS Release Build script...');

    // Check flutter availability
    print('Checking flutter version...');
    final checkResult = await Process.run('fvm', ['flutter', '--version']);
    if (checkResult.exitCode != 0) {
      print('Warning: fvm flutter command failed check.');
      print(checkResult.stderr);
    } else {
      print(checkResult.stdout);
    }

    print('Building release (this may take a while)...');

    // Using Process.start safely with stdout/stderr pipe to stream output if needed,
    // but for this debug step, let's just use run to ensure we capture it at the end if it fails
    // OR start and listen to stream to print progress.
    // Let's use Process.start and pipe to stdout manually to ensure run_command captures it.

    final buildProcess = await Process.start(
      'fvm',
      ['flutter', 'build', 'macos', '--release'],
    );

    // Pipe output to our stdout
    await stdout.addStream(buildProcess.stdout);
    await stderr.addStream(buildProcess.stderr);

    final buildExitCode = await buildProcess.exitCode;

    if (buildExitCode != 0) {
      print('❌ Build failed with exit code $buildExitCode');
      exit(buildExitCode);
    }

    print('✅ Build successful.');

    final source = 'build/macos/Build/Products/Release/OpenTerm.app';
    final destination = '/Applications/OpenTerm.app';

    if (!await Directory(source).exists()) {
      print('❌ Error: Build artifact not found at $source');
      exit(1);
    }

    print('📦 Installing to $destination...');

    // Remove existing
    if (await Directory(destination).exists()) {
      print('  Removing existing application...');
      final deleteResult = await Process.run('rm', ['-rf', destination]);
      if (deleteResult.exitCode != 0) {
        print('  ❌ Failed to remove existing app: ${deleteResult.stderr}');
        print('  Try running this script with sudo.');
        exit(1);
      }
    }

    // Copy
    final copyResult = await Process.run('cp', ['-R', source, destination]);

    if (copyResult.exitCode != 0) {
      print('  ❌ Failed to copy app: ${copyResult.stderr}');
      print('  Try running this script with sudo.');
      exit(1);
    }

    print('🎉 Successfully installed TerminalStudio.app to /Applications');
  } catch (e, stack) {
    print('❌ Uncaught error: $e');
    print(stack);
    exit(1);
  }
}
