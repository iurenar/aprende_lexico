// lib/auth/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _googleSignIn = GoogleSignIn();

  // 🔥 GUARDAR USUARIO EN FIRESTORE
  static Future<void> _saveUserToFirestore(User user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        // Usuario nuevo - crear documento
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName ?? user.email?.split('@').first ?? 'Usuario',
          'photoURL': user.photoURL,
          'profession': null, // Se llenará en onboarding
          'level': 'principiante',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
          'isGoogleUser': user.providerData.any((info) => info.providerId == 'google.com'),
        });

        print("✅ Usuario creado en Firestore: ${user.uid}");
      } else {
        // Usuario existente - actualizar último login
        await userRef.update({
          'lastLogin': FieldValue.serverTimestamp(),
          'name': user.displayName ?? userDoc.get('name'),
        });

        print("✅ Usuario actualizado en Firestore: ${user.uid}");
      }
    } catch (e) {
      print("❌ Error guardando usuario en Firestore: $e");
    }
  }

  // 🔥 LOGIN CON EMAIL
  static Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Auth Error: ${e.code}");
      rethrow;
    }
  }

  // 🔥 CREAR CUENTA NUEVA
  static Future<User?> createUserWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ Firebase Error crear cuenta: ${e.code}");
      rethrow;
    }
  }

  // 🔥 GOOGLE SIGN IN
  static Future<User?> signInWithGoogle() async {
    try {
      print("🔵 Google Sign-In iniciado");

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print("⚠️ Usuario canceló Google Sign-In");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _saveUserToFirestore(userCredential.user!);
      }

      print("✅ Google Sign-In exitoso");
      return userCredential.user;
    } catch (e) {
      debugPrint("❌ Google Sign-In Error: $e");
      rethrow;
    }
  }

  // 🔥 CERRAR SESIÓN
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // 🔥 VERIFICAR SI HAY USUARIO LOGUEADO
  static User? get currentUser => _auth.currentUser;

  // 🔥 STREAM DE AUTENTICACIÓN (para escuchar cambios)
  static Stream<User?> get authStateChanges => _auth.authStateChanges();
}