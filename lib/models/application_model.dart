class Application {
  final int id;
  final int jobId;
  final String firstName;
  final String lastName;
  final String email;
  final String cvUrl;
  final String cvFileName;
  final String createdAt;

  Application({
    required this.id,
    required this.jobId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.cvUrl,
    this.cvFileName = 'curriculum.pdf',
    this.createdAt = '',
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as int,
      jobId: json['jobId'] as int,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      cvUrl: json['cvUrl'] as String,
      cvFileName: (json['cvFileName'] as String?) ?? 'curriculum.pdf',
      createdAt: (json['createdAt'] as String?) ?? '',
    );
  }
}