import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:terminal_studio/src/core/record/profile_record.dart';
import 'package:terminal_studio/src/core/state/database.dart';
import 'package:terminal_studio/src/core/state/settings.dart';

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
                                _editProfile(context, ref, profile),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () async {
                              final box =
                                  await ref.read(profileBoxProvider.future);
                              final copy = profile.duplicate();
                              await box.add(copy);
                            },
                            tooltip: 'Duplicate',
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteProfile(context, ref, profile),
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

  Future<void> _createProfile(BuildContext context, WidgetRef ref) async {
    final name = await _showNameDialog(context, 'New Profile', '');
    if (name == null || name.isEmpty) return;

    final box = await ref.read(profileBoxProvider.future);
    final profile = ProfileRecord(name: name);
    await box.add(profile);
  }

  Future<void> _deleteProfile(
    BuildContext context,
    WidgetRef ref,
    ProfileRecord profile,
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

    await profile.delete();
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    ProfileRecord profile,
  ) async {
    await showDialog(
      context: context,
      builder: (ctx) => _ProfileEditDialog(profile: profile),
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
  const _ProfileEditDialog({required this.profile});
  final ProfileRecord profile;

  @override
  State<_ProfileEditDialog> createState() => _ProfileEditDialogState();
}

class _ProfileEditDialogState extends State<_ProfileEditDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _shellCtrl;
  late final TextEditingController _fontFamilyCtrl;
  late final TextEditingController _wdCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.name);
    _shellCtrl = TextEditingController(text: widget.profile.shell ?? '');
    _fontFamilyCtrl =
        TextEditingController(text: widget.profile.fontFamily ?? '');
    _wdCtrl =
        TextEditingController(text: widget.profile.workingDirectory ?? '');
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
    final p = widget.profile;

    return AlertDialog(
      title: Text('Edit: ${p.name}'),
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
                initialValue: p.themeId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Theme (empty = inherit)',
                  hintText: 'dark',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => p.themeId = v.isEmpty ? null : v,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: p.fontSize?.toString() ?? '',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Font Size (empty = inherit)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() => p.fontSize = double.tryParse(v));
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
                initialValue: p.backgroundOpacity?.toString() ?? '',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Background Opacity (empty = inherit)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  setState(() => p.backgroundOpacity = double.tryParse(v));
                },
              ),
              const SizedBox(height: 24),
              Text('Cursor', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                initialValue: p.cursorShape,
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
                onChanged: (v) => setState(() => p.cursorShape = v),
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
          onPressed: () {
            p.name = _nameCtrl.text;
            p.shell = _shellCtrl.text.isEmpty ? null : _shellCtrl.text;
            p.fontFamily =
                _fontFamilyCtrl.text.isEmpty ? null : _fontFamilyCtrl.text;
            p.workingDirectory = _wdCtrl.text.isEmpty ? null : _wdCtrl.text;
            p.save();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
