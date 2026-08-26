import 'package:my_thesis_project/data/models/memory_item.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
@Sync()
class Category {
  int id = 0;
  String name;

  @Backlink('category')
  final memoryItems = ToMany<MemoryItem>();

  Category({this.id = 0, required this.name});
}
