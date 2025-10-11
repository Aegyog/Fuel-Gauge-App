// The data model for a single maintenance log entry.
class MaintenanceLog {
  final int? id; // Supabase ID
  final String userId; // Foreign key to the user
  final String vehicleId;
  final String serviceType;
  final String date;
  final double mileage;
  final double? cost;
  final String? notes;
  final double? nextReminderMileage;
  final String? nextReminderDate;

  MaintenanceLog({
    this.id,
    required this.userId,
    required this.vehicleId,
    required this.serviceType,
    required this.date,
    required this.mileage,
    this.cost,
    this.notes,
    this.nextReminderMileage,
    this.nextReminderDate,
  });

  // Converts a MaintenanceLog object into a Map for Supabase.
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vehicle_id': vehicleId,
        'service_type': serviceType,
        'date': date,
        'mileage': mileage,
        'cost': cost,
        'notes': notes,
        'next_reminder_mileage': nextReminderMileage,
        'next_reminder_date': nextReminderDate,
      };

  // Creates a MaintenanceLog object from a Map received from Supabase.
  factory MaintenanceLog.fromJson(Map<String, dynamic> json) => MaintenanceLog(
        id: json['id'],
        userId: json['user_id'],
        vehicleId: json['vehicle_id'],
        serviceType: json['service_type'],
        date: json['date'],
        mileage: json['mileage'],
        cost: json['cost'],
        notes: json['notes'],
        nextReminderMileage: json['next_reminder_mileage'],
        nextReminderDate: json['next_reminder_date'],
      );
}
