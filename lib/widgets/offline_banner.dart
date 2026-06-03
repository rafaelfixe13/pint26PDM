import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../rotas.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;
  const OfflineBanner({required this.child, super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _offline = false;
  bool _initialized = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _verificar();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _verificar());
  }

  Future<void> _verificar() async {
    bool semInternet;
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 3),
      );
      socket.destroy();
      semInternet = false;
    } catch (_) {
      semInternet = true;
    }

    if (!mounted) return;

    // Só mostra o popup na transição online → offline (não no arranque)
    final perdeuLigacao = semInternet && !_offline && _initialized;

    if (semInternet != _offline) {
      setState(() => _offline = semInternet);
    }

    if (!_initialized) _initialized = true;

    if (perdeuLigacao) {
      _mostrarPopup();
    }
  }

  void _mostrarPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = router.routerDelegate.navigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        barrierDismissible: true,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red, size: 26),
              SizedBox(width: 10),
              Text('Sem ligação'),
            ],
          ),
          content: const Text(
            'Perdeste a ligação à internet.\nA app continua em modo offline.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          bottom: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Container(
              key: ValueKey(_offline),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _offline ? Colors.red.shade50 : Colors.green.shade50,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(
                _offline ? Icons.wifi_off : Icons.wifi,
                color: _offline ? Colors.red : Colors.green,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
