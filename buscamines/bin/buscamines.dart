import 'dart:io';
import 'dart:math';

const int boardRows = 6;
const int boardCols = 10;
const int totalMines = 8;
const int minesPerQuadrant = 2;
const String hiddenCellChar = '·';

void main() => MinesweeperGame().run();

class Cell {
  bool mine = false;
  bool open = false;
  bool flag = false;
  int n = 0;
}

class MinesweeperGame {
  MinesweeperGame() {
    _placeInitialMines();
  }

  final _r = Random();
  final List<List<Cell>> _board = List.generate(
    boardRows,
    (_) => List.generate(boardCols, (_) => Cell()),
  );

  bool _firstMove = true;
  bool _cheat = false;
  bool _gameOver = false;
  int _turns = 0;

  void run() {
    stdout.writeln('Buscamines (A-F, 0-9)');
    _help();
    while (!_gameOver) {
      _printBoard();
      stdout.write('Escriu una comanda: ');
      final cmd = stdin.readLineSync()?.trim();
      if (cmd == null) {
        stdout.writeln('\nSortint del joc.');
        return;
      }
      if (cmd.isNotEmpty) _handle(cmd);
    }
  }

  void _handle(String cmd) {
    final lower = cmd.toLowerCase();
    if (lower == 'help' || lower == 'ajuda') return _help();
    if (lower == 'cheat' || lower == 'trampes' || lower == 'trampa') {
      _cheat = !_cheat;
      stdout.writeln(_cheat ? 'Trampes activades.' : 'Trampes desactivades.');
      return;
    }

    final p = _parse(cmd);
    if (p == null) {
      stdout.writeln('Comanda no valida. Escriu "help" o "ajuda".');
      return;
    }

    final row = p.$1, col = p.$2, action = p.$3;
    if (action == 'flag' || action == 'bandera') return _toggleFlag(row, col);
    if (action != null) {
      stdout.writeln('Accio no valida. Usa "flag" o "bandera".');
      return;
    }

    final wasOpen = _cell(row, col).open;
    final exploded = _reveal(row, col, firstMove: _firstMove, userMove: true);
    if (!wasOpen) _turns++;
    _firstMove = false;

    if (exploded) return _end(false);
    if (_openedSafeCells() == boardRows * boardCols - totalMines) _end(true);
  }

  bool _reveal(
    int row,
    int col, {
    required bool firstMove,
    required bool userMove,
  }) {
    if (!_inside(row, col)) return false;
    final c = _cell(row, col);
    if (c.open) return false;

    if (c.flag) {
      if (!userMove) return false;
      c.flag = false;
    }

    if (c.mine) {
      if (firstMove) {
        _moveMine(row, col);
      } else {
        return userMove;
      }
    }

    final mines = _adjacentMines(row, col);
    c.open = true;
    c.n = mines;

    if (mines == 0) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr != 0 || dc != 0)
            _reveal(row + dr, col + dc, firstMove: false, userMove: false);
        }
      }
    }
    return false;
  }

  void _toggleFlag(int row, int col) {
    final c = _cell(row, col);
    if (c.open) {
      stdout.writeln('Aquesta casella ja esta descoberta.');
      return;
    }
    c.flag = !c.flag;
    stdout.writeln(c.flag ? 'Bandera posada.' : 'Bandera treta.');
  }

  void _end(bool won) {
    _gameOver = true;
    _printBoard(showMines: true);
    stdout.writeln(won ? 'Has guanyat!' : 'Has perdut!');
    stdout.writeln('Numero de tirades: $_turns');
  }

  void _printBoard({bool showMines = false}) {
    final left = _boardLines(showMines);
    if (_cheat && !showMines) {
      final right = _boardLines(true);
      for (var i = 0; i < left.length; i++)
        stdout.writeln('${left[i]}     ${right[i]}');
      return;
    }
    for (final line in left) stdout.writeln(line);
  }

  List<String> _boardLines(bool showMines) {
    final out = <String>[' 0123456789'];
    for (var r = 0; r < boardRows; r++) {
      final line = StringBuffer(String.fromCharCode('A'.codeUnitAt(0) + r));
      for (var c = 0; c < boardCols; c++)
        line.write(_char(_cell(r, c), showMines));
      out.add(line.toString());
    }
    return out;
  }

  String _char(Cell c, bool showMines) {
    if (c.open) {
      if (c.mine) return '*';
      final n = c.n;
      return n == 0 ? ' ' : '$n';
    }
    if (c.flag && !showMines) return '#';
    if (showMines && c.mine) return '*';
    return hiddenCellChar;
  }

  void _help() {
    stdout.writeln('Comandes disponibles:');
    stdout.writeln('  A0..F9            -> destapar casella');
    stdout.writeln('  A0 flag           -> posar o treure bandera');
    stdout.writeln('  A0 bandera        -> posar o treure bandera');
    stdout.writeln('  cheat | trampes   -> mostrar/amagar mines');
    stdout.writeln('  help | ajuda      -> mostrar ajuda');
  }

  (int, int, String?)? _parse(String cmd) {
    final m = RegExp(r'^([A-Fa-f])\s*([0-9])(?:\s+(\w+))?$').firstMatch(cmd);
    if (m == null) return null;
    final row = m.group(1)!.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
    final col = int.parse(m.group(2)!);
    final action = m.group(3)?.toLowerCase();
    return (row, col, action);
  }

  bool _inside(int row, int col) =>
      row >= 0 && row < boardRows && col >= 0 && col < boardCols;
  Cell _cell(int row, int col) => _board[row][col];

  int _adjacentMines(int row, int col) {
    var mines = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        if ((dr != 0 || dc != 0) &&
            _inside(row + dr, col + dc) &&
            _cell(row + dr, col + dc).mine) {
          mines++;
        }
      }
    }
    return mines;
  }

  int _openedSafeCells() {
    var count = 0;
    for (final row in _board) {
      for (final c in row) if (!c.mine && c.open) count++;
    }
    return count;
  }

  void _placeInitialMines() {
    _placeMinesInQuadrant(0, 2, 0, 4);
    _placeMinesInQuadrant(0, 2, 5, 9);
    _placeMinesInQuadrant(3, 5, 0, 4);
    _placeMinesInQuadrant(3, 5, 5, 9);
  }

  void _placeMinesInQuadrant(int r0, int r1, int c0, int c1) {
    final pos = <(int, int)>[];
    for (var r = r0; r <= r1; r++) {
      for (var c = c0; c <= c1; c++) pos.add((r, c));
    }
    pos.shuffle(_r);
    for (var i = 0; i < minesPerQuadrant; i++) {
      final p = pos[i];
      _cell(p.$1, p.$2).mine = true;
    }
  }

  void _moveMine(int row, int col) {
    _cell(row, col).mine = false;
    final free = <(int, int)>[];
    for (var r = 0; r < boardRows; r++) {
      for (var c = 0; c < boardCols; c++) {
        final cell = _cell(r, c);
        if (!cell.mine && !cell.open && !cell.flag) free.add((r, c));
      }
    }
    if (free.isNotEmpty) {
      final p = free[_r.nextInt(free.length)];
      _cell(p.$1, p.$2).mine = true;
    } else {
      _cell(row, col).mine = true;
    }
  }
}
