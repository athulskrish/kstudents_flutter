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
    ContactMessage,
    Event,
    EventCategory,
    District,
    Initiative,
    FAQ,
    ContactUs
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
    ContactMessageSerializer,
    EventSerializer,
    EventCategorySerializer,
    DistrictSerializer,
    InitiativeSerializer,
    FAQSerializer
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

class InitiativeViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Initiative.objects.filter(is_published=True)
    serializer_class = InitiativeSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description']

class FAQViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = FAQ.objects.filter(is_published=True)
    serializer_class = FAQSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['question', 'answer']

class QuestionPaperUploadView(views.APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [AllowAny]  # Allow any user to upload for now

    def post(self, request, *args, **kwargs):
        print("="*80)
        print("QuestionPaperUploadView.post() called")
        print(f"Request content type: {request.content_type}")
        print(f"Request headers: {request.headers}")
        print(f"Request method: {request.method}")
        print(f"Request data: {request.data}")
        print(f"Request files: {request.FILES}")
        print("="*80)
        
        file_obj = request.FILES.get('file')
        subject = request.data.get('subject')
        degree = request.data.get('degree')
        semester = request.data.get('semester')
        year = request.data.get('year')
        university_id = request.data.get('university_id')
        
        # Default to admin user if no created_by is provided
        created_by_id = request.data.get('created_by', 1)
        
        if not file_obj:
            return Response({'detail': 'Missing file.'}, status=status.HTTP_400_BAD_REQUEST)
        if not subject:
            return Response({'detail': 'Missing subject.'}, status=status.HTTP_400_BAD_REQUEST)
        if not degree:
            return Response({'detail': 'Missing degree.'}, status=status.HTTP_400_BAD_REQUEST)
        if not semester:
            return Response({'detail': 'Missing semester.'}, status=status.HTTP_400_BAD_REQUEST)
        if not year:
            return Response({'detail': 'Missing year.'}, status=status.HTTP_400_BAD_REQUEST)
        if not university_id:
            return Response({'detail': 'Missing university_id.'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Convert to integers if they're strings
            degree_id = int(degree)
            semester_val = int(semester)
            year_val = int(year)
            university_id_val = int(university_id)
            created_by_id_val = int(created_by_id)
            
            print(f"Creating QuestionPaper with: degree_id={degree_id}, semester={semester_val}, year={year_val}, university_id={university_id_val}")
            
            # Get the user profile for created_by
            from admindashboard.models import UserProfile
            user_profile = UserProfile.objects.get(id=created_by_id_val)
            
            paper = QuestionPaper.objects.create(
                file_path=file_obj,
                subject=subject,
                degree_id=degree_id,
                semester=semester_val,
                year=year_val,
                university_id_id=university_id_val,
                is_published=True,
                created_by=user_profile
            )
            return Response({'detail': 'File uploaded successfully.', 'id': paper.id}, status=status.HTTP_201_CREATED)
        except UserProfile.DoesNotExist:
            print("UserProfile does not exist")
            return Response({'detail': 'Invalid user profile ID.'}, status=status.HTTP_400_BAD_REQUEST)
        except ValueError as e:
            print(f"ValueError: {str(e)}")
            return Response({'detail': f'Invalid field values: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(f"Exception: {str(e)}")
            import traceback
            traceback.print_exc()
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    # Add this to debug why OPTIONS/GET requests might be coming through
    def get(self, request, *args, **kwargs):
        return Response({'detail': 'GET method not allowed. Use POST for file uploads.'}, 
                        status=status.HTTP_405_METHOD_NOT_ALLOWED)
    
    def options(self, request, *args, **kwargs):
        response = super().options(request, *args, **kwargs)
        print("OPTIONS request received", response)
        return response

class NoteUploadView(views.APIView):
    parser_classes = [MultiPartParser, FormParser]
    permission_classes = [AllowAny]  # Allow any user to upload for now

    def post(self, request, *args, **kwargs):
        print("="*80)
        print("NoteUploadView.post() called")
        print(f"Request content type: {request.content_type}")
        print(f"Request headers: {request.headers}")
        print(f"Request method: {request.method}")
        print(f"Request data: {request.data}")
        print(f"Request files: {request.FILES}")
        print("="*80)
        
        file_obj = request.FILES.get('file')
        title = request.data.get('title')
        subject = request.data.get('subject') or request.data.get('module', '')  # Try subject first, then module
        module = request.data.get('module', '')  # Get module if available
        degree = request.data.get('degree')
        semester = request.data.get('semester')
        year = request.data.get('year')
        university = request.data.get('university')
        
        # Default to admin user if no uploaded_by is provided
        uploaded_by_id = request.data.get('uploaded_by', 1)
        
        if not file_obj:
            return Response({'detail': 'Missing file.'}, status=status.HTTP_400_BAD_REQUEST)
        if not title:
            return Response({'detail': 'Missing title.'}, status=status.HTTP_400_BAD_REQUEST)
        if not degree:
            return Response({'detail': 'Missing degree.'}, status=status.HTTP_400_BAD_REQUEST)
        if not semester:
            return Response({'detail': 'Missing semester.'}, status=status.HTTP_400_BAD_REQUEST)
        if not year:
            return Response({'detail': 'Missing year.'}, status=status.HTTP_400_BAD_REQUEST)
        if not university:
            return Response({'detail': 'Missing university.'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            # Convert to integers if they're strings
            degree_id = int(degree)
            semester_val = int(semester)
            year_val = int(year)
            university_id = int(university)
            uploaded_by_id_val = int(uploaded_by_id)
            
            print(f"Creating Note with: title={title}, degree_id={degree_id}, semester={semester_val}, year={year_val}, university_id={university_id}")
            
            # Get the user profile for uploaded_by
            from admindashboard.models import UserProfile
            user_profile = UserProfile.objects.get(id=uploaded_by_id_val)
            
            # Create the note with all required fields
            note = Note.objects.create(
                file=file_obj,
                title=title,
                subject=subject or module,  # Use subject if available, otherwise module
                degree_id=degree_id,
                semester=semester_val,
                year=year_val,
                university_id=university_id,
                uploaded_by=user_profile,
                is_published=True
            )
            return Response({'detail': 'File uploaded successfully.', 'id': note.id}, status=status.HTTP_201_CREATED)
        except UserProfile.DoesNotExist:
            print("UserProfile does not exist")
            return Response({'detail': 'Invalid user profile ID.'}, status=status.HTTP_400_BAD_REQUEST)
        except ValueError as e:
            print(f"ValueError: {str(e)}")
            return Response({'detail': f'Invalid field values: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
        except Exception as e:
            print(f"Exception: {str(e)}")
            import traceback
            traceback.print_exc()
            return Response({'detail': str(e)}, status=status.HTTP_400_BAD_REQUEST)

    # Add this to debug why OPTIONS/GET requests might be coming through
    def get(self, request, *args, **kwargs):
        return Response({'detail': 'GET method not allowed. Use POST for file uploads.'}, 
                        status=status.HTTP_405_METHOD_NOT_ALLOWED)
    
    def options(self, request, *args, **kwargs):
        response = super().options(request, *args, **kwargs)
        print("OPTIONS request received", response)
        return response

class ContactMessageView(views.APIView):
    permission_classes = [AllowAny]  # Changed from IsAuthenticatedOrReadOnly to AllowAny

    def post(self, request, *args, **kwargs):
        try:
            # Create contact message directly using ContactUs model (no created_by required)
            ContactUs.objects.create(
                name=request.data.get('name'),
                email=request.data.get('email'),
                subject=request.data.get('subject'),
                message=request.data.get('message')
            )
            return Response({'detail': 'Message sent successfully.'}, status=status.HTTP_201_CREATED)
        except Exception as e:
            print(f"Error sending message: {str(e)}")
            return Response({'detail': f'Failed to send message: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)

class AffiliateProductViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AffiliateProduct.objects.all()
    serializer_class = AffiliateProductSerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

class AffiliateCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AffiliateCategory.objects.all()
    serializer_class = AffiliateCategorySerializer
    permission_classes = [IsAuthenticatedOrReadOnly]

class EventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Event.objects.filter(is_published=True)
    serializer_class = EventSerializer
    permission_classes = [AllowAny]
    filter_backends = [DjangoFilterBackend, filters.SearchFilter]
    filterset_fields = ['category', 'district', 'event_start']
    search_fields = ['name', 'description', 'place']

class EventCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EventCategory.objects.all()
    serializer_class = EventCategorySerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['category']

class DistrictViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = District.objects.filter(is_active=True)
    serializer_class = DistrictSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name']

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