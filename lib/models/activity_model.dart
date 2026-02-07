class ActivityModel {
  final DateTime date;
  final List<String> completedContentIds;
  final int studyDurationMinutes;

  ActivityModel({
    required this.date,
    required this.completedContentIds,
    required this.studyDurationMinutes,
  });
}
