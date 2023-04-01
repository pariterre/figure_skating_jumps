import 'dart:convert';

import 'package:figure_skating_jumps/enums/jump_type.dart';
import 'package:figure_skating_jumps/models/jump.dart';
import 'package:http/http.dart';

class HttpClient {
  static final HttpClient _httpClient = HttpClient._internal();
  static const String _serverAddress = "148.113.140.6:8080";
  static const String _addFileRoute = "file";
  static const String _analyzeRoute = "analyze";

  factory HttpClient() {
    return _httpClient;
  }

  HttpClient._internal();

  Future<bool> uploadFile(
      {required String fileName, required String fileContent}) async {
    Uri uri = Uri.http(_serverAddress, _addFileRoute, {"fileName": fileName});
    Response resp = await put(uri, body: fileContent);
    return resp.statusCode == 200;
  }

  Future<List<Jump>?> analyze(
      {required String fileName, required String captureID}) async {
    Uri uri = Uri.http(_serverAddress, _analyzeRoute);
    Map<String, String> content = {"fileName": fileName};
    Response resp = await post(uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(content));
    if (resp.statusCode != 200) return null;
    List<Jump> jumps = [];
    for (var jump in jsonDecode(resp.body)) {
      jumps.add(Jump(
          ((jump['start'] * 1000) as double).round(),
          ((jump['duration'] * 1000) as double).round(),
          false,
          JumpType.unknown,
          "",
          0,
          captureID,
          jump['timeToMax'],
          jump['maxRotSpeed'],
          jump['numRot']));
    }

    return jumps;
  }
}
