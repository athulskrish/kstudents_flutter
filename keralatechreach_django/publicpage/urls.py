from django.urls import path
from . import views

app_name = 'publicpage' # Explicitly define the app namespace

urlpatterns = [
    path('', views.home, name='home'),
    path('search/', views.search, name='search'),
    path('events/', views.events_list, name='events'),
    path('news/', views.news_list, name='news_list'),
    path('newsletter-signup/', views.newsletter_signup, name='newsletter_signup'),
    path('news/<slug:slug>/', views.news_detail, name='news_detail'),
    path('events/<int:pk>/', views.event_detail, name='event_detail'),
    path('questionpapers/<int:pk>/', views.questionpaper_detail, name='questionpaper_detail'),
    path('about/', views.about, name='about'),
    path('services/', views.services, name='services'),
    path('contact/', views.contact, name='contact'),
]