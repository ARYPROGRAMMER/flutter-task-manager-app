import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_overlay.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _authErrorMessage;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    setState(() {
      _authErrorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await context.read<AuthService>().signUpWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _displayNameController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      _showAuthError(_friendlyAuthMessage(error));
    } catch (error) {
      _showAuthError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignup() async {
    setState(() {
      _authErrorMessage = null;
      _isLoading = true;
    });

    try {
      final didSignIn = await context.read<AuthService>().signInWithGoogle();

      if (didSignIn && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (error) {
      _showAuthError(_friendlyGoogleAuthMessage(error));
    } catch (error) {
      _showAuthError(error.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAuthError(String message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _authErrorMessage = message;
    });
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use at least 6 characters for the password.';
      case 'network-request-failed':
        return 'Network connection failed. Please try again.';
      default:
        return error.message ?? 'Unable to create your account.';
    }
  }

  String _friendlyGoogleAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'That email is already connected to another sign-in method.';
      case 'invalid-credential':
        return 'Google could not verify this sign-in. Check Firebase setup.';
      case 'operation-not-allowed':
        return 'Google sign-in is not enabled for this Firebase project.';
      case 'network-request-failed':
        return 'Network connection failed. Please try again.';
      default:
        return error.message ?? 'Unable to sign up with Google.';
    }
  }

  String? _validateDisplayName(String? value) {
    final displayName = value?.trim() ?? '';

    if (displayName.isEmpty) {
      return 'Display name is required';
    }

    if (displayName.length < 2) {
      return 'Display name must be at least 2 characters';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Email address is required';
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SignupHeader(theme: theme),
                      const SizedBox(height: 28),
                      if (_authErrorMessage != null)
                        _SignupErrorBanner(message: _authErrorMessage!),
                      CustomTextField(
                        controller: _displayNameController,
                        labelText: 'Display Name',
                        prefixIcon: Icons.person_outline,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: _validateDisplayName,
                      ),
                      CustomTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        prefixIcon: Icons.alternate_email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),
                      CustomTextField(
                        controller: _passwordController,
                        labelText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleSignup,
                        icon: const Icon(Icons.person_add_alt_rounded),
                        label: const Text('Sign Up'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleSignup,
                        icon: const _GoogleMark(),
                        label: const Text('Sign up with Google'),
                      ),
                    ],
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.primaryContainer,
      ),
      child: Text(
        'G',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SignupHeader extends StatelessWidget {
  final ThemeData theme;

  const _SignupHeader({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            color: theme.colorScheme.primaryContainer,
          ),
          child: Icon(
            Icons.checklist_rounded,
            color: theme.colorScheme.onPrimaryContainer,
            size: 46,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Create account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Build a clean workspace for every task.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SignupErrorBanner extends StatelessWidget {
  final String message;

  const _SignupErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
