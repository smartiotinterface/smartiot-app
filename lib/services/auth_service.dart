// lib/services/auth_service.dart
// SmartIoT v1.0.2 — Phone Auth added
// ✅ Email/Password sign-in + registration
// ✅ Google Sign-In
// ✅ Phone Number OTP sign-in (Firebase SMS)
// ✅ Email verification check on sign-in (with resend support)
// ✅ Password strength validation
// ✅ Secure logout: clears SecureStorage + Google sign-in cache
// ✅ Error codes mapped to l10n keys for bilingual support
// ✅ All auth error cases handled

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/secure_storage.dart';
import 'country_code_service.dart';
import 'firebase_service.dart';
import 'notification_service.dart';

enum AuthLoadingState {
  idle,
  emailSignIn,
  emailRegister,
  google,
  logout,
  phone,
  phoneVerify,
}

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _googleSignIn = GoogleSignIn();

  AuthLoadingState _loadingState = AuthLoadingState.idle;
  String? _errorMessage;
  String? _verificationId;

  AuthLoadingState get loadingState  => _loadingState;
  bool get isLoading                 => _loadingState != AuthLoadingState.idle;
  bool get isGoogleLoading           => _loadingState == AuthLoadingState.google;
  bool get isPhoneLoading            => _loadingState == AuthLoadingState.phone;
  bool get isPhoneVerifyLoading      => _loadingState == AuthLoadingState.phoneVerify;
  bool get isEmailLoading            =>
      _loadingState == AuthLoadingState.emailSignIn ||
      _loadingState == AuthLoadingState.emailRegister;
  String? get errorMessage           => _errorMessage;
  User? get currentUser              => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// True when signed-in user is verified OR used a social provider.
  bool get isEmailVerified {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (user.emailVerified) return true;
    return user.providerData.any((p) =>
        p.providerId == 'google.com' ||
        p.providerId == 'phone' ||
        p.providerId == 'apple.com' ||
        p.providerId == 'facebook.com');
  }

  void _setLoading(AuthLoadingState state) {
    _loadingState = state;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ── Email / Password Sign-In ───────────────────────────────────────────
  Future<bool> signInWithEmail(String email, String password) async {
    _errorMessage = null;
    _setLoading(AuthLoadingState.emailSignIn);
    try {
      final result = await _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = result.user;
      const skipVerification = kIsWeb;
      if (user != null && !skipVerification && !isEmailVerified) {
        _errorMessage = 'email_not_verified';
        _setLoading(AuthLoadingState.idle);
        return false;
      }
      if (user?.uid != null) {
        FirebaseService().registerEmailLookup(user!.uid, email.trim());
        _saveFcmTokenForUser(user.uid);
      }
      _setLoading(AuthLoadingState.idle);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setLoading(AuthLoadingState.idle);
      return false;
    } catch (_) {
      _errorMessage = 'auth_err_unexpected';
      _setLoading(AuthLoadingState.idle);
      return false;
    }
  }

  // ── Email / Password Registration ──────────────────────────────────────
  Future<bool> registerWithEmail(
      String email, String password, String displayName) async {
    _errorMessage = null;
    _setLoading(AuthLoadingState.emailRegister);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      final user = credential.user;
      if (user != null) {
        if (displayName.trim().isNotEmpty) {
          await user.updateDisplayName(displayName.trim());
        }
        await user.sendEmailVerification();
        FirebaseService().registerEmailLookup(user.uid, email.trim());
      }
      _setLoading(AuthLoadingState.idle);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setLoading(AuthLoadingState.idle);
      return false;
    } catch (_) {
      _errorMessage = 'auth_err_unexpected';
      _setLoading(AuthLoadingState.idle);
      return false;
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────────────
  Future<bool> signInWithGoogle() async {
    _errorMessage = null;
    _setLoading(AuthLoadingState.google);
    try {
      if (kIsWeb) {
        try {
          final silentUser = await _googleSignIn.signInSilently();
          if (silentUser != null) {
            return await _completeGoogleSignIn(silentUser);
          }
        } catch (_) {}
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setLoading(AuthLoadingState.idle);
        return false;
      }
      return await _completeGoogleSignIn(googleUser);
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      _setLoading(AuthLoadingState.idle);
      return false;
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('popup_closed') ||
          errStr.contains('user_cancelled') ||
          errStr.contains('canceled') ||
          errStr.contains('cancelled')) {
        _setLoading(AuthLoadingState.idle);
        return false;
      }
      if (errStr.contains('network')) {
        _errorMessage = 'auth_err_network';
      } else {
        _errorMessage = 'auth_err_google_failed';
      }
      _setLoading(AuthLoadingState.idle);
      return false;
    }
  }

  Future<bool> _completeGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user?.uid != null && user?.email != null) {
        FirebaseService().registerEmailLookup(user!.uid, user.email!);
        FirebaseService().saveGoogleProfile(user.uid, user.displayName, user.photoURL);
        _saveFcmTokenForUser(user.uid);
      }
      _setLoading(AuthLoadingState.idle);
      return true;
    } catch (e) {
      _errorMessage = 'auth_err_google_failed';
      _setLoading(AuthLoadingState.idle);
      return false;
    }
  }

  // ── Phone Number Sign-In ───────────────────────────────────────────────
  /// Step 1: Send OTP to phone number.
  /// [phoneNumber] must include country code, e.g. "+8801XXXXXXXXX"
  /// Returns true if OTP was sent successfully.
  Future<bool> sendPhoneOTP(
    String phoneNumber, {
    required void Function() onCodeSent,
    required void Function(String errorKey) onError,
    String dialCode = '+880',
  }) async {
    _errorMessage = null;
    _setLoading(AuthLoadingState.phone);

    // [FIX-E164] Normalise to E.164 before sending to Firebase.
    // Without this, bare numbers like "01711XXXXXX" fail silently.
    final normalised = CountryCodeService.normalizeE164(
      phoneNumber.trim(),
      dialCode: dialCode,
    );
    if (kDebugMode) debugPrint('[Auth] OTP → normalised: $normalised');

    bool sent = false;
    await _auth.verifyPhoneNumber(
      phoneNumber: normalised,
      timeout: const Duration(seconds: 60),

      // Android auto-verification (no OTP needed)
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          if (result.user?.uid != null) {
            _saveFcmTokenForUser(result.user!.uid);
          }
        } catch (_) {}
        _setLoading(AuthLoadingState.idle);
      },

      verificationFailed: (FirebaseAuthException e) {
        _errorMessage = _mapPhoneError(e.code);
        _setLoading(AuthLoadingState.idle);
        onError(_errorMessage!);
      },

      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        sent = true;
        _setLoading(AuthLoadingState.idle);
        onCodeSent();
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );

    return sent;
  }

  /// Step 2: Verify the OTP entered by the user.
  Future<bool> verifyPhoneOTP(String otp) async {
    if (_verificationId == null) {
      _errorMessage = 'auth_err_phone_failed';
      return false;
    }
    _errorMessage = null;
    _setLoading(AuthLoadingState.phoneVerify);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp.trim(),
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user?.uid != null) {
        _saveFcmTokenForUser(user!.uid);
      }
      _setLoading(AuthLoadingState.idle);
      return user != null;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapPhoneError(e.code);
      _setLoading(AuthLoadingState.idle);
      return false;
    } catch (_) {
      _errorMessage = 'auth_err_unexpected';
      _setLoading(AuthLoadingState.idle);
      return false;
    }
  }

  // ── Auto Session Restore ───────────────────────────────────────────────
  Future<bool> tryRestoreSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.getIdToken();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── FCM Token Helper ──────────────────────────────────────────────────
  static Future<void> _saveFcmTokenForUser(String uid) async {
    try {
      final token = await NotificationService.getFcmToken();
      if (token != null) {
        await FirebaseService().saveFcmToken(uid, token);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] FCM token save failed: $e');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────
  Future<void> logout() async {
    _setLoading(AuthLoadingState.logout);
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) await FirebaseService().removeFcmToken(uid);
    } catch (_) {}
    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    try {
      await _auth.signOut();
    } catch (_) {}
    await SecureStorage.clearAll();
    _verificationId = null;
    _setLoading(AuthLoadingState.idle);
  }

  // ── Password Reset ─────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapError(e.code);
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── Resend Verification Email ──────────────────────────────────────────
  Future<bool> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Password Validation ───────────────────────────────────────────────
  static String? validatePassword(String? v, {bool isLogin = false}) {
    if (v == null || v.isEmpty) return 'pwd_required';
    if (isLogin) return null;
    if (v.length < 8) return 'pwd_min_8';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'pwd_need_upper';
    if (!v.contains(RegExp(r'[0-9]'))) return 'pwd_need_number';
    return null;
  }

  // ── Compatibility aliases ──────────────────────────────────────────────
  Future<bool> login(String email, String password) =>
      signInWithEmail(email, password);

  Future<bool> register(String email, String password) =>
      registerWithEmail(email, password, '');

  // ── Error → l10n key ─────────────────────────────────────────────────
  String _mapError(String code) {
    switch (code) {
      case 'user-not-found':                           return 'auth_err_no_account';
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':                return 'auth_err_wrong_password';
      case 'invalid-email':                            return 'auth_err_invalid_email';
      case 'user-disabled':                            return 'auth_err_disabled';
      case 'email-already-in-use':                     return 'auth_err_email_in_use';
      case 'weak-password':                            return 'auth_err_weak_password';
      case 'operation-not-allowed':                    return 'auth_err_not_allowed';
      case 'network-request-failed':                   return 'auth_err_network';
      case 'too-many-requests':                        return 'auth_err_too_many';
      case 'account-exists-with-different-credential': return 'auth_err_account_exists';
      default:                                         return 'auth_err_generic';
    }
  }

  String _mapPhoneError(String code) {
    switch (code) {
      case 'invalid-phone-number':    return 'auth_err_invalid_phone';
      case 'invalid-verification-code':
      case 'invalid-verification-id': return 'auth_err_invalid_otp';
      case 'session-expired':         return 'auth_err_otp_expired';
      case 'too-many-requests':       return 'auth_err_too_many';
      case 'network-request-failed':  return 'auth_err_network';
      default:                        return 'auth_err_phone_failed';
    }
  }
}
