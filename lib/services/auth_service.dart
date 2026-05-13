import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '245256901547-k0c9448nrsctnlbhv1b7b74flt0nqpp4.apps.googleusercontent.com',
  );

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    } catch (error) {
      throw AuthServiceException('Unable to sign in. ${error.toString()}');
    }
  }

  Future<void> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(displayName);
      await userCredential.user?.reload();
    } on FirebaseAuthException {
      rethrow;
    } catch (error) {
      throw AuthServiceException(
        'Unable to create your account. ${error.toString()}',
      );
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return false;
      }

      final googleAuthentication = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuthentication.accessToken,
        idToken: googleAuthentication.idToken,
      );

      await _firebaseAuth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException {
      rethrow;
    } on PlatformException catch (error) {
      throw AuthServiceException(_googleSignInPlatformMessage(error));
    } catch (error) {
      throw AuthServiceException(
        'Unable to sign in with Google. ${error.toString()}',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } on FirebaseAuthException {
      rethrow;
    } catch (error) {
      throw AuthServiceException('Unable to log out. ${error.toString()}');
    }
  }

  String _googleSignInPlatformMessage(PlatformException error) {
    final details = error.message ?? error.details?.toString() ?? '';
    final isDeveloperConfigurationError =
        error.code == 'sign_in_failed' && details.contains(': 10:');

    if (isDeveloperConfigurationError) {
      return 'Google sign-in is not configured for this APK. Add this app package and signing SHA fingerprint in Firebase, download the updated google-services.json, then rebuild.';
    }

    return 'Unable to sign in with Google. ${error.message ?? error.code}';
  }
}

class AuthServiceException implements Exception {
  final String message;

  const AuthServiceException(this.message);

  @override
  String toString() {
    return message;
  }
}
