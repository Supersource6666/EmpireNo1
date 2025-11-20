import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class BookReaderPage extends StatefulWidget {
  const BookReaderPage({super.key});

  @override
  State<BookReaderPage> createState() => _BookReaderPageState();
}

class _BookReaderPageState extends State<BookReaderPage> {
  final List<Map<String, String>> books = [
    {"title": "三国演义", "author": "罗贯中", "audio": "assets/sounds/book1.mp3"},
    {"title": "红楼梦", "author": "曹雪芹", "audio": "assets/sounds/book2.mp3"},
    {"title": "西游记", "author": "吴承恩", "audio": "assets/sounds/book3.mp3"},
  ];
  final AudioPlayer _player = AudioPlayer();
  int? playingIndex;

  void _play(int index) async {
    setState(() { playingIndex = index; });
    await _player.stop();
    await _player.play(AssetSource(books[index]["audio"]!));
  }

  void _stop() async {
    await _player.stop();
    setState(() { playingIndex = null; });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('听读书阅读器')),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          final book = books[index];
          final isPlaying = playingIndex == index;
          return ListTile(
            leading: Icon(Icons.book, color: isPlaying ? Colors.blue : null),
            title: Text(book["title"]!),
            subtitle: Text('作者：${book["author"]}'),
            trailing: isPlaying
                ? IconButton(icon: const Icon(Icons.stop), onPressed: _stop)
                : IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _play(index)),
          );
        },
      ),
    );
  }
}
