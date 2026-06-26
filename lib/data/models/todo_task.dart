import "package:my_thesis_project/data/models/memory_item.dart";
import "package:objectbox/objectbox.dart";




@Entity()
@Sync()
class TodoTask {
  int id = 0;
  String image;
  String taskTitle;
  String taskDescription;
  String taskCreated;
  bool taskCompleted;
  String taskNote;
  String taskDeadline;

  String? ocrText;
  int? fileSizeBytes;
  String? documentDate;


  //relationship to the each memory item
  @Backlink('todoTask')
  final memoryItem = ToMany<MemoryItem>();

  TodoTask({
    this.id = 0,
    required this.image,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskCreated,
    this.taskCompleted = false,
    this.taskNote ="",
    this.taskDeadline ="",
    this.fileSizeBytes,
    this.ocrText,
    this.documentDate
});
}