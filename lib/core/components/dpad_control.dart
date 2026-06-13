import 'package:flutter/material.dart';

/// D-pad + кнопка огня для аркадных игр (танки).
///
/// D-pad — **единая зона со скольжением**: направление определяется положением
/// пальца относительно центра (доминантная ось), и меняется на лету, если вести
/// пальцем — не нужно отпускать и попадать в маленькую кнопку. В центре —
/// мёртвая зона (стоп). Мультитач (держать направление + жать огонь) — две
/// независимые зоны через [Listener] (сырые указатели). Использует
/// [AxisDirection] (тип Flutter), чтобы `core/` не зависел от фич; экран-хост
/// маппит его в игровое направление.
class DpadControl extends StatefulWidget {
  const DpadControl({
    super.key,
    required this.onDirection,
    required this.onFireChanged,
    this.accent = const Color(0xFF4ECDC4),
  });

  /// Текущее направление (null — отпущено/стоп).
  final ValueChanged<AxisDirection?> onDirection;

  /// Зажата (true) либо отпущена (false) кнопка огня.
  final ValueChanged<bool> onFireChanged;

  final Color accent;

  @override
  State<DpadControl> createState() => _DpadControlState();
}

class _DpadControlState extends State<DpadControl> {
  static const double _cell = 56;
  static const double _pad = _cell * 3;

  AxisDirection? _dir;
  int? _padPointer;
  bool _firing = false;

  void _setDir(AxisDirection? d) {
    if (_dir == d) return;
    setState(() => _dir = d);
    widget.onDirection(d);
  }

  /// Направление по позиции пальца относительно центра пада (с мёртвой зоной).
  void _updateDir(Offset local) {
    final dx = local.dx - _pad / 2;
    final dy = local.dy - _pad / 2;
    const dead = _pad * 0.15;
    if (dx * dx + dy * dy < dead * dead) {
      _setDir(null);
      return;
    }
    _setDir(dx.abs() > dy.abs()
        ? (dx > 0 ? AxisDirection.right : AxisDirection.left)
        : (dy > 0 ? AxisDirection.down : AxisDirection.up));
  }

  void _endPad(int pointer) {
    if (_padPointer != pointer) return;
    _padPointer = null;
    _setDir(null);
  }

  void _fire(bool on) {
    if (_firing == on) return;
    setState(() => _firing = on);
    widget.onFireChanged(on);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 22, 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [_buildDpad(), _buildFire()],
      ),
    );
  }

  Widget _buildDpad() {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (e) {
        _padPointer = e.pointer;
        _updateDir(e.localPosition);
      },
      onPointerMove: (e) {
        if (e.pointer == _padPointer) _updateDir(e.localPosition);
      },
      onPointerUp: (e) => _endPad(e.pointer),
      onPointerCancel: (e) => _endPad(e.pointer),
      child: SizedBox(
        width: _pad,
        height: _pad,
        child: Stack(
          children: [
            Positioned(
                left: _cell,
                top: 0,
                child: _cellView(AxisDirection.up, Icons.keyboard_arrow_up)),
            Positioned(
                left: _cell,
                bottom: 0,
                child:
                    _cellView(AxisDirection.down, Icons.keyboard_arrow_down)),
            Positioned(
                left: 0,
                top: _cell,
                child:
                    _cellView(AxisDirection.left, Icons.keyboard_arrow_left)),
            Positioned(
                right: 0,
                top: _cell,
                child:
                    _cellView(AxisDirection.right, Icons.keyboard_arrow_right)),
          ],
        ),
      ),
    );
  }

  /// Чисто визуальная клетка крестовины (ввод — на внешнем [Listener]).
  Widget _cellView(AxisDirection d, IconData icon) {
    final active = _dir == d;
    return Container(
      width: _cell,
      height: _cell,
      decoration: BoxDecoration(
        color: active
            ? widget.accent.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Icon(
        icon,
        color: active ? Colors.black : Colors.white.withValues(alpha: 0.7),
        size: 32,
      ),
    );
  }

  Widget _buildFire() {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _fire(true),
      onPointerUp: (_) => _fire(false),
      onPointerCancel: (_) => _fire(false),
      child: AnimatedScale(
        scale: _firing ? 0.92 : 1,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [widget.accent, const Color(0xFF7C5CFF)],
            ),
            boxShadow: [
              BoxShadow(
                  color: widget.accent.withValues(alpha: 0.5), blurRadius: 18),
            ],
          ),
          child: const Icon(Icons.bolt, color: Colors.white, size: 42),
        ),
      ),
    );
  }
}
