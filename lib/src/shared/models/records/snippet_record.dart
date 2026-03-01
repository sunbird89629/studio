/// A saved command snippet that can be run from the Command Palette.
class SnippetRecord {
  final String id;
  final String name;
  final String command;

  const SnippetRecord({
    required this.id,
    required this.name,
    required this.command,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'command': command,
      };

  factory SnippetRecord.fromJson(String id, Map<String, dynamic> json) =>
      SnippetRecord(
        id: id,
        name: json['name'] as String? ?? id,
        command: json['command'] as String? ?? '',
      );
}
