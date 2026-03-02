import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class Country {
  final String code;
  final String name;
  final String flag;

  Country(this.code, this.name, this.flag);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Country &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => name;
}

class Skill {
  final String id;
  final String name;
  final String category;
  final IconData icon;

  Skill(this.id, this.name, this.category, this.icon);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Skill && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class SubscriptionPlan {
  final String id;
  final String name;
  final double price;
  final String features;

  SubscriptionPlan(this.id, this.name, this.price, this.features);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class Interest {
  final String id;
  final String name;
  final Color color;

  Interest(this.id, this.name, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Interest && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => name;
}

class CustomClassExamplesViewModel extends ChangeNotifier {
  final formKey = GlobalKey<FormState>();

  final List<Country> countries = [
    Country('US', 'United States', '🇺🇸'),
    Country('CA', 'Canada', '🇨🇦'),
    Country('GB', 'United Kingdom', '🇬🇧'),
    Country('DE', 'Germany', '🇩🇪'),
    Country('FR', 'France', '🇫🇷'),
    Country('JP', 'Japan', '🇯🇵'),
    Country('AU', 'Australia', '🇦🇺'),
    Country('BR', 'Brazil', '🇧🇷'),
    Country('IN', 'India', '🇮🇳'),
    Country('CN', 'China', '🇨🇳'),
    Country('IT', 'Italy', '🇮🇹'),
    Country('ES', 'Spain', '🇪🇸'),
    Country('MX', 'Mexico', '🇲🇽'),
    Country('RU', 'Russia', '🇷🇺'),
    Country('KR', 'South Korea', '🇰🇷'),
    Country('AR', 'Argentina', '🇦🇷'),
    Country('NL', 'Netherlands', '🇳🇱'),
    Country('SE', 'Sweden', '🇸🇪'),
    Country('CH', 'Switzerland', '🇨🇭'),
    Country('BE', 'Belgium', '🇧🇪'),
    Country('PL', 'Poland', '🇵🇱'),
    Country('NO', 'Norway', '🇳🇴'),
    Country('AT', 'Austria', '🇦🇹'),
    Country('DK', 'Denmark', '🇩🇰'),
    Country('FI', 'Finland', '🇫🇮'),
    Country('IE', 'Ireland', '🇮🇪'),
    Country('PT', 'Portugal', '🇵🇹'),
    Country('GR', 'Greece', '🇬🇷'),
    Country('NZ', 'New Zealand', '🇳🇿'),
    Country('SG', 'Singapore', '🇸🇬'),
  ];

  final List<Skill> skills = [
    Skill('flutter', 'Flutter', 'Mobile', Icons.phone_android),
    Skill('dart', 'Dart', 'Language', Icons.code),
    Skill('firebase', 'Firebase', 'Backend', Icons.cloud),
    Skill('rest', 'REST API', 'Backend', Icons.api),
    Skill('graphql', 'GraphQL', 'Backend', Icons.graphic_eq),
    Skill('ui', 'UI/UX Design', 'Design', Icons.design_services),
    Skill('testing', 'Testing', 'Quality', Icons.bug_report),
    Skill('react', 'React', 'Frontend', Icons.web),
    Skill('vue', 'Vue.js', 'Frontend', Icons.web),
    Skill('angular', 'Angular', 'Frontend', Icons.web),
    Skill('node', 'Node.js', 'Backend', Icons.dns),
    Skill('python', 'Python', 'Language', Icons.code),
    Skill('java', 'Java', 'Language', Icons.code),
    Skill('kotlin', 'Kotlin', 'Language', Icons.code),
    Skill('swift', 'Swift', 'Language', Icons.code),
    Skill('typescript', 'TypeScript', 'Language', Icons.code),
    Skill('javascript', 'JavaScript', 'Language', Icons.code),
    Skill('docker', 'Docker', 'DevOps', Icons.storage),
    Skill('kubernetes', 'Kubernetes', 'DevOps', Icons.cloud_circle),
    Skill('aws', 'AWS', 'Cloud', Icons.cloud_queue),
    Skill('azure', 'Azure', 'Cloud', Icons.cloud_queue),
    Skill('gcp', 'Google Cloud', 'Cloud', Icons.cloud_queue),
    Skill('mongodb', 'MongoDB', 'Database', Icons.storage),
    Skill('postgresql', 'PostgreSQL', 'Database', Icons.storage),
    Skill('mysql', 'MySQL', 'Database', Icons.storage),
    Skill('redis', 'Redis', 'Database', Icons.storage_rounded),
    Skill('git', 'Git', 'Version Control', Icons.source),
    Skill('agile', 'Agile', 'Methodology', Icons.groups),
    Skill('scrum', 'Scrum', 'Methodology', Icons.people),
    Skill('cicd', 'CI/CD', 'DevOps', Icons.sync),
  ];

  final List<SubscriptionPlan> plans = [
    SubscriptionPlan('free', 'Free', 0, 'Basic features'),
    SubscriptionPlan('pro', 'Pro', 9.99, 'Advanced features'),
    SubscriptionPlan('enterprise', 'Enterprise', 29.99, 'All features'),
  ];

  final List<Interest> interests = [
    Interest('gaming', 'Gaming', Colors.purple),
    Interest('music', 'Music', Colors.pink),
    Interest('sports', 'Sports', Colors.orange),
    Interest('reading', 'Reading', Colors.blue),
    Interest('travel', 'Travel', Colors.green),
    Interest('cooking', 'Cooking', Colors.red),
  ];

  Country? selectedCountry;
  List<Skill> selectedSkills = [];
  SubscriptionPlan? selectedPlan;
  List<Interest> selectedInterests = [];
  Country? selectedCountryWithFilter;
  List<Skill> selectedSkillsWithFilter = [];

  void setSelectedCountry(Country? value) {
    selectedCountry = value;
    notifyListeners();
  }

  void setSelectedSkills(List<Skill> value) {
    selectedSkills = value;
    notifyListeners();
  }

  void setSelectedPlan(SubscriptionPlan? value) {
    selectedPlan = value;
    notifyListeners();
  }

  void setSelectedInterests(List<Interest> value) {
    selectedInterests = value;
    notifyListeners();
  }

  void setSelectedCountryWithFilter(Country? value) {
    selectedCountryWithFilter = value;
    notifyListeners();
  }

  void setSelectedSkillsWithFilter(List<Skill> value) {
    selectedSkillsWithFilter = value;
    notifyListeners();
  }

  void logFormData() {
    final message = StringBuffer();
    message.writeln('Form Data:');
    message.writeln('Country: ${selectedCountry?.name ?? "None"}');
    message.writeln('Skills: ${selectedSkills.map((s) => s.name).join(", ")}');
    message.writeln('Plan: ${selectedPlan?.name ?? "None"}');
    message.writeln(
        'Interests: ${selectedInterests.map((i) => i.name).join(", ")}');

    logger.i(message.toString());
  }
}
