// lib/screens/user_guide_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v1.0.2 — In-App User Guide / Documentation Screen
//  Expandable Q&A sections covering setup, features & troubleshooting.
//  No internet required — all content is embedded.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class UserGuideScreen extends StatelessWidget {
  const UserGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? Colors.white : AppTheme.lightText;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: AppTheme.smartPurple,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Guide',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            height: 0.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.10)
                : AppTheme.smartPurple.withValues(alpha: 0.10),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            _GuideBanner(isDark: isDark),

            const SizedBox(height: 20),

            // Getting Started
            _GuideSection(
              icon: Icons.rocket_launch_rounded,
              title: 'Getting Started',
              isDark: isDark,
              items: const [
                _GuideItem(
                  q: 'What do I need to use this app?',
                  a: '• ESP32-based Smart Water Tank hardware (BD-1)\n'
                      '• WiFi router (2.4 GHz)\n'
                      '• Android 6.0+ or iOS 12+ smartphone\n'
                      '• Google or email account for login',
                ),
                _GuideItem(
                  q: 'How do I set up a new device?',
                  a: '1. Power on the ESP32 device — the OLED shows "BLE PROV"\n'
                      '2. Open the app → tap "Add New Device" on the home screen\n'
                      '3. Follow the 6-step Bluetooth provisioning wizard\n'
                      '4. Enter your WiFi credentials when prompted\n'
                      '5. Wait for the device to connect — the OLED shows your IP\n'
                      '6. The dashboard appears automatically after pairing',
                ),
                _GuideItem(
                  q: 'How do I log in?',
                  a: 'Tap "Sign in with Google" for one-tap login, or use your '
                      'email and password. Your session is saved — you stay logged '
                      'in until you sign out manually.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dashboard
            _GuideSection(
              icon: Icons.dashboard_rounded,
              title: 'Dashboard',
              isDark: isDark,
              items: const [
                _GuideItem(
                  q: 'What does the tank indicator show?',
                  a: 'The 3D tank widget shows real-time water level:\n'
                      '• EMPTY (0–25%) — Red\n'
                      '• LOW (26–50%) — Orange\n'
                      '• MID (51–75%) — Yellow\n'
                      '• FULL (76–100%) — Blue/Teal\n'
                      'The percentage and level label update every few seconds.',
                ),
                _GuideItem(
                  q: 'How do I control the pump?',
                  a: '• Auto Mode: The pump starts/stops automatically based on '
                      'water level thresholds you set\n'
                      '• Manual Mode: Use the ON/OFF toggle on the dashboard\n'
                      'Tap the mode button to switch between AUTO and MANUAL.',
                ),
                _GuideItem(
                  q: 'What is "Dry Run" protection?',
                  a: 'If the pump runs but no water is detected (empty tank or '
                      'suction issue), the device automatically stops the pump '
                      'and shows a DRY RUN alert. Tap "Reset Dry Run" on the '
                      'dashboard to clear the alarm after fixing the issue.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Schedules & Automation
            _GuideSection(
              icon: Icons.schedule_rounded,
              title: 'Schedules & Automation',
              isDark: isDark,
              items: const [
                _GuideItem(
                  q: 'How do I set a pump schedule?',
                  a: '1. Go to Settings → Pump Schedules\n'
                      '2. Tap the "+" button to create a new schedule\n'
                      '3. Set start time, end time, and repeat days\n'
                      '4. Enable the schedule toggle\n'
                      'The pump follows the schedule only when in Auto Mode.',
                ),
                _GuideItem(
                  q: 'What are Scenes?',
                  a: 'Scenes let you save preset configurations (pump mode, '
                      'thresholds) and apply them with one tap. Useful for '
                      'switching between "Summer" and "Winter" watering patterns.',
                ),
                _GuideItem(
                  q: 'What are Automations?',
                  a: 'Automations trigger actions based on conditions:\n'
                      '• If water level < 20% → Turn ON pump\n'
                      '• If water level > 90% → Turn OFF pump\n'
                      '• If pump ON for > 30 min → Send notification\n'
                      'Go to Settings → Automations to create rules.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Notifications & Alarms
            _GuideSection(
              icon: Icons.notifications_outlined,
              title: 'Notifications & Alarms',
              isDark: isDark,
              items: const [
                _GuideItem(
                  q: 'What notifications does the app send?',
                  a: '• Tank FULL / EMPTY alerts\n'
                      '• Pump ON / OFF confirmation\n'
                      '• Dry Run alarm\n'
                      '• Device offline alert (no data for 45 seconds)\n'
                      '• Alarm threshold crossed (custom)',
                ),
                _GuideItem(
                  q: 'How do I set alarm thresholds?',
                  a: 'Go to Settings → Alarm Thresholds. Set minimum and maximum '
                      'water level percentages. You will receive a push notification '
                      'when the level goes outside the safe range.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Device Sharing
            _GuideSection(
              icon: Icons.group_outlined,
              title: 'Device Sharing',
              isDark: isDark,
              items: const [
                _GuideItem(
                  q: 'Can I share my device with someone else?',
                  a: 'Yes! Go to Settings → Device Sharing → Share Device. Enter '
                      'the email address of the person you want to share with. They '
                      'will see your device on their app with view and control access.',
                ),
                _GuideItem(
                  q: 'How do I remove a shared user?',
                  a: 'Go to Settings → Device Sharing. Tap the trash icon next to '
                      'the user you want to remove. They will immediately lose access.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Troubleshooting
            _GuideSection(
              icon: Icons.build_rounded,
              title: 'Troubleshooting',
              isDark: isDark,
              items: const [
                _GuideItem(
                  q: 'Device shows "Offline" on the dashboard',
                  a: '• Check that the ESP32 is powered on\n'
                      '• Verify the WiFi router is working\n'
                      '• Check that the device is within WiFi range\n'
                      '• Restart the ESP32 by pressing the reset button\n'
                      '• If the issue persists, re-provision the device',
                ),
                _GuideItem(
                  q: 'BLE provisioning fails or times out',
                  a: '• Make sure Bluetooth and Location are enabled on your phone\n'
                      '• Stay within 3 meters of the ESP32 during provisioning\n'
                      '• Ensure no other phone is trying to provision at the same time\n'
                      '• Restart the ESP32 and try again\n'
                      '• Make sure you are entering the correct WiFi password (case-sensitive)',
                ),
                _GuideItem(
                  q: 'Water level shows wrong percentage',
                  a: '• If using ultrasonic sensor: Go to Settings → Sensor Calibration '
                      'and enter your tank dimensions\n'
                      '• If using float sensors: Verify the float switch wiring matches '
                      'the firmware GPIO mapping\n'
                      '• Restart the ESP32 after calibration',
                ),
                _GuideItem(
                  q: 'App crashes or freezes',
                  a: '• Force-close and restart the app\n'
                      '• Make sure you have a stable internet connection\n'
                      '• Check for app updates in the Play Store\n'
                      '• If the issue persists, contact support at '
                      'smartiotinterface@gmail.com with your device model and '
                      'app version (found in About → App Version)',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Contact support card
            _ContactCard(isDark: isDark),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Banner at the top
// ─────────────────────────────────────────────────────────────────────────────
class _GuideBanner extends StatelessWidget {
  final bool isDark;
  const _GuideBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.smartPurple.withValues(alpha: isDark ? 0.25 : 0.12),
            AppTheme.accent.withValues(alpha: isDark ? 0.15 : 0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.smartPurple.withValues(alpha: 0.20),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.smartPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppTheme.smartPurple, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SMART Water Level Control BD',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'User Guide — v1.0.2',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : AppTheme.lightTextSub,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Expandable guide section
// ─────────────────────────────────────────────────────────────────────────────
class _GuideSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isDark;
  final List<_GuideItem> items;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.isDark,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.smartPurple),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.smartPurple,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        // Expandable items
        Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.20)
                    : Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: items
                  .map((item) => _ExpandableItem(item: item, isDark: isDark))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single expandable Q&A item
// ─────────────────────────────────────────────────────────────────────────────
class _ExpandableItem extends StatefulWidget {
  final _GuideItem item;
  final bool isDark;
  const _ExpandableItem({required this.item, required this.isDark});

  @override
  State<_ExpandableItem> createState() => _ExpandableItemState();
}

class _ExpandableItemState extends State<_ExpandableItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _heightFactor = _ctrl.drive(CurveTween(curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : AppTheme.lightText;
    final subColor = widget.isDark ? Colors.white70 : AppTheme.lightTextSub;

    return Column(
      children: [
        InkWell(
          onTap: _toggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.item.q,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.smartPurple,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _heightFactor,
          builder: (ctx, child) => ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              widget.item.a,
              style: TextStyle(
                fontSize: 13,
                color: subColor,
                height: 1.7,
              ),
            ),
          ),
        ),
        Container(
          height: 0.5,
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
        ),
      ],
    );
  }
}

// Data class for a guide Q&A item
class _GuideItem {
  final String q;
  final String a;
  const _GuideItem({required this.q, required this.a});
}

// ─────────────────────────────────────────────────────────────────────────────
//  Contact support card at the bottom
// ─────────────────────────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final bool isDark;
  const _ContactCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.smartPurple.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.smartPurple.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.support_agent_rounded,
                  color: AppTheme.smartPurple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Need more help?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppTheme.lightText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Contact our support team — we\'re happy to help!',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : AppTheme.lightTextSub,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('mailto:smartiotinterface@gmail.com'),
              mode: LaunchMode.externalApplication,
            ),
            child: const Text(
              '📧 smartiotinterface@gmail.com',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.smartPurple,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
