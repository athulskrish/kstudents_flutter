# Home Screen Implementation Plan

## 1. Home Screen Slider Implementation
- [x] Connect to backend API to fetch slider images from AdSlider model
- [x] Display slider images in a carousel on home screen
- [x] Implement URL navigation when slider image is clicked
- [x] Add loading state and error handling for slider images
- [x] Implement auto-scrolling functionality for slider

## 2. Featured Content Implementation
- [x] Create models in Django backend to mark items as "featured on home"
  - [x] Add `show_on_home` boolean field to Job, Event, and News models
  - [x] Update Django admin forms to include this checkbox
  - [x] Create API endpoints to fetch only featured items

- [x] Implement Home Screen Sections in Flutter
  - [x] Featured Jobs Section
    - [x] Display job name and company
    - [x] Navigate to job details on tap
  
  - [x] Featured Events Section
    - [x] Display event name and date
    - [x] Navigate to event details on tap
  
  - [x] Featured News Section
    - [x] Display news title and date
    - [x] Navigate to news details on tap
  
  - [x] Featured Exams Section
    - [x] Display exam name and date
    - [x] Navigate to exam details on tap

## 3. Backend Changes Required
- [x] Update AdSlider model in Django to ensure it has:
  - [x] Image field
  - [x] Title field
  - [x] URL field for navigation
  - [x] Active/inactive status
  - [x] Position/order field

- [x] Add `show_on_home` field to:
  - [x] Job model
  - [x] Event model
  - [x] News model
  - [x] Exam model

- [x] Create API endpoints:
  - [x] `/api/featured-jobs/` - Returns jobs with show_on_home=True
  - [x] `/api/featured-events/` - Returns events with show_on_home=True
  - [x] `/api/featured-news/` - Returns news with show_on_home=True
  - [x] `/api/featured-exams/` - Returns exams with show_on_home=True

## 4. Flutter Implementation Tasks
- [x] Update ApiService to fetch featured content
  - [x] `getFeaturedJobs()`
  - [x] `getFeaturedEvents()`
  - [x] `getFeaturedNews()`
  - [x] `getFeaturedExams()`

- [x] Update HomeScreen widget
  - [x] Add loading states for each section
  - [x] Implement error handling for API failures
  - [x] Create responsive layout for different screen sizes
  - [x] Add "View All" buttons for each section
  - [x] Add Featured Exams section

## 5. Testing
- [x] Test slider navigation with various URL types
- [x] Test featured content display with different data amounts
- [x] Test error states when API fails
- [x] Test empty states when no featured content is available

## 6. Implementation Plan

### Step 1: Backend Updates (Completed)
1. ✅ Add `show_on_home` boolean field to the Exam model in Django
2. ✅ Update Exam admin form to include the checkbox
3. ✅ Create the `/api/featured-exams/` API endpoint

### Step 2: Flutter Updates (Completed)
1. ✅ Add `getFeaturedExams()` method to ApiService
2. ✅ Update HomeScreen to fetch and display featured exams
3. ✅ Create a new `_buildFeaturedExamsSection()` method in HomeScreen
4. ✅ Add navigation to exam details on tap

### Step 3: Testing (Partially Completed)
1. ✅ Test the new API endpoint
2. ✅ Test the exam section display on the home screen
3. ✅ Test navigation to exam details 