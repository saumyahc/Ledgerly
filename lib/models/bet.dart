class BetChallenge {
  final String id;
  final String title;
  final String description;
  final double stake;
  final DateTime endDate;
  final List<Participant> participants;

  BetChallenge({
    required this.id,
    required this.title,
    required this.description,
    required this.stake,
    required this.endDate,
    required this.participants,
  });
}

class Participant {
  final String name;
  double progress; // e.g., kms run or workouts completed
  bool completed;

  Participant({
    required this.name,
    this.progress = 0,
    this.completed = false,
  });
}
