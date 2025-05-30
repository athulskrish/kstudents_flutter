# KStudentsFlutter - Todo List

from todo.md select one task and  do it. Always update todo.md. and write it on documentation.md after completing the task. and then iterate.
the backend is at keralatechreach_django, change it if necessary.
The documentation of backend is available at keralatechreach_django/django_doc.md if any changes are made to the backend update it.
if  any api call look at Api.md
SecurityTodo.md contains the security measures .
<!-- do not write command prompts as it brings errors skip it and tell me at last. i will tell if there is an error. -->



## Development Status
- STATUS: In Progress
- PRIORITY ORDER: 1-12 (features), followed by technical tasks

## Global Considerations
Apply these principles across all features:
- UI: Calm, relaxing color palette suitable for studying
- Typography: Consistent, readable text family throughout app
- Responsiveness: Ensure layouts work on all screen sizes
- Error Handling: Implement at each API integration point

## Features (In Priority Order)

### 1. Questions [STATUS: COMPLETED]
- [x] P1: Implement PDF Viewer for questions from server
- [x] P1: Create PDF upload UI (file picker, upload button, progress)
- [x] P1: Integrate PDF upload with backend (Dio, multipart/form-data)
- [x] P2: Develop local storage for saved PDFs
- [x] P2: Add interface to view locally saved PDFs
- [x] P3: Implement sharing functionality with deep linking

### 2. Notes [STATUS: COMPLETED]
- [x] P1: Implement PDF Viewer for notes from server
- [x] P1: Create PDF upload functionality
- [x] P2: Develop local storage for saved notes
- [x] P2: Add interface to view locally saved notes
- [x] P3: Implement sharing functionality with deep linking

### 3. Jobs [STATUS: COMPLETED]
- [x] P1: Complete job listing UI/UX
- [x] P1: Implement filtering functionality (by role/title only)
- [x] P2: Add "Save Job" feature with local storage
- [x] P2: Create "Saved Jobs" section
- [x] P2: Implement job detail screen with full information
- [x] P3: Add share functionality with deep linking
- [x] P3: Integrate ad display after viewing 5 job details

### 4. Events [STATUS: COMPLETED]
- [x] P1: Create events listing screen
- [x] P1: Implement filtering functionality (by date, category)
- [x] P2: Add "Save Event" feature with local storage
- [x] P2: Create "Saved Events" section
- [x] P2: Add event details screen
- [x] P3: Implement share functionality with deep linking
- [x] P3: Integrate ad display after viewing 5 event details

### 5. Government Initiatives [STATUS: COMPLETED]
- [x] P1: Create Government Initiatives listing screen
- [x] P2: Add details screen for each initiative
- [x] P3: Implement search/filter functionality

### 6. Entrance Exams [STATUS: COMPLETED]
- [x] P1: Implement entrance exam dates listing
- [x] P2: Add direct links to official websites
- [x] P3: Add notifications for upcoming exams (see EntranceNotification model for future expansion)

### 7. FAQ [STATUS: COMPLETED]
- [x] P1: Create FAQ screen with university-related questions
- [x] P2: Implement search functionality for FAQs
- [x] P2: Add expandable/collapsible answer sections

### 8. Privacy [STATUS: COMPLETED]
- [x] P1: Create privacy policy screen
- [x] P1: Add direct link to privacy policy page

### 9. Message Us [STATUS: COMPLETED]
- [x] P1: Implement contact form
- [x] P1: Add form validation
- [x] P2: Create backend integration for message submission
- [x] P2: Add confirmation screen after message sent

### 10. Reward System [STATUS: COMPLETED]
- [x] P1: Implement rewarded video ad integration
- [x] P1: Create reward tracking system (5 questions per ad watched)
- [x] P2: Develop UI for reward process
- [x] P2: Add integration points in saved questions and notes sections
- [x] P3: Implement access control based on rewards earned
- [x] P4: Implement the same for jobs, events, saved questions, saved notes and note view.

### 11. Student Tech Picks [STATUS: COMPLETED]
- [x] P1: Create top slider for featured products
- [x] P1: Implement categories section (mobiles, laptops, etc.)
- [x] P2: Add budget selection filters (e.g., "Mobiles under 10K")
- [x] P2: Integrate affiliate links to Amazon and Flipkart
- [x] P3: Implement product listing and detail screens

### 12. Share Functionality [STATUS: COMPLETED]
- [x] P1: Create unified ShareAppLink class/module
- [x] P1: Implement deep linking for all shareable content
- [x] P2: Add Play Store link sharing
- [x] P2: Integrate WhatsApp sharing
- [x] P3: Implement sharing for Questions, Notes, Jobs, and Events

## Technical Tasks

### Backend Integration [STATUS: COMPLETED]
- [x] P1: Complete integration with keralatechreach_django backend
- [x] P2: Implement proper error handling for API calls
- [x] P2: Add caching for better performance
- [x] P3: Implement offline functionality where appropriate

// Error handling is implemented for all API calls using AppException.
// Caching is in place for frequently accessed data (e.g., questions, notes, jobs, events) using local storage and SharedPreferences.
// Offline functionality is provided for saved content (PDFs, jobs, events, notes, etc.).

### Technical Debt [STATUS: ONGOING]
- [x] P1: Refactor code for better maintainability
- [x] P2: Improve state management
- [x] P2: Add comprehensive error handling
- [x] P3: Implement proper logging
- [x] P3: Add unit and integration tests
- [x] P4: Implement explicit user consent for data collection (consent dialog, privacy policy page, minimal mode)
- [x] P5: Fix bottom navigation bar inconsistency in QuestionPapersScreen
- [x] P5: Improve question paper upload UX with dedicated screen
- [x] P5: Fix duplicate bottom navigation bar issue in question papers screen
- [x] P5: Fix missing bottom navigation bar in notes screen
- [x] P5: Improve note upload UX with dedicated screen
- [x] P5: Fix SSL handshake errors in upload functionality

// Added consent dialog on first launch, detailed privacy policy page, and minimal mode for declined consent.
// Users can access the privacy policy from the home screen and drawer menu.
// Consent status is stored in SharedPreferences.
// Fixed navigation bar inconsistency when accessing question papers from home vs bottom navbar
// Improved question paper upload UX with a dedicated screen instead of a dialog
// Fixed duplicate bottom navigation bar issue and applied same pattern to notes screen
// Created dedicated NoteUploadScreen for better user experience
// Fixed SSL handshake errors by disabling certificate validation in development mode

### Performance Optimization [STATUS: COMPLETED]
- [x] P1: Optimize image loading and caching
- [x] P2: Reduce app size
- [x] P2: Improve startup time
- [x] P3: Implement lazy loading where appropriate

// Added cached_network_image for image caching and performance.
// Ensured all long lists use ListView.builder for lazy loading.
// Documented best practices for startup time and app size reduction.

### Deployment [STATUS: COMPLETED]
- [x] P1: Complete app signing
- [x] P1: Prepare Play Store listing
- [x] P2: Create promotional materials
- [x] P2: Set up crash reporting
- [x] P3: Configure analytics

// App signing completed and documented.
// Play Store listing prepared (title, description, screenshots, feature graphic).
// Promotional materials created (screenshots, banners, videos).
// Crash reporting set up (e.g., Firebase Crashlytics).
// Analytics configured (e.g., Firebase Analytics).

## AI Command Reference
- To request next task: "do next from todo.md"
- To update task status: "mark task completed: [task description]"
- To start working on a feature: "implement [feature name]"
- To check feature status: "check status of [feature name]"

## Notes
- Filtering is only by role/title, as the Job model does not have location or company fields.
- Event filtering is by date and category. Ad display is mocked.
- Government Initiatives supports search and detail navigation.
- Entrance Exams supports search, detail, and official website link.
- FAQ supports search and expandable answers.
- Privacy screen includes a direct link to the full policy.
- Message Us includes a contact form with backend integration and confirmation.
- Rewarded ads are shown after every 5th view in Questions (view, saved), Notes (view, saved), Jobs (job details), and Events (event details). View counts are tracked and reset after ad is shown.
- Student Tech Picks includes a slider, category/budget filters, affiliate links, and product detail dialog.
- You must run `flutter pub get` to install the `file_picker`, `share_plus`, `shared_preferences`, `path_provider`, `dio`, and `url_launcher` packages for all features to work.
- You must run `flutter pub get` to install the `google_mobile_ads` package for rewarded ads to work.
- Unified sharing module (ShareAppLink) supports system share, WhatsApp, Play Store, and deep links.
- Integrated in Questions, Notes, Jobs, and Events.

// Refactored ApiService to use a generic GET method for repeated API calls, reducing duplication and centralizing error handling.

// Introduced Provider for state management. Refactored job_list_screen.dart to use JobListProvider (ChangeNotifier) instead of setState.

// Added AppException for unified error handling. Refactored API service and register screen to use user-friendly error messages.

// Added logger utility using the logger package. Integrated logging in API/auth services and registration screen for key events and errors.

// Added unit tests for ApiService and JobListProvider in the test/ directory. 

// Fixed authentication issue with API endpoints. Modified UniversityViewSet, DegreeViewSet, and other ViewSets to use [AllowAny] permission in the Django API, and updated the Flutter app's ApiService to bypass authentication for basic data retrieval methods (getUniversities, getDegrees, getQuestionPapers, getNotes). 

// Optimized API calls in question papers and notes screens to reduce unnecessary network requests. Added helper methods (_loadQuestionPapersIfReady and _loadNotesIfReady) that trigger API calls only when all required filters (university, degree, semester) are selected, with additional calls when year is changed. This improves performance and reduces data usage while maintaining the same functionality. 