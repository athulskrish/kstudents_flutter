from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    UniversityViewSet,
    DegreeViewSet,
    QuestionPaperViewSet,
    NoteViewSet,
    ExamViewSet,
    EntranceNotificationViewSet,
    CustomTokenObtainPairView,
    TokenRefreshView,
    RegisterView,
    NewsViewSet,
    JobViewSet,
    QuestionPaperUploadView,
    NoteUploadView,
    ContactMessageView,
    AffiliateProductViewSet,
    AffiliateCategoryViewSet,
    EventViewSet,
    EventCategoryViewSet,
    DistrictViewSet,
    InitiativeViewSet,
    FAQViewSet,
    FeaturedJobsViewSet,
    FeaturedEventsViewSet,
    FeaturedNewsViewSet,
    FeaturedExamsViewSet,
    EmailVerificationView,
    ResendVerificationEmailView
)

# Create the router for ViewSets
router = DefaultRouter()
router.register(r'universities', UniversityViewSet)
router.register(r'degrees', DegreeViewSet)
router.register(r'question-papers', QuestionPaperViewSet)
router.register(r'notes', NoteViewSet)
router.register(r'exams', ExamViewSet)
router.register(r'entrance-notifications', EntranceNotificationViewSet)
router.register(r'news', NewsViewSet)
router.register(r'jobs', JobViewSet)
router.register(r'affiliate-products', AffiliateProductViewSet)
router.register(r'affiliate-categories', AffiliateCategoryViewSet)
router.register(r'events', EventViewSet)
router.register(r'event-categories', EventCategoryViewSet)
router.register(r'districts', DistrictViewSet)
router.register(r'initiatives', InitiativeViewSet)
router.register(r'faqs', FAQViewSet)
router.register(r'featured-jobs', FeaturedJobsViewSet, basename='featured-jobs')
router.register(r'featured-events', FeaturedEventsViewSet, basename='featured-events')
router.register(r'featured-news', FeaturedNewsViewSet, basename='featured-news')
router.register(r'featured-exams', FeaturedExamsViewSet, basename='featured-exams')

# Define custom endpoints first
urlpatterns = [
    # Authentication endpoints
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', RegisterView.as_view(), name='auth_register'),
    path('auth/verify-email/<str:token>/', EmailVerificationView.as_view(), name='verify_email'),
    path('auth/resend-verification-email/', ResendVerificationEmailView.as_view(), name='resend_verification_email'),
    
    # Upload endpoints - these must come before router.urls to avoid conflicts
    path('question-papers/upload/', QuestionPaperUploadView.as_view(), name='questionpaper-upload'),
    path('notes/upload/', NoteUploadView.as_view(), name='note-upload'),
    path('contact/', ContactMessageView.as_view(), name='contact-message'),
    
    # Include router URLs last
    path('', include(router.urls)),
]
