class Job {
  final int id;
  final int companyId;
  final String companyName;
  final String title;
  final String description;
  final String createdAt;
  final int applicationsCount;

  Job({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.title,
    required this.description,
    required this.createdAt,
    this.applicationsCount = 0,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'] as int,
      companyId: json['companyId'] as int,
      companyName: (json['companyName'] ?? '') as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: (json['createdAt'] ?? '') as String,
      applicationsCount: (json['applicationsCount'] as int?) ?? 0,
    );
  }
}