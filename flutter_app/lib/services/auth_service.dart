import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _fa = FirebaseAuth.instance;

  static User? get currentUser => _fa.currentUser;

  static Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null;
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await _fa.signInWithCredential(credential);
    return userCred.user;
  }

  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _fa.signOut();
  }
}
