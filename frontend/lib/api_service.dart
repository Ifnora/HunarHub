import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://hunarhub-pakistan-api-henna.vercel.app';

  final String token;

  ApiService({required this.token});

  // LOGIN
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return _handleResponse(response);
  }

  // AUTHENTICATION HEADERS
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // GET JOBS
  Future<Map<String, dynamic>> getJobs({
    int page = 1,
    int limit = 10,
  }) async {
    final uri = Uri.parse('$baseUrl/jobs').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(uri, headers: _headers);
    return _handleResponse(response);
  }

  // GET USER PROFILE
  Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/profile'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // UPDATE USER PROFILE
  Future<Map<String, dynamic>> updateProfile({
    String? city,
    String? country,
    List<dynamic>? education,
    List<dynamic>? skills,
    List<dynamic>? experience,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: _headers,
      body: jsonEncode({
        if (city != null) 'city': city,
        if (country != null) 'country': country,
        if (education != null) 'education': education,
        if (skills != null) 'skills': skills,
        if (experience != null) 'experience': experience,
      }),
    );

    return _handleResponse(response);
  }

  // CREATE CV
  Future<Map<String, dynamic>> createCV({
    required String title,
    required String cvType,
    required String templateName,
    required Map<String, dynamic> content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cv'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'cv_type': cvType,
        'template_name': templateName,
        'content': content,
      }),
    );

    return _handleResponse(response);
  }

  // GET ALL CVS
  Future<Map<String, dynamic>> getCVs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cv'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // UPDATE CV
  Future<Map<String, dynamic>> updateCV({
    required String id,
    required String title,
    required String cvType,
    required String templateName,
    required Map<String, dynamic> content,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cv/$id'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        'cv_type': cvType,
        'template_name': templateName,
        'content': content,
      }),
    );

    return _handleResponse(response);
  }

  // DELETE CV
  Future<Map<String, dynamic>> deleteCV(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cv/$id'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // GET SAVED JOBS
  Future<Map<String, dynamic>> getSavedJobs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/applications/saved'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // SAVE JOB
  Future<Map<String, dynamic>> saveJob(String jobId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/applications/saved/$jobId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // REMOVE SAVED JOB
  Future<Map<String, dynamic>> removeSavedJob(String jobId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/applications/saved/$jobId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // RECORD JOB APPLICATION
  Future<Map<String, dynamic>> applyForJob(String jobId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/applications/$jobId/apply'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // GET APPLICATION TRACKING
  Future<Map<String, dynamic>> getApplications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/applications'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  // HANDLE API RESPONSES
  static Map<String, dynamic> _handleResponse(
    http.Response response,
  ) {
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response.');
    }

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception(
      data is Map
          ? data['message']?.toString() ?? 'API request failed'
          : 'API request failed',
    );
  }
}
