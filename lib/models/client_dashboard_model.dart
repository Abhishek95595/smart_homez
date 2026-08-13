class ClientDashboardModel {
  const ClientDashboardModel({
    required this.clientId,
    required this.homeId,
    required this.period,
    required this.from,
    required this.to,
    required this.timeZone,
    required this.currentPowerSource,
    required this.liveWatts,
    required this.labels,
    required this.dataPoints,
    required this.gridData,
    required this.backupData,
    required this.switchoverMinutesData,
    required this.totalKwh,
    required this.gridKwh,
    required this.backupKwh,
    required this.switchoverMinutes,
    required this.gridCost,
    required this.backupCost,
    required this.totalCost,
    required this.yesterdayKwh,
  });

  final String clientId;
  final String homeId;
  final String period;
  final DateTime? from;
  final DateTime? to;
  final String timeZone;
  final String currentPowerSource;
  final double liveWatts;
  final List<String> labels;
  final List<double> dataPoints;
  final List<double> gridData;
  final List<double> backupData;
  final List<double> switchoverMinutesData;
  final double totalKwh;
  final double gridKwh;
  final double backupKwh;
  final double switchoverMinutes;
  final double gridCost;
  final double backupCost;
  final double totalCost;
  final double yesterdayKwh;

  factory ClientDashboardModel.fromJson(Map<String, dynamic> json) {
    List<double> doubles(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((value) => (value as num?)?.toDouble() ?? 0)
            .toList(growable: false);

    return ClientDashboardModel(
      clientId: json['client_id']?.toString() ?? '',
      homeId: json['home_id']?.toString() ?? '',
      period: json['period']?.toString() ?? 'daily',
      from: DateTime.tryParse(json['from']?.toString() ?? ''),
      to: DateTime.tryParse(json['to']?.toString() ?? ''),
      timeZone: json['time_zone']?.toString() ?? '',
      currentPowerSource: json['current_power_source']?.toString() ?? 'Unknown',
      liveWatts: (json['live_watts'] as num?)?.toDouble() ?? 0,
      labels: (json['labels'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      dataPoints: doubles('data_points'),
      gridData: doubles('grid_data'),
      backupData: doubles('backup_data'),
      switchoverMinutesData: doubles('switchover_minutes_data'),
      totalKwh: (json['total_kwh'] as num?)?.toDouble() ?? 0,
      gridKwh: (json['grid_kwh'] as num?)?.toDouble() ?? 0,
      backupKwh: (json['backup_kwh'] as num?)?.toDouble() ?? 0,
      switchoverMinutes: (json['switchover_minutes'] as num?)?.toDouble() ?? 0,
      gridCost: (json['grid_cost'] as num?)?.toDouble() ?? 0,
      backupCost: (json['backup_cost'] as num?)?.toDouble() ?? 0,
      totalCost: (json['total_cost'] as num?)?.toDouble() ?? 0,
      yesterdayKwh:
          ((json['yesterday'] as Map<String, dynamic>?)?['kwh'] as num?)
              ?.toDouble() ??
          0,
    );
  }
}
