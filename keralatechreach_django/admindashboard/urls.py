from django.contrib.auth import views as auth_views
from django.urls import path
from .views.dashboard import dashboard, tables
from .views.academic import (
    question_list, question_create, question_edit, question_delete,
    university_list, university_create, university_edit, university_delete,
    degree_list, degree_create, degree_edit, degree_delete,
    exam_list, exam_create, exam_edit, exam_delete,
    note_list, note_create, note_edit, note_delete
)
from .views.content import (
    news_list, news_create, news_edit, news_delete,
    event_list, event_create, event_edit, event_delete,
    gallery_list, gallery_create, gallery_edit, gallery_delete,
    district_list, district_create, district_edit, district_delete,
    initiative_list, initiative_create, initiative_edit, initiative_delete,
    event_category_list, event_category_create, event_category_edit, event_category_delete
)
from .views.users import (
    register, profile, user_list, user_detail, user_delete,
    UserListView, UserCreateView, UserUpdateView, UserDeleteView,
    custom_logout
)
from .views.jobs import job_list, job_create, job_edit, job_delete
from .views.activity_log import activity_log_view
from .views.contact_messages import contact_messages, contact_message_detail, contact_message_delete
from .views.ads import ad_list, ad_create, ad_edit, ad_delete

app_name = 'admindashboard'

urlpatterns = [
    # Authentication URLs
    path('login/', auth_views.LoginView.as_view(template_name='admindashboard/login.html'), name='login'),
    path('logout/', custom_logout, name='logout'),
    path('register/', register, name='register'),
    path('profile/', profile, name='profile'),
    
    # Password Reset URLs
    path('password-reset/',
         auth_views.PasswordResetView.as_view(
             template_name='admindashboard/password_reset.html',
             email_template_name='admindashboard/password_reset_email.html',
             subject_template_name='admindashboard/password_reset_subject.txt',
             success_url='/admindashboard/password-reset/done/'
         ),
         name='password_reset'),
    path('password-reset/done/',
         auth_views.PasswordResetDoneView.as_view(
             template_name='admindashboard/password_reset_done.html'
         ),
         name='password_reset_done'),
    path('reset/<uidb64>/<token>/',
         auth_views.PasswordResetConfirmView.as_view(
             template_name='admindashboard/password_reset_confirm.html',
             success_url='/admindashboard/reset/done/'
         ),
         name='password_reset_confirm'),
    path('reset/done/',
         auth_views.PasswordResetCompleteView.as_view(
             template_name='admindashboard/password_reset_complete.html'
         ),
         name='password_reset_complete'),
    
    # User Management
    path('users/', UserListView.as_view(), name='user_list'),
    path('users/add/', UserCreateView.as_view(), name='user_create'),
    path('users/<int:pk>/edit/', UserUpdateView.as_view(), name='user_update'),
    path('users/<int:pk>/delete/', UserDeleteView.as_view(), name='user_delete'),
    
    # Dashboard
    path('', dashboard, name='dashboard'),
    path('dashboard/', dashboard, name='dashboard'),
    path('tables/', tables, name='tables'),
    
    # Question Paper URLs
    path('questions/', question_list, name='question_list'),
    path('questions/create/', question_create, name='question_create'),
    path('questions/<int:pk>/edit/', question_edit, name='question_edit'),
    path('questions/<int:pk>/delete/', question_delete, name='question_delete'),
    
    # Note URLs
    path('notes/', note_list, name='note_list'),
    path('notes/create/', note_create, name='note_create'),
    path('notes/<int:pk>/edit/', note_edit, name='note_edit'),
    path('notes/<int:pk>/delete/', note_delete, name='note_delete'),
    
    # University URLs
    path('universities/', university_list, name='university_list'),
    path('universities/create/', university_create, name='university_create'),
    path('universities/<int:pk>/edit/', university_edit, name='university_edit'),
    path('universities/<int:pk>/delete/', university_delete, name='university_delete'),
    
    # Degree URLs
    path('degrees/', degree_list, name='degree_list'),
    path('degrees/create/', degree_create, name='degree_create'),
    path('degrees/<int:pk>/edit/', degree_edit, name='degree_edit'),
    path('degrees/<int:pk>/delete/', degree_delete, name='degree_delete'),
    
    # Exam URLs
    path('exams/', exam_list, name='exam_list'),
    path('exams/create/', exam_create, name='exam_create'),
    path('exams/<int:pk>/edit/', exam_edit, name='exam_edit'),
    path('exams/<int:pk>/delete/', exam_delete, name='exam_delete'),
    
    # Job URLs
    path('jobs/', job_list, name='job_list'),
    path('jobs/create/', job_create, name='job_create'),
    path('jobs/<int:pk>/edit/', job_edit, name='job_edit'),
    path('jobs/<int:pk>/delete/', job_delete, name='job_delete'),
    
    # Event URLs
    path('events/', event_list, name='event_list'),
    path('events/create/', event_create, name='event_create'),
    path('events/<int:pk>/edit/', event_edit, name='event_edit'),
    path('events/<int:pk>/delete/', event_delete, name='event_delete'),
    
    # Event Category URLs
    path('event-categories/', event_category_list, name='event_category_list'),
    path('event-categories/create/', event_category_create, name='event_category_create'),
    path('event-categories/<int:pk>/edit/', event_category_edit, name='event_category_edit'),
    path('event-categories/<int:pk>/delete/', event_category_delete, name='event_category_delete'),
    
    # News URLs
    path('news/', news_list, name='news_list'),
    path('news/create/', news_create, name='news_create'),
    path('news/<int:pk>/edit/', news_edit, name='news_edit'),
    path('news/<int:pk>/delete/', news_delete, name='news_delete'),
    
    # District URLs
    path('districts/', district_list, name='district_list'),
    path('districts/create/', district_create, name='district_create'),
    path('districts/<int:pk>/edit/', district_edit, name='district_edit'),
    path('districts/<int:pk>/delete/', district_delete, name='district_delete'),
    
    # Initiative URLs
    path('initiatives/', initiative_list, name='initiative_list'),
    path('initiatives/create/', initiative_create, name='initiative_create'),
    path('initiatives/<int:pk>/edit/', initiative_edit, name='initiative_edit'),
    path('initiatives/<int:pk>/delete/', initiative_delete, name='initiative_delete'),
    
    # Gallery URLs
    path('gallery/', gallery_list, name='gallery_list'),
    path('gallery/create/', gallery_create, name='gallery_create'),
    path('gallery/<int:pk>/edit/', gallery_edit, name='gallery_edit'),
    path('gallery/<int:pk>/delete/', gallery_delete, name='gallery_delete'),
    
    path('activity-log/', activity_log_view, name='activity_log'),

    # Contact Messages
    path('contact-messages/', contact_messages, name='contact_messages'),
    path('contact-messages/<int:pk>/', contact_message_detail, name='contact_message_detail'),
    path('contact-messages/<int:pk>/delete/', contact_message_delete, name='contact_message_delete'),

    # Ad Settings
    path('ads/', ad_list, name='ad_list'),
    path('ads/create/', ad_create, name='ad_create'),
    path('ads/<int:pk>/edit/', ad_edit, name='ad_edit'),
    path('ads/<int:pk>/delete/', ad_delete, name='ad_delete'),
]