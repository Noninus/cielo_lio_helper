import 'dart:async';
import 'dart:convert';

import 'package:cielo_lio_helper/payment_response.dart';
import 'package:cielo_lio_helper/payment_service/checkout_request.dart';
import 'package:cielo_lio_helper/utils.dart';
import 'package:flutter/services.dart';

class PaymentService2 {
  final MethodChannel _messagesChannel;
  final String? _scheme;
  final String? _host;
  static StreamController<PaymentResponse> _controller =
      StreamController.broadcast();

  Stream<PaymentResponse> get streamData => _controller.stream;

  PaymentService2(this._scheme, this._host, this._messagesChannel);

  String _generatePaymentUri(CheckoutRequest request) {
    try {
      String base64 = toBase64(request);
      return "lio://payment?request=$base64&urlCallback=$_scheme://$_host";
    } catch (e) {
      throw e;
    }
  }

  checkout(CheckoutRequest request) async {
    try {
      _messagesChannel.setMethodCallHandler((call) async {
        switch (call.method) {
          case "checkoutCallback":
            _controller
                .add(PaymentResponse.fromJson(jsonDecode(call.arguments)));
            break;
          default:
        }
      });
    } on PlatformException catch (e) {
      // _controller.add(PaymentResponse(
      //     success: false,
      //     message: e.toString(),
      //     reason: "platError",
      //     responseCode: "9999"));
    }
    var uri = _generatePaymentUri(request);
    await _messagesChannel.invokeMethod('payment', {"uri": uri});
  }
}
