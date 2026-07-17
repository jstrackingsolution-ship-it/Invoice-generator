class Client {
  String name;
  String email;
  String phone;
  String address;

  Client({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'phone': phone,
        'address': address,
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        name: json['name'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        address: json['address'] ?? '',
      );

  Client copyWith({String? name, String? email, String? phone, String? address}) {
    return Client(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
    );
  }
}
