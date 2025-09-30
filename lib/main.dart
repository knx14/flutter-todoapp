import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // JSONエンコード/デコード用
import 'package:uuid/uuid.dart'; // 一意なID生成用
import 'models/todo_item.dart'; // 作成したモデルをインポート

enum TodoFilter {
  all,
  incomplete,
  completed,
}

void main() {
  // アプリケーションの開始
  runApp(const TodoApp());
}

class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ToDo App',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const TodoListScreen(), // メイン画面
    );
  }
}

// ------------------------------------------------
// ToDoリストのメイン画面
// ------------------------------------------------

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  // 状態（State）として管理するToDoアイテムのリスト
  List<TodoItem> _todos = [];
  final Uuid _uuid = const Uuid(); // ID生成器
  TodoFilter _currentFilter = TodoFilter.all;
  List<TodoItem> get _filteredTodos {
    switch (_currentFilter) {
      case TodoFilter.incomplete:
       return _todos.where((todo) => !todo.isDone).toList();
      case TodoFilter.completed:
       return _todos.where((todo) => todo.isDone).toList();
      case TodoFilter.all:
       default:
        return _todos;
    }
  }
  //Todoタスクを完了したときにタイトルを削除するときに利用するアニメーション
  final Map<String, double> _opacityMap = {};
  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const Duration _removalDelay = Duration(milliseconds: 700);

  @override
  void initState() {
    super.initState();
    _loadTodos(); // 画面が作成されたときに保存されたデータを読み込む
  }

  // ------------------------------------------------
  // データの永続化 (shared_preferences)
  // ------------------------------------------------

  // 1. ToDoリストの読み込み（Read）
  Future<void> _loadTodos() async {
    final prefs = await SharedPreferences.getInstance();
    // 'todos'というキーで保存されたJSON文字列を取得
    final String? todosJson = prefs.getString('todos');

    if (todosJson != null) {
      // JSON文字列をList<Map>にデコード
      final List<dynamic> decodedList = jsonDecode(todosJson);
      setState(() {
        // List<Map>をList<TodoItem>に変換して状態を更新
        _todos = decodedList
            .map((item) => TodoItem.fromJson(item as Map<String, dynamic>))
            .toList();
      });
    }
  }

  // 2. ToDoリストの保存（Persistence）
  Future<void> _saveTodos() async {
    final prefs = await SharedPreferences.getInstance();
    // List<TodoItem>をList<Map>に変換
    final List<Map<String, dynamic>> mapList =
        _todos.map((todo) => todo.toJson()).toList();
    
    // List<Map>をJSON文字列にエンコード
    final String todosJson = jsonEncode(mapList);

    // JSON文字列を 'todos' キーで保存
    await prefs.setString('todos', todosJson);
  }

  // ------------------------------------------------
  // ToDoの追加 (Create)
  // ------------------------------------------------

  void _addTodo(String title) {
    if (title.isEmpty) return; // 空のタスクは追加しない

    setState(() {
      // 1. 新しいTodoItemを作成（ユニークIDを生成）
      final newTodo = TodoItem(
        id: _uuid.v4(),
        title: title,
      );
      // 2. リストに追加
      _todos.add(newTodo);
    });
    // 3. 変更を保存
    _saveTodos();
  }
  
  // ------------------------------------------------
  // ToDoの状態変更 (Update)
  // ------------------------------------------------

  void _toggleTodoStatus(TodoItem todo) {
    if (todo.isDone) {
      setState(() {
        todo.isDone = false;
        _opacityMap.remove(todo.id);
      });
      _saveTodos();
      return;
    }
    setState(() {
      todo.isDone = true;
      _opacityMap[todo.id] = 0.0;
    });
    _saveTodos();
  
    //フィードバックメッセージの表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('タスク「${todo.title}」を完了しました！'),
        duration: const Duration(seconds: 2),
      ),
    );

    //アニメーション完了を待ってからリストから削除する遅延処理
    Future.delayed(_removalDelay, () {
      if (!mounted) return;
      _deleteTodo(todo.id);
      _opacityMap.remove(todo.id);
    });
  }

  // ------------------------------------------------
  // ToDoの削除 (Delete)
  // ------------------------------------------------
  
  void _deleteTodo(String id) {
    setState(() {
      // 1. IDが一致するTodoをリストから削除
      _todos.removeWhere((todo) => todo.id == id);
    });
    // 2. 変更を保存
    _saveTodos();
  }

  //Todoフィルタリング
  void _setFilter(TodoFilter filter) {
    setState(() {
      _currentFilter = filter;
    });
  }

  // 空の状態に応じたメッセージを取得
  String _getEmptyMessage() {
    switch (_currentFilter) {
      case TodoFilter.incomplete:
        return '未完了のタスクがありません！';
      case TodoFilter.completed:
        return '完了したタスクがありません！';
      case TodoFilter.all:
      default:
        return 'タスクがありません！追加しましょう 😊';
    }
  }


  // ------------------------------------------------
  // UI - タスク追加用のダイアログ表示
  // ------------------------------------------------

  Future<void> _showAddTodoDialog() async {
    TextEditingController controller = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新しいタスクを追加'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'タスク名を入力'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('追加'),
              onPressed: () {
                _addTodo(controller.text); // タスク追加処理を実行
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditTodoDialog(TodoItem todo) async {
    TextEditingController controller = TextEditingController(text: todo.title);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('タスクを編集する'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'タスク名を入力'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () {
                setState(() {
                  todo.title = controller.text;
                });
                _saveTodos(); // 変更を保存
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ------------------------------------------------
  // UI - 画面の描画
  // ------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ToDoリスト'),
        elevation: 10,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: SegmentedButton<TodoFilter>(
              segments: const <ButtonSegment<TodoFilter>>[
               ButtonSegment<TodoFilter>(value: TodoFilter.all, label: Text('すべて')),
               ButtonSegment<TodoFilter>(value: TodoFilter.incomplete, label: Text('未完了')),
               ButtonSegment<TodoFilter>(value: TodoFilter.completed, label: Text('完了')),
              ],
              selected: {_currentFilter},
              onSelectionChanged: (Set<TodoFilter> newSelection) {
                _setFilter(newSelection.first);
              },
            ),
          ),
        ),
      ),
    
      // リスト表示部分
      body: _filteredTodos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getEmptyMessage(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_currentFilter != TodoFilter.all)
                    const SizedBox(height: 8),
                  if (_currentFilter != TodoFilter.all)
                    TextButton(
                      onPressed: () => _setFilter(TodoFilter.all),
                      child: const Text('すべてのタスクを表示'),
                    ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _filteredTodos.length,
              itemBuilder: (context, index) {
                final todo = _filteredTodos[index];
                return AnimatedOpacity(
                  opacity: _opacityMap.containsKey(todo.id) ? _opacityMap[todo.id]! : 1.0,
                  duration: _animationDuration,
                  child: ListTile(
                   leading: Checkbox(
                    value: todo.isDone,
                    onChanged: (bool? newValue) {
                      _toggleTodoStatus(todo);
                    },
                  ),
                  // タスクのタイトル
                  title: Text(
                    todo.title,
                    style: TextStyle(
                      // 完了していたら打ち消し線を入れる
                      decoration: todo.isDone ? TextDecoration.lineThrough : null,
                      color: todo.isDone ? Colors.grey : Colors.black,
                    ),
                  ),
                  // 削除ボタン
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteTodo(todo.id),
                  ),
                  // タスク編集機能は、このListTileの onTap に実装できます
                  onTap: () {
                    // TODO: タスク編集ダイアログを表示するロジックをここに追加
                    _showEditTodoDialog(todo);
                  },
                ),
                );
              },
            ),
      
      // タスク追加ボタン
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog, // ダイアログ表示
        child: const Icon(Icons.add),
      ),
    );
  }
}