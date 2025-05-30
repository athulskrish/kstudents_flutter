from rest_framework import viewsets, filters
from rest_framework.permissions import IsAuthenticatedOrReadOnly, AllowAny
from django_filters.rest_framework import DjangoFilterBackend
from admindashboard.models import (
    QuestionPaper,
    Note,
    University,
    Degree,
    Exam,
    EntranceNotification,
    News,
    Job,
    AffiliateProduct,
    AffiliateCategory,
    ContactMessage
)
from .serializers import (
    QuestionPaperSerializer,
    NoteSerializer,
    UniversitySerializer,
    DegreeSerializer,
    ExamSerializer,
    EntranceNotificationSerializer,
    NewsSerializer,
    JobSerializer,
    AffiliateProductSerializer,
    AffiliateCategorySerializer,
    ContactMessageSerializer
)
from rest_framework import status, views
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response

class UniversityViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = University.objects.all()
    serializer_class = UniversitySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']

class DegreeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Degree.objects.all()
    serializer_class = DegreeSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['university']
    search_fields = ['name']

class QuestionPaperViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = QuestionPaper.objects.filter(is_published=True)
    serializer_class = QuestionPaperSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['degree', 'semester', 'year', 'university_id']
    search_fields = ['subject']

class NoteViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Note.objects.all()
    serializer_class = NoteSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['degree', 'semester', 'year', 'university']
    search_fields = ['title', 'module']

class ExamViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Exam.objects.filter(is_published=True)
    serializer_class = ExamSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['degree_name', 'semester', 'admission_year', 'university']
    search_fields = ['exam_name']

class EntranceNotificationViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EntranceNotification.objects.filter(is_published=True)
    serializer_class = EntranceNotificationSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'description']

class NewsViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = News.objects.filter(is_published=True)
    serializer_class = NewsSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'content', 'excerpt']

class JobViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Job.objects.filter(is_published=True)
    serializer_class = JobSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['title', 'description']

class QuestionPaperUploadView(views.APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [IsAuthenticatedOrReadOnly]

    def post(self, request, *args, **kwargs):
        file_obj = request.FILES.get('file')
        subject = request.data.get('subject')
        degree = request.data.get('degree')
        semester = request.data.get('semester')
        year = request.data.get('year')
        university_id = request.data.get('university_id')
        if not file_obj or not subject or not degree or not semester or not year or not university_id:
            return Response({'detail': 'Missing required fields.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            paper = QuestionPaper.objects.create(
                file_path=file_obj,
                subject=subject,
                degree_id=degree,
                semester=semester,
                year=year,
                university_id_id=university_id,
                is_published=True
            )
            return Response({'detail': 'File uploaded successfully.', 'id': paper.id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

class NoteUploadView(views.APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [IsAuthenticatedOrReadOnly]

    def post(self, request, *args, **kwargs):
        file_obj = request.FILES.get('file')
        title = request.data.get('title')
        module = request.data.get('module')
        degree = request.data.get('degree')
        semester = request.data.get('semester')
        year = request.data.get('year')
        university = request.data.get('university')
        if not file_obj or not title or not degree or not semester or not year or not university:
            return Response({'detail': 'Missing required fields.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            note = Note.objects.create(
                file=file_obj,
                title=title,
                module=module or '',
                degree_id=degree,
                semester=semester,
                year=year,
                university_id=university
            )
            return Response({'detail': 'File uploaded successfully.', 'id': note.id}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

class ContactMessageView(views.APIView):
    permission_classes = [IsAuthenticatedOrReadOnly]

    def post(self, request, *args, **kwargs):
        serializer = ContactMessageSerializer(data=request.data)
        if serializer.is_valid():
            serializer.save()
            return Response({'detail': 'Message sent successfully.'}, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class AffiliateProductViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AffiliateProduct.objects.all()
    serializer_class = AffiliateProductSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

class AffiliateCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AffiliateCategory.objects.all()
    serializer_class = AffiliateCategorySerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

# api/views/auth.py
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from api.serializers import UserSerializer, CustomTokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = UserSerializer

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()

        refresh = RefreshToken.for_user(user)
        access_token = str(refresh.access_token)
        refresh_token = str(refresh)

        return Response({
            "user": UserSerializer(user, context=self.get_serializer_context()).data,
            "message": "User created successfully",
            "access": access_token,
            "refresh": refresh_token,
        }, status=status.HTTP_201_CREATED)