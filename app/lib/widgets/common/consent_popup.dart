import 'package:flutter/material.dart';

class ConsentPopup extends StatefulWidget {
  const ConsentPopup({super.key});

  @override
  State<ConsentPopup> createState() => _ConsentPopupState();
}

class _ConsentPopupState extends State<ConsentPopup> {
  final List<_ConsentItem> _items = [
    _ConsentItem(
      title: 'Cámara',
      detail:
          'Las fotos se usan únicamente para estimar proporciones corporales y rangos de movimiento. '
          'Salen del dispositivo solo si activa el backup en la nube.',
      accepted: false,
    ),
    _ConsentItem(
      title: 'Almacenamiento local',
      detail:
          'Se guardan métricas derivadas de las fotos (proporciones, ángulos). '
          'Nunca se almacenan imágenes identificables salvo autorización explícita.',
      accepted: false,
    ),
    _ConsentItem(
      title: 'Datos de salud',
      detail:
          'Lesiones y condiciones que indiques afectan únicamente a la prescripción de ejercicio. '
          'No se comparten con terceros sin tu consentimiento explícito.',
      accepted: false,
    ),
  ];

  bool get _allAccepted => _items.every((i) => i.accepted);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111111),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PERMISOS',
              style: TextStyle(
                color: Color(0xFF00FF88),
                fontSize: 14,
                fontFamily: 'monospace',
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            ..._items.map((item) => _ConsentTile(
                  item: item,
                  onChanged: (v) => setState(() => item.accepted = v),
                )),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _allAccepted ? () => Navigator.pop(context, true) : null,
                style: TextButton.styleFrom(
                  backgroundColor:
                      _allAccepted ? const Color(0xFF00FF88) : const Color(0xFF1A1A1A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
                ),
                child: Text(
                  'ACEPTAR',
                  style: TextStyle(
                    color: _allAccepted ? const Color(0xFF0A0A0A) : const Color(0xFF444444),
                    fontFamily: 'monospace',
                    letterSpacing: 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentItem {
  final String title;
  final String detail;
  bool accepted;
  _ConsentItem({required this.title, required this.detail, required this.accepted});
}

class _ConsentTile extends StatelessWidget {
  final _ConsentItem item;
  final ValueChanged<bool> onChanged;

  const _ConsentTile({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: item.accepted,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: const Color(0xFF00FF88),
            checkColor: const Color(0xFF0A0A0A),
            side: const BorderSide(color: Color(0xFF333333)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.detail,
                  style: const TextStyle(
                    color: Color(0xFF888888),
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
