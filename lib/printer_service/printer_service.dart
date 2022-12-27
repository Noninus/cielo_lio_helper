export 'print_alignment.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'dart:typed_data';

import '../lio_response.dart';
import '../utils.dart';
import 'print_alignment.dart';
import 'print_request.dart';
import 'print_style.dart';
import 'queue_manager.dart';

class PrinterService {
  final String? _scheme;
  final String? _host;

  static Stream<LioResponse>? _streamLink;
  static const EventChannel _responsesChannel =
      const EventChannel("cielo_lio_helper/print_responses");

  QueueManager? _queueManager;

  PrinterService(this._scheme, this._host, MethodChannel messagesChannel) {
    _queueManager = QueueManager(messagesChannel: messagesChannel);
    _stream().listen((LioResponse response) {
      if (response.code == 0) {
        _queueManager!.processResponse(response);
      } else {
        _queueManager!.clear();
        _queueManager!.callback!.call(response);
      }
    });
  }

  static Stream<LioResponse> _stream() {
    if (_streamLink == null) {
      _streamLink = _responsesChannel
          .receiveBroadcastStream("print_responses")
          .cast<String>()
          .map((response) => LioResponse.fromJson(jsonDecode(response)));
    }
    return _streamLink!;
  }

  enqueue(String text, PrintAlignment alignment, int size, int typeface,
      String operation) {
    var uri = _generatePrintUri(text, alignment, size, typeface, operation);
    _queueManager!.enqueue(uri);
  }

  print(Function(LioResponse response) callback) {
    _queueManager!.print(callback);
  }

  Uint8List dataFromBase64String(String base64String) {
    return base64Decode(base64String);
  }

  String _generatePrintUri(String text, PrintAlignment alignment, int size,
      int typeface, String operation) {
    try {
      var style = Style(
          keyAttributesAlign: alignment.toPrinterAttribute(),
          keyAttributesTextsize: size,
          keyAttributesTypeface: typeface);
      var styles = List<Style>.from([style]);

      if (operation == "PRINT_IMAGE") {
        final decodedBytes = dataFromBase64String(text);

        var directory = Directory('/storage/emulated/0/Download');
        final String path = directory.path;

        File fileImg = File('$path/imagem.jpg');
        fileImg.writeAsBytesSync(decodedBytes);
        text = fileImg.path;
      }

      PrintRequest printRequest =
          new PrintRequest(operation, styles, List.from([text]));
      String base64 = toBase64(printRequest);
      return "lio://print?request=$base64&urlCallback=$_scheme://$_host";
    } catch (e) {
      throw e;
    }
  }
}
