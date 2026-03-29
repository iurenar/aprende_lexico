import 'package:aprende_lexico/enums/interview_flow.dart';


final List<InterviewStep> interviewSteps = [

  // 🧱 FASE 1 – Análisis del puesto
  InterviewStep(
    phase: "Análisis del puesto",
    question:
    "Sin mirar la descripción del puesto, ¿cómo describirías con tus palabras qué buscarán en el candidato ideal?",
  ),
  InterviewStep(
    phase: "Análisis del puesto",
    question:
    "De todo lo que piden, ¿cuáles son las tres competencias más críticas para tener éxito en este puesto y por qué?",
  ),
  InterviewStep(
    phase: "Análisis del puesto",
    question:
    "¿Cuáles son tres logros o proyectos pasados que demuestren esas competencias?",
  ),
  InterviewStep(
    phase: "Análisis del puesto",
    question:
    "¿Hay algún requisito donde sientas un punto débil? ¿Cómo lo compensarías?",
  ),

  // ⭐ FASE 2 – Método STAR
  InterviewStep(
    phase: "Método STAR",
    question:
    "Contextualízame uno de esos proyectos. ¿Cuál era el problema y tu rol?",
  ),
  InterviewStep(
    phase: "Método STAR",
    question:
    "¿Qué acciones concretas tomaste tú? Detalla herramientas, metodologías o habilidades usadas.",
  ),
  InterviewStep(
    phase: "Método STAR",
    question:
    "¿Cuál fue el resultado medible? ¿Qué impacto tuvo?",
  ),
  InterviewStep(
    phase: "Método STAR",
    question:
    "¿Cómo se conecta esta experiencia con el puesto al que postulas?",
  ),

  // ⚠️ FASE 3 – Preguntas difíciles
  InterviewStep(
    phase: "Preguntas difíciles",
    question:
    "¿Por qué dejas o dejaste tu puesto anterior?",
  ),
  InterviewStep(
    phase: "Preguntas difíciles",
    question:
    "Háblame de una debilidad real y cómo la estás trabajando.",
  ),
  InterviewStep(
    phase: "Preguntas difíciles",
    question:
    "¿Por qué quieres trabajar aquí y no en la competencia?",
  ),
  InterviewStep(
    phase: "Preguntas difíciles",
    question:
    "Preséntate profesionalmente en dos minutos.",
  ),

  // 🧠 FASE 4 – Preguntas del candidato
  InterviewStep(
    phase: "Preguntas al entrevistador",
    question:
    "¿Qué preguntas harías para entender los desafíos del rol?",
  ),
  InterviewStep(
    phase: "Preguntas al entrevistador",
    question:
    "¿Qué preguntas harías para decidir si este trabajo es para ti?",
  ),
];
