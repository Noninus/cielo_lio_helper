import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cielo_lio_helper/cielo_lio_helper.dart';
import 'package:cielo_lio_helper/printer_service/print_operation.dart';
import 'package:cielo_lio_helper_example/img_string.dart';
import 'package:cielo_lio_helper_example/img_string_340_cubic.dart';
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
  TextEditingController controller = TextEditingController();

  _requestPermission() async {
    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
    ].request();
    print(statuses[Permission.storage]);

    var status = await Permission.storage.status;
    setState(() {
      _permissions = 'Storage: ${status.isGranted.toString()} ';
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
    // var random = Random();
    // var unitPrice = random.nextInt(400) + 100;
    // var quantity = random.nextInt(9) + 1;
    // var total = unitPrice * quantity;

    var request = CheckoutRequest(
      clientID: "WklO9jhmr0U3OAyMiRrlj0E5H3pHnQnziXTTVsEDkABaMrhWdi",
      accessToken: "KxSIJKSDsnqHHpBJhF7TUakhpXw2UacaGnfQpV1b0TE8Ocupn5",
      value: int.parse(controller.text.replaceAll(',', '').replaceAll('.', '')),
      paymentCode: "CREDITO_AVISTA",
      installments: 0,
      email: "dev.sdk@braspag.com.br",
      merchantCode: "0000000000000003",
      reference: "mesa x",
      items: List.from(
        [
          Item(
            sku: "${Random().nextInt(100000) + 1000}",
            name: "Pagamento mesa x",
            unitPrice: int.parse(
                controller.text.replaceAll(',', '').replaceAll('.', '')),
            quantity: 1,
            unitOfMeasure: "money",
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
      CieloLioHelper.cancelLastSubscription();
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

  _printImageSemResize() {
    CieloLioHelper.enqueue('INICIO TESTE IMAGEM sem resize',
        PrintAlignment.CENTER, 30, 1, PrintOperation.text);

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

  _printImageComResize() {
    CieloLioHelper.enqueue('INICIO TESTE IMAGEM com resize nearest',
        PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        '$imgString', PrintAlignment.CENTER, 100, 1, PrintOperation.image);

    CieloLioHelper.enqueue(
        'FIM TESTE IMAGEM', PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.printQueue((LioResponse response) => setState(() {
          _printResponse = response;
          _isPrinting = false;
        }));
  }

  _printImageComResizeAverage() {
    CieloLioHelper.enqueue('INICIO TESTE IMAGEM com resize average',
        PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        '$imgString', PrintAlignment.CENTER, 101, 1, PrintOperation.image);

    CieloLioHelper.enqueue(
        'FIM TESTE IMAGEM', PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.printQueue((LioResponse response) => setState(() {
          _printResponse = response;
          _isPrinting = false;
        }));
  }

  _printImageRefeitoGimp() {
    CieloLioHelper.enqueue('INICIO TESTE IMAGEM 340 refeito no gimp',
        PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue('$imgString340Cubic', PrintAlignment.CENTER, 30, 1,
        PrintOperation.image);

    CieloLioHelper.enqueue(
        'FIM TESTE IMAGEM', PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.printQueue((LioResponse response) => setState(() {
          _printResponse = response;
          _isPrinting = false;
        }));
  }

  _printImageComResizeLinear() {
    CieloLioHelper.enqueue('INICIO TESTE IMAGEM com resize linear',
        PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        '$imgString', PrintAlignment.CENTER, 103, 1, PrintOperation.image);

    CieloLioHelper.enqueue(
        'FIM TESTE IMAGEM', PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.printQueue((LioResponse response) => setState(() {
          _printResponse = response;
          _isPrinting = false;
        }));
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

    CieloLioHelper.enqueue('INICIO TESTE IMAGEM 100', PrintAlignment.CENTER, 30,
        1, PrintOperation.text);

    CieloLioHelper.enqueue(
        '$imgString', PrintAlignment.CENTER, 100, 1, PrintOperation.image);

    CieloLioHelper.enqueue(
        'FIM TESTE IMAGEM', PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.enqueue('INICIO TESTE convetida do gimp',
        PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue('$imgString340Cubic', PrintAlignment.CENTER, 30, 1,
        PrintOperation.image);

    CieloLioHelper.enqueue(
        'FIM TESTE IMAGEM', PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue(
        "\n\n\n", PrintAlignment.CENTER, 20, 1, PrintOperation.text);

    CieloLioHelper.enqueue('INICIO TESTE convetida do gimp convertida aqui tmb',
        PrintAlignment.CENTER, 30, 1, PrintOperation.text);

    CieloLioHelper.enqueue('$imgString340Cubic', PrintAlignment.CENTER, 100, 1,
        PrintOperation.image);

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
              TextField(
                controller: controller,
              ),
              ElevatedButton(
                  onPressed: () => printSampleTexts(), child: Text("Imprimir")),
              ElevatedButton(
                  onPressed: () => _printImage(), child: Text("print image")),
              ElevatedButton(
                  onPressed: () => _printImageSemResize(),
                  child: Text("print image sem resize")),
              ElevatedButton(
                  onPressed: () => _printImageComResize(),
                  child: Text("print image com resize nearest")),
              ElevatedButton(
                  onPressed: () => _printImageComResizeAverage(),
                  child: Text("print image com resize avegare")),
              ElevatedButton(
                  onPressed: () => _printImageRefeitoGimp(),
                  child: Text("_printImageRefeitoGimp")),
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
