// lib/screens/sharing_screen.dart
// [FIX H-3 / F-1] Device Sharing UI — Firebase + Rules were ready, UI was missing
// Owner can share device with other users by email (UID lookup) and revoke access.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/device_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../core/utils.dart';

class SharingScreen extends StatefulWidget {
  final DeviceService deviceService;
  const SharingScreen({super.key, required this.deviceService});

  @override
  State<SharingScreen> createState() => _SharingScreenState();
}

class _SharingScreenState extends State<SharingScreen> {
  // [FIX] Store uid→email map so we display readable labels instead of raw UIDs
  final Map<String, String> _sharedUsers = {}; // uid → email
  bool _loading = true;
  bool _adding = false;
  String? _error;
  final _emailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // [FIX CRASH] AppLocalizations.of(context) cannot be called during initState()
    // because inherited widgets (localizations) are not yet available.
    // Use addPostFrameCallback to defer until after the first frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadShared();
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  String? get _deviceId => widget.deviceService.selectedDeviceId;

  // [FIX] In-memory email cache so added-this-session emails show correctly
  final Map<String, String> _emailCache = {};

  String _truncateUid(String uid) =>
      // [FIX BUG-9] Was using \$ escape — string interpolation never worked
      uid.length > 16 ? '${uid.substring(0, 8)}…${uid.substring(uid.length - 6)}' : uid;

  Future<void> _loadShared() async {
    if (_deviceId == null) {
      if (mounted) setState(() { _loading = false; _error = AppLocalizations.of(context).no_devices; });
      return;
    }
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final uids = await FirebaseService().getSharedUsers(_deviceId!);
      // [FIX] Resolve UIDs to emails where possible (stored in user_lookup table)
      final Map<String, String> resolved = {};
      for (final uid in uids) {
        resolved[uid] = _emailCache[uid] ?? _truncateUid(uid);
      }
      if (mounted) setState(() { _sharedUsers.clear(); _sharedUsers.addAll(resolved); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = AppLocalizations.of(context).failed; _loading = false; });
    }
  }

  Future<void> _shareByEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    if (_deviceId == null) return;

    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final currentEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    // Prevent sharing with yourself
    if (email.toLowerCase() == currentEmail.toLowerCase()) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).cannot_share_self, isError: true);
      return;
    }

    if (mounted) setState(() { _adding = true; _error = null; });
    try {
      // [FIX CRITICAL] Lookup the real Firebase UID for this email.
      // On Spark plan (no Cloud Functions), we use a user_lookup table
      // that every user writes to on login: user_lookup/{email_key} = uid
      final fb = FirebaseService();
      final targetUid = await fb.lookupUidByEmail(email);

      if (targetUid == null) {
        if (mounted) {
          AppUtils.showSnack(
            context,
            AppLocalizations.of(context).share_user_not_found,
            isError: true,
          );
        }
        return;
      }

      if (targetUid == currentUid) {
        if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).cannot_share_self, isError: true);
        return;
      }

      if (_sharedUsers.containsKey(targetUid)) {
        if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).already_shared, isError: true);
        return;
      }

      await fb.shareDevice(_deviceId!, targetUid);
      _emailCtrl.clear();
      // [FIX] Cache email so list shows readable label
      _emailCache[targetUid] = email;
      if (mounted) setState(() => _sharedUsers[targetUid] = email);
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).access_granted(email));
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).share_failed, isError: true);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _revoke(String uid) async {
    if (_deviceId == null) return;
    // Confirm before revoking so user doesn't accidentally remove access
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).revoke_access_title),
        content: Text(AppLocalizations.of(context).revoke_confirm_user(_sharedUsers[uid] ?? _truncateUid(uid))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: Text(AppLocalizations.of(context).remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseService().unshareDevice(_deviceId!, uid);
      if (mounted) setState(() => _sharedUsers.remove(uid));
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).access_revoked);
    } catch (_) {
      if (mounted) AppUtils.showSnack(context, AppLocalizations.of(context).revoke_failed, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).device_sharing),
        backgroundColor:
            isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadShared,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Add-share input ───────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context).share_with_user,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white : Colors.black87,
                    )),
                const SizedBox(height: 4),
                Text(
                  'Enter the email address of the person you want to share this device with.',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(
                            color:
                                isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context).email_hint,
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.email_outlined,
                              size: 18),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                        ),
                        onSubmitted: (_) => _shareByEmail(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _adding
                        ? const SizedBox(
                            width: 44, height: 44,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : FilledButton(
                            onPressed: _shareByEmail,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryLight,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: Text(AppLocalizations.of(context).share),
                          ),
                  ],
                ),
              ],
            ),
          ),

          // ── Shared-with list ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Shared with (${_sharedUsers.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _loadShared)
                    : _sharedUsers.isEmpty
                        ? const _EmptyView()
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                            itemCount: _sharedUsers.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final uid = _sharedUsers.keys.elementAt(i);
                              final label = _sharedUsers[uid]!;
                              return _SharedUserTile(
                                label: label,  // [FIX] shows email, not raw UID
                                isDark: isDark,
                                isPending: false,
                                onRevoke: () => _revoke(uid),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Shared user tile ───────────────────────────────────────────────────────

class _SharedUserTile extends StatelessWidget {
  final String label;
  final bool isDark;
  final bool isPending;
  final VoidCallback onRevoke;

  const _SharedUserTile({
    required this.label,
    required this.isDark,
    required this.isPending,
    required this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.12),
          child: Text(
            label.isNotEmpty ? label[0].toUpperCase() : '?',
            style: const TextStyle(
                color: AppTheme.primaryLight, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(label,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 14)),
        subtitle: Text(
          isPending ? 'Pending invite' : 'Has access',
          style: TextStyle(
            fontSize: 11,
            color: isPending ? Colors.orange : AppTheme.success,
          ),
        ),
        trailing: TextButton.icon(
          onPressed: onRevoke,
          icon: const Icon(Icons.remove_circle_outline_rounded,
              size: 16, color: Colors.redAccent),
          label: Text(AppLocalizations.of(context).revoke,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8)),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.group_off_rounded,
                size: 56, color: Colors.grey.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context).not_shared,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'Share this device with family members or colleagues to give them monitoring access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context).retry),
          ),
        ],
      ),
    );
  }
}
