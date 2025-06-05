import 'package:flutter/material.dart';
import 'question_papers_screen.dart';
import 'notes_screen.dart';
import 'saved_study_materials_screen.dart';

class StudyMaterialsScreen extends StatelessWidget {
  const StudyMaterialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Study Materials'),
          actions: [
            IconButton(
              icon: const Icon(Icons.bookmark),
              tooltip: 'Saved Study Materials',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SavedStudyMaterialsScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Question Papers'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            QuestionPapersScreen(showBottomBar: false),
            NotesScreen(showBottomBar: false),
          ],
        ),
      ),
    );
  }
} 