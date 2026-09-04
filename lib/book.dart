import 'package:isar_community/isar.dart';

part 'book.g.dart';

@collection
class SavedBook {
  Id id = Isar.autoIncrement;

  late String title;
  late String author;
  late String coverUrl;

  @Index(type: IndexType.hash)
  late String category;

  // New fields
  String description = '';
  String publisher = '';
  int pageCount = 0;

  @Index(type: IndexType.hash)
  String status = 'Not Started'; // 'Not Started' | 'Reading' | 'Finished'
}