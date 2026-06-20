// lib/screens/about_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v1.0.2 — About Screen (Full Page)
//  Replaces the old ModalBottomSheet _showAboutSheet() in settings_screen.dart
//  Contains: App Info · Developer · Legal · Documentation · Contact & Social
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/utils.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'privacy_policy_screen.dart';
import 'user_guide_screen.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() => _version = '${info.version} (${info.buildNumber})');
      }
    } catch (_) {}
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppUtils.showSnack(context, AppLocalizations.of(context).could_not_open_link, isError: true);
      }
    }
  }

  void _navigate(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subColor = isDark ? Colors.white54 : AppTheme.lightTextSub;

    return Scaffold(
      backgroundColor: bg,
      appBar: _buildAppBar(isDark, textColor),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App Card ──────────────────────────────────────────────────
            _AppCard(version: _version, isDark: isDark, cardBg: cardBg, textColor: textColor, subColor: subColor),

            const SizedBox(height: 20),

            // ── Developer ─────────────────────────────────────────────────
            _SectionCard(
              title: 'DEVELOPER',
              isDark: isDark,
              cardBg: cardBg,
              children: [
                _InfoRow(label: 'Developer', value: AppConstants.developerName, isDark: isDark),
                _Divider(isDark: isDark),
                _InfoRow(label: 'Company', value: AppConstants.companyName, isDark: isDark),
                _Divider(isDark: isDark),
                _InfoRow(label: 'Country', value: '🇧🇩 Bangladesh', isDark: isDark),
                _Divider(isDark: isDark),
                _InfoRow(label: 'Firmware', value: AppConstants.firmwareVersion, isDark: isDark),
              ],
            ),

            const SizedBox(height: 16),

            // ── Legal ─────────────────────────────────────────────────────
            _SectionCard(
              title: 'LEGAL',
              isDark: isDark,
              cardBg: cardBg,
              children: [
                _LinkRow(
                  label: 'Privacy Policy',
                  sublabel: 'How we handle your data',
                  icon: Icons.privacy_tip_outlined,
                  isDark: isDark,
                  onTap: () => _navigate(const PrivacyPolicyScreen()),
                ),
                _Divider(isDark: isDark),
                _LinkRow(
                  label: 'Terms of Use',
                  sublabel: 'Rules for using this app',
                  icon: Icons.gavel_rounded,
                  isDark: isDark,
                  onTap: () => _navigate(const PrivacyPolicyScreen(showTerms: true)),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Documentation ─────────────────────────────────────────────
            _SectionCard(
              title: 'DOCUMENTATION',
              isDark: isDark,
              cardBg: cardBg,
              children: [
                _LinkRow(
                  label: 'User Guide',
                  sublabel: 'Setup, features & troubleshooting',
                  icon: Icons.menu_book_rounded,
                  isDark: isDark,
                  onTap: () => _navigate(const UserGuideScreen()),
                ),
                _Divider(isDark: isDark),
                _LinkRow(
                  label: 'Video Tutorials',
                  sublabel: 'Watch on YouTube',
                  icon: Icons.play_circle_outline_rounded,
                  isDark: isDark,
                  external: true,
                  onTap: () => _launch('https://www.youtube.com/@SmartIoTInterface'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Contact & Social ──────────────────────────────────────────
            _SectionCard(
              title: 'CONTACT & SOCIAL',
              isDark: isDark,
              cardBg: cardBg,
              children: [
                _LinkRow(
                  label: 'Email Support',
                  sublabel: 'smartiotinterface@gmail.com',
                  icon: Icons.email_outlined,
                  isDark: isDark,
                  onTap: () => _launch('mailto:smartiotinterface@gmail.com'),
                ),
                _Divider(isDark: isDark),
                _LinkRow(
                  label: 'Phone',
                  sublabel: '+880 168 060 3444',
                  icon: Icons.phone_outlined,
                  isDark: isDark,
                  onTap: () => _launch('tel:+8801680603444'),
                ),
                _Divider(isDark: isDark),
                _LinkRow(
                  label: 'Facebook Page',
                  sublabel: 'SmartIoTInterface',
                  icon: Icons.facebook_rounded,
                  isDark: isDark,
                  external: true,
                  onTap: () => _launch('https://www.facebook.com/SmartIoTInterface'),
                ),
                _Divider(isDark: isDark),
                _LinkRow(
                  label: 'YouTube Channel',
                  sublabel: '@SmartIoTInterface',
                  icon: Icons.smart_display_outlined,
                  isDark: isDark,
                  external: true,
                  onTap: () => _launch('https://www.youtube.com/@SmartIoTInterface'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Footer ────────────────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Text(
                    'Made with 💙 in Bangladesh 🇧🇩',
                    style: TextStyle(fontSize: 13, color: subColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2026 Smart IoT Interface — All rights reserved',
                    style: TextStyle(fontSize: 11, color: subColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color textColor) {
    return AppBar(
      backgroundColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: AppTheme.smartPurple,
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'About',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  App identity card at the top
// ─────────────────────────────────────────────────────────────────────────────
class _AppCard extends StatelessWidget {
  final String version;
  final bool isDark;
  final Color cardBg, textColor, subColor;

  const _AppCard({
    required this.version,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.30)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppTheme.smartPurple, Color(0xFF2196F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.smartPurple.withValues(alpha: 0.40),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
                child: Image.asset(
                  'assets/images/smart_iot_logo.png',
                  width: 76, height: 76, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 38),
                ),
              ),
          ),
          const SizedBox(height: 14),

          // App name
          Text(
            AppConstants.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),

          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.smartPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.smartPurple.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              version.isNotEmpty ? 'v$version' : 'Loading…',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.smartPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section card wrapper
// ─────────────────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final bool isDark;
  final Color cardBg;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.smartPurple,
              letterSpacing: 1.2,
            ),
          ),
        ),
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
          child: Column(children: children),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Static label ↔ value row
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _InfoRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white54 : AppTheme.lightTextSub,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppTheme.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tappable row that navigates or opens a URL
// ─────────────────────────────────────────────────────────────────────────────
class _LinkRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;
  final bool external;

  const _LinkRow({
    required this.label,
    this.sublabel,
    required this.icon,
    required this.isDark,
    required this.onTap,
    this.external = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subColor = isDark ? Colors.white38 : AppTheme.lightTextSub;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.smartPurple),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    if (sublabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        sublabel!,
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                external
                    ? Icons.open_in_new_rounded
                    : Icons.chevron_right_rounded,
                size: 18,
                color: subColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Thin divider between rows
// ─────────────────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 48),
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.07),
    );
  }
}
