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
    JobViewSet
)

router = DefaultRouter()
router.register(r'universities', UniversityViewSet)
router.register(r'degrees', DegreeViewSet)
router.register(r'question-papers', QuestionPaperViewSet)
router.register(r'notes', NoteViewSet)
router.register(r'exams', ExamViewSet)
router.register(r'entrance-notifications', EntranceNotificationViewSet)
router.register(r'news', NewsViewSet)
router.register(r'jobs', JobViewSet)

urlpatterns = [
    path('', include(router.urls)),
    path('auth/login/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/register/', RegisterView.as_view(), name='auth_register'),
]
