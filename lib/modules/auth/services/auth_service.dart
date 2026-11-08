import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../firebase_options.dart';
import '../../notebook/repositories/notebook_repository.dart';
import '../models/user_account.dart';

class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();

  final NotebookRepository _notebookRepo;
  UserAccount _currentUser = UserAccount.guest();
  bool _isFirebaseInitialized = false;
  bool _isGoogleSignInInitialized = false;
  bool _isBusy = false;
  StreamSubscription<User?>? _authSubscription;

  /// Optional custom OAuth handler for unit tests
  Future<UserAccount?> Function()? customGoogleSignInHandler;

  AuthService._internal() : _notebookRepo = NotebookRepository();

  AuthService({NotebookRepository? notebookRepo, this.customGoogleSignInHandler})
      : _notebookRepo = notebookRepo ?? NotebookRepository();

  UserAccount get currentUser => _currentUser;
  bool get isSignedIn => !_currentUser.isGuest;
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  bool get isBusy => _isBusy;

  /// Initializes local user state from SQLite and connects to Firebase if configured.
  Future<void> initialize() async {
    await refreshLocalAccount();

    if (!DefaultFirebaseOptions.isConfigured) {
      _isFirebaseInitialized = false;
      return;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _isFirebaseInitialized = true;

      // Initialize GoogleSignIn 7.x on supported mobile/macOS platforms only (skip Web & Desktop)
      if (_usesNativeGoogleSignInPlugin) {
        await _ensureGoogleSignInInitialized();
      }

      // Listen to Firebase Auth state changes
      _authSubscription?.cancel();
      _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
        (User? fbUser) async {
          if (fbUser != null) {
            await _syncFirebaseUserToLocal(fbUser);
          }
        },
        onError: (e) {
          debugPrint('Firebase Auth stream error: $e');
        },
      );
    } catch (e) {
      _isFirebaseInitialized = false;
      debugPrint('Firebase initialization skipped (offline/unconfigured): $e');
    }
  }

  bool get _usesNativeGoogleSignInPlugin {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized || kIsWeb) return;
    try {
      await GoogleSignIn.instance.initialize();
      _isGoogleSignInInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn.initialize warning: $e');
    }
  }

  /// Reloads the user account from SQLite `user_profile`.
  Future<UserAccount> refreshLocalAccount() async {
    final profileMap = await _notebookRepo.getUserProfile();
    _currentUser = UserAccount.fromProfileMap(profileMap);
    notifyListeners();
    return _currentUser;
  }

  /// Signs in with Google across all platforms (Web, Android, iOS, macOS, Windows, Linux).
  Future<UserAccount> signInWithGoogle() async {
    _isBusy = true;
    notifyListeners();

    try {
      // 1. If a custom test handler is injected, use it
      if (customGoogleSignInHandler != null) {
        final account = await customGoogleSignInHandler!();
        if (account != null) {
          await _notebookRepo.updateAuthProfile(
            firebaseUid: account.uid,
            email: account.email,
            displayName: account.displayName,
            photoUrl: account.photoUrl,
          );
          return await refreshLocalAccount();
        }
        throw Exception('Đã hủy đăng nhập Google.');
      }

      // 2. Verify Firebase configuration
      if (!_isFirebaseInitialized) {
        await initialize();
      }
      if (!_isFirebaseInitialized) {
        throw Exception(
          'Dự án Firebase chưa được cấu hình (lib/firebase_options.dart). '
          'Vui lòng chạy `flutterfire configure` sau khi tạo dự án Firebase.',
        );
      }

      final FirebaseAuth auth = FirebaseAuth.instance;
      UserCredential credential;

      if (kIsWeb) {
        // Web: Use popup flow to avoid DWDS hangs
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        credential = await auth.signInWithPopup(googleProvider);
      } else if (_usesNativeGoogleSignInPlugin) {
        // Android / iOS / macOS: Use google_sign_in 7.x authenticate() flow, fallback to signInWithProvider
        try {
          await _ensureGoogleSignInInitialized();
          final GoogleSignInAccount googleUser =
              await GoogleSignIn.instance.authenticate();
          final GoogleSignInAuthentication googleAuth =
              googleUser.authentication;

          final OAuthCredential oauthCred = GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          );
          credential = await auth.signInWithCredential(oauthCred);
        } catch (nativeErr) {
          debugPrint('Native GoogleSignIn fallback to provider flow: $nativeErr');
          final googleProvider = GoogleAuthProvider();
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          credential = await auth.signInWithProvider(googleProvider);
        }
      } else {
        // Windows / Linux Desktop: Use Firebase OAuth provider flow
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        credential = await auth.signInWithProvider(googleProvider);
      }

      final User? fbUser = credential.user;
      if (fbUser == null) {
        throw Exception('Không nhận được thông tin tài khoản từ Google.');
      }

      await _syncFirebaseUserToLocal(fbUser);
      return _currentUser;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _syncFirebaseUserToLocal(User fbUser) async {
    await _notebookRepo.updateAuthProfile(
      firebaseUid: fbUser.uid,
      email: fbUser.email ?? 'user@gmail.com',
      displayName: fbUser.displayName ?? 'Người học LangCurve',
      photoUrl: fbUser.photoURL,
    );
    await refreshLocalAccount();
  }

  /// Signs out from Google and Firebase, returning the local profile to Guest mode
  /// while keeping all local vocabulary and SRS progress intact.
  Future<void> signOut() async {
    _isBusy = true;
    notifyListeners();

    try {
      if (_isFirebaseInitialized) {
        if (!kIsWeb && _isGoogleSignInInitialized) {
          try {
            await GoogleSignIn.instance.signOut();
          } catch (e) {
            debugPrint('GoogleSignIn signOut warning: $e');
          }
        }
        try {
          await FirebaseAuth.instance.signOut();
        } catch (e) {
          debugPrint('FirebaseAuth signOut warning: $e');
        }
      }

      await _notebookRepo.updateAuthProfile(
        firebaseUid: null,
        email: 'guest@langcurve.local',
        displayName: 'Người học LangCurve',
        photoUrl: null,
      );
      await refreshLocalAccount();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
