// lib/screens/privacy_policy_screen.dart
// ══════════════════════════════════════════════════════════════════════════════
//  SmartIoT v1.0.2 — In-App Privacy Policy & Terms of Use Screen
//  Renders as native Flutter widgets — no WebView, no internet required.
//  Content matches privacy_policy.html v1.0 (May 29, 2026)
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  /// Set [showTerms] = true to show Terms of Use section instead of Privacy Policy.
  final bool showTerms;
  const PrivacyPolicyScreen({super.key, this.showTerms = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final cardBg = isDark ? AppTheme.darkCard : AppTheme.lightCard;
    final textColor = isDark ? Colors.white : AppTheme.lightText;
    final subColor = isDark ? Colors.white54 : AppTheme.lightTextSub;

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
          showTerms ? 'Terms of Use' : 'Privacy Policy',
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
        padding: const EdgeInsets.all(20),
        child: showTerms
            ? _TermsContent(isDark: isDark, cardBg: cardBg, textColor: textColor, subColor: subColor)
            : _PrivacyContent(isDark: isDark, cardBg: cardBg, textColor: textColor, subColor: subColor),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Privacy Policy content
// ─────────────────────────────────────────────────────────────────────────────
class _PrivacyContent extends StatelessWidget {
  final bool isDark;
  final Color cardBg, textColor, subColor;

  const _PrivacyContent({
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header card
        _HeaderCard(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          meta: 'App: SMART Water Level Control BD\n'
              'Version: 1.0.0  ·  Last Updated: May 29, 2026\n'
              'Developer: Smart IoT Interface',
          isDark: isDark,
          cardBg: cardBg,
          subColor: subColor,
        ),

        // Intro highlight
        _HighlightBox(
          text: 'This app controls and monitors water tanks using an ESP32 IoT device. '
              'We are committed to protecting your privacy.',
          isDark: isDark,
        ),

        _Section(title: '1. Data We Collect', isDark: isDark, textColor: textColor),
        _BulletList(isDark: isDark, items: const [
          'Account Data: Email address and display name (via Google Sign-In or email/password)',
          'Device Data: Water level readings, pump status, sensor data from your ESP32 device',
          'Usage Data: App settings, schedules, automation rules, scenes you create',
          'Location: Not collected',
          'Payment Info: Not collected',
        ]),

        _Section(title: '2. How We Use Your Data', isDark: isDark, textColor: textColor),
        _BulletList(isDark: isDark, items: const [
          'To display your water tank status on the dashboard',
          'To send push notifications (pump alerts, level warnings)',
          'To sync your device settings across sessions',
          'To enable device sharing with other users',
          'To improve app stability via crash reports (Firebase Crashlytics)',
        ]),

        _Section(title: '3. Data Storage', isDark: isDark, textColor: textColor),
        _Para(
          text: 'Your data is stored in Firebase Realtime Database (Google LLC, USA) '
              'and protected by Firebase security rules. Data is accessible only by '
              'authenticated users who own or have been granted access to a device.',
          isDark: isDark,
        ),

        _Section(title: '4. Third-Party Services', isDark: isDark, textColor: textColor),
        _BulletList(isDark: isDark, items: const [
          'Firebase (Google LLC): Authentication, database, crash reporting, push notifications',
          'Google Sign-In: Optional login method',
        ]),
        _LinkText(
          prefix: 'Firebase privacy policy: ',
          label: 'firebase.google.com/support/privacy',
          url: 'https://firebase.google.com/support/privacy',
          isDark: isDark,
        ),

        _Section(title: '5. Data Sharing', isDark: isDark, textColor: textColor),
        _Para(
          text: 'We do not sell, rent, or share your personal data with third parties, '
              'except as required by law or as necessary to provide the service '
              '(e.g., Firebase services).',
          isDark: isDark,
        ),

        _Section(title: '6. Device Sharing Feature', isDark: isDark, textColor: textColor),
        _Para(
          text: 'If you use the "Share Device" feature, the email address of the person '
              'you share with will be stored in the database to grant them access. '
              'You can remove shared users at any time from the Settings screen.',
          isDark: isDark,
        ),

        _Section(title: '7. Data Retention', isDark: isDark, textColor: textColor),
        _Para(
          text: 'Your data is retained as long as your account is active. You can delete '
              'your account and all associated data by contacting us at '
              'smartiotinterface@gmail.com.',
          isDark: isDark,
        ),

        _Section(title: '8. Children\'s Privacy', isDark: isDark, textColor: textColor),
        _Para(
          text: 'This app is not directed at children under 13. We do not knowingly '
              'collect data from children.',
          isDark: isDark,
        ),

        _Section(title: '9. Security', isDark: isDark, textColor: textColor),
        _Para(
          text: 'We use AES-256 encryption for credential storage, HTTPS for all '
              'communications, and Firebase security rules to restrict data access. '
              'BLE provisioning uses encrypted payloads.',
          isDark: isDark,
        ),

        _Section(title: '10. Your Rights (Bangladesh & General)', isDark: isDark, textColor: textColor),
        _BulletList(isDark: isDark, items: const [
          'Access the personal data we hold about you',
          'Request correction of inaccurate data',
          'Request deletion of your data',
          'Withdraw consent at any time',
        ]),
        _LinkText(
          prefix: 'To exercise these rights, contact: ',
          label: 'smartiotinterface@gmail.com',
          url: 'mailto:smartiotinterface@gmail.com',
          isDark: isDark,
        ),

        _Section(title: '11. Changes to This Policy', isDark: isDark, textColor: textColor),
        _Para(
          text: 'We may update this policy. The "Last Updated" date at the top will '
              'reflect any changes. Continued use of the app after changes constitutes '
              'acceptance.',
          isDark: isDark,
        ),

        _Section(title: '12. Contact', isDark: isDark, textColor: textColor),
        _BulletList(isDark: isDark, items: const [
          'Company: Smart IoT Interface',
          'Email: smartiotinterface@gmail.com',
          'Country: Bangladesh',
        ]),

        const SizedBox(height: 24),
        Center(
          child: Text(
            '© 2026 Smart IoT Interface — Privacy Policy v1.0',
            style: TextStyle(fontSize: 11, color: subColor),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Terms of Use content
// ─────────────────────────────────────────────────────────────────────────────
class _TermsContent extends StatelessWidget {
  final bool isDark;
  final Color cardBg, textColor, subColor;

  const _TermsContent({
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderCard(
          icon: Icons.gavel_rounded,
          title: 'Terms of Use',
          meta: 'App: SMART Water Level Control BD\n'
              'Version: 1.0.0  ·  Effective: May 29, 2026',
          isDark: isDark,
          cardBg: cardBg,
          subColor: subColor,
        ),

        _HighlightBox(
          text: 'By using this app, you agree to these terms. Please read them carefully.',
          isDark: isDark,
        ),

        _Section(title: '1. Acceptance of Terms', isDark: isDark, textColor: textColor),
        _Para(
          text: 'By downloading or using SMART Water Level Control BD, you agree to be '
              'bound by these Terms of Use. If you do not agree, please do not use the app.',
          isDark: isDark,
        ),

        _Section(title: '2. Use of the App', isDark: isDark, textColor: textColor),
        _BulletList(isDark: isDark, items: const [
          'This app is intended for controlling and monitoring water tanks via ESP32 devices',
          'You must have a valid account to use the app',
          'You are responsible for maintaining the security of your account credentials',
          'You must not use the app for any unlawful purpose',
        ]),

        _Section(title: '3. Device & Data Responsibility', isDark: isDark, textColor: textColor),
        _Para(
          text: 'You are solely responsible for the physical setup of your ESP32 device '
              'and water tank system. Smart IoT Interface is not liable for any hardware '
              'malfunction, water damage, or property damage resulting from use of this app.',
          isDark: isDark,
        ),

        _Section(title: '4. Limitations of Liability', isDark: isDark, textColor: textColor),
        _Para(
          text: 'The app is provided "as is" without warranty of any kind. Smart IoT '
              'Interface shall not be liable for any indirect, incidental, or consequential '
              'damages arising from your use of the app.',
          isDark: isDark,
        ),

        _Section(title: '5. Changes to Terms', isDark: isDark, textColor: textColor),
        _Para(
          text: 'We reserve the right to modify these terms at any time. Continued use '
              'of the app after changes constitutes acceptance of the new terms.',
          isDark: isDark,
        ),

        _Section(title: '6. Contact', isDark: isDark, textColor: textColor),
        _LinkText(
          prefix: 'Questions? Contact us: ',
          label: 'smartiotinterface@gmail.com',
          url: 'mailto:smartiotinterface@gmail.com',
          isDark: isDark,
        ),

        const SizedBox(height: 24),
        Center(
          child: Text(
            '© 2026 Smart IoT Interface — Terms of Use v1.0',
            style: TextStyle(fontSize: 11, color: subColor),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _HeaderCard extends StatelessWidget {
  final IconData icon;
  final String title, meta;
  final bool isDark;
  final Color cardBg, subColor;

  const _HeaderCard({
    required this.icon,
    required this.title,
    required this.meta,
    required this.isDark,
    required this.cardBg,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.smartPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.smartPurple, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.smartPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: TextStyle(fontSize: 11, color: subColor, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightBox extends StatelessWidget {
  final String text;
  final bool isDark;
  const _HighlightBox({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.smartPurple.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: const Border(
          left: BorderSide(color: AppTheme.smartPurple, width: 3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? Colors.white70 : AppTheme.lightText,
          height: 1.6,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final bool isDark;
  final Color textColor;
  const _Section({required this.title, required this.isDark, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppTheme.lightText,
        ),
      ),
    );
  }
}

class _Para extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Para({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: isDark ? Colors.white70 : AppTheme.lightTextSub,
        height: 1.7,
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final bool isDark;
  const _BulletList({required this.items, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7, right: 8),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.smartPurple.withValues(alpha: 0.70),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : AppTheme.lightTextSub,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _LinkText extends StatelessWidget {
  final String prefix, label, url;
  final bool isDark;
  const _LinkText({
    required this.prefix,
    required this.label,
    required this.url,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: prefix,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppTheme.lightTextSub,
                  height: 1.7,
                ),
              ),
              TextSpan(
                text: label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.smartPurple,
                  decoration: TextDecoration.underline,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
