/// Gate de onboarding mutabil, citit de redirect-ul routerului. Deliberat un
/// static simplu (fără reactive redirect): `main()` îl seedează din profilul
/// local înainte de a construi routerul, iar wizard-ul îl schimbă o singură
/// dată. Testele setează `OnboardingGate.done = true` pentru a porni pe /home.
abstract final class OnboardingGate {
  static bool done = false;
}
