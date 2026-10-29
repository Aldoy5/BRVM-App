import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import 'auth_providers.dart';
import 'auth_repository.dart';

/// Écran de connexion et de création de compte par Email / Mot de passe
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authRepo = ref.read(authRepositoryProvider);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isRegisterMode) {
        await authRepo.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await authRepo.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // La redirection est gérée automatiquement par le routeur
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthRepository.mapAuthError(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ResponsiveCenter(
              maxWidth: 440,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Logo / En-tête
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet,
                              size: 34,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppConstants.appName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _isRegisterMode
                              ? 'Créez votre compte pour gérer votre portefeuille'
                              : 'Connectez-vous pour accéder à vos titres',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Message d'erreur s'il y a lieu
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.lossLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.loss.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 20,
                                  color: AppColors.loss,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.loss,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Champ Email
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: 'Adresse e-mail',
                            hintText: 'exemple@domaine.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez saisir votre adresse e-mail';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Veuillez saisir une adresse e-mail valide';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Champ Mot de passe
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9F9F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez saisir votre mot de passe';
                            }
                            if (value.length < 6) {
                              return 'Le mot de passe doit comporter au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Bouton principal d'action
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _isRegisterMode ? 'Créer un compte' : 'Se connecter',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Lien bascule Connexion / Inscription
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isRegisterMode = !_isRegisterMode;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isRegisterMode
                                ? 'Déjà un compte ? Se connecter'
                                : 'Pas encore de compte ? S\'inscrire',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
