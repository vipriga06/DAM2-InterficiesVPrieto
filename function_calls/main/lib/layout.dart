import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cupertino_desktop_kit/cdk.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';
import 'canvas_painter.dart';
import 'drawable.dart';

class Layout extends StatefulWidget {
  const Layout({super.key, required this.title});

  final String title;

  @override
  State<Layout> createState() => _LayoutState();
}

class _LayoutState extends State<Layout> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  final random = Random();
  final placeholders = [
    'Dibuixa una línia 10, 50 i 100, 25 ...',
    'Dibuixa dues linies i dos cercles',
    'Dibuixa un cercle amb centre a 150, 200 i radi 50 ...',
    'Fes un rectangle entre x=10, y=20 i x=100, y=200 ...',
    'Dibuixa un cercle a la posició 50,100 de radi 34.66',
    'Dibuixa un rectangle al 50% d\'amplada i meitat d\'alcada',
    'Canvia el polígon seleccionat a gradient radial vermell-groc',
    'Escriu "Hola" en negreta i italic al centre',
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context);
    final selected = appData.selectedDrawable;

    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(
          middle: Text(widget.title),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: CupertinoColors.systemGrey5,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          appData.updateCanvasSize(
                            Size(constraints.maxWidth, constraints.maxHeight),
                          );
                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              appData.selectAt(details.localPosition);
                            },
                            child: CustomPaint(
                              painter: CanvasPainter(
                                drawables: appData.drawables,
                                selectedId: appData.selectedDrawableId,
                              ),
                              child: Container(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: CupertinoScrollbar(
                              controller: _scrollController,
                              child: SingleChildScrollView(
                                controller: _scrollController,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        appData.responseText,
                                        style: const TextStyle(fontSize: 16.0),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Seleccionat: ${selected == null ? 'cap' : '${selected.runtimeType} (${selected.id})'}',
                                        style: const TextStyle(fontSize: 14.0),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Mida canvas: ${appData.canvasSize.width.toStringAsFixed(0)} x ${appData.canvasSize.height.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 13.0),
                                      ),
                                      const SizedBox(height: 8),
                                      if (selected != null)
                                        _selectedDetails(selected),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          width: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CDKFieldText(
                              maxLines: 5,
                              controller: _textController,
                              placeholder: placeholders[
                                  random.nextInt(placeholders.length)],
                              enabled:
                                  !appData.isLoading, // Desactiva si carregant
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: CDKButton(
                                  style: CDKButtonStyle.action,
                                  onPressed: appData.isLoading
                                      ? null
                                      : () {
                                          final userPrompt =
                                              _textController.text;
                                          appData.callWithCustomTools(
                                              userPrompt: userPrompt);
                                        },
                                  child: const Text('Query'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CDKButton(
                                  onPressed: appData.selectedDrawableId == null
                                      ? null
                                      : () => appData.deleteSelected(),
                                  child: const Text('Delete Selected'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CDKButton(
                                  onPressed: appData.isLoading
                                      ? () => appData.cancelRequests()
                                      : null,
                                  child: const Text('Cancel'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (appData.isLoading)
                Positioned.fill(
                  child: Container(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.5),
                    child: const Center(
                      child: CupertinoActivityIndicator(
                        radius: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }

  Widget _selectedDetails(Drawable selected) {
    if (selected is Line) {
      return Text(
        'Line: (${selected.start.dx.toStringAsFixed(1)}, ${selected.start.dy.toStringAsFixed(1)}) -> (${selected.end.dx.toStringAsFixed(1)}, ${selected.end.dy.toStringAsFixed(1)})',
      );
    }
    if (selected is Rectangle) {
      return Text(
        'Rectangle: TL(${selected.topLeft.dx.toStringAsFixed(1)}, ${selected.topLeft.dy.toStringAsFixed(1)}) BR(${selected.bottomRight.dx.toStringAsFixed(1)}, ${selected.bottomRight.dy.toStringAsFixed(1)})',
      );
    }
    if (selected is Circle) {
      return Text(
        'Circle: C(${selected.center.dx.toStringAsFixed(1)}, ${selected.center.dy.toStringAsFixed(1)}) R=${selected.radius.toStringAsFixed(1)}',
      );
    }
    if (selected is TextElement) {
      return Text(
        'Text: "${selected.text}" @ (${selected.position.dx.toStringAsFixed(1)}, ${selected.position.dy.toStringAsFixed(1)})',
      );
    }
    return const SizedBox.shrink();
  }
}
