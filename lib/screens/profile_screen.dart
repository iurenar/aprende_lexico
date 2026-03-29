import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aprende_lexico/onboarding/onboarding_controller.dart';
import '../enums/profession.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  Profession _selectedProfession = Profession.general;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    final controller = context.read<OnboardingController>();
    _nameController = TextEditingController(text: controller.userName);
    _selectedProfession = controller.state.profession;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final controller = context.read<OnboardingController>();

      // Actualizar nombre si cambió
      if (_nameController.text != controller.userName) {
        await controller.updateUserProfile(name: _nameController.text);
      }

      // Actualizar profesión si cambió
      if (_selectedProfession != controller.state.profession) {
        await controller.updateUserProfile(profession: _selectedProfession);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showImageSource() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Elegir de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        setState(() {
          _imageFile = file;
          _isLoading = true;
        });

        final controller = context.read<OnboardingController>();
        final url = await controller.uploadProfileImage(file);

        if (url != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Foto actualizada')),
          );
        }
      }
    } catch (e) {
      print("❌ Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto de perfil (placeholder)
              Consumer<OnboardingController>(
                builder: (context, controller, child) {
                  return Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: _imageFile != null
                            ? FileImage(_imageFile!)
                            : (controller.state.photoUrl != null
                            ? NetworkImage(controller.state.photoUrl!)
                            : const AssetImage('assets/lexiga/icono.png') as ImageProvider),
                      ),

                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImageSource,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.indigo,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),

              // Email (solo lectura)
              Consumer<OnboardingController>(
                builder: (context, controller, child) {
                  return TextFormField(
                    initialValue: controller.state.email ?? 'No disponible',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.email),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Nombre (editable)
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Profesión (selector)
              Consumer<OnboardingController>(
                builder: (context, controller, child) {
                  return DropdownButtonFormField<Profession>(
                    value: _selectedProfession,
                    decoration: InputDecoration(
                      labelText: 'Profesión',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.work),
                    ),
                    items: Profession.values.map((profession) {
                      String label;
                      switch (profession) {
                        case Profession.lawyer: label = 'Abogado';
                        case Profession.doctor: label = 'Médico';
                        case Profession.engineer: label = 'Ingeniero';
                        case Profession.student: label = 'Estudiante';
                        case Profession.educator: label = 'Maestro';
                        case Profession.architect: label = 'Arquitecto';
                        case Profession.general: label = 'General';
                        case Profession.marketer: label = 'Marketer';
                      }
                      return DropdownMenuItem(
                        value: profession,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedProfession = value);
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 20),

              // Información adicional
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Información de la cuenta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(),
                      Consumer<OnboardingController>(
                        builder: (context, controller, child) {
                          return ListTile(
                            leading: const Icon(Icons.school),
                            title: const Text('Nivel'),
                            trailing: Text(controller.level),
                          );
                        },
                      ),
                      Consumer<OnboardingController>(
                        builder: (context, controller, child) {
                          return ListTile(
                            leading: const Icon(Icons.flag),
                            title: const Text('Progreso'),
                            trailing: Text(
                              controller.isCompleted ? 'Completado' : 'En progreso',
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'Guardar cambios',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}