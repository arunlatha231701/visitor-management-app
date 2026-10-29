class Visitor {
  const Visitor({
    required this.id,
    required this.name,
    required this.mobile,
    this.email,
    required this.visitorsType,
    required this.project,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.checkInTime,
    this.checkOutTime,
  });

  final String id;
  final String name;
  final String mobile;
  final String? email;
  final String visitorsType;
  final String project;
  final String purpose;
  final String status;
  final DateTime createdAt;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  Visitor copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    bool clearEmail = false,
    String? visitorsType,
    String? project,
    String? purpose,
    String? status,
    DateTime? createdAt,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    bool clearCheckInTime = false,
    bool clearCheckOutTime = false,
  }) {
    return Visitor(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: clearEmail ? null : (email ?? this.email),
      visitorsType: visitorsType ?? this.visitorsType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: clearCheckInTime
          ? null
          : (checkInTime ?? this.checkInTime),
      checkOutTime: clearCheckOutTime
          ? null
          : (checkOutTime ?? this.checkOutTime),
    );
  }
}