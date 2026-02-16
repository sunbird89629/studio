import 'package:fluent_ui/fluent_ui.dart';
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
      data: (profiles) => ScaffoldPage(
        header: PageHeader(
          title: const Text('Profiles'),
          commandBar: CommandBar(
            mainAxisAlignment: MainAxisAlignment.end,
            primaryItems: [
              CommandBarButton(
                icon: const Icon(FluentIcons.add),
                label: const Text('New Profile'),
                onPressed: () => _createProfile(context, ref),
              ),
            ],
          ),
        ),
        content: profiles.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FluentIcons.contact, size: 48),
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
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: profiles.length,
                itemBuilder: (context, index) {
                  final profile = profiles[index];
                  final isActive = profile.id == activeId;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile.selectable(
                      selected: isActive,
                      leading: Icon(
                        isActive
                            ? FluentIcons.radio_btn_on
                            : FluentIcons.radio_btn_off,
                      ),
                      title: Text(profile.name),
                      subtitle: Text(_profileSummary(profile)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isActive)
                            Tooltip(
                              message: 'Activate',
                              child: IconButton(
                                icon: const Icon(FluentIcons.play, size: 16),
                                onPressed: () {
                                  ref
                                      .read(activeProfileIdProvider.notifier)
                                      .state = profile.id;
                                },
                              ),
                            ),
                          if (isActive)
                            Tooltip(
                              message: 'Deactivate',
                              child: IconButton(
                                icon: const Icon(FluentIcons.pause, size: 16),
                                onPressed: () {
                                  ref
                                      .read(activeProfileIdProvider.notifier)
                                      .state = null;
                                },
                              ),
                            ),
                          Tooltip(
                            message: 'Edit',
                            child: IconButton(
                              icon: const Icon(FluentIcons.edit, size: 16),
                              onPressed: () =>
                                  _editProfile(context, ref, profile),
                            ),
                          ),
                          Tooltip(
                            message: 'Duplicate',
                            child: IconButton(
                              icon: const Icon(FluentIcons.copy, size: 16),
                              onPressed: () async {
                                final box =
                                    await ref.read(profileBoxProvider.future);
                                final copy = profile.duplicate();
                                await box.add(copy);
                              },
                            ),
                          ),
                          Tooltip(
                            message: 'Delete',
                            child: IconButton(
                              icon: const Icon(FluentIcons.delete, size: 16),
                              onPressed: () =>
                                  _deleteProfile(context, ref, profile),
                            ),
                          ),
                        ],
                      ),
                      onPressed: () {
                        ref.read(activeProfileIdProvider.notifier).state =
                            isActive ? null : profile.id;
                      },
                    ),
                  );
                },
              ),
      ),
      loading: () => const Center(child: ProgressRing()),
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
      builder: (ctx) => ContentDialog(
        title: const Text('Delete Profile'),
        content: Text('Delete "${profile.name}"? This cannot be undone.'),
        actions: [
          Button(
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
      builder: (ctx) => ContentDialog(
        title: Text(title),
        content: TextBox(
          controller: controller,
          placeholder: 'Profile name',
          autofocus: true,
        ),
        actions: [
          Button(
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

    return ContentDialog(
      title: Text('Edit: ${p.name}'),
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoLabel(
              label: 'Name',
              child: TextBox(controller: _nameCtrl),
            ),
            const SizedBox(height: 16),

            // ── Appearance ──
            const Text('Appearance',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Theme (empty = inherit)',
              child: TextFormBox(
                initialValue: p.themeId ?? '',
                placeholder: 'dark',
                onChanged: (v) => p.themeId = v.isEmpty ? null : v,
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Font Size (0 = inherit)',
              child: NumberBox<double>(
                value: p.fontSize,
                onChanged: (v) => setState(() => p.fontSize = v),
                smallChange: 1,
                placeholder: 'inherit',
              ),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Font Family (empty = inherit)',
              child: TextBox(controller: _fontFamilyCtrl),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Background Opacity (empty = inherit)',
              child: NumberBox<double>(
                value: p.backgroundOpacity,
                onChanged: (v) => setState(() => p.backgroundOpacity = v),
                smallChange: 0.1,
                placeholder: 'inherit',
              ),
            ),
            const SizedBox(height: 16),

            // ── Cursor ──
            const Text('Cursor', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Cursor Shape',
              child: ComboBox<String?>(
                value: p.cursorShape,
                items: [
                  const ComboBoxItem<String?>(
                    value: null,
                    child: Text('Inherit'),
                  ),
                  const ComboBoxItem(value: 'block', child: Text('Block')),
                  const ComboBoxItem(value: 'beam', child: Text('Beam')),
                  const ComboBoxItem(
                      value: 'underline', child: Text('Underline')),
                ],
                onChanged: (v) => setState(() => p.cursorShape = v),
              ),
            ),
            const SizedBox(height: 16),

            // ── Shell ──
            const Text('Shell', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Shell Path (empty = inherit)',
              child: TextBox(controller: _shellCtrl),
            ),
            const SizedBox(height: 8),
            InfoLabel(
              label: 'Working Directory (empty = inherit)',
              child: TextBox(controller: _wdCtrl),
            ),
          ],
        ),
      ),
      actions: [
        Button(
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
