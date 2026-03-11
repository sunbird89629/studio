import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/shared/models/records/profile_record.dart';
import 'package:terminal_studio/src/features/settings/infrastructure/config_file_repository.dart';
import 'package:terminal_studio/src/features/settings/application/database_providers.dart';
import 'package:terminal_studio/src/features/settings/application/settings_providers.dart';

/// Settings panel for managing profiles (create/edit/delete/duplicate).
class ProfilesSettingsView extends ConsumerWidget {
  const ProfilesSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final activeId = ref.watch(activeProfileIdProvider);

    return profilesAsync.when(
      data: (profiles) => Scaffold(
        appBar: AppBar(
          title: const Text('Profiles'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _createProfile(context, ref),
              tooltip: 'New Profile',
            ),
          ],
        ),
        body: profiles.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.person, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'No profiles yet',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Profiles let you save different configurations\n'
                      'for work, personal, or SSH sessions.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      child: const Text('Create first profile'),
                      onPressed: () => _createProfile(context, ref),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final isActive = profile.id == activeId;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      selected: isActive,
                      leading: Icon(
                        isActive
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(profile.name),
                      subtitle: Text(_profileSummary(profile)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon:
                                Icon(isActive ? Icons.pause : Icons.play_arrow),
                            onPressed: () {
                              ref.read(activeProfileIdProvider.notifier).state =
                                  isActive ? null : profile.id;
                            },
                            tooltip: isActive ? 'Deactivate' : 'Activate',
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _editProfile(context, ref, profile, profiles),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () =>
                                _duplicateProfile(ref, profile, profiles),
                            tooltip: 'Duplicate',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteProfile(context, ref, profile, profiles),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                      onTap: () {
                        ref.read(activeProfileIdProvider.notifier).state =
                            isActive ? null : profile.id;
                      },
                    ),
                  );
                },
              ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  String _profileSummary(ProfileRecord p) {
    final parts = <String>[];
    if (p.shell != null) parts.add('Shell: ${p.shell}');
    if (p.themeId != null) parts.add('Theme: ${p.themeId}');
    if (p.fontSize != null) parts.add('Font: ${p.fontSize}pt');
    if (p.fontFamily != null) parts.add(p.fontFamily!);
    if (parts.isEmpty) parts.add('Inherits all global settings');
    return parts.join(' · ');
  }

  Future<void> _saveProfiles(WidgetRef ref, List<ProfileRecord> profiles) async {
    final settings = await ref.read(settingsProvider.future);
    await ref.read(configFileServiceProvider).saveToFile(
          settings,
          profiles: profiles,
        );
    ref.invalidate(profilesProvider);
  }

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(context, 'New Profile', '');
    if (name == null || name.isEmpty) return;

    final profiles = List<ProfileRecord>.from(
      await ref.read(profilesProvider.future),
    );
    profiles.add(ProfileRecord(name: name));
    await _saveProfiles(ref, profiles);
  }

  Future<void> _duplicateProfile(
    WidgetRef ref,
    ProfileRecord profile,
    List<ProfileRecord> profiles,
  ) async {
    final updated = List<ProfileRecord>.from(profiles);
    updated.add(profile.duplicate());
    await _saveProfiles(ref, updated);
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    ProfileRecord profile,
    List<ProfileRecord> profiles,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text('Delete "${profile.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          FilledButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    // Deactivate if this was the active profile
    final activeId = ref.read(activeProfileIdProvider);
    if (activeId == profile.id) {
      ref.read(activeProfileIdProvider.notifier).state = null;
    }

    final updated = profiles.where((p) => p.id != profile.id).toList();
    await _saveProfiles(ref, updated);
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    ProfileRecord profile,
    List<ProfileRecord> profiles,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ProfileEditDialog(
        profile: profile,
        onSaved: (updated) async {
          final list = profiles.map((p) => p.id == updated.id ? updated : p).toList();
          await _saveProfiles(ref, list);
        },
      ),
    );
  }

  Future<String?> _showNameDialog(
    BuildContext context,
    String title,
    String initialValue,
  ) async {
    final controller = TextEditingController(text: initialValue);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Profile name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(null),
          ),
          FilledButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(ctx).pop(controller.text),
          ),
        ],
      ),
    );
  }
}

/// Dialog for editing a profile's overridable fields.
class _ProfileEditDialog extends StatefulWidget {
  const _ProfileEditDialog({required this.profile, required this.onSaved});
  final ProfileRecord profile;
  final Future<void> Function(ProfileRecord updated) onSaved;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _shellCtrl;
  late final TextEditingController _fontFamilyCtrl;
  late final TextEditingController _wdCtrl;

  // Local mutable copy to avoid mutating the original before saving
  late ProfileRecord _edited;

  @override
  void initState() {
    super.initState();
    _edited = widget.profile.duplicate(newName: widget.profile.name);
    _edited = ProfileRecord(
      id: widget.profile.id,
      name: widget.profile.name,
      shell: widget.profile.shell,
      shellArgs: widget.profile.shellArgs,
      themeId: widget.profile.themeId,
      fontSize: widget.profile.fontSize,
      fontFamily: widget.profile.fontFamily,
      env: widget.profile.env,
      workingDirectory: widget.profile.workingDirectory,
      cursorShape: widget.profile.cursorShape,
      cursorBlink: widget.profile.cursorBlink,
      lineHeight: widget.profile.lineHeight,
      letterSpacing: widget.profile.letterSpacing,
      backgroundOpacity: widget.profile.backgroundOpacity,
      padding: widget.profile.padding,
    );
    _nameCtrl = TextEditingController(text: _edited.name);
    _shellCtrl = TextEditingController(text: _edited.shell ?? '');
    _fontFamilyCtrl = TextEditingController(text: _edited.fontFamily ?? '');
    _wdCtrl = TextEditingController(text: _edited.workingDirectory ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _shellCtrl.dispose();
    _fontFamilyCtrl.dispose();
    _wdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit: ${widget.profile.name}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              Text('Appearance', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                initialValue: _edited.themeId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Theme (empty = inherit)',
                  hintText: 'dark',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) =>
                    setState(() => _edited.themeId = v.isEmpty ? null : v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _edited.fontSize?.toString() ?? '',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Font Size (empty = inherit)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() => _edited.fontSize = double.tryParse(v));
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fontFamilyCtrl,
                decoration: const InputDecoration(
                  labelText: 'Font Family (empty = inherit)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _edited.backgroundOpacity?.toString() ?? '',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Background Opacity (empty = inherit)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() => _edited.backgroundOpacity = double.tryParse(v));
                },
              ),
              const SizedBox(height: 24),
              Text('Cursor', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: _edited.cursorShape,
                decoration: const InputDecoration(
                  labelText: 'Cursor Shape',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem<String?>(
                      value: null, child: Text('Inherit')),
                  DropdownMenuItem(value: 'block', child: Text('Block')),
                  DropdownMenuItem(value: 'beam', child: Text('Beam')),
                  DropdownMenuItem(
                      value: 'underline', child: Text('Underline')),
                ],
                onChanged: (v) => setState(() => _edited.cursorShape = v),
              ),
              const SizedBox(height: 24),
              Text('Shell', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _shellCtrl,
                decoration: const InputDecoration(
                  labelText: 'Shell Path (empty = inherit)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _wdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Working Directory (empty = inherit)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        FilledButton(
          child: const Text('Save'),
          onPressed: () async {
            _edited.name = _nameCtrl.text;
            _edited.shell = _shellCtrl.text.isEmpty ? null : _shellCtrl.text;
            _edited.fontFamily =
                _fontFamilyCtrl.text.isEmpty ? null : _fontFamilyCtrl.text;
            _edited.workingDirectory =
                _wdCtrl.text.isEmpty ? null : _wdCtrl.text;
            Navigator.of(context).pop();
            await widget.onSaved(_edited);
          },
        ),
      ],
    );
  }
}
