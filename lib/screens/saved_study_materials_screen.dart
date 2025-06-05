import 'package:flutter/material.dart';
import 'question_papers_screen.dart'; // Import QuestionPapersScreen
import 'notes_screen.dart'; // Import NotesScreen

class SavedStudyMaterialsScreen extends StatefulWidget {
  @override
  _SavedStudyMaterialsScreenState createState() => _SavedStudyMaterialsScreenState();
}

class _SavedStudyMaterialsScreenState extends State<SavedStudyMaterialsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Study Materials'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Saved Question Papers'),
            Tab(text: 'Saved Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Content for Saved Question Papers tab
          QuestionPapersScreen(showSavedOnly: true, showUploadFab: false, showBottomBar: false,), // Use QuestionPapersScreen with saved only
          // Content for Saved Notes tab
          NotesScreen(showSavedOnly: true, showUploadFab: false, showBottomBar: false,), // Use NotesScreen with saved only
        ],
      ),
    );
  }
}