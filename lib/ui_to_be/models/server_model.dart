class ServerModel {
  final String id;
  final String name;
  final String region;
  final String nodeId;
  final String publicIp;
  final bool isAvailable;

  const ServerModel({
    required this.id,
    required this.name,
    required this.region,
    required this.nodeId,
    required this.publicIp,
    this.isAvailable = true,
  });

  factory ServerModel.fromVpnNodeJson(Map<String, dynamic> json) {
    final hostname = (json['hostname'] as String? ?? '').trim();
    final region = (json['region'] as String? ?? '').trim();

    return ServerModel(
      id: (json['id'] as String? ?? '').trim(),
      name: hostname.isNotEmpty ? hostname : region,
      region: region,
      nodeId: hostname.isNotEmpty ? hostname.toUpperCase() : 'VPN-NODE',
      publicIp: (json['public_ip'] as String? ?? '').trim(),
      isAvailable: json['is_online'] as bool? ?? true,
    );
  }

  factory ServerModel.malaysia() => const ServerModel(
    id: 'my-kl-01',
    name: 'Malaysia',
    region: 'Kuala Lumpur',
    nodeId: 'KL-NODE-01',
    publicIp: '187.77.157.240',
  );
}
