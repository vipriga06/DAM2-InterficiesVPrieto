import 'dart:io';
import 'dart:math';

void main(List<String> arguments) {
  final game = _Minesweeper();
  game.start();
}

class _Minesweeper {
  static const int _rows = 6;
  static const int _cols = 10;
  static const int _mines = 8;
  static const List<String> _rowLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

  final List<List<_Cell>> _board = List.generate(
    _rows,
    (_) => List.generate(_cols, (_) => _Cell()),
  );
  final Random _rand = Random();

  bool _cheatMode = false;
  bool _gameOver = false;
  bool _hasWon = false;
  bool _firstMoveDone = false;
  int _turns = 0;

  void start() {
    _printIntro();
    _seedMines();
    while (!_gameOver) {
      _renderForTurn();
      stdout.write('Escriu una comanda: ');
      final input = stdin.readLineSync();
      if (input == null) {
        stdout.writeln('Entrada no vàlida.');
        continue;
      }
      _handleCommand(input.trim());
    }
    stdout.writeln(_renderBoard(showMines: false));
    stdout.writeln(_hasWon ? 'Has guanyat!' : 'Has perdut!');
    stdout.writeln('Número de tirades: $_turns');
  }

  void _renderForTurn() {
    stdout.writeln(_renderBoard(showMines: _cheatMode));
    if (_cheatMode) {
      stdout.writeln('Mode trampa activat (cheat).');
    }
  }

  String _renderBoard({required bool showMines}) {
    final buffer = StringBuffer();
    buffer.writeln(' 0123456789' + (showMines ? '      0123456789' : ''));
    for (var r = 0; r < _rows; r++) {
      final rowDisplay = StringBuffer('${_rowLabels[r]}');
      final cheatDisplay = StringBuffer('${_rowLabels[r]}');
      for (var c = 0; c < _cols; c++) {
        rowDisplay.write(_displayForCell(_board[r][c]));
        cheatDisplay.write(_cheatDisplay(_board[r][c]));
      }
      if (showMines) {
        buffer.writeln('${rowDisplay.toString()}${cheatDisplay.toString()}');
      } else {
        buffer.writeln(rowDisplay.toString());
      }
    }
    return buffer.toString();
  }

  String _displayForCell(_Cell cell) {
    if (cell.flagged) return '#';
    if (cell.hasMine && cell.revealed) return '*';
    if (!cell.revealed) return '·';
    if (cell.adjacentMines == 0) return ' ';
    return cell.adjacentMines.toString();
  }

  String _cheatDisplay(_Cell cell) {
    if (cell.hasMine) return '*';
    return _displayForCell(cell);
  }

  void _handleCommand(String command) {
    if (command.isEmpty) return;
    final lower = command.toLowerCase();
    if (lower == 'help' || lower == 'ajuda') {
      _printHelp();
      return;
    }
    if (lower == 'cheat' || lower == 'trampes') {
      _cheatMode = !_cheatMode;
      stdout.writeln(_cheatMode ? 'Trampes activades.' : 'Trampes desactivades.');
      return;
    }

    final parts = command.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      _handleReveal(parts[0]);
      return;
    }
    if (parts.length == 2) {
      final action = parts[1].toLowerCase();
      if (action == 'flag' || action == 'bandera') {
        _toggleFlag(parts[0]);
        return;
      }
    }
    stdout.writeln('Comanda desconeguda. Escriu "help" per ajudar-te.');
  }

  void _handleReveal(String positionRaw) {
    final pos = _parsePosition(positionRaw);
    if (pos == null) {
      stdout.writeln('Coordenada no vàlida. Ex: C3');
      return;
    }
    final cell = _board[pos.x][pos.y];
    if (cell.revealed) {
      stdout.writeln('La casella ${_formatPosition(pos)} ja està destapada.');
      return;
    }
    if (cell.flagged) {
      cell.flagged = false;
      stdout.writeln('Bandera retirada automàticament a ${_formatPosition(pos)}.');
    }
    final bool wasFirstMove = !_firstMoveDone;
    _firstMoveDone = true;
    final exploded = _revealCell(pos.x, pos.y, isFirstMove: wasFirstMove, isUserMove: true);
    _turns++;
    if (exploded) {
      _gameOver = true;
      _hasWon = false;
      _revealAllCells();
      return;
    }
    if (_hasWonCondition()) {
      _gameOver = true;
      _hasWon = true;
      _revealAllCells();
    }
  }

  void _toggleFlag(String positionRaw) {
    final pos = _parsePosition(positionRaw);
    if (pos == null) {
      stdout.writeln('Coordenada no vàlida. Ex: E1 bandera');
      return;
    }
    final cell = _board[pos.x][pos.y];
    if (cell.revealed) {
      stdout.writeln('No es pot posar bandera en una casella destapada.');
      return;
    }
    cell.flagged = !cell.flagged;
    stdout.writeln(cell.flagged
        ? 'Bandera col·locada a ${_formatPosition(pos)}.'
        : 'Bandera retirada de ${_formatPosition(pos)}.');
  }

  bool _revealCell(int row, int col, {required bool isFirstMove, required bool isUserMove}) {
    if (!_isInside(row, col)) return false;
    final cell = _board[row][col];
    if (cell.revealed || cell.flagged) {
      return false;
    }
    if (cell.hasMine) {
      if (isFirstMove) {
        _relocateMine(row, col);
      } else if (isUserMove) {
        return true;
      } else {
        return false;
      }
    }
    final refreshedCell = _board[row][col];
    if (refreshedCell.revealed) return false;
    refreshedCell.adjacentMines = _countAdjacent(row, col);
    refreshedCell.revealed = true;
    if (refreshedCell.adjacentMines == 0) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          final nr = row + dr;
          final nc = col + dc;
          if (_isInside(nr, nc)) {
            _revealCell(nr, nc, isFirstMove: false, isUserMove: false);
          }
        }
      }
    }
    return false;
  }

  void _relocateMine(int row, int col) {
    _board[row][col].hasMine = false;
    final targetQuadrant = _quadrant(row, col);
    final candidates = <Point<int>>[];
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final cell = _board[r][c];
        if (cell.hasMine || cell.revealed) continue;
        if (_quadrant(r, c) == targetQuadrant) {
          candidates.add(Point(r, c));
        }
      }
    }
    if (candidates.isEmpty) {
      for (var r = 0; r < _rows; r++) {
        for (var c = 0; c < _cols; c++) {
          final cell = _board[r][c];
          if (!cell.hasMine && !cell.revealed && !(r == row && c == col)) {
            candidates.add(Point(r, c));
          }
        }
      }
    }
    if (candidates.isEmpty) {
      throw StateError('No hi ha espais disponibles per moure la mina.');
    }
    final chosen = candidates[_rand.nextInt(candidates.length)];
    _board[chosen.x][chosen.y].hasMine = true;
  }

  void _seedMines() {
    final quadrants = List.generate(4, (_) => <Point<int>>[]);
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        quadrants[_quadrant(r, c)].add(Point(r, c));
      }
    }
    for (final quad in quadrants) {
      quad.shuffle(_rand);
    }
    final minesPerQuadrant = _mines ~/ 4;
    for (var q = 0; q < 4; q++) {
      for (var placed = 0; placed < minesPerQuadrant; placed++) {
        final point = quadrants[q][placed];
        _board[point.x][point.y].hasMine = true;
      }
    }
  }

  void _revealAllCells() {
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final cell = _board[r][c];
        cell.flagged = false;
        if (cell.hasMine) {
          cell.revealed = true;
        } else {
          cell.adjacentMines = _countAdjacent(r, c);
          cell.revealed = true;
        }
      }
    }
  }

  bool _hasWonCondition() {
    var revealedSafe = 0;
    for (final row in _board) {
      for (final cell in row) {
        if (!cell.hasMine && cell.revealed) revealedSafe++;
      }
    }
    return revealedSafe == (_rows * _cols - _mines);
  }

  int _countAdjacent(int row, int col) {
    var count = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final nr = row + dr;
        final nc = col + dc;
        if (_isInside(nr, nc) && _board[nr][nc].hasMine) {
          count++;
        }
      }
    }
    return count;
  }

  bool _isInside(int row, int col) => row >= 0 && row < _rows && col >= 0 && col < _cols;

  Point<int>? _parsePosition(String raw) {
    if (raw.length < 2) return null;
    final letter = raw[0].toUpperCase();
    final rowIndex = _rowLabels.indexOf(letter);
    if (rowIndex == -1) return null;
    final numberPart = raw.substring(1);
    final colIndex = int.tryParse(numberPart);
    if (colIndex == null || colIndex < 0 || colIndex >= _cols) return null;
    return Point(rowIndex, colIndex);
  }

  int _quadrant(int row, int col) {
    final bool top = row < (_rows / 2);
    final bool left = col < (_cols / 2);
    if (top && left) return 0;
    if (top && !left) return 1;
    if (!top && left) return 2;
    return 3;
  }

  String _formatPosition(Point<int> point) => '${_rowLabels[point.x]}${point.y}';

  void _printIntro() {
    stdout.writeln('Buscamines per línia de comandes (Exercici 03)');
    _printHelp();
  }

  void _printHelp() {
    stdout.writeln('Comandes disponibles:');
    stdout.writeln('- "B2" per destapar una casella.');
    stdout.writeln('- "B2 flag" o "B2 bandera" per posar/treure una bandera.');
    stdout.writeln('- "cheat" o "trampes" per mostrar/amagar el tauler amb mines.');
    stdout.writeln('- "help" o "ajuda" per mostrar aquesta llista.');
  }
}

class _Cell {
  bool hasMine = false;
  bool revealed = false;
  bool flagged = false;
  int adjacentMines = 0;
}
