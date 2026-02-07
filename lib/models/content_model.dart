class ContentModel {
  final String id;
  final String title;
  final String imageUrl;
  final String type; // 'book' or 'series'
  final String level; // 'A1', 'A2', etc. or 'Beginner'
  bool isCompleted;

  ContentModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.level,
    this.isCompleted = false,
  });
}
