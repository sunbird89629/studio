import 'package:terminal_studio/src/util/uuid.dart';

class SSHKeyRecord {
  String uuid;

  String name;

  String? comment;

  String? passphrase;

  String? privateKey;

  String? publicKey;

  SSHKeyRecord({
    String? uuid,
    required this.name,
    this.comment,
    this.passphrase,
    this.privateKey,
    this.publicKey,
  }) : uuid = uuid ?? uuidV4();

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'name': name,
        if (comment != null) 'comment': comment,
        if (passphrase != null) 'passphrase': passphrase,
        if (privateKey != null) 'private_key': privateKey,
        if (publicKey != null) 'public_key': publicKey,
      };

  factory SSHKeyRecord.fromJson(Map<String, dynamic> json) {
    return SSHKeyRecord(
      uuid: json['uuid'] as String?,
      name: json['name'] as String? ?? '',
      comment: json['comment'] as String?,
      passphrase: json['passphrase'] as String?,
      privateKey: json['private_key'] as String?,
      publicKey: json['public_key'] as String?,
    );
  }
}
