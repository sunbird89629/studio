import 'package:flex_tabs/flex_tabs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_term/src/shared/models/records/ssh_host_record.dart';
import 'package:open_term/src/features/ssh/infrastructure/ssh_storage_repository.dart';
import 'package:open_term/src/features/settings/application/database_providers.dart';
import 'package:open_term/src/shared/widgets/fluent_back_button.dart';
import 'package:open_term/src/shared/widgets/fluent_form.dart';
import 'package:open_term/src/shared/utils/validators.dart';

class HostEditPage extends ConsumerStatefulWidget {
  const HostEditPage({super.key, this.record});

  final SSHHostRecord? record;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HostEditDialogState();
}

class _HostEditDialogState extends ConsumerState<HostEditPage> {
  bool get isEditing => widget.record != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Host' : 'Add Host'),
        leading:
            Navigator.of(context).canPop() ? const FluentBackButton() : null,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                if (widget.record != null) {
                  final hosts =
                      await ref.read(sshHostsProvider.future);
                  await ref
                      .read(sshStorageServiceProvider)
                      .deleteHost(widget.record!.uuid, List.from(hosts));
                  ref.invalidate(sshHostsProvider);
                }
                close();
              },
              tooltip: 'Delete',
            ),
        ],
      ),
      body: SSHHostEditForm(
        record: widget.record,
        onSaved: _onSaved,
      ),
    );
  }

  Future<void> _onSaved(SSHHostRecord record) async {
    final service = ref.read(sshStorageServiceProvider);
    final hosts = List<SSHHostRecord>.from(
      await ref.read(sshHostsProvider.future),
    );

    final existingIdx = hosts.indexWhere((h) => h.uuid == record.uuid);
    if (existingIdx >= 0) {
      await service.updateHost(record, hosts);
    } else {
      await service.addHost(record, hosts);
    }

    ref.invalidate(sshHostsProvider);
    close();
  }

  void close() {
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        return Navigator.of(context).pop();
      }

      if (TabScope.of(context) != null) {
        return TabScope.of(context)!.dispose();
      }
    }
  }
}

class SSHHostEditForm extends ConsumerStatefulWidget {
  const SSHHostEditForm({super.key, this.record, this.onSaved});

  final SSHHostRecord? record;

  final void Function(SSHHostRecord record)? onSaved;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HostEditFormState();
}

class _HostEditFormState extends ConsumerState<SSHHostEditForm> {
  final formKey = GlobalKey<FormState>();

  late final record = widget.record ?? SSHHostRecord.uninitialized();

  @override
  Widget build(BuildContext context) {
    Widget widget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FluentFormHeader('Protocol'),
              DropdownButtonFormField<String>(
                initialValue: 'ssh',
                items: const [
                  DropdownMenuItem(
                    value: 'ssh',
                    child: Text('SSH'),
                  ),
                ],
                onChanged: (value) {},
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const FluentFormDivider(),
              TextFormField(
                initialValue: record.name,
                decoration: const InputDecoration(
                  labelText: 'Label',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) => record.name = value!,
              ),
            ],
          ),
        ),
        const FluentFormSeparator(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: record.host,
                  decoration: const InputDecoration(
                    labelText: 'Host',
                    hintText: 'example.com / 1.2.3.4',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Host is required';
                    }
                    return isHostOrIP(value) ? null : 'Invalid host or IP';
                  },
                  onSaved: (value) => record.host = value!,
                ),
                const FluentFormDivider(),
                TextFormField(
                  initialValue: record.port.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Port',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Port is required';
                    }
                    return isPort(value) ? null : 'Invalid port';
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  onSaved: (value) => record.port = int.parse(value!),
                ),
                const FluentFormDivider(),
                TextFormField(
                  initialValue: record.username,
                  decoration: const InputDecoration(
                    labelText: 'User',
                    hintText: 'root',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => record.username = value,
                ),
                const FluentFormDivider(),
                TextFormField(
                  initialValue: record.password,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (value) => record.password = value,
                ),
              ],
            ),
          ),
        ),
        const FluentFormSeparator(),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                FilledButton(
                  onPressed: _submitForm,
                  child: const Text('Save'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  child: const Text('Test Connection'),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );

    widget = Form(
      key: formKey,
      child: widget,
    );

    widget = Container(
      alignment: Alignment.center,
      child: SizedBox(
        width: 500,
        child: widget,
      ),
    );

    widget = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: widget,
    );

    return widget;
  }

  void _submitForm() {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      widget.onSaved?.call(record);
    }
  }
}
