class CompanyProfile {
  String name;
  String address;
  String email;
  String phone;

  /// Tanzania Revenue Authority Taxpayer Identification Number.
  String tinNumber;

  /// Base64-encoded logo image bytes (PNG/JPEG), or null if none uploaded.
  String? logoBase64;

  CompanyProfile({
    this.name = 'SJ TRACKING SOLUTION',
    this.address = '',
    this.email = '',
    this.phone = '',
    this.tinNumber = '',
    this.logoBase64,
  });

  bool get hasLogo => logoBase64 != null && logoBase64!.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'address': address,
        'email': email,
        'phone': phone,
        'tinNumber': tinNumber,
        'logoBase64': logoBase64,
      };

  factory CompanyProfile.fromJson(Map<String, dynamic> json) => CompanyProfile(
        name: json['name'] ?? 'SJ TRACKING SOLUTION',
        address: json['address'] ?? '',
        email: json['email'] ?? '',
        phone: json['phone'] ?? '',
        tinNumber: json['tinNumber'] ?? '',
        logoBase64: json['logoBase64'],
      );
}
