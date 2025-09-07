// lib/data/api_client.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    required this.auth,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final FirebaseAuth auth;
  final http.Client _http;

  Future<Map<String, dynamic>> _requestJson(
      String method,
      String path, {
        Map<String, dynamic>? body,
        Map<String, String>? extraHeaders,
      }) async {
    final user = auth.currentUser;
    final idToken = await user?.getIdToken();

    final uri = Uri.parse('$baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (idToken != null) 'Authorization': 'Bearer $idToken',
      ...?extraHeaders,
    };

    http.Response resp;
    final encoded = body == null ? null : jsonEncode(body);

    try {
      switch (method) {
        case 'GET':
          resp = await _http.get(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        case 'POST':
          resp = await _http.post(uri, headers: headers, body: encoded).timeout(const Duration(seconds: 30));
          break;
        case 'PUT':
          resp = await _http
              .put(uri, headers: headers, body: encoded)
              .timeout(const Duration(seconds: 30));
          break;
        case 'DELETE':
          resp = await _http.delete(uri, headers: headers).timeout(const Duration(seconds: 20));
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    } on SocketException {
      throw ApiException('No internet connection. Please check your network.');
    } on HttpException {
      throw ApiException('Failed to connect to server.');
    } on FormatException {
      throw ApiException('Invalid server response format.');
    } on TimeoutException {
      throw ApiException('Request timed out. Please try again later.');
    } catch (e) {
      throw ApiException('Unexpected network error: $e');
    }

    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      String message = 'HTTP ${resp.statusCode} error';
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map && decoded['error'] != null) {
          message = decoded['error'].toString();
        } else {
          message = resp.body;
        }
      } catch (_) {
        // fallback
      }
      throw ApiException(message, statusCode: resp.statusCode);
    }

    if (resp.body.isEmpty) return <String, dynamic>{};

    final decoded = jsonDecode(resp.body);
    if (decoded is Map<String, dynamic>) return decoded;

    // Some APIs return list directly
    return {'data': decoded};
  }

  // Shortcuts
  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) =>
      _requestJson('POST', path, body: body);

  Future<Map<String, dynamic>> getJson(String path) =>
      _requestJson('GET', path);

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) =>
      _requestJson('PUT', path, body: body);

  Future<Map<String, dynamic>> deleteJson(String path) =>
      _requestJson('DELETE', path);

  // -------------------------
  // Notes endpoints
  // -------------------------
  Future<Map<String, dynamic>> createNote({
    required String title,
    required String content,
    required String kind,
    required String skin,
  }) async {
    return await postJson('/notes', {
      'title': title,
      'content': content,
      'kind': kind,
      'skin': skin,
    });
  }

  Future<Map<String, dynamic>> updateNote({
    required String id,
    required String title,
    required String content,
    required String kind,
    required String skin,
  }) async {
    return await putJson('/notes/$id', {
      'title': title,
      'content': content,
      'kind': kind,
      'skin': skin,
    });
  }

  Future<void> deleteNote(String id) async {
    await deleteJson('/notes/$id');
  }

  Future<List<dynamic>> getNotes() async {
    final rsp = await getJson('/notes');

    if (rsp['data'] is List) return (rsp['data'] as List).cast<dynamic>();
    for (final key in ['items', 'notes']) {
      if (rsp[key] is List) return (rsp[key] as List).cast<dynamic>();
    }
    for (final v in rsp.values) {
      if (v is List) return v.cast<dynamic>();
    }
    return const <dynamic>[];
  }

  // -------------------------
  // AI endpoints
  // -------------------------
  Future<Map<String, dynamic>> aiSuggestTitle({required String content}) =>
      postJson('/ai/suggest_title', {'content': content});

  Future<Map<String, dynamic>> aiSummarize({required String content}) =>
      postJson('/ai/summarize', {'content': content});

  Future<Map<String, dynamic>> aiSuggestTags({required String content}) =>
      postJson('/ai/tags', {'content': content});

  void close() => _http.close();
}
