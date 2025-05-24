from django.contrib import admin
from .models import (
    QuestionPaper, University, Degree, Exam, Job, District,
    Initiative, EventCategory, Event, News, ContactMessage,
    Gallery, SiteSetting, UserProfile
)

@admin.register(QuestionPaper)
class QuestionPaperAdmin(admin.ModelAdmin):
    list_display = ('degree', 'semester', 'subject', 'year', 'university_id', 'is_published', 'created_by')
    list_filter = ('degree', 'semester', 'year', 'university_id', 'is_published')
    search_fields = ('subject', 'degree__name')
    list_editable = ('is_published',)

@admin.register(University)
class UniversityAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_by')
    search_fields = ('name',)

@admin.register(Degree)
class DegreeAdmin(admin.ModelAdmin):
    list_display = ('name', 'university', 'created_by')
    list_filter = ('university',)
    search_fields = ('name', 'university__name')

@admin.register(Exam)
class ExamAdmin(admin.ModelAdmin):
    list_display = ('exam_name', 'exam_date', 'degree_name', 'semester', 'university', 'is_published', 'created_by')
    list_filter = ('exam_date', 'university', 'semester', 'is_published')
    search_fields = ('exam_name', 'degree_name__name')
    list_editable = ('is_published',)

@admin.register(Job)
class JobAdmin(admin.ModelAdmin):
    list_display = ('title', 'last_date', 'is_published', 'created_by')
    list_filter = ('last_date', 'is_published')
    search_fields = ('title', 'description')
    list_editable = ('is_published',)

@admin.register(District)
class DistrictAdmin(admin.ModelAdmin):
    list_display = ('name', 'created_by')
    search_fields = ('name',)

@admin.register(Initiative)
class InitiativeAdmin(admin.ModelAdmin):
    list_display = ('name', 'link', 'is_published', 'created_by')
    list_filter = ('is_published',)
    search_fields = ('name', 'description')
    list_editable = ('is_published',)

@admin.register(EventCategory)
class EventCategoryAdmin(admin.ModelAdmin):
    list_display = ('category', 'created_by')
    search_fields = ('category',)

@admin.register(Event)
class EventAdmin(admin.ModelAdmin):
    list_display = ('name', 'event_start', 'event_end', 'place', 'district', 'category', 'is_published', 'created_by')
    list_filter = ('district', 'category', 'event_start', 'is_published')
    search_fields = ('name', 'description', 'place')
    list_editable = ('is_published',)

@admin.register(News)
class NewsAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'updated_at', 'is_published', 'created_by')
    list_filter = ('is_published', 'created_at')
    search_fields = ('title', 'content')
    list_editable = ('is_published',)

@admin.register(ContactMessage)
class ContactMessageAdmin(admin.ModelAdmin):
    list_display = ('subject', 'name', 'email', 'created_at', 'is_read', 'created_by')
    list_filter = ('is_read', 'created_at')
    search_fields = ('name', 'email', 'subject', 'message')
    list_editable = ('is_read',)

@admin.register(Gallery)
class GalleryAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at', 'is_visible', 'created_by')
    list_filter = ('is_visible', 'created_at')
    search_fields = ('title', 'description')
    list_editable = ('is_visible',)

@admin.register(SiteSetting)
class SiteSettingAdmin(admin.ModelAdmin):
    list_display = ('key', 'is_public', 'updated_at', 'created_by')
    list_filter = ('is_public', 'updated_at')
    search_fields = ('key', 'value', 'description')
    list_editable = ('is_public',)

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'email', 'phone', 'district', 'is_active', 'is_staff', 'is_verified', 'is_approved')
    list_filter = (
        'district', 'is_active', 'is_staff', 'is_superuser',
        'is_verified', 'is_approved', 'is_blocked', 'is_deleted'
    )
    search_fields = ('user__username', 'email', 'phone', 'bio')
    list_editable = ('is_active', 'is_verified', 'is_approved')
