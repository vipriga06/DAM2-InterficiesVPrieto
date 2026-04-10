import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'constants.dart';
import 'drawable.dart';

const streamingModel = 'granite4:3b';
const functionCallingModel = 'granite4:3b';
const jsonFixModel = 'granite4:3b';

class AppData extends ChangeNotifier {
  String _responseText = "";
  bool _isLoading = false;
  bool _isInitial = true;
  http.Client? _client;
  IOClient? _ioClient;
  HttpClient? _httpClient;
  StreamSubscription<String>? _streamSubscription;

  final List<Drawable> drawables = [];
  String? _selectedDrawableId;
  Size _canvasSize = const Size(800, 600);

  String get responseText =>
      _isInitial ? "..." : (_isLoading ? "Esperant ..." : _responseText);

  bool get isLoading => _isLoading;
  String? get selectedDrawableId => _selectedDrawableId;
  Drawable? get selectedDrawable =>
      _selectedDrawableId == null ? null : _findById(_selectedDrawableId!);
  Size get canvasSize => _canvasSize;

  AppData() {
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void addDrawable(Drawable drawable) {
    drawables.add(drawable);
    _selectedDrawableId = drawable.id;
    notifyListeners();
  }

  void updateCanvasSize(Size size) {
    if (size.width <= 0 || size.height <= 0) {
      return;
    }

    _canvasSize = size;
  }

  void selectAt(Offset point) {
    for (var i = drawables.length - 1; i >= 0; i--) {
      if (drawables[i].hitTest(point)) {
        _selectedDrawableId = drawables[i].id;
        notifyListeners();
        return;
      }
    }

    _selectedDrawableId = null;
    notifyListeners();
  }

  void deleteSelected() {
    if (_selectedDrawableId == null) {
      return;
    }
    drawables.removeWhere((d) => d.id == _selectedDrawableId);
    _selectedDrawableId = null;
    notifyListeners();
  }

  void updateSelectedFromUi(Map<String, dynamic> patch) {
    if (_selectedDrawableId == null) {
      return;
    }
    final target = _findById(_selectedDrawableId!);
    if (target == null) {
      return;
    }
    _updateDrawable(target, patch);
    notifyListeners();
  }

  Future<void> callStream({required String question}) async {
    _isInitial = false;
    setLoading(true);

    try {
      var request = http.Request(
        'POST',
        Uri.parse('http://localhost:11434/api/generate'),
      );

      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode(
          {'model': streamingModel, 'prompt': question, 'stream': true});

      var streamedResponse = await _client!.send(request);
      _streamSubscription =
          streamedResponse.stream.transform(utf8.decoder).listen((value) {
        var jsonResponse = jsonDecode(value);
        var jsonResponseStr = jsonResponse['response'];
        _responseText = "$_responseText\n$jsonResponseStr";
        notifyListeners();
      }, onError: (error) {
        if (error is http.ClientException &&
            error.message == 'Connection closed while receiving data') {
          _responseText += "\nRequest cancelled.";
        } else {
          _responseText += "\nError during streaming: $error";
        }
        setLoading(false);
        notifyListeners();
      }, onDone: () {
        setLoading(false);
      });
    } catch (e) {
      _responseText = "\nError during streaming.";
      setLoading(false);
      notifyListeners();
    }
  }

  Future<dynamic> fixJsonInStrings(dynamic data) async {
    if (data is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        result[entry.key] = await fixJsonInStrings(entry.value);
      }
      return result;
    } else if (data is List) {
      return Future.wait(data.map((value) => fixJsonInStrings(value)));
    } else if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty) {
        return data;
      }

      try {
        // Si és JSON dins d'una cadena, el deserialitzem
        final parsed = jsonDecode(data);
        return fixJsonInStrings(parsed);
      } catch (_) {
        if (_looksLikeJsonCandidate(trimmed)) {
          final repairedJson = await _repairJsonWithAi(trimmed);
          if (repairedJson != null) {
            return fixJsonInStrings(repairedJson);
          }
        }

        // Si no és JSON o no es pot reparar, retornem la cadena tal qual
        return data;
      }
    }
    // Retorna qualsevol altre tipus sense canvis (números, booleans, etc.)
    return data;
  }

  bool _looksLikeJsonCandidate(String value) {
    return value.startsWith('{') ||
        value.startsWith('[') ||
        ((value.contains('{') || value.contains('[')) && value.contains(':'));
  }

  Future<dynamic> _repairJsonWithAi(String rawJson) async {
    const apiUrl = 'http://localhost:11434/api/chat';
    final body = {
      "model": jsonFixModel,
      "stream": false,
      "format": "json",
      "messages": [
        {
          "role": "system",
          "content":
              "You repair malformed JSON. Return only valid JSON that preserves the original intent and values as closely as possible."
        },
        {
          "role": "user",
          "content":
              "Repair this malformed JSON and return only the fixed JSON:\n$rawJson"
        }
      ]
    };

    try {
      final response = await _client!.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        return null;
      }

      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['message']?['content'];
      if (content is! String || content.trim().isEmpty) {
        return null;
      }

      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  dynamic cleanKeys(dynamic value) {
    if (value is Map<String, dynamic>) {
      final result = <String, dynamic>{};
      value.forEach((k, v) {
        result[k.trim()] = cleanKeys(v);
      });
      return result;
    }
    if (value is List) {
      return value.map(cleanKeys).toList();
    }
    return value;
  }

  Future<void> callWithCustomTools({required String userPrompt}) async {
    const apiUrl = 'http://localhost:11434/api/chat';
    _isInitial = false;
    setLoading(true);

    final body = {
      "model": functionCallingModel,
      "stream": false,
      "messages": [
        {
          "role": "system",
          "content":
              "Sempre fes servir tool calls per dibuixar/editar/esborrar. Pots usar coordenades absolutes, percentatges (com 50%) o paraules relatives com meitat/centre/diagonal."
        },
        {
          "role": "system",
          "content":
              "Canvas: ${_canvasSize.width.toStringAsFixed(1)}x${_canvasSize.height.toStringAsFixed(1)}. SelectedId: ${_selectedDrawableId ?? 'none'}."
        },
        {
          "role": "system",
          "content": "Shapes: ${jsonEncode(_shapeSummaries())}"
        },
        {"role": "user", "content": userPrompt}
      ],
      "tools": tools
    };

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['message'] != null &&
            jsonResponse['message']['tool_calls'] != null) {
          final toolCalls = (jsonResponse['message']['tool_calls'] as List)
              .map((e) => cleanKeys(e))
              .toList();
          for (final tc in toolCalls) {
            if (tc['function'] != null) {
              await _processFunctionCall(tc['function']);
            }
          }
        }
        setLoading(false);
      } else {
        setLoading(false);
        throw Exception("Error: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error during API call: $e");
      setLoading(false);
    }
  }

  void cancelRequests() {
    _streamSubscription?.cancel();
    _httpClient?.close(force: true);
    _httpClient = HttpClient();
    _ioClient = IOClient(_httpClient!);
    _client = _ioClient;
    _responseText += "\nRequest cancelled.";
    setLoading(false);
    notifyListeners();
  }

  double parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _processFunctionCall(Map<String, dynamic> functionCall) async {
    final fixedJson = await fixJsonInStrings(functionCall);
    final parametersData = fixedJson['arguments'];
    final parameters = parametersData is Map<String, dynamic>
        ? parametersData
        : <String, dynamic>{};

    String name = fixedJson['name'];
    String infoText = "Draw $name: $parameters";

    debugPrint(infoText);
    _responseText = "$_responseText\n$infoText";

    switch (name) {
      case 'draw_circle':
        final dx = _parseCoordinate(parameters['x'], axis: Axis.horizontal);
        final dy = _parseCoordinate(parameters['y'], axis: Axis.vertical);
        final radius =
            _parseDistance(parameters['radius'], isMinCanvasReference: true);
        addDrawable(
          Circle(
            id: _newId(),
            center: Offset(dx, dy),
            radius: max(0.0, radius),
            strokeColor: _parseColor(parameters['strokeColor']) ?? Colors.black,
            strokeWidth: _parseDistance(parameters['strokeWidth'], fallback: 2),
            fill: FillStyle(
              mode: _parseFillMode(parameters['fillMode']),
              colorA: _parseColor(parameters['fillColorA']) ??
                  const Color(0xFF93C5FD),
              colorB: _parseColor(parameters['fillColorB']) ??
                  const Color(0xFF2563EB),
              angleDegrees:
                  _parseDistance(parameters['gradientAngle'], fallback: 45),
            ),
          ),
        );
        break;

      case 'draw_line':
        final startX =
            _parseCoordinate(parameters['startX'], axis: Axis.horizontal);
        final startY =
            _parseCoordinate(parameters['startY'], axis: Axis.vertical);
        final endX =
            _parseCoordinate(parameters['endX'], axis: Axis.horizontal);
        final endY = _parseCoordinate(parameters['endY'], axis: Axis.vertical);
        final start = Offset(startX, startY);
        final end = Offset(endX, endY);
        addDrawable(
          Line(
            id: _newId(),
            start: start,
            end: end,
            strokeColor: _parseColor(parameters['strokeColor']) ?? Colors.black,
            strokeWidth: _parseDistance(parameters['strokeWidth'], fallback: 2),
          ),
        );
        break;

      case 'draw_rectangle':
        final topLeft = Offset(
          _parseCoordinate(parameters['topLeftX'], axis: Axis.horizontal),
          _parseCoordinate(parameters['topLeftY'], axis: Axis.vertical),
        );
        final bottomRight = Offset(
          _parseCoordinate(parameters['bottomRightX'], axis: Axis.horizontal),
          _parseCoordinate(parameters['bottomRightY'], axis: Axis.vertical),
        );
        addDrawable(
          Rectangle(
            id: _newId(),
            topLeft: topLeft,
            bottomRight: bottomRight,
            strokeColor: _parseColor(parameters['strokeColor']) ?? Colors.black,
            strokeWidth: _parseDistance(parameters['strokeWidth'], fallback: 2),
            fill: FillStyle(
              mode: _parseFillMode(parameters['fillMode']),
              colorA: _parseColor(parameters['fillColorA']) ??
                  const Color(0xFFFDE68A),
              colorB: _parseColor(parameters['fillColorB']) ??
                  const Color(0xFFF97316),
              angleDegrees:
                  _parseDistance(parameters['gradientAngle'], fallback: 45),
            ),
          ),
        );
        break;

      case 'draw_text':
        addDrawable(
          TextElement(
            id: _newId(),
            text: (parameters['text'] ?? 'Text').toString(),
            position: Offset(
              _parseCoordinate(parameters['x'], axis: Axis.horizontal),
              _parseCoordinate(parameters['y'], axis: Axis.vertical),
            ),
            color: _parseColor(parameters['color']) ?? Colors.black,
            fontFamily: (parameters['fontFamily'] ?? 'Roboto').toString(),
            fontSize: _parseDistance(parameters['fontSize'], fallback: 16),
            fontWeight: _parseFontWeight(parameters['fontWeight']),
            fontStyle: _parseFontStyle(parameters['fontStyle']),
          ),
        );
        break;

      case 'select_shape':
        final id = (parameters['id'] ?? '').toString();
        if (id.isNotEmpty && _findById(id) != null) {
          _selectedDrawableId = id;
          notifyListeners();
        }
        break;

      case 'delete_shape':
        final id = (parameters['id'] ?? '').toString();
        final removeSelected = parameters['selected'] == true || id.isEmpty;
        if (removeSelected) {
          deleteSelected();
        } else {
          drawables.removeWhere((d) => d.id == id);
          if (_selectedDrawableId == id) {
            _selectedDrawableId = null;
          }
          notifyListeners();
        }
        break;

      case 'update_shape':
        final id = (parameters['id'] ?? '').toString();
        final target = _resolveEditableTarget(
          explicitId: id,
          useSelected: parameters['selected'] == true || id.isEmpty,
        );
        if (target != null) {
          _updateDrawable(target, parameters);
          _selectedDrawableId = target.id;
          notifyListeners();
        }
        break;

      default:
        debugPrint("Unknown function call: ${fixedJson['name']}");
    }
  }

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(9999)}';

  List<Map<String, dynamic>> _shapeSummaries() {
    return drawables.map((d) {
      if (d is Line) {
        return {"id": d.id, "type": "line"};
      }
      if (d is Rectangle) {
        return {"id": d.id, "type": "rectangle"};
      }
      if (d is Circle) {
        return {"id": d.id, "type": "circle"};
      }
      if (d is TextElement) {
        return {"id": d.id, "type": "text", "text": d.text};
      }
      return {"id": d.id, "type": "unknown"};
    }).toList();
  }

  Drawable? _findById(String id) {
    for (final d in drawables) {
      if (d.id == id) {
        return d;
      }
    }
    return null;
  }

  Drawable? _resolveEditableTarget(
      {required String explicitId, required bool useSelected}) {
    if (explicitId.isNotEmpty) {
      return _findById(explicitId);
    }
    if (useSelected && _selectedDrawableId != null) {
      return _findById(_selectedDrawableId!);
    }
    return null;
  }

  void _updateDrawable(Drawable drawable, Map<String, dynamic> p) {
    if (drawable is Line) {
      drawable.start = Offset(
        _parseCoordinate(p['startX'] ?? p['x'] ?? drawable.start.dx,
            axis: Axis.horizontal),
        _parseCoordinate(p['startY'] ?? drawable.start.dy, axis: Axis.vertical),
      );
      drawable.end = Offset(
        _parseCoordinate(p['endX'] ?? drawable.end.dx, axis: Axis.horizontal),
        _parseCoordinate(p['endY'] ?? p['y'] ?? drawable.end.dy,
            axis: Axis.vertical),
      );
      drawable.strokeColor =
          _parseColor(p['strokeColor']) ?? drawable.strokeColor;
      drawable.strokeWidth =
          _parseDistance(p['strokeWidth'], fallback: drawable.strokeWidth);
      return;
    }

    if (drawable is Rectangle) {
      drawable.topLeft = Offset(
        _parseCoordinate(p['topLeftX'] ?? p['x'] ?? drawable.topLeft.dx,
            axis: Axis.horizontal),
        _parseCoordinate(p['topLeftY'] ?? p['y'] ?? drawable.topLeft.dy,
            axis: Axis.vertical),
      );
      drawable.bottomRight = Offset(
        _parseCoordinate(p['bottomRightX'] ?? drawable.bottomRight.dx,
            axis: Axis.horizontal),
        _parseCoordinate(p['bottomRightY'] ?? drawable.bottomRight.dy,
            axis: Axis.vertical),
      );
      drawable.strokeColor =
          _parseColor(p['strokeColor']) ?? drawable.strokeColor;
      drawable.strokeWidth =
          _parseDistance(p['strokeWidth'], fallback: drawable.strokeWidth);
      drawable.fill = drawable.fill.copyWith(
        mode: _parseFillMode(p['fillMode'], fallback: drawable.fill.mode),
        colorA: _parseColor(p['fillColorA']) ?? drawable.fill.colorA,
        colorB: _parseColor(p['fillColorB']) ?? drawable.fill.colorB,
        angleDegrees: _parseDistance(p['gradientAngle'],
            fallback: drawable.fill.angleDegrees),
      );
      return;
    }

    if (drawable is Circle) {
      drawable.center = Offset(
        _parseCoordinate(p['x'] ?? drawable.center.dx, axis: Axis.horizontal),
        _parseCoordinate(p['y'] ?? drawable.center.dy, axis: Axis.vertical),
      );
      drawable.radius =
          max(1, _parseDistance(p['radius'], fallback: drawable.radius));
      drawable.strokeColor =
          _parseColor(p['strokeColor']) ?? drawable.strokeColor;
      drawable.strokeWidth =
          _parseDistance(p['strokeWidth'], fallback: drawable.strokeWidth);
      drawable.fill = drawable.fill.copyWith(
        mode: _parseFillMode(p['fillMode'], fallback: drawable.fill.mode),
        colorA: _parseColor(p['fillColorA']) ?? drawable.fill.colorA,
        colorB: _parseColor(p['fillColorB']) ?? drawable.fill.colorB,
        angleDegrees: _parseDistance(p['gradientAngle'],
            fallback: drawable.fill.angleDegrees),
      );
      return;
    }

    if (drawable is TextElement) {
      drawable.text = (p['text'] ?? drawable.text).toString();
      drawable.position = Offset(
        _parseCoordinate(p['x'] ?? drawable.position.dx, axis: Axis.horizontal),
        _parseCoordinate(p['y'] ?? drawable.position.dy, axis: Axis.vertical),
      );
      drawable.color = _parseColor(p['color']) ?? drawable.color;
      drawable.fontFamily = (p['fontFamily'] ?? drawable.fontFamily).toString();
      drawable.fontSize =
          _parseDistance(p['fontSize'], fallback: drawable.fontSize);
      drawable.fontWeight =
          _parseFontWeight(p['fontWeight'], fallback: drawable.fontWeight);
      drawable.fontStyle =
          _parseFontStyle(p['fontStyle'], fallback: drawable.fontStyle);
    }
  }

  double _parseCoordinate(dynamic value, {required Axis axis}) {
    final maxValue =
        axis == Axis.horizontal ? _canvasSize.width : _canvasSize.height;
    if (value == null) {
      return maxValue / 2;
    }

    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().toLowerCase().trim();
    if (text.isEmpty) {
      return maxValue / 2;
    }

    if (text.endsWith('%')) {
      final pct = double.tryParse(text.substring(0, text.length - 1));
      if (pct != null) {
        return (pct / 100.0) * maxValue;
      }
    }

    if (text.contains('meitat') ||
        text.contains('mitad') ||
        text.contains('center') ||
        text.contains('centre')) {
      return maxValue / 2;
    }

    if (text.contains('diagonal') ||
        text.contains('bottom') ||
        text.contains('dreta') ||
        text.contains('derecha')) {
      return maxValue;
    }

    if (text.contains('top') ||
        text.contains('esquerra') ||
        text.contains('izquierda')) {
      return 0;
    }

    final number = double.tryParse(text);
    return number ?? maxValue / 2;
  }

  double _parseDistance(dynamic value,
      {double fallback = 10, bool isMinCanvasReference = false}) {
    final maxValue = isMinCanvasReference
        ? min(_canvasSize.width, _canvasSize.height)
        : max(_canvasSize.width, _canvasSize.height);
    if (value == null) {
      return fallback;
    }
    if (value is num) {
      return value.toDouble();
    }

    final text = value.toString().toLowerCase().trim();
    if (text.endsWith('%')) {
      final pct = double.tryParse(text.substring(0, text.length - 1));
      if (pct != null) {
        return (pct / 100.0) * maxValue;
      }
    }

    return double.tryParse(text) ?? fallback;
  }

  FillMode _parseFillMode(dynamic value, {FillMode fallback = FillMode.solid}) {
    final text = (value ?? '').toString().toLowerCase().trim();
    switch (text) {
      case 'none':
        return FillMode.none;
      case 'linear':
        return FillMode.linear;
      case 'radial':
        return FillMode.radial;
      case 'solid':
        return FillMode.solid;
      default:
        return fallback;
    }
  }

  Color? _parseColor(dynamic value) {
    if (value == null) {
      return null;
    }

    final text = value.toString().trim().toLowerCase();
    if (text.isEmpty) {
      return null;
    }

    const named = {
      'red': Colors.red,
      'vermell': Colors.red,
      'blue': Colors.blue,
      'blau': Colors.blue,
      'green': Colors.green,
      'verd': Colors.green,
      'black': Colors.black,
      'negre': Colors.black,
      'white': Colors.white,
      'blanc': Colors.white,
      'yellow': Colors.yellow,
      'groc': Colors.yellow,
      'orange': Colors.orange,
      'taronja': Colors.orange,
      'purple': Colors.purple,
      'lila': Colors.purple,
      'gray': Colors.grey,
      'grey': Colors.grey,
      'gris': Colors.grey,
    };
    if (named.containsKey(text)) {
      return named[text];
    }

    final normalized = text.startsWith('#') ? text.substring(1) : text;
    if (normalized.length == 6) {
      final parsed = int.tryParse('ff$normalized', radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }
    if (normalized.length == 8) {
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }

    return null;
  }

  FontWeight _parseFontWeight(dynamic value,
      {FontWeight fallback = FontWeight.normal}) {
    final text = (value ?? '').toString().toLowerCase().trim();
    if (text == 'bold' || text == '700') {
      return FontWeight.bold;
    }
    if (text == 'normal' || text == '400') {
      return FontWeight.normal;
    }
    return fallback;
  }

  FontStyle _parseFontStyle(dynamic value,
      {FontStyle fallback = FontStyle.normal}) {
    final text = (value ?? '').toString().toLowerCase().trim();
    if (text == 'italic') {
      return FontStyle.italic;
    }
    if (text == 'normal') {
      return FontStyle.normal;
    }
    return fallback;
  }
}
