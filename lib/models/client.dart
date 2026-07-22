class Client {
  String name;
  String email;
  String phone;
  String address;

  /// Client's VAT Registration Number, printed on the invoice's "Bill To"
  /// section when provided.
  String vrn;

  /// Client's Taxpayer Identification Number, printed on the invoice's
  /// "Bill To" section when provided.
  String tin;

  Client({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
    this.vrn = '',
    this.tin = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
        'vrn': vrn,
        'tin': tin,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
        vrn: json['vrn'] ?? '',
        tin: json['tin'] ?? '',
      );

  Client copyWith(
      {String? name, String? email, String? phone, String? address, String? vrn, String? tin}) {
    return Client(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      vrn: vrn ?? this.vrn,
      tin: tin ?? this.tin,
    );
  }
}
