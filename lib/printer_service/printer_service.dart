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
import 'package:image/image.dart';

class PrinterService {
  final String? _scheme;
  final String? _host;

  static Stream<LioResponse>? _streamLink;
  static const EventChannel _responsesChannel =
      const EventChannel("cielo_lio_helper/print_responses");

  QueueManager? _queueManager;

  /// Quem abre esse arquivo eh o app da Cielo, em outro processo, e ele nao
  /// enxerga os diretorios privados deste app. Por isso o armazenamento
  /// compartilhado vem primeiro; o privado fica como ultimo recurso, para o
  /// caso de o sistema barrar a gravacao em /Download.
  static const String _imagemPathCompartilhado =
      '/storage/emulated/0/Download/imagem.jpg';

  static String get _imagemPathPrivado =>
      '${Directory.systemTemp.path}/imagem.jpg';

  static List<String> get _imagemPaths =>
      [_imagemPathCompartilhado, _imagemPathPrivado];

  PrinterService(this._scheme, this._host, MethodChannel messagesChannel) {
    _queueManager = QueueManager(messagesChannel: messagesChannel);
    _stream().listen((LioResponse response) {
      if (response.code == 0) {
        _queueManager!.processResponse(response);
      } else {
        _queueManager!.clear();
        _queueManager!.callback?.call(response);
      }

      // Apaga so depois que a fila esvazia: se a imagem nao for o primeiro
      // item, apagar a cada resposta a remove antes de ser enviada.
      if (_queueManager!.isEmpty) _limparImagemTemp();
    });
  }

  void _limparImagemTemp() {
    for (final path in _imagemPaths) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
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

  /// Grava a imagem no primeiro caminho que aceitar a escrita.
  File _gravarImagemTemp(Uint8List bytes) {
    Object? ultimoErro;
    for (final path in _imagemPaths) {
      try {
        final file = File(path);
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        return file;
      } catch (e) {
        ultimoErro = e;
      }
    }
    throw FileSystemException(
        'Nao foi possivel gravar a imagem para impressao: $ultimoErro');
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

        File fileImg = _gravarImagemTemp(decodedBytes);

        //Interpolation nearest
        if (size == 100) {
          Image? image = decodeImage(fileImg.readAsBytesSync());

          // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
          Image resizedImage = copyResize(image!, width: 340);

          fileImg.writeAsBytesSync(encodeJpg(resizedImage));
        }

        //Interpolation average
        if (size == 101) {
          Image? image = decodeImage(fileImg.readAsBytesSync());

          // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
          Image resizedImage = copyResize(image!,
              width: 340, interpolation: Interpolation.average);

          fileImg.writeAsBytesSync(encodeJpg(resizedImage));
        }

        //Interpolation cubic
        if (size == 102) {
          Image? image = decodeImage(fileImg.readAsBytesSync());

          // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
          Image resizedImage = copyResize(image!,
              width: 340, interpolation: Interpolation.cubic);

          fileImg.writeAsBytesSync(encodeJpg(resizedImage));
        }

        //Interpolation linear
        if (size == 103) {
          Image? image = decodeImage(fileImg.readAsBytesSync());

          // Resize the image to a 120x? thumbnail (maintaining the aspect ratio).
          Image resizedImage = copyResize(image!,
              width: 340, interpolation: Interpolation.linear);

          fileImg.writeAsBytesSync(encodeJpg(resizedImage));
        }

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
