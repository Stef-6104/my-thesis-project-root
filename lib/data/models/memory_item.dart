import 'package:my_thesis_project/data/models/category.dart';
import 'package:my_thesis_project/data/models/todo_task.dart';
import 'package:objectbox/objectbox.dart';

@Entity()
@Sync()
class MemoryItem {
  int id = 0;
  bool memoryNum = false;

  //relationship to the todotask
  final todoTask = ToOne<TodoTask>();

  //relationship to category
  final category = ToOne<Category>();
}
