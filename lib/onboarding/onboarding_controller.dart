import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'onboarding_state.dart';
import '../enums/profession.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class OnboardingController extends ChangeNotifier {
  OnboardingState _state = const OnboardingState(step: OnboardingStep.intro);

  OnboardingState get state => _state;
  bool get isCompleted => _state.step == OnboardingStep.completed;

  // ============================
  // GETTERS PARA EL HOME
  // ============================

  String get userName {
    if (_state.name != null && _state.name!.isNotEmpty) {
      return _state.name!;
    }
    if (_state.email != null) {
      return _state.email!.split('@').first;
    }
    return "Usuario";
  }

  String get professionLabel {
    if (_state.profession == null) return "Sin profesión";

    switch (_state.profession!) {
      case Profession.lawyer: return "Abogado";
      case Profession.doctor: return "Médico";
      case Profession.engineer: return "Ingeniero";
      case Profession.student: return "Estudiante";
      case Profession.educator: return "Maestro";
      case Profession.architect: return "Arquitecto";
      case Profession.general: return "General";
      case Profession.marketer: return "Marketer";
    }
  }

  String get level => "Principiante";

  // ============================
  // NAVEGACIÓN ENTRE PASOS
  // ============================

  void next(OnboardingStep step) {
    print("🔄 Cambiando paso del onboarding a: $step");
    _state = _state.copyWith(step: step);
    notifyListeners();
  }

  // ============================
  // 🔥 RESETEAR A INTRO (PARA USUARIOS NUEVOS)
  // ============================

  void resetToIntro() {
    print("🔄 Resetando onboarding a Intro");
    _state = _state.copyWith(
      step: OnboardingStep.intro,
      // Mantener email y nombre para no perder datos
    );
    notifyListeners();
  }

  // ============================
  // CUANDO EL USUARIO SE AUTENTICA
  // ============================

  void onAuthenticated({
    required String email,
    String? name,
    required bool isGoogle,
  }) {
    print("✅ Usuario autenticado: $email, Google: $isGoogle");
    _state = _state.copyWith(
      email: email,
      name: name,
      isGoogleSignIn: isGoogle,
      step: OnboardingStep.profession,
    );
    notifyListeners();
  }

  // ============================
  // CUANDO ELIGE PROFESIÓN (NUEVO USUARIO)
  // ============================

  Future<void> setProfession(Profession profession) async {
    final needsProfile = !_state.isGoogleSignIn && (_state.name == null);
    _state = _state.copyWith(
      profession: profession,
      step: needsProfile ? OnboardingStep.profile : OnboardingStep.completed,
    );
    notifyListeners();

    if (_state.step == OnboardingStep.completed) {
      await _saveUserProfessionToFirestore(profession);
    }
  }

  // ============================
  // 🔥 CARGAR PROFESIÓN GUARDADA (USUARIO EXISTENTE)
  // ============================

  void setProfessionFromSaved(Profession profession) {
    print("📥 Cargando profesión guardada: $profession");
    _state = _state.copyWith(
      profession: profession,
      step: OnboardingStep.completed,
    );
    print("✅ Profesión cargada desde Firestore. Paso actual: ${_state.step}");
    notifyListeners();
  }

  // ============================
  // 🔥 GUARDAR PROFESIÓN EN FIRESTORE
  // ============================

  Future<void> _saveUserProfessionToFirestore(Profession profession) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("⚠️ No hay usuario autenticado para guardar");
      return;
    }

    try {
      print("💾 Guardando profesión en Firestore: ${profession.name}");
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'name': _state.name ?? user.displayName ?? user.email?.split('@').first,
        'profession': profession.name,
        'isGoogleUser': _state.isGoogleSignIn,
        'onboardingCompleted': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      print("✅ Profesión guardada exitosamente en Firestore");
    } catch (e) {
      print("❌ Error guardando profesión: $e");
    }
  }

  // ============================
  // 🔥 CARGAR DATOS DESDE FIRESTORE
  // ============================

  Future<void> loadUserDataFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      print("📥 Cargando datos de Firestore para: ${user.uid}");

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // 🔹 PROFESIÓN
        if (data['profession'] != null) {
          final professionName = data['profession'] as String;
          for (var p in Profession.values) {
            if (p.name == professionName) {
              setProfessionFromSaved(p);
              break;
            }
          }
        }

        // 🔹 NOMBRE
        if (data['name'] != null && _state.name == null) {
          _state = _state.copyWith(name: data['name']);
        }

        // 🔥 🔥 🔥 FOTO DE PERFIL (AQUÍ VA)
        if (data['photoUrl'] != null) {
          _state = _state.copyWith(photoUrl: data['photoUrl']);
        }

        notifyListeners(); // 👈 IMPORTANTE
      }
    } catch (e) {
      print("❌ Error cargando datos de Firestore: $e");
    }
  }

  // ============================
  // 🔥 MÉTODO PARA ACTUALIZAR PERFIL (OPCIONAL)
  // ============================

  Future<void> updateUserProfile({
    String? name,
    Profession? profession,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      Map<String, dynamic> updates = {};
      if (name != null) {
        updates['name'] = name;
        _state = _state.copyWith(name: name);
      }
      if (profession != null) {
        updates['profession'] = profession.name;
        _state = _state.copyWith(profession: profession);
      }

      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update(updates);
        print("✅ Perfil actualizado en Firestore");
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error actualizando perfil: $e");
    }
  }

  Future<String?> uploadProfileImage(File imageFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      // Mostrar indicador de carga
      print("📤 Subiendo imagen a Firebase Storage...");

      // Crear referencia en Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('profile_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Subir archivo
      final uploadTask = await storageRef.putFile(imageFile);

      // Obtener URL de descarga
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // Guardar URL en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'photoUrl': downloadUrl});

      // Actualizar estado local
      _state = _state.copyWith(photoUrl: downloadUrl);
      notifyListeners();

      print("✅ Foto subida exitosamente: $downloadUrl");
      return downloadUrl;

    } catch (e) {
      print("❌ Error subiendo imagen: $e");
      return null;
    }
  }
}