class FuelLog {
  final double mileage;
  final double liters;
  final double pricePerLiter;
  final double cost;
  final String date;
  final String? note;
  final String vehicleId;

  FuelLog({
    required this.mileage,
    required this.liters,
    required this.pricePerLiter,
    required this.cost,
    required this.date,
    required this.vehicleId,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'mileage': mileage,
        'liters': liters,
        'pricePerLiter': pricePerLiter,
        'cost': cost,
        'date': date,
        'note': note,
        'vehicleId': vehicleId,
      };

  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
        mileage: json['mileage'],
        liters: json['liters'],
        pricePerLiter: json['pricePerLiter'],
        cost: json['cost'],
        date: json['date'],
        note: json['note'],
        vehicleId: json['vehicleId'] ?? 'Default',
      );
}
