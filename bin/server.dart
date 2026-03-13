import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

List stages = [];

void main() async {
  // Load stages.json
  final file = File('stages.json');
  if (await file.exists()) {
    stages = jsonDecode(await file.readAsString());
  } else {
    print("stages.json not found!");
  }

  final router = Router();
  router.get('/stages', (Request req) =>
      Response.ok(jsonEncode(stages), headers: {'Content-Type': 'application/json'}));

  // Serve
  var handler = const Pipeline()
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final server = await serve(handler, InternetAddress.anyIPv4, 8080);
  print('Server running on http://${server.address.address}:${server.port}');
}