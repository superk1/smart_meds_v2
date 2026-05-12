class NotificationPreferences {
  final bool expirationAlertsEnabled;
  final bool stockAlertsEnabled;

  const NotificationPreferences({
    this.expirationAlertsEnabled = true,
    this.stockAlertsEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'expirationAlertsEnabled': expirationAlertsEnabled,
      'stockAlertsEnabled': stockAlertsEnabled,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      expirationAlertsEnabled: json['expirationAlertsEnabled'] as bool? ?? true,
      stockAlertsEnabled: json['stockAlertsEnabled'] as bool? ?? true,
    );
  }
}
