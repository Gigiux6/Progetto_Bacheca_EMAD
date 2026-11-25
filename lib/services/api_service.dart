import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/application_model.dart';
import '../models/job_model.dart';

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}

class CompanySession {
  final String token;
  final int companyId;
  final String companyName;
  final String email;

  const CompanySession({
    required this.token,
    required this.companyId,
    required this.companyName,
    required this.email,
  });
}

class ApiService {
  static const _keyToken = 'auth_token';
  static const _keyCompanyId = 'company_id';
  static const _keyCompanyName = 'company_name';
  static const _keyCompanyEmail = 'company_email';

  static String _extractError(http.Response res, String fallback) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic> && decoded['error'] != null) {
        return decoded['error'].toString();
      }
    } catch (_) {}
    return fallback;
  }

  /// Restores the saved company session from SharedPreferences, if present.
  static Future<CompanySession?> getSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    final companyId = prefs.getInt(_keyCompanyId);
    final companyName = prefs.getString(_keyCompanyName);
    final email = prefs.getString(_keyCompanyEmail);
    if (token == null || companyId == null || companyName == null) {
      return null;
    }
    return CompanySession(
      token: token,
      companyId: companyId,
      companyName: companyName,
      email: email ?? '',
    );
  }

  // R5 - Recupera gli annunci pubblici
  static Future<List<Job>> fetchJobs() async {
    final response = await http.get(Uri.parse('${AppConfig.baseUrl}/api/jobs'));
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Job.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw ApiException(_extractError(response, 'Errore nel caricamento annunci'));
  }

  // Area Riservata - Recupera solo gli annunci dell'azienda autenticata
  static Future<List<Job>> fetchMyJobs() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) {
      throw const ApiException('Sessione non valida. Effettua di nuovo il login.');
    }

    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/my-jobs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((json) => Job.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw ApiException(_extractError(response, 'Errore nel caricamento dei tuoi annunci'));
  }

  // R1 - Registrazione azienda
  static Future<void> register(String email, String password, String name) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'name': name.trim(),
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw ApiException(_extractError(res, 'Errore durante la registrazione'));
    }
  }

  // R2 - Login azienda
  static Future<CompanySession> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final session = CompanySession(
        token: data['token'] as String,
        companyId: data['companyId'] as int,
        companyName: data['name'] as String,
        email: (data['email'] ?? email.trim()) as String,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, session.token);
      await prefs.setInt(_keyCompanyId, session.companyId);
      await prefs.setString(_keyCompanyName, session.companyName);
      await prefs.setString(_keyCompanyEmail, session.email);
      return session;
    }
    throw ApiException(_extractError(res, 'Credenziali non valide'));
  }

  // R3 - Logout azienda
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token != null) {
      try {
        await http.post(
          Uri.parse('${AppConfig.baseUrl}/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      } catch (_) {
        // Puliamo comunque la sessione locale anche se il server non è raggiungibile.
      }
    }
    await prefs.remove(_keyToken);
    await prefs.remove(_keyCompanyId);
    await prefs.remove(_keyCompanyName);
    await prefs.remove(_keyCompanyEmail);
  }

  // R4 - Creazione Annuncio
  static Future<Job> createJob(String title, String description) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) {
      throw const ApiException('Devi effettuare il login per pubblicare un annuncio.');
    }

    final res = await http.post(
      Uri.parse('${AppConfig.baseUrl}/api/jobs'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'title': title.trim(),
        'description': description.trim(),
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return Job.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw ApiException(_extractError(res, 'Errore nella pubblicazione dell\'annuncio'));
  }

  // R6 - Candidatura con file PDF
  static Future<void> submitApplication({
    required int jobId,
    required String firstName,
    required String lastName,
    required String email,
    String? cvFilePath,
    Uint8List? cvBytes,
    required String cvFileName,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConfig.baseUrl}/api/jobs/$jobId/apply'),
    );
    request.fields['firstName'] = firstName.trim();
    request.fields['lastName'] = lastName.trim();
    request.fields['email'] = email.trim();

    if (cvBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes('cv', cvBytes, filename: cvFileName),
      );
    } else if (cvFilePath != null) {
      request.files.add(
        await http.MultipartFile.fromPath('cv', cvFilePath, filename: cvFileName),
      );
    } else {
      throw const ApiException('Seleziona un file PDF per il curriculum.');
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(_extractError(response, 'Errore nell\'invio della candidatura'));
    }
  }

  // R7 - Candidature ricevute dall'azienda
  static Future<List<Application>> fetchApplications(int jobId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    if (token == null) {
      throw const ApiException('Sessione scaduta. Effettua di nuovo il login.');
    }

    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/jobs/$jobId/applications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final List<dynamic> body = jsonDecode(res.body);
      return body.map((json) => Application.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw ApiException(_extractError(res, 'Errore nel caricamento delle candidature'));
  }
}
