class VisitorModel {
  const VisitorModel({
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

  factory VisitorModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null || value.toString().trim().isEmpty) {
        return null;
      }

      return DateTime.tryParse(value.toString())?.toLocal();
    }

    return VisitorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString(),
      visitorsType:
          (json['visitor_type'] ?? json['visitorsType'])?.toString() ?? '',
      project: json['project']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt:
          parseDate(json['created_at'] ?? json['createdAt']) ?? DateTime.now(),
      checkInTime: parseDate(json['check_in_time'] ?? json['checkInTime']),
      checkOutTime: parseDate(json['check_out_time'] ?? json['checkOutTime']),
    );
  }

  Map<String, dynamic> toJson({bool included = true}) => {
    if (included) 'id': id,
    'name': name,
    'mobile': mobile,
    'email': email,
    'visitor_type': visitorsType,
    'project': project,
    'purpose': purpose,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'check_in_time': checkInTime?.toIso8601String(),
    'check_out_time': checkOutTime?.toIso8601String(),
  };

  VisitorModel copyWith({
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
    return VisitorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: clearEmail ? null : (email ?? this.email),
      visitorsType: visitorsType ?? this.visitorsType,
      project: project ?? this.project,
      purpose: purpose ?? this.purpose,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      checkInTime: clearCheckInTime ? null : (checkInTime ?? this.checkInTime),
      checkOutTime: clearCheckOutTime
          ? null
          : (checkOutTime ?? this.checkOutTime),
    );
  }
}
