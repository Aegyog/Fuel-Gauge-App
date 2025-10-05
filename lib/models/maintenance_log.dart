import 'package:uuid/uuid.dart';

// Represents a single maintenance record for a vehicle.
// Includes service details, cost, mileage, and optional reminders.
class MaintenanceLog {
  final String id;
  final String vehicleId;
  final String serviceType;
  final String date;
  final double mileage;
  final double? cost;
  final String? notes;
  final double? nextReminderMileage;
  final String? nextReminderDate;

  // Constructor automatically generates a unique ID if not provided.
  MaintenanceLog({
    String? id,
    required this.vehicleId,
    required this.serviceType,
    required this.date,
    required this.mileage,
    this.cost,
    this.notes,
    this.nextReminderMileage,
    this.nextReminderDate,
  }) : id = id ?? const Uuid().v4();

  // Converts the MaintenanceLog object to a JSON map for storage or transfer.
  Map<String, dynamic> toJson() => {
        'id': id,
        'vehicleId': vehicleId,
        'serviceType': serviceType,
        'date': date,
        'mileage': mileage,
        'cost': cost,
        'notes': notes,
        'nextReminderMileage': nextReminderMileage,
        'nextReminderDate': nextReminderDate,
      };

  // Creates a MaintenanceLog object from a JSON map (used when reading from storage).
  factory MaintenanceLog.fromJson(Map<String, dynamic> json) => MaintenanceLog(
        id: json['id'],
        vehicleId: json['vehicleId'],
        serviceType: json['serviceType'],
        date: json['date'],
        mileage: json['mileage'],
        cost: json['cost'],
        notes: json['notes'],
        nextReminderMileage: json['nextReminderMileage'],
        nextReminderDate: json['nextReminderDate'],
      );
}
