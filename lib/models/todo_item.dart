import 'package:uuid/uuid.dart';

class TodoItem {
    //プロパティの定義
    final String id;//finalは変更不可の変数
    String title;
    bool isDone;//boolは真偽値

    //コンストラクタの定義
    TodoItem({String? id, required this.title, this.isDone = false}) 
        : id = id ?? const Uuid().v4();

//データの永続化のための変換メソッド
//TodoItemをMap<String, dynamic>に変換するメソッド
Map<String, dynamic> toMap() {
    return {
        'id': id,
        'title': title,
        'isDone': isDone,
    };
}

//JSONエンコード用のメソッド（toMapと同じ内容）
Map<String, dynamic> toJson() {
    return {
        'id': id,
        'title': title,
        'isDone': isDone,
    };
}
//MapからTodoItemオブジェクトを生成する
factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'],
    );
}
}
