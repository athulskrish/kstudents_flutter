from django.shortcuts import render
from django.contrib.auth.decorators import login_required
from django.db.models import Count
from django.utils import timezone
from datetime import timedelta
from ..models import (
    QuestionPaper, University, Degree, Exam, Job, District,
    Initiative, EventCategory, Event, News, ContactMessage,
    Gallery, SiteSetting, UserProfile
)
from ..decorators import staff_required

@login_required
def dashboard(request):
    # Get current date and last week
    now = timezone.now()
    last_week = now - timedelta(days=7)
    
    # Basic Statistics
    context = {
        'total_users': UserProfile.objects.count() if request.user.is_staff else 1,
        'total_questions': QuestionPaper.objects.count(),
        'total_events': Event.objects.count(),
        'total_news': News.objects.count(),
    }

    # Staff-only statistics
    if request.user.is_staff:
        context.update({
            # Recent counts (last 7 days)
            'new_users': UserProfile.objects.filter(user__date_joined__gte=last_week).count(),
            'new_questions': QuestionPaper.objects.filter(updated_at__gte=last_week).count(),
            'new_events': Event.objects.filter(updated_at__gte=last_week).count(),
            'new_news': News.objects.filter(created_at__gte=last_week).count(),
            
            # Upcoming Events
            'upcoming_events': Event.objects.filter(
                event_start__gte=now
            ).order_by('event_start')[:5],
            
            # Recent Activity
            'recent_questions': QuestionPaper.objects.order_by('-updated_at')[:5],
            'recent_news': News.objects.order_by('-created_at')[:5],
            
            # Content Status
            'published_questions': QuestionPaper.objects.filter(is_published=True).count(),
            'draft_questions': QuestionPaper.objects.filter(is_published=False).count(),
            'published_events': Event.objects.filter(is_published=True).count(),
            'draft_events': Event.objects.filter(is_published=False).count(),
            'published_news': News.objects.filter(is_published=True).count(),
            'draft_news': News.objects.filter(is_published=False).count(),
            
            # Messages
            'unread_messages': ContactMessage.objects.filter(is_read=False).count(),
            'total_messages': ContactMessage.objects.count(),
            
            # University Statistics
            'university_count': University.objects.count(),
            'degree_count': Degree.objects.count(),
            
            # Event Categories
            'event_categories': EventCategory.objects.annotate(
                event_count=Count('event')
            ).order_by('-event_count')[:5],
        })
    else:
        # Regular user statistics
        context.update({
            'upcoming_events': Event.objects.filter(
                event_start__gte=now,
                is_published=True
            ).order_by('event_start')[:5],
            'recent_news': News.objects.filter(
                is_published=True
            ).order_by('-created_at')[:5],
        })
    
    return render(request, 'admindashboard/dashboard.html', context)

@login_required
@staff_required
def tables(request):
    context = {
        'questions': QuestionPaper.objects.all().order_by('-updated_at')[:10],
        'events': Event.objects.all().order_by('-updated_at')[:10],
        'jobs': Job.objects.all().order_by('-updated_at')[:10],
        'news': News.objects.all().order_by('-created_at')[:10],
        'users': UserProfile.objects.all().order_by('-user__date_joined')[:10],
    }
    return render(request, 'admindashboard/tables.html', context) 