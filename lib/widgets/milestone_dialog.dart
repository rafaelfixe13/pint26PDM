import 'package:flutter/material.dart';
import '../services/milestone_service.dart';

class MilestoneDialog extends StatefulWidget {
  final Milestone milestone;
  final VoidCallback onClose;

  const MilestoneDialog({
    super.key,
    required this.milestone,
    required this.onClose,
  });

  static Future<void> mostrar(BuildContext context, Milestone milestone) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => MilestoneDialog(
        milestone: milestone,
        onClose: () => Navigator.of(context, rootNavigator: true).pop(),
      ),
    );
  }

  @override
  State<MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<MilestoneDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header gradiente
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A5F), Color(0xFF2563EB)],
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.milestone.emoji,
                      style: const TextStyle(fontSize: 64),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Marco Alcançado!',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.milestone.titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Body
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text(
                  widget.milestone.descricao,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF444444),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Estrelinhas decorativas
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(Icons.star, color: Color(0xFFFBBF24), size: 20),
                  )),
                ),
              ),

              // Botão
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
