import 'dart:io';
import 'package:flutter/material.dart';
import 'package:aprende_lexico/lesson/voice_chat_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:aprende_lexico/enums/training_mode.dart';
import 'package:aprende_lexico/avatar/avatar_selection_screen.dart';


class PresentationPracticeScreen extends StatefulWidget {
  const PresentationPracticeScreen({super.key});

  @override
  State<PresentationPracticeScreen> createState() =>
      _PresentationPracticeScreenState();
}

class _PresentationPracticeScreenState
    extends State<PresentationPracticeScreen> {

  String? _attachedFileName;
  String? _attachedFilePath;

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _attachedFileName = result.files.single.name;
        _attachedFilePath = result.files.single.path;
      });
    }
  }


  String prepareDocumentContext(String rawText) {
    const maxChars = 1500;

    final cleaned = rawText
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return cleaned.length > maxChars
        ? cleaned.substring(0, maxChars)
        : cleaned;
  }

  Future<String?> extractDocumentText(String path) async {
    try {
      if (path.endsWith(".pdf")) {
        final file = File(path);
        final bytes = await file.readAsBytes();

        final document = PdfDocument(inputBytes: bytes);
        final extractor = PdfTextExtractor(document);
        final text = extractor.extractText();

        document.dispose();
        return text;
      }

      if (path.endsWith(".docx")) {
        final bytes = await File(path).readAsBytes();
        return docxToText(bytes);
      }

      if (path.endsWith(".txt")) {
        return await File(path).readAsString();
      }
    } catch (e) {
      debugPrint("❌ Error leyendo documento: $e");
    }

    return null;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Practicar presentación"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🎤 TÍTULO
            const Text(
              "🎤 Practicar presentación",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // 📄 DESCRIPCIÓN
            const Text(
              "Simula una presentación profesional y recibe correcciones "
                  "en tiempo real para mejorar tu claridad, léxico y seguridad.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 20),

            // 📎 ADJUNTAR DOCUMENTO
            const Text(
              "Documento de apoyo (opcional)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text("Adjuntar archivo"),
                  onPressed: _pickDocument,
                ),

                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _attachedFileName ?? "Ningún archivo adjunto",
                    style: TextStyle(
                      color: _attachedFileName == null
                          ? Colors.grey
                          : Colors.green,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const Spacer(),


            // ▶ COMENZAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  String? documentContext;

                  if (_attachedFilePath != null) {
                    final raw = await extractDocumentText(_attachedFilePath!);
                    if (raw != null && raw.trim().isNotEmpty) {
                      documentContext = prepareDocumentContext(raw);
                    }
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AvatarCatalogScreen(
                        mode: TrainingMode.presentation,
                        documentContext: documentContext,
                      ),
                    ),
                  );
                },
                child: const Text("Comenzar práctica"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
