import 'dart:collection';

import 'package:flutter/services.dart';

import '../lio_response.dart';

class QueueManager {
  final MethodChannel? _messagesChannel;
  Queue<String>? _queue = Queue();
  Function(LioResponse response)? callback;

  QueueManager({MethodChannel? messagesChannel})
      : this._messagesChannel = messagesChannel;

  processResponse(LioResponse response) {
    if (_queue!.isEmpty) return;
    _queue!.removeFirst();
    if (_queue!.isNotEmpty) {
      _invokeMethodPrint(_queue!.first);
    } else {
      if (this.callback != null) {
        this.callback!.call(response);
        this.callback = null;
      }
    }
  }

  enqueue(String uri) {
    _queue!.add(uri);
  }

  clear() {
    _queue!.clear();
  }

  print(Function(LioResponse code) callback) async {
    this.callback = callback;
    await _invokeMethodPrint(_queue!.first);
  }

  _invokeMethodPrint(String uri) async {
    await _messagesChannel!.invokeMethod('print', {"uri": uri});
  }
}
