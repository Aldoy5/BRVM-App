import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository.dart';

/// Provider du repository d'authentification
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Flux d'état d'authentification (émet à chaque connexion / déconnexion)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Utilisateur actuellement connecté (null si déconnecté)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

/// Identifiant unique (UID) de l'utilisateur connecté
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});
