// lib/screens/scenes_screen.dart
// SmartIoT v8.0.0 — Scenes (One-tap pump presets)
// Scene = একটি বাটনে pump ON/OFF + mode AUTO/MANUAL preset চালু হয়
// Firebase RTDB: /scenes/{deviceId}/{sceneId}
// Spark-plan safe: minimal reads/writes, local execution

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../core/constants.dart';
import '../l10n/app_localizations.dart';
import '../core/utils.dart';

// ── Model ─────────────────────────────────────────────────────
class SceneModel {
  final String id;
  final String name;
  final String icon;        // emoji
  final String pumpCmd;     // 'ON' | 'OFF' | 'NONE'
  final String modeCmd;     // 'AUTO' | 'MANUAL' | 'NONE'
  final String color;       // hex e.g. 'purple' | 'blue' | 'green' | 'orange'
  final int createdAt;

  const SceneModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.pumpCmd,
    required this.modeCmd,
    required this.color,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'name': name, 'icon': icon,
    'pumpCmd': pumpCmd, 'modeCmd': modeCmd,
    'color': color, 'createdAt': createdAt,
  };

  factory SceneModel.fromMap(String id, Map<dynamic, dynamic> m) => SceneModel(
    id: id,
    name: m['name']?.toString() ?? 'Scene',
    icon: m['icon']?.toString() ?? '⚡',
    pumpCmd: m['pumpCmd']?.toString() ?? 'NONE',
    modeCmd: m['modeCmd']?.toString() ?? 'NONE',
    color: m['color']?.toString() ?? 'purple',
    createdAt: (m['createdAt'] as num?)?.toInt() ?? 0,
  );

  Color get accentColor {
    switch (color) {
      case 'blue':   return AppTheme.accent;
      case 'green':  return AppTheme.success;
      case 'orange': return AppTheme.warning;
      case 'red':    return AppTheme.danger;
      default:       return AppTheme.smartPurple;
    }
  }
}

// ── Built-in default scenes ───────────────────────────────────
const _kDefaultScenes = [
  {'name': 'Fill Tank',    'icon': '💧', 'pumpCmd': 'ON',   'modeCmd': 'MANUAL', 'color': 'blue'},
  {'name': 'Stop Pump',    'icon': '🛑', 'pumpCmd': 'OFF',  'modeCmd': 'MANUAL', 'color': 'red'},
  {'name': 'Auto Mode',    'icon': '🤖', 'pumpCmd': 'NONE', 'modeCmd': 'AUTO',   'color': 'green'},
  {'name': 'Manual Mode',  'icon': '🎛️', 'pumpCmd': 'NONE', 'modeCmd': 'MANUAL', 'color': 'orange'},
];

// ── Screen ────────────────────────────────────────────────────
class ScenesScreen extends StatefulWidget {
  final DeviceService deviceService;
  const ScenesScreen({super.key, required this.deviceService});

  @override
  State<ScenesScreen> createState() => _ScenesScreenState();
}

class _ScenesScreenState extends State<ScenesScreen>
    with SingleTickerProviderStateMixin {
  final _fb = FirebaseService();
  List<SceneModel> _scenes = [];
  bool _loading = true;
  String? _runningId;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _load();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  String? get _deviceId => widget.deviceService.selectedDeviceId;

  Future<void> _load() async {
    if (_deviceId == null) {
      setState(() => _loading = false);
      return;
    }
    setState(() => _loading = true);
    try {
      final snap = await _fb.db
          .ref('scenes/$_deviceId')
          .get();
      final list = <SceneModel>[];
      if (snap.exists && snap.value != null) {
        final map = Map<dynamic, dynamic>.from(snap.value is Map ? snap.value as Map<dynamic,dynamic> : {});
        for (final e in map.entries) {
          list.add(SceneModel.fromMap(
              e.key.toString(), Map<dynamic, dynamic>.from(e.value is Map ? e.value as Map<dynamic,dynamic> : {})));
        }
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      if (mounted) setState(() { _scenes = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runScene(SceneModel s) async {
    if (_deviceId == null || _runningId != null) return;
    setState(() => _runningId = s.id);
    try {
      if (s.modeCmd != 'NONE') {
        await _fb.sendModeCommand(_deviceId!, s.modeCmd)
            .timeout(AppConstants.commandTimeout);
      }
      if (s.pumpCmd != 'NONE') {
        await _fb.sendPumpCommand(_deviceId!, s.pumpCmd)
            .timeout(AppConstants.commandTimeout);
      }
      await _fb.logEvent(_deviceId!, 'Scene run: ${s.name}');
      if (mounted) _snack('✅ ${s.name} — ${AppLocalizations.of(context).success}', false);
    } catch (_) {
      if (mounted) _snack(AppLocalizations.of(context).err_network, true);
    }
    if (mounted) setState(() => _runningId = null);
  }

  Future<void> _addDefaultScenes() async {
    if (_deviceId == null) return;
    setState(() => _loading = true);
    try {
      for (final d in _kDefaultScenes) {
        final ref = _fb.db.ref('scenes/$_deviceId').push();
        await ref.set({
          ...d, 'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        });
      }
      await _load();
      if (mounted) _snack('✅ ${AppLocalizations.of(context).success}', false);
    } catch (_) {
      if (mounted) { setState(() => _loading = false); _snack(AppLocalizations.of(context).failed, true); }
    }
  }

  Future<void> _deleteScene(SceneModel s) async {
    if (_deviceId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Delete Scene',
        body: 'Delete "${s.name}"?',
        isDark: context.read<ThemeNotifier>().isDark,
      ),
    );
    if (ok != true) return;
    try {
      await _fb.db.ref('scenes/$_deviceId/${s.id}').remove();
      setState(() => _scenes.removeWhere((x) => x.id == s.id));
      if (mounted) _snack(AppLocalizations.of(context).scene_deleted, false);
    } catch (_) {
      if (mounted) _snack('${AppLocalizations.of(context).failed} (delete)', true);
    }
  }

  Future<void> _openAddScene() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddSceneSheet(
        isDark: context.read<ThemeNotifier>().isDark,
        onSave: (name, icon, pumpCmd, modeCmd, color) async {
          if (_deviceId == null) return;
          final ref = _fb.db.ref('scenes/$_deviceId').push();
          await ref.set({
            'name': name, 'icon': icon,
            'pumpCmd': pumpCmd, 'modeCmd': modeCmd,
            'color': color,
            'createdAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
          });
          await _load();
        },
      ),
    );
  }

  void _snack(String msg, bool isError) {
    AppUtils.showSnack(context, msg, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;

    return Container(
      color: bg,
      child: Column(children: [
        // ── Title bar ──────────────────────────────────────────
        _TitleBar(
          title: 'Scenes',
          isDark: isDark,
          action: IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppTheme.smartPurple,
            onPressed: _openAddScene,
            tooltip: 'Add scene',
          ),
        ),

        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.smartPurple))
          : _deviceId == null
            ? _NoDeviceMsg(isDark: isDark)
            : _scenes.isEmpty
              ? _EmptyState(isDark: isDark, onAdd: _addDefaultScenes)
              : RefreshIndicator(
                  color: AppTheme.smartPurple,
                  onRefresh: _load,
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: _scenes.length,
                    itemBuilder: (_, i) => _SceneCard(
                      scene: _scenes[i],
                      isDark: isDark,
                      isRunning: _runningId == _scenes[i].id,
                      pulseCtrl: _pulseCtrl,
                      onTap: () => _runScene(_scenes[i]),
                      onDelete: () => _deleteScene(_scenes[i]),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

// ── Scene Card ────────────────────────────────────────────────
class _SceneCard extends StatelessWidget {
  final SceneModel scene;
  final bool isDark, isRunning;
  final AnimationController pulseCtrl;
  final VoidCallback onTap, onDelete;

  const _SceneCard({
    required this.scene, required this.isDark,
    required this.isRunning, required this.pulseCtrl,
    required this.onTap, required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = scene.accentColor;
    return AnimatedBuilder(
      animation: pulseCtrl,
      builder: (_, child) {
        final glow = isRunning
            ? BoxShadow(
                color: color.withValues(alpha: 0.3 + pulseCtrl.value * 0.25),
                blurRadius: 18 + pulseCtrl.value * 12,
                spreadRadius: 2,
              )
            : BoxShadow(
                color: color.withValues(alpha: isDark ? 0.12 : 0.08),
                blurRadius: 16, offset: const Offset(0, 4),
              );
        return GestureDetector(
          onTap: isRunning ? null : onTap,
          onLongPress: onDelete,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: isDark ? AppTheme.darkCard : Colors.white,
              border: Border.all(
                color: isRunning
                    ? color.withValues(alpha: 0.7)
                    : color.withValues(alpha: isDark ? 0.25 : 0.18),
                width: isRunning ? 2 : 1.2,
              ),
              boxShadow: [glow],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: isDark
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: _CardContent(scene: scene, isDark: isDark, isRunning: isRunning, color: color),
                    )
                  : _CardContent(scene: scene, isDark: isDark, isRunning: isRunning, color: color),
            ),
          ),
        );
      },
    );
  }
}

class _CardContent extends StatelessWidget {
  final SceneModel scene;
  final bool isDark, isRunning;
  final Color color;
  const _CardContent({required this.scene, required this.isDark, required this.isRunning, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: isRunning
                      ? SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: color,
                          ),
                        )
                      : Text(scene.icon, style: const TextStyle(fontSize: 22)),
                ),
              ),
              Icon(Icons.bolt_rounded, color: color.withValues(alpha: 0.5), size: 18),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                scene.name,
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.lightText,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(children: [
                if (scene.pumpCmd != 'NONE') _Tag(scene.pumpCmd, color),
                if (scene.pumpCmd != 'NONE' && scene.modeCmd != 'NONE')
                  const SizedBox(width: 4),
                if (scene.modeCmd != 'NONE') _Tag(scene.modeCmd, color),
              ]),
              const SizedBox(height: 2),
              Text(
                'Long-press to delete',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.white24 : Colors.black26,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ── Add Scene Bottom Sheet ─────────────────────────────────────
class _AddSceneSheet extends StatefulWidget {
  final bool isDark;
  final Future<void> Function(String, String, String, String, String) onSave;
  const _AddSceneSheet({required this.isDark, required this.onSave});

  @override
  State<_AddSceneSheet> createState() => _AddSceneSheetState();
}

class _AddSceneSheetState extends State<_AddSceneSheet> {
  final _nameCtrl = TextEditingController();
  String _icon = '⚡';
  String _pumpCmd = 'NONE';
  String _modeCmd = 'NONE';
  String _color = 'purple';
  bool _saving = false;

  static const _icons = ['⚡','💧','🛑','🤖','🎛️','🌊','⏸️','▶️','🔄','💡','🏠','🌙'];
  static const _colors = ['purple', 'blue', 'green', 'orange', 'red'];
  static const _colorMap = {
    'purple': AppTheme.smartPurple,
    'blue': AppTheme.accent,
    'green': AppTheme.success,
    'orange': AppTheme.warning,
    'red': AppTheme.danger,
  };

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _nameCtrl.text.trim(), _icon, _pumpCmd, _modeCmd, _color,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bg = widget.isDark ? AppTheme.darkCard : Colors.white;
    final textColor = widget.isDark ? Colors.white : AppTheme.lightText;
    final subColor = widget.isDark ? Colors.white38 : AppTheme.lightTextSub;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(l10n.scene_new_title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 16),

          // Name
          TextField(
            controller: _nameCtrl,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              labelText: 'Scene Name',
              labelStyle: TextStyle(color: subColor),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.smartPurple.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.smartPurple, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Icon picker
          Text(l10n.scene_icon_label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _icons.map((ic) => GestureDetector(
              onTap: () => setState(() => _icon = ic),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _icon == ic
                      ? AppTheme.smartPurple.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _icon == ic ? AppTheme.smartPurple : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(child: Text(ic, style: const TextStyle(fontSize: 20))),
              ),
            )).toList(),
          ),
          const SizedBox(height: 14),

          // Pump + Mode
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.scene_pump_label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
              const SizedBox(height: 4),
              _Dropdown(
                isDark: widget.isDark,
                value: _pumpCmd,
                items: const ['NONE', 'ON', 'OFF'],
                onChanged: (v) => setState(() => _pumpCmd = v),
              ),
            ])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l10n.scene_mode_label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
              const SizedBox(height: 4),
              _Dropdown(
                isDark: widget.isDark,
                value: _modeCmd,
                items: const ['NONE', 'AUTO', 'MANUAL'],
                onChanged: (v) => setState(() => _modeCmd = v),
              ),
            ])),
          ]),
          const SizedBox(height: 14),

          // Color picker
          Text(l10n.scene_color_label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor)),
          const SizedBox(height: 6),
          Row(children: _colors.map((c) => GestureDetector(
            onTap: () => setState(() => _color = c),
            child: Container(
              margin: const EdgeInsets.only(right: 10),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color: _colorMap[c],
                shape: BoxShape.circle,
                border: Border.all(
                  color: _color == c ? Colors.white : Colors.transparent,
                  width: 2.5,
                ),
                boxShadow: _color == c ? [
                  BoxShadow(color: _colorMap[c]!.withValues(alpha: 0.5), blurRadius: 8)
                ] : null,
              ),
            ),
          )).toList()),
          const SizedBox(height: 20),

          // Save button
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.smartPurple,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : Text(l10n.scene_save,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  final bool isDark;
  final String value;
  final List<String> items;
  final void Function(String) onChanged;
  const _Dropdown({required this.isDark, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.smartPurple.withValues(alpha: 0.3)),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: isDark ? AppTheme.darkCard : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.lightText,
          fontWeight: FontWeight.w600, fontSize: 13,
        ),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

// ── Empty / No Device ─────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final bool isDark;
  final VoidCallback onAdd;
  const _EmptyState({required this.isDark, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, size: 56,
                color: isDark ? Colors.white24 : Colors.black26),
            const SizedBox(height: 16),
            Text(l10n.scene_empty_title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.lightText)),
            const SizedBox(height: 8),
            Text(l10n.scene_empty_sub,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13,
                    color: isDark ? Colors.white38 : AppTheme.lightTextSub)),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.auto_fix_high_rounded, size: 18),
              label: Text(l10n.scene_add_defaults),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.smartPurple,
                side: const BorderSide(color: AppTheme.smartPurple),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDeviceMsg extends StatelessWidget {
  final bool isDark;
  const _NoDeviceMsg({required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: Text(AppLocalizations.of(context).no_devices,
        style: TextStyle(color: isDark ? Colors.white38 : AppTheme.lightTextSub)),
  );
}

class _TitleBar extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget? action;
  const _TitleBar({required this.title, required this.isDark, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.smartPurple.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Row(children: [
        Text(title,
            style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.lightText,
              letterSpacing: 0.3,
            )),
        const Spacer(),
        if (action != null) action!,
      ]),
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title, body;
  final bool isDark;
  const _ConfirmDialog({required this.title, required this.body, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(title, style: TextStyle(color: isDark ? Colors.white : AppTheme.lightText, fontWeight: FontWeight.w700)),
      content: Text(body, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.lightTextSub)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.delete, style: const TextStyle(color: AppTheme.danger)),
        ),
      ],
    );
  }
}
