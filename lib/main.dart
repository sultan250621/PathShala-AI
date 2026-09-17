import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OfflineDemoScreen(),
    );
  }
}

class OfflineDemoScreen extends StatefulWidget {
  const OfflineDemoScreen({super.key});

  @override
  State<OfflineDemoScreen> createState() => _OfflineDemoScreenState();
}

class _OfflineDemoScreenState extends State<OfflineDemoScreen> {
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<Database> getDatabase() async {
    return openDatabase(
      join(await getDatabasesPath(), 'offline_demo.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, text TEXT)',
        );
      },
      version: 1,
    );
  }

  Future<void> addNote(String text) async {
    final db = await getDatabase();
    await db.insert('notes', {'text': text});
    loadNotes();
  }

  Future<void> loadNotes() async {
    final db = await getDatabase();
    final data = await db.query('notes');
    setState(() {
      notes = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline-First Demo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => addNote('Note saved at ${DateTime.now()}'),
              child: const Text('Save a Note (No Internet Needed for rural student)'),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: notes.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(notes[index]['text']));
              },
            ),
          ),
        ],
      ),
    );
  }
}