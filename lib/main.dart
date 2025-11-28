import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const AreaApp());
}

class AreaApp extends StatelessWidget {
  const AreaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AreaWiz',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Courier', // Monospaced font looks cool/technical
      ),
      home: const ShapeMorphScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. DATA MODELS & SHAPE LOGIC
// ---------------------------------------------------------------------------

enum ShapeType {
  loading, // For the chaotic start
  triangle,
  rectangle,
  circle,
  trapezoid,
  box,
  cylinder,
  cone,
}

class ShapeConfig {
  final String name;
  final List<String> inputs;
  final Function(List<double>) calculate;

  ShapeConfig(this.name, this.inputs, this.calculate);
}

// Map of logic for inputs and calculation
final Map<ShapeType, ShapeConfig> shapeConfigs = {
  ShapeType.triangle: ShapeConfig("TRIANGLE", [
    "Base",
    "Height",
  ], (v) => 0.5 * v[0] * v[1]),
  ShapeType.rectangle: ShapeConfig("RECTANGLE", [
    "Length",
    "Width",
  ], (v) => v[0] * v[1]),
  ShapeType.circle: ShapeConfig("CIRCLE", [
    "Radius",
  ], (v) => math.pi * v[0] * v[0]),
  ShapeType.trapezoid: ShapeConfig("TRAPEZOID", [
    "Base A",
    "Base B",
    "Height",
  ], (v) => 0.5 * (v[0] + v[1]) * v[2]),
  ShapeType.box: ShapeConfig("BOX (Surface Area)", [
    "Length",
    "Width",
    "Height",
  ], (v) => 2 * (v[0] * v[1] + v[1] * v[2] + v[2] * v[0])),
  ShapeType.cylinder: ShapeConfig("CYLINDER", [
    "Radius",
    "Height",
  ], (v) => 2 * math.pi * v[0] * (v[0] + v[1])),
  ShapeType.cone: ShapeConfig("CONE", ["Radius", "Height"], (v) {
    double r = v[0];
    double h = v[1];
    double s = math.sqrt(r * r + h * h);
    return math.pi * r * (r + s);
  }),
};

// ---------------------------------------------------------------------------
// 2. PARTICLE MATH ENGINE
// ---------------------------------------------------------------------------

class PointGenerator {
  static const int particleCount = 120; // Number of floating dots

  // Generates target coordinates (0.0 to 1.0 scale) for shapes
  static List<Offset> getPoints(ShapeType type) {
    List<Offset> points = [];

    switch (type) {
      case ShapeType.loading:
        // Random chaos
        for (int i = 0; i < particleCount; i++) {
          points.add(
            Offset(math.Random().nextDouble(), math.Random().nextDouble()),
          );
        }
        break;

      case ShapeType.circle:
        for (int i = 0; i < particleCount; i++) {
          double theta = (i / particleCount) * 2 * math.pi;
          points.add(
            Offset(0.5 + 0.35 * math.cos(theta), 0.5 + 0.35 * math.sin(theta)),
          );
        }
        break;

      case ShapeType.rectangle:
        int side = particleCount ~/ 4;
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.2 + (i / side) * 0.6, 0.2)); // Top
        }
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.8, 0.2 + (i / side) * 0.6)); // Right
        }
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.8 - (i / side) * 0.6, 0.8)); // Bottom
        }
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.2, 0.8 - (i / side) * 0.6)); // Left
        }
        break;

      case ShapeType.triangle:
        int side = particleCount ~/ 3;
        for (int i = 0; i < side; i++) {
          points.add(
            Offset(0.5 + (i / side) * 0.3, 0.2 + (i / side) * 0.6),
          ); // Right slope
        }
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.8 - (i / side) * 0.6, 0.8)); // Bottom
        }
        for (int i = 0; i < side; i++) {
          points.add(
            Offset(0.2 + (i / side) * 0.3, 0.8 - (i / side) * 0.6),
          ); // Left slope
        }
        break;

      case ShapeType.trapezoid:
        // Trapezoid: narrow top, wide bottom
        int side = particleCount ~/ 4;
        // Top edge (center, narrow: 0.35 to 0.65)
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.35 + (i / side) * 0.3, 0.3));
        }
        // Right slope (angled outward)
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.65 + (i / side) * 0.15, 0.3 + (i / side) * 0.5));
        }
        // Bottom edge (wide: 0.8 to 0.2)
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.8 - (i / side) * 0.6, 0.8));
        }
        // Left slope (angled outward)
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.2 + (i / side) * 0.15, 0.8 - (i / side) * 0.5));
        }
        break;

      case ShapeType.cone:
        // Cone: triangle profile with curved bottom (3D cone projection)
        int side = particleCount ~/ 3;
        // Right slope from apex to base
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.5 + (i / side) * 0.3, 0.2 + (i / side) * 0.6));
        }
        // Curved bottom edge (elliptical arc)
        for (int i = 0; i < side; i++) {
          double theta = (i / side) * math.pi; // Half circle
          points.add(
            Offset(
              0.8 - 0.6 * (1 - math.cos(theta)) / 2,
              0.8 + 0.05 * math.sin(theta), // Slight curve downward
            ),
          );
        }
        // Left slope from base to apex
        for (int i = 0; i < side; i++) {
          points.add(Offset(0.2 + (i / side) * 0.3, 0.8 - (i / side) * 0.6));
        }
        break;

      case ShapeType.cylinder:
        // Top Ellipse, Bottom Ellipse, Sides
        int circlePts = 40;
        int linePts = 20;
        // Top circle
        for (int i = 0; i < circlePts; i++) {
          double theta = (i / circlePts) * 2 * math.pi;
          points.add(
            Offset(0.5 + 0.3 * math.cos(theta), 0.25 + 0.05 * math.sin(theta)),
          );
        }
        // Bottom circle
        for (int i = 0; i < circlePts; i++) {
          double theta = (i / circlePts) * 2 * math.pi;
          points.add(
            Offset(0.5 + 0.3 * math.cos(theta), 0.75 + 0.05 * math.sin(theta)),
          );
        }
        // Sides
        for (int i = 0; i < linePts; i++) {
          points.add(Offset(0.2, 0.25 + (i / linePts) * 0.5));
        }
        for (int i = 0; i < linePts; i++) {
          points.add(Offset(0.8, 0.25 + (i / linePts) * 0.5));
        }
        break;

      case ShapeType.box: // 3D Cube wireframe projection
        // Front face: (0.3,0.3) to (0.7,0.7)
        // Back face: (0.4, 0.2) to (0.8, 0.6)
        // Simplified: Just 2 squares and connectors
        int sqPts = 40;
        int conPts = 10;
        // Front Square
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.25 + (i / (sqPts / 4)) * 0.4, 0.35)); // Top
        }
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.65, 0.35 + (i / (sqPts / 4)) * 0.4)); // Right
        }
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.65 - (i / (sqPts / 4)) * 0.4, 0.75)); // Bottom
        }
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.25, 0.75 - (i / (sqPts / 4)) * 0.4)); // Left
        }

        // Back Square (Offset up/right)
        double ox = 0.15;
        double oy = -0.15;
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.25 + ox + (i / (sqPts / 4)) * 0.4, 0.35 + oy));
        }
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.65 + ox, 0.35 + oy + (i / (sqPts / 4)) * 0.4));
        }
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.65 + ox - (i / (sqPts / 4)) * 0.4, 0.75 + oy));
        }
        for (int i = 0; i < sqPts / 4; i++) {
          points.add(Offset(0.25 + ox, 0.75 + oy - (i / (sqPts / 4)) * 0.4));
        }

        // Connectors
        for (int i = 0; i < conPts; i++) {
          points.add(Offset(0.25 + i / conPts * ox, 0.35 + i / conPts * oy));
        }
        for (int i = 0; i < conPts; i++) {
          points.add(Offset(0.65 + i / conPts * ox, 0.35 + i / conPts * oy));
        }
        for (int i = 0; i < conPts; i++) {
          points.add(Offset(0.65 + i / conPts * ox, 0.75 + i / conPts * oy));
        }
        for (int i = 0; i < conPts; i++) {
          points.add(Offset(0.25 + i / conPts * ox, 0.75 + i / conPts * oy));
        }
        break;
    }

    // Fill remaining if math was slightly off
    while (points.length < particleCount) {
      points.add(points.last);
    }
    // Truncate if too many
    if (points.length > particleCount) {
      points = points.sublist(0, particleCount);
    }
    return points;
  }
}

// ---------------------------------------------------------------------------
// 3. MAIN SCREEN
// ---------------------------------------------------------------------------

class ShapeMorphScreen extends StatefulWidget {
  const ShapeMorphScreen({super.key});

  @override
  State<ShapeMorphScreen> createState() => _ShapeMorphScreenState();
}

class _ShapeMorphScreenState extends State<ShapeMorphScreen>
    with TickerProviderStateMixin {
  ShapeType currentShape = ShapeType.loading;
  ShapeType targetShape = ShapeType.loading;

  // Animation Controller for morphing
  late AnimationController _morphController;
  late Animation<double> _morphAnimation;

  // Animation Controller for continuous floating
  late AnimationController _floatController;

  // Page Controller for bottom selector
  late PageController _pageController;

  // Input Controllers
  List<TextEditingController> _inputControllers = [];
  String _resultText = "";

  // Loading sequence state
  bool _isLoadingSequence = true;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _morphAnimation = CurvedAnimation(
      parent: _morphController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    // Continuous floating animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _pageController = PageController(viewportFraction: 0.25, initialPage: 0);

    // Start the splash sequence
    _runOpeningSequence();
  }

  @override
  void dispose() {
    // Clean up animation controllers
    _morphController.dispose();
    _floatController.dispose();
    _pageController.dispose();

    // Clean up input controllers
    for (var controller in _inputControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void _runOpeningSequence() async {
    // Speed up for intro (adjusted: 500ms)
    _morphController.duration = const Duration(milliseconds: 500);

    // Defines the order of shapes for the loading animation
    final sequence = [
      ShapeType.triangle,
      ShapeType.cone,
      ShapeType.cylinder,
      ShapeType.rectangle,
      ShapeType.circle,
    ];

    for (var shape in sequence) {
      if (!mounted) return;
      setState(() {
        currentShape = targetShape;
        targetShape = shape;
      });
      _morphController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 560));
    }

    if (!mounted) return;
    setState(() {
      _isLoadingSequence = false;
      // Settle on the first actual option
      currentShape = targetShape;
      targetShape = ShapeType.triangle; // Starting selection
      _generateInputControllers(ShapeType.triangle);
    });
    await _morphController.forward(from: 0);

    if (!mounted) return;
    // Reset to normal speed
    _morphController.duration = const Duration(milliseconds: 800);
  }

  void _generateInputControllers(ShapeType type) {
    for (var c in _inputControllers) {
      c.dispose();
    }
    _inputControllers = [];
    _resultText = "";
    if (shapeConfigs.containsKey(type)) {
      for (var _ in shapeConfigs[type]!.inputs) {
        _inputControllers.add(TextEditingController());
      }
    }
  }

  void _onShapeSelected(int index) {
    // Mapping PageView index to Enum (skipping 'loading')
    final actualShapes = ShapeType.values
        .where((s) => s != ShapeType.loading)
        .toList();
    final newShape = actualShapes[index];

    if (newShape != targetShape) {
      setState(() {
        currentShape = targetShape;
        targetShape = newShape;
        _generateInputControllers(newShape);
      });
      _morphController.forward(from: 0);
    }
  }

  void _calculate() {
    if (!shapeConfigs.containsKey(targetShape)) return;

    final config = shapeConfigs[targetShape]!;
    List<double> values = [];

    try {
      for (var c in _inputControllers) {
        if (c.text.isEmpty) {
          setState(() => _resultText = "Enter Value");
          return;
        }
        values.add(double.parse(c.text));
      }

      final area = config.calculate(values);
      setState(() {
        _resultText = area.toStringAsFixed(2);
      });
    } catch (e) {
      setState(() => _resultText = "Invalid");
    }
  }

  @override
  Widget build(BuildContext context) {
    // List of shapes to display in selector
    final selectableShapes = ShapeType.values
        .where((s) => s != ShapeType.loading)
        .toList();

    return Scaffold(
      resizeToAvoidBottomInset: false, // Prevent keyboard from breaking layout
      body: Stack(
        children: [
          // 1. The Particle Canvas (Top Half)
          Positioned.fill(
            bottom: MediaQuery.of(context).size.height * 0.4,
            child: AnimatedBuilder(
              animation: Listenable.merge([_morphAnimation, _floatController]),
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(
                    startType: currentShape,
                    endType: targetShape,
                    progress: _morphAnimation.value,
                    floatProgress: _floatController.value,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),

          // Intro Text
          if (_isLoadingSequence)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 200.0,
                ), // Push it down a bit
                child: Text(
                  "Initiating Area Wizard...",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 16,
                    letterSpacing: 2,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 2. The Interaction Area (Bottom Half)
          if (!_isLoadingSequence)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.55,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                    stops: [0.0, 0.2],
                  ),
                ),
                child: Column(
                  children: [
                    // Shape Title
                    Text(
                      shapeConfigs[targetShape]?.name ?? "",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: Colors.white54,
                      ),
                    ),

                    const Spacer(),

                    // Inputs and Calculate Button Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Dynamic Input Fields
                          Expanded(
                            flex: 2,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                _inputControllers.length,
                                (index) {
                                  String label =
                                      shapeConfigs[targetShape]!.inputs[index];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: TextField(
                                      controller: _inputControllers[index],
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: label,
                                        labelStyle: const TextStyle(
                                          color: Colors.white38,
                                        ),
                                        enabledBorder:
                                            const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.white24,
                                              ),
                                            ),
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.white,
                                              ),
                                            ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),

                          // Calculate Button & Result
                          Expanded(
                            flex: 1,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_resultText.isNotEmpty)
                                  Text(
                                    _resultText,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.cyanAccent,
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                GestureDetector(
                                  onTap: _calculate,
                                  child: Container(
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Text(
                                        "CALC",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // 3. The Shape Selector (Carousel)
                    SizedBox(
                      height: 120,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onShapeSelected,
                        itemCount: selectableShapes.length,
                        itemBuilder: (context, index) {
                          final shape = selectableShapes[index];
                          bool isSelected = (shape == targetShape);

                          // Symbol Mapping
                          final Map<ShapeType, String> shapeSymbols = {
                            ShapeType.triangle: "△",
                            ShapeType.rectangle: "▭",
                            ShapeType.circle: "○",
                            ShapeType.trapezoid: "▽",
                            ShapeType.box: "▢",
                            ShapeType.cylinder: "◎",
                            ShapeType.cone: "▲",
                          };

                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                index,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: isSelected ? 60 : 40,
                                  height: isSelected ? 60 : 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.1),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            width: 1,
                                          ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    shapeSymbols[shape] ?? "?",
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white54,
                                      fontSize: isSelected ? 30 : 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSelected ? 1.0 : 0.5,
                                  child: Text(
                                    shapeConfigs[shape]?.name ?? "",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. CUSTOM PAINTER (THE VISUAL MAGIC)
// ---------------------------------------------------------------------------

class ParticlePainter extends CustomPainter {
  final ShapeType startType;
  final ShapeType endType;
  final double progress;
  final double floatProgress;
  final Color color;

  ParticlePainter({
    required this.startType,
    required this.endType,
    required this.progress,
    required this.floatProgress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;

    // Get raw points (0.0 - 1.0)
    final startPoints = PointGenerator.getPoints(startType);
    final endPoints = PointGenerator.getPoints(endType);

    // Draw parameters
    double dotSize = 3.0;
    double scale = size.width * 0.7; // Shape size relative to screen width
    double offsetX = (size.width - scale) / 2;
    double offsetY = (size.height - scale) / 2;

    for (int i = 0; i < PointGenerator.particleCount; i++) {
      // Linear Interpolation (Lerp)
      Offset start = startPoints[i];
      Offset end = endPoints[i];

      double curX = start.dx + (end.dx - start.dx) * progress;
      double curY = start.dy + (end.dy - start.dy) * progress;

      // Continuous floating animation using controller value
      double time = floatProgress * 2 * math.pi; // 0 to 2π cycle
      double noiseX = 0.008 * math.sin(time + i * 0.1);
      double noiseY = 0.008 * math.cos(time + i * 0.15);
      curX += noiseX;
      curY += noiseY;

      // Convert to Screen Coordinates
      double screenX = offsetX + curX * scale;
      double screenY = offsetY + curY * scale;

      canvas.drawCircle(Offset(screenX, screenY), dotSize, paint);

      // Draw faint connections for a "constellation" look
      if (i > 0 && (startType != ShapeType.loading)) {
        // Only draw lines if points are close enough (mesh effect)
        if ((startPoints[i] - startPoints[i - 1]).distance < 0.2) {
          final linePaint = Paint()
            ..color = color.withValues(alpha: 0.15)
            ..strokeWidth = 1.0;

          // Lerp previous point
          Offset startPrev = startPoints[i - 1];
          Offset endPrev = endPoints[i - 1];
          double prevX = startPrev.dx + (endPrev.dx - startPrev.dx) * progress;
          double prevY = startPrev.dy + (endPrev.dy - startPrev.dy) * progress;

          canvas.drawLine(
            Offset(screenX, screenY),
            Offset(offsetX + prevX * scale, offsetY + prevY * scale),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.startType != startType ||
        oldDelegate.endType != endType ||
        (progress == 0 ||
            progress == 1); // Repaint for "floating" idle animation
  }
}
