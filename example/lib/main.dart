import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cielo_lio_helper/cielo_lio_helper.dart';
import 'package:cielo_lio_helper/printer_service/print_operation.dart';
import 'package:cielo_lio_helper_example/img_string.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

const String sampleText = "SAMPLE TEXT";

const String clientId = "YOUR-CLIENT-ID";
const String accessToken = "YOUR-ACCESS-TOKEN";

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _ec = 'Unknown';
  String _logicNumber = 'Unknown';
  double _batteryLevel = -1;
  LioResponse _printResponse;
  bool _isPrinting = false;
  CancelRequest _cancelRequest;
  String _permissions = "";
  String _path = "";

  _requestPermission() async {
    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.camera,
      Permission.manageExternalStorage,
      Permission.photos,
    ].request();
    print(statuses[Permission.storage]);
    print(statuses[Permission.manageExternalStorage]);

    var status = await Permission.storage.status;
    var status1 = await Permission.manageExternalStorage.status;
    var status2 = await Permission.camera.status;
    setState(() {
      _permissions =
          'Storage: ${status.isGranted.toString()} | ExternalStorage: ${status1.isGranted.toString()} | Camera: ${status2.isGranted.toString()}';
    });
  }

  @override
  void initState() {
    super.initState();
    _requestPermission();
    initECState();
    initLogicNumberState();
    initBatteryLevelState();
    initCieloLioHelper();
  }

  initCieloLioHelper() {
    CieloLioHelper.init(
      host: "dev.mauricifj",
      schemes: SchemeAggregate(
        printResponseScheme: "print_response",
        paymentResponseScheme: "payment_response",
        reversalResponseScheme: "reversal_response",
      ),
    );
  }

  printSampleTexts() {
    setState(() => _isPrinting = true);

    printQueue();

    for (int i = 15; i <= 30; i += 5) {
      for (int j = 0; j < 10; j++) {
        CieloLioHelper.enqueue(
            sampleText, PrintAlignment.CENTER, i, j, PrintOperation.text);
      }
    }

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.printQueue((LioResponse response) {
      setState(() {
        _printResponse = response;
        _isPrinting = false;
      });
    });
  }

  Future<void> initECState() async {
    String ec;
    try {
      ec = await CieloLioHelper.ec;
    } on PlatformException {
      _ec = 'Failed to get ec.';
    }

    if (!mounted) return;

    setState(() {
      _ec = ec;
    });
  }

  Future<void> initLogicNumberState() async {
    String logicNumber;
    try {
      logicNumber = await CieloLioHelper.logicNumber;
    } on PlatformException {
      logicNumber = 'Failed to get logic number.';
    }

    if (!mounted) return;

    setState(() {
      _logicNumber = logicNumber;
    });
  }

  Future<void> initBatteryLevelState() async {
    double batteryLevel;
    try {
      batteryLevel = await CieloLioHelper.batteryLevel;
    } on PlatformException {
      batteryLevel = -1;
    }

    if (!mounted) return;

    setState(() {
      _batteryLevel = batteryLevel;
    });
  }

  checkout() {
    var random = Random();
    var unitPrice = random.nextInt(400) + 100;
    var quantity = random.nextInt(9) + 1;
    var total = unitPrice * quantity;

    var request = CheckoutRequest(
      clientID: clientId,
      accessToken: accessToken,
      value: total,
      paymentCode: "CREDITO_AVISTA",
      installments: 0,
      email: "dev.sdk@braspag.com.br",
      merchantCode: "0000000000000003",
      reference: "reference_text",
      items: List.from(
        [
          Item(
            sku: "${Random().nextInt(100000) + 1000}",
            name: "water bottle",
            unitPrice: unitPrice,
            quantity: quantity,
            unitOfMeasure: "bottle",
          ),
        ],
      ),
    );

    CieloLioHelper.checkout(request, (response) {
      _cancelRequest = CancelRequest(
        accessToken: accessToken,
        clientID: clientId,
        authCode: response.payments[0].authCode,
        cieloCode: response.payments[0].cieloCode,
        merchantCode: response.payments[0].merchantCode,
        value: response.payments[0].amount,
        id: response.id,
      );
    });
  }

  cancelLastPayment() {
    if (_cancelRequest != null) {
      CieloLioHelper.cancelPayment(_cancelRequest, (response) {
        print(response.id);
      });
    }
  }

  printQueue() async {
    CieloLioHelper.enqueue(
        sampleText, PrintAlignment.CENTER, 30, 1, PrintOperation.text);
    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 30, 1, PrintOperation.text);
    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 30, 1, PrintOperation.text);
    CieloLioHelper.enqueue(
        'SAGRES TESTES', PrintAlignment.CENTER, 30, 1, PrintOperation.text);
  }

  _printImage() async {
    CieloLioHelper.enqueue('INICIO TESTE IMAGEM', PrintAlignment.CENTER, 30, 1,
        PrintOperation.text);

    CieloLioHelper.enqueue(
        '$imgString', PrintAlignment.CENTER, 30, 1, PrintOperation.image);

    CieloLioHelper.enqueue(
        'FIM TESTE IMAGEM', PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.printQueue((LioResponse response) => setState(() {
          _printResponse = response;
          _isPrinting = false;
        }));
  }

  String checkPrintState() {
    if (_isPrinting) return "PRINTING...";
    if (_printResponse?.message != null) return _printResponse.message;
    return "Unknown";
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            children: [
              Text('Permissions: $_permissions'),
              _path != ''
                  ? Image.file(
                      File(_path),
                      scale: 2,
                    )
                  : Container(),
              _path != '' ? Text('_path: $_path') : Container(),
              Text('EC: $_ec'),
              Text('LOGIC NUMBER: $_logicNumber'),
              Text(
                  'BATTERY LEVEL: ${_batteryLevel >= 0 ? "${_batteryLevel.toString()}%" : "Unknown"}'),
              Text('PRINT STATE: ${checkPrintState()}'),
              ElevatedButton(
                  onPressed: () => printSampleTexts(), child: Text("Imprimir")),
              ElevatedButton(
                  onPressed: () => _printImage(), child: Text("print image")),
              ElevatedButton(onPressed: () => checkout(), child: Text("Pagar")),
              ElevatedButton(
                  onPressed: () => cancelLastPayment(),
                  child: Text("Cancelar último pagamento")),
            ],
          ),
        ),
      ),
    );
  }
}
