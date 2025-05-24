from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.utils import timezone
from datetime import timedelta
from django.contrib import messages
from django.db.models import Q
from django.core.paginator import Paginator
from django.utils.text import slugify
from itertools import chain

from django.contrib.auth import get_user_model
from admindashboard.models import News, Event, QuestionPaper, Testimonial, FAQ, Initiative, Exam, EntranceNotification, ContactUs, AdSettings # Import FAQ model and AdSettings
from .forms import NewsletterSignupForm # Import the newsletter form
from .models import NewsletterSubscriber # Import the newsletter model

User = get_user_model() # Get the custom user model

def home(request):
    if request.user.is_authenticated:
        return redirect('admindashboard:dashboard')
    
    newsletter_form = NewsletterSignupForm() # Instantiate the form
    
    now = timezone.now()
    
    context = {
        'newsletter_form': newsletter_form, # Add form to context
        # Get latest published events
        'upcoming_events': Event.objects.filter(
            event_start__gte=now,
            is_published=True
        ).order_by('event_start')[:3],
        
        # Get latest published news
        'latest_news': News.objects.filter(
            is_published=True
        ).order_by('-created_at')[:3],
        
        # Get published initiatives
        'initiatives': Initiative.objects.filter(
            is_published=True
        ).order_by('-updated_at')[:2],
        
        # Get latest exams and notifications
        'latest_exams': Exam.objects.filter(
            is_published=True,
            exam_date__gte=now
        ).order_by('exam_date')[:4],
        
        'entrance_notifications': EntranceNotification.objects.filter(
            is_published=True,
            deadline__gte=now
        ).order_by('deadline')[:4],
        
        # Get testimonials and FAQs
        'testimonials': Testimonial.objects.filter(
            is_approved=True
        ).order_by('-created_at')[:3],
        
        'faqs': FAQ.objects.filter(
            is_published=True
        ).order_by('display_order')[:5],
    }

    return render(request, 'publicpage/home.html', context)

def newsletter_signup(request):
    if request.method == 'POST':
        form = NewsletterSignupForm(request.POST)
        if form.is_valid():
            form.save()
            messages.success(request, 'Thank you for subscribing to our newsletter!')
        else:
            for error in form.errors.values():
                messages.error(request, error[0])
    return redirect('publicpage:home')

# Detail views for public pages
def news_detail(request, slug):
    news_article = get_object_or_404(News, slug=slug, is_published=True)
    related_news = News.objects.filter(is_published=True).exclude(id=news_article.id).order_by('-created_at')[:3]
    
    # Get active ads for each location
    ads = {
        'above_content': AdSettings.objects.filter(location='above_content', is_active=True).first(),
        'below_content': AdSettings.objects.filter(location='below_content', is_active=True).first(),
        'sidebar_top': AdSettings.objects.filter(location='sidebar_top', is_active=True).first(),
        'sidebar_bottom': AdSettings.objects.filter(location='sidebar_bottom', is_active=True).first(),
        'between_content': AdSettings.objects.filter(location='between_content', is_active=True).first(),
    }
    
    # Increment view count
    news_article.views_count += 1
    news_article.save()
    
    context = {
        'news_article': news_article,
        'related_news': related_news,
        'ads': ads,
    }
    return render(request, 'publicpage/news_detail.html', context)

def event_detail(request, pk):
    event = get_object_or_404(Event, pk=pk, is_published=True)
    return render(request, 'publicpage/event_detail.html', {'event': event})

def questionpaper_detail(request, pk):
    question_paper = get_object_or_404(QuestionPaper, pk=pk, is_published=True)
    return render(request, 'publicpage/questionpaper_detail.html', {'question_paper': question_paper})

def search(request):
    query = request.GET.get('q', '')
    now = timezone.now()
    
    if query:
        # Search in multiple models
        events = Event.objects.filter(
            Q(name__icontains=query) | Q(description__icontains=query),
            is_published=True,
            event_start__gte=now
        ).order_by('event_start')

        news = News.objects.filter(
            Q(title__icontains=query) | Q(content__icontains=query),
            is_published=True
        ).order_by('-created_at')

        exams = Exam.objects.filter(
            Q(exam_name__icontains=query) | Q(degree_name__name__icontains=query),
            is_published=True,
            exam_date__gte=now
        ).order_by('exam_date')

        initiatives = Initiative.objects.filter(
            Q(name__icontains=query) | Q(description__icontains=query),
            is_published=True
        ).order_by('-updated_at')

        entrance_notifications = EntranceNotification.objects.filter(
            Q(title__icontains=query) | Q(description__icontains=query),
            is_published=True,
            deadline__gte=now
        ).order_by('deadline')

    else:
        events = Event.objects.none()
        news = News.objects.none()
        exams = Exam.objects.none()
        initiatives = Initiative.objects.none()
        entrance_notifications = EntranceNotification.objects.none()

    context = {
        'query': query,
        'events': events[:5],
        'news': news[:5],
        'exams': exams[:5],
        'initiatives': initiatives[:5],
        'entrance_notifications': entrance_notifications[:5],
        'total_results': len(events) + len(news) + len(exams) + len(initiatives) + len(entrance_notifications)
    }

    return render(request, 'publicpage/search_results.html', context)

def events_list(request):
    now = timezone.now()
    
    # Get all upcoming published events
    events = Event.objects.filter(
        event_start__gte=now,
        is_published=True
    ).order_by('event_start')
    
    # Add pagination
    paginator = Paginator(events, 10)  # Show 10 events per page
    page = request.GET.get('page')
    events_page = paginator.get_page(page)
    
    # Group events by month for the calendar view
    events_by_month = {}
    for event in events:
        month_key = event.event_start.strftime('%B %Y')
        if month_key not in events_by_month:
            events_by_month[month_key] = []
        events_by_month[month_key].append(event)
    
    context = {
        'events': events_page,
        'events_by_month': events_by_month,
    }
    
    return render(request, 'publicpage/events_list.html', context)

def news_list(request):
    news_articles = News.objects.filter(
        is_published=True
    ).order_by('-created_at')
    
    context = {
        'news_articles': news_articles,
    }
    return render(request, 'publicpage/news_list.html', context)

def about(request):
    return render(request, 'publicpage/about.html')

def services(request):
    return render(request, 'publicpage/services.html')

def contact(request):
    if request.method == 'POST':
        try:
            # Create new contact message
            ContactUs.objects.create(
                name=request.POST.get('name'),
                email=request.POST.get('email'),
                subject=request.POST.get('subject'),
                message=request.POST.get('message')
            )
            messages.success(request, 'Thank you for your message! We will get back to you soon.')
        except Exception as e:
            messages.error(request, 'Sorry, there was an error sending your message. Please try again.')
        return redirect('publicpage:contact')
        
    return render(request, 'publicpage/contact.html')