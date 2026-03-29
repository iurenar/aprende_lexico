import '../enums/profession.dart';

enum OnboardingStep {
  intro,
  auth,
  profession,
  profile,
  completed,
}


class OnboardingState {
  final OnboardingStep step;

  // Auth
  final String? email;
  final String? name;
  final bool isGoogleSignIn;
  final String? photoUrl;

  // Cognitivo (Aria)
  final Profession profession;

  const OnboardingState({
    required this.step,
    this.email,
    this.name,
    this.isGoogleSignIn = false,
    this.profession = Profession.general, // 👈 default seguro
    this.photoUrl,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    String? email,
    String? name,
    bool? isGoogleSignIn,
    Profession? profession,
    String? photoUrl,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      email: email ?? this.email,
      name: name ?? this.name,
      isGoogleSignIn: isGoogleSignIn ?? this.isGoogleSignIn,
      profession: profession ?? this.profession,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
  }
