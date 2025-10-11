// The data model for a single fuel log entry.
class FuelLog {
  final int? id; // Supabase ID
  final String userId; // Foreign key to the user
  final double mileage;
  final double liters;
  final double pricePerLiter;
  final double cost;
  final String date;
  final String? note;
  final String vehicleId;

  FuelLog({
    this.id,
    required this.userId,
    required this.mileage,
    required this.liters,
    required this.pricePerLiter,
    required this.cost,
    required this.date,
    required this.vehicleId,
    this.note,
  });

  // Converts a FuelLog object into a Map for Supabase.
  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'mileage': mileage,
        'liters': liters,
        'price_per_liter': pricePerLiter,
        'cost': cost,
        'date': date,
        'note': note,
        'vehicle_id': vehicleId,
      };

  // Creates a FuelLog object from a Map received from Supabase.
  factory FuelLog.fromJson(Map<String, dynamic> json) => FuelLog(
        id: json['id'],
        userId: json['user_id'],
        mileage: json['mileage'],
        liters: json['liters'],
        pricePerLiter: json['price_per_liter'],
        cost: json['cost'],
        date: json['date'],
        note: json['note'],
        vehicleId: json['vehicle_id'],
      );
}
