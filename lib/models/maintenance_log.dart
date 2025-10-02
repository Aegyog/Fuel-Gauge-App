import 'package:uuid/uuid.dart';

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
