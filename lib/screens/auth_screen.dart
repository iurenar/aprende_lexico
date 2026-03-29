import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import 'package:aprende_lexico/onboarding/onboarding_state.dart';
import 'package:aprende_lexico/auth/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMessage;
  final FocusNode _passwordFocusNode = FocusNode();

  // Validaciones
  bool get _isValidEmail =>
      _emailController.text.trim().isNotEmpty &&
          _emailController.text.contains('@');

  bool get _isValidPassword => _passwordController.text.length >= 6;
  bool get _isFormValid => _isValidEmail && _isValidPassword;

  void _clearError() {
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }
  }

  // 🔥 MÉTODO CLAVE: Navegar al OnboardingFlow
  void _navigateToOnboardingFlow() {
    print("🚀 Navegando a OnboardingFlow desde AuthScreen");

    // Método 1: Usar Navigator pushReplacementNamed (recomendado)
    Navigator.pushReplacementNamed(context, '/onboarding');

    // Método 2: O usar Navigator pushReplacement directamente
    // Navigator.pushReplacement(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => const OnboardingFlow(),
    //   ),
    // );
  }
  void _continueToProfessionTemporarily() {
    print("🧪 Acceso temporal a ProfessionScreen");

    context.read<OnboardingController>().onAuthenticated(
      email: 'temp@lexia.app',
      name: 'Usuario temporal',
      isGoogle: false,
    );
  }

  // Login con email
  Future<void> _signInWithEmail() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print("📧 Intentando login con email: $email");

      final user = await AuthService.signInWithEmail(
        email: email,
        password: password,
      );

      if (user != null && context.mounted) {
        print("✅ Login exitoso con email");

        // 🔥 1. Actualizar el estado del controller
        context.read<OnboardingController>().onAuthenticated(
          email: user.email ?? email,
          name: user.displayName,
          isGoogle: false,
        );

        // 🔥 2. Navegar al OnboardingFlow
        _navigateToOnboardingFlow();

        // 🔥 3. Asegurarse de que está en el paso "profession"
        // Esto ya lo hace onAuthenticated() según tu controller
      } else {
        setState(() => _errorMessage = 'Error en la autenticación');
      }
    } catch (e) {
      print("❌ Error en login email: $e");
      setState(() => _errorMessage = _getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Login con Google
// Login con Google - VERSIÓN MEJORADA
  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print("🔄 Ejecutando _signInWithGoogle()...");

      final user = await AuthService.signInWithGoogle();

      if (user != null) {
        print("✅ Google Sign-In exitoso en UI");
        print("📧 Email del usuario: ${user.email}");
        print("👤 Nombre: ${user.displayName}");
        print("🔑 UID: ${user.uid}");

        if (context.mounted) {
          // 🔥 Actualizar el estado del controller
          context.read<OnboardingController>().onAuthenticated(
            email: user.email ?? '',
            name: user.displayName,
            isGoogle: true,
          );

          // 🔥 Navegar al OnboardingFlow
          _navigateToOnboardingFlow();
        }
      } else {
        print("⚠️ Google Sign-In retornó null (usuario canceló)");
        setState(() => _errorMessage = 'Autenticación cancelada');
      }
    } catch (e, stackTrace) {
      print("❌ ERROR CRÍTICO en Google Sign-In:");
      print("Error: $e");
      print("Stack trace: $stackTrace");

      // Manejo específico de errores
      String errorMsg = 'Error en Google Sign-In';

      if (e.toString().contains('sign_in_failed')) {
        errorMsg = 'Error de configuración de Google';
      } else if (e.toString().contains('12500')) {
        errorMsg = 'Configura el SHA-1 en Firebase Console';
      } else if (e.toString().contains('12501')) {
        errorMsg = 'El usuario canceló el inicio de sesión';
      } else if (e.toString().contains('NETWORK_ERROR')) {
        errorMsg = 'Error de conexión a internet';
      } else if (e.toString().contains('INVALID_CREDENTIAL')) {
        errorMsg = 'Credenciales de Firebase incorrectas';
      }

      setState(() => _errorMessage = errorMsg);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Para crear cuenta nueva
  Future<void> _createAccount() async {
    if (!_isFormValid) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      print("📝 Creando cuenta nueva: $email");

      // Asegúrate de tener este método en AuthService
      final user = await AuthService.createUserWithEmail(
        email: email,
        password: password,
      );

      if (user != null && context.mounted) {
        print("✅ Cuenta creada exitosamente");

        // 🔥 1. Actualizar el estado del controller
        context.read<OnboardingController>().onAuthenticated(
          email: user.email ?? email,
          name: user.displayName,
          isGoogle: false,
        );

        // 🔥 2. Navegar al OnboardingFlow
        _navigateToOnboardingFlow();
      } else {
        setState(() => _errorMessage = 'Error al crear cuenta');
      }
    } catch (e) {
      print("❌ Error creando cuenta: $e");
      setState(() => _errorMessage = _getErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    print("⚠️ Error recibido: $errorStr");

    if (errorStr.contains('invalid-email')) return 'Email inválido';
    if (errorStr.contains('user-not-found') || errorStr.contains('wrong-password'))
      return 'Credenciales incorrectas';
    if (errorStr.contains('too-many-requests')) return 'Demasiados intentos';
    if (errorStr.contains('network-request-failed')) return 'Error de conexión';
    if (errorStr.contains('email-already-in-use')) return 'El email ya está registrado';
    if (errorStr.contains('weak-password')) return 'Contraseña muy débil';
    return 'Error: $errorStr';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Crear cuenta"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            const Text(
              "Bienvenido a LEXIGA",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Mejora tu comunicación profesional",
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Formulario
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        prefixIcon: const Icon(Icons.email),
                        errorText: _emailController.text.isNotEmpty && !_isValidEmail
                            ? 'Email inválido'
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onChanged: (_) {
                        _clearError();
                        setState(() {});
                      },
                      onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                        errorText: _passwordController.text.isNotEmpty && !_isValidPassword
                            ? 'Mínimo 6 caracteres'
                            : null,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      obscureText: !_showPassword,
                      onChanged: (_) {
                        _clearError();
                        setState(() {});
                      },
                      onSubmitted: (_) {
                        if (_isFormValid) _signInWithEmail();
                      },
                    ),

                    // Enlace recuperar contraseña
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          print("ℹ️ Recuperar contraseña");
                        },
                        child: const Text("¿Olvidaste tu contraseña?"),
                      ),
                    ),

                    // Mensaje de error
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Botón Continuar (Login)
            ElevatedButton(
              onPressed: _isFormValid && !_isLoading ? _signInWithEmail : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.indigo,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
                  : const Text("Continuar", style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 16),

            // Separador
            Row(children: [
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text("o continúa con", style: TextStyle(color: Colors.grey.shade600)),
              ),
              Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
            ]),

            const SizedBox(height: 16),

            // Botón Google
            ElevatedButton.icon(
              icon: Image.asset("assets/google.png", height: 20, width: 20),
              label: Text(
                _isLoading ? "Procesando..." : "Continuar con Google",
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                elevation: 0,
              ),
              onPressed: _isLoading ? null : _signInWithGoogle,
            ),

            const SizedBox(height: 24),
            const SizedBox(height: 12),

            TextButton(
              onPressed: _isLoading ? null : _continueToProfessionTemporarily,
              child: const Text(
                "Continuar sin iniciar sesión (temporal)",
                style: TextStyle(
                  decoration: TextDecoration.underline,
                  color: Colors.grey,
                ),
              ),
            ),

            // Enlace Registro/Cuenta
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("¿No tienes cuenta? "),
                TextButton(
                  onPressed: _isLoading ? null : _createAccount,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Regístrate",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}