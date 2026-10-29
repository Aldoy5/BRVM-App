import 'package:firebase_auth/firebase_auth.dart';

/// Repository gérant l'authentification Firebase (Email / Mot de passe)
class AuthRepository {
  final FirebaseAuth? _customAuth;

  AuthRepository({FirebaseAuth? auth}) : _customAuth = auth;

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) return const Stream.empty();
    return auth.authStateChanges();
  }

  User? get currentUser => _auth?.currentUser;

  /// Connexion avec Email et Mot de passe
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Service d\'authentification indisponible.');
    }
    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Création d'un nouveau compte avec Email et Mot de passe
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Service d\'authentification indisponible.');
    }
    return await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  /// Convertit les codes d'erreur Firebase Auth en messages lisibles en français
  static String mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'Aucun utilisateur trouvé avec cette adresse email.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Adresse email ou mot de passe incorrect.';
        case 'email-already-in-use':
          return 'Cette adresse email est déjà associée à un compte.';
        case 'invalid-email':
          return 'Le format de l\'adresse email est invalide.';
        case 'weak-password':
          return 'Le mot de passe doit comporter au moins 6 caractères.';
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'too-many-requests':
          return 'Trop de tentatives infructueuses. Veuillez réessayer plus tard.';
        case 'network-request-failed':
          return 'Erreur réseau : vérifiez votre connexion internet.';
        default:
          return error.message ?? 'Une erreur d\'authentification est survenue.';
      }
    }
    return error.toString();
  }
}
