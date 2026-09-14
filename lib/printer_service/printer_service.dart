export 'print_alignment.dart';

import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:image/image.dart';

import '../lio_response.dart';
import 'print_alignment.dart';
import 'print_attributes.dart';

/// Impressao pelo SDK da Cielo, dentro do proprio processo.
///
/// A integracao anterior era por deep link `lio://print`, que passava o
/// *caminho de um arquivo* para o app da Cielo abrir. Isso deixou de funcionar:
/// o app da Cielo roda com outro UID e nao enxerga o diretorio privado deste
/// app, e a partir do Android 11 tambem nao enxerga o que gravamos em area
/// compartilhada. Aqui os bytes vao direto para o SDK, sem arquivo no meio.
///
/// A API publica (`enqueue` / `print`) continua identica.
class PrinterService {
  // ignore: unused_field
  final String? _scheme;
  // ignore: unused_field
  final String? _host;

  final MethodChannel _messagesChannel;

  /// Itens ja preparados, na ordem em que devem sair na impressora.
  final List<Map<String, dynamic>> _items = [];

  PrinterService(this._scheme, this._host, this._messagesChannel);

  /// Enfileira um item, sem imprimir.
  ///
  /// Para `PRINT_IMAGE`, [text] e a imagem em base64. Os tamanhos 100 a 103
  /// continuam significando "redimensionar para 340px de largura", cada um com
  /// uma interpolacao diferente.
  enqueue(String text, PrintAlignment alignment, int size, int typeface,
      String operation) {
    final attributes = <String, int>{
      PrintAttributes.align: alignment.toPrinterAttribute(),
      PrintAttributes.textSize: size,
      PrintAttributes.typeface: typeface,
    };

    if (operation == "PRINT_IMAGE") {
      _items.add({
        'operation': operation,
        'bytes': _prepararImagem(text, size),
        'attributes': attributes,
      });
    } else {
      _items.add({
        'operation': operation,
        'text': text,
        'attributes': attributes,
      });
    }
  }

  /// Imprime tudo o que foi enfileirado e chama [callback] ao final.
  ///
  /// A fila e esvaziada antes da chamada nativa, entao uma falha nao deixa
  /// itens presos para a proxima impressao.
  print(Function(LioResponse response) callback) async {
    final items = List<Map<String, dynamic>>.from(_items);
    _items.clear();

    try {
      final response = await _messagesChannel
          .invokeMethod('printItems', {'items': items});

      callback(LioResponse.fromJson(Map<String, dynamic>.from(response as Map)));
    } catch (e) {
      callback(LioResponse(1, e.toString()));
    }
  }

  Uint8List _prepararImagem(String base64String, int size) {
    final bytes = dataFromBase64String(base64String);

    final interpolacao = const {
      100: Interpolation.nearest,
      101: Interpolation.average,
      102: Interpolation.cubic,
      103: Interpolation.linear,
    }[size];

    if (interpolacao == null) return bytes;

    final image = decodeImage(bytes);
    if (image == null) return bytes;

    return Uint8List.fromList(
        encodeJpg(copyResize(image, width: 340, interpolation: interpolacao)));
  }

  Uint8List dataFromBase64String(String base64String) {
    return base64Decode(base64String);
  }
}
