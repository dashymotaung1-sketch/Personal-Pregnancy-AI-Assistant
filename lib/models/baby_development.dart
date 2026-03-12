class BabyDevelopment {
  final int week;
  final String babySize;
  final String development;
  final String healthTip;

  BabyDevelopment({
    required this.week,
    required this.babySize,
    required this.development,
    required this.healthTip,
  });
}

// Example data (you can expand it to 40 weeks)
final List<BabyDevelopment> developmentData = [
  BabyDevelopment(
    week: 1,
    babySize: 'Poppy seed',
    development: 'Baby conception occurs.',
    healthTip: 'Start taking prenatal vitamins.',
  ),
  BabyDevelopment(
    week: 4,
    babySize: 'Apple seed',
    development: 'Heart starts forming.',
    healthTip: 'Maintain a balanced diet.',
  ),
  BabyDevelopment(
    week: 12,
    babySize: 'Lime',
    development: 'Facial features developing.',
    healthTip: 'Drink plenty of water and rest.',
  ),
  BabyDevelopment(
    week: 20,
    babySize: 'Banana',
    development: 'Baby can hear sounds.',
    healthTip: 'Start light exercises if approved by doctor.',
  ),
  BabyDevelopment(
    week: 28,
    babySize: 'Eggplant',
    development: 'Baby’s lungs developing rapidly.',
    healthTip: 'Attend regular check-ups.',
  ),
  BabyDevelopment(
    week: 36,
    babySize: 'Romaine lettuce',
    development: 'Baby gains weight quickly.',
    healthTip: 'Prepare hospital bag and birth plan.',
  ),
];