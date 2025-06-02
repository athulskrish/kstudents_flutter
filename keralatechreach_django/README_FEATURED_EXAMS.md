# Featured Exams Implementation

This document contains instructions for implementing the "Featured Exams" functionality on the home screen.

## Changes Made

1. Added `show_on_home` boolean field to the `Exam` model
2. Created a migration file for the model change
3. Updated the `ExamForm` to include the new field
4. Updated the exam form template to include a checkbox for featuring exams
5. Updated the exam table template to show which exams are featured
6. Added a `FeaturedExamsViewSet` to the API
7. Registered the API endpoint in the URL configuration
8. Updated the `ExamSerializer` to include the new field

## How to Apply These Changes

1. Apply the migration:
   ```bash
   python manage.py migrate
   ```

2. Restart the Django development server:
   ```bash
   python manage.py runserver
   ```

3. Log in to the admin dashboard and edit some exams to mark them as "show_on_home"

4. Test the API endpoint by accessing `/api/featured-exams/`

## Testing

1. Make sure the Django server is running
2. Log in to the admin dashboard
3. Go to the Exams section
4. Edit a few exams and check the "Show on Home Page" checkbox
5. Save the changes
6. Open a browser and navigate to `http://localhost:8000/api/featured-exams/` (adjust the URL as needed)
7. Verify that only exams marked as "show_on_home" and "is_published" are returned

## Integration with Flutter App

The Flutter app has already been updated to fetch and display featured exams on the home screen. Once these backend changes are applied, the app should automatically display the featured exams.

## Troubleshooting

If you encounter any issues:

1. Check the Django server logs for errors
2. Verify that the migration was applied successfully
3. Make sure at least one exam is marked as both "is_published" and "show_on_home"
4. Check the API endpoint URL in the Flutter app matches the one registered in the Django backend 