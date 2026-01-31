import 'package:flutter/material.dart';

class OnboardingModel {
  final String title;
  final String subtitle;
  final IconData icon;

  const OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

const List<OnboardingModel> onboardingPages = [
  OnboardingModel(
    title: "Welcome to MatchPoint",
    subtitle: "Find and book nearby sports courts anytime, anywhere.",
    icon: Icons.sports_tennis_rounded,
  ),
  OnboardingModel(
    title: "Real-Time Court Availability",
    subtitle: "Check live availability and reserve your preferred court in seconds.",
    icon: Icons.schedule_rounded,
  ),
  OnboardingModel(
    title: "Play. Compete. Enjoy.",
    subtitle: "Invite friends, schedule matches, and enjoy hassle-free court booking on the go.",
    icon: Icons.groups_rounded,
  ),
];
