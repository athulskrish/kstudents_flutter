from rest_framework import viewsets, filters, permissions
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
    ContactUs,
    UserProfile
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
from django.core.mail import send_mail, EmailMultiAlternatives
from django.conf import settings
import uuid
from datetime import timedelta
from django.utils import timezone
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.shortcuts import get_object_or_404, render
from django.http import Http404

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
    lookup_field = 'slug'

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

class FeaturedExamsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that returns exams marked to show on the home page
    """
    queryset = Exam.objects.filter(show_on_home=True, is_published=True).order_by('exam_date')[:5]
    serializer_class = ExamSerializer
    permission_classes = [permissions.AllowAny]

class FeaturedJobsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that returns jobs marked to show on the home page
    """
    queryset = Job.objects.filter(is_published=True).order_by('-updated_at')[:5]
    serializer_class = JobSerializer
    permission_classes = [permissions.AllowAny]

class FeaturedEventsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that returns events marked to show on the home page
    """
    queryset = Event.objects.filter(is_published=True).order_by('event_start')[:5]
    serializer_class = EventSerializer
    permission_classes = [permissions.AllowAny]

class FeaturedNewsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that returns news articles marked to show on the home page
    """
    queryset = News.objects.filter(is_published=True).order_by('-created_at')[:5]
    serializer_class = NewsSerializer
    permission_classes = [permissions.AllowAny]

# api/views/auth.py
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework import generics, permissions
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import get_user_model
from api.serializers import UserSerializer, CustomTokenObtainPairSerializer
from rest_framework_simplejwt.tokens import RefreshToken
from django.shortcuts import get_object_or_404 # Import get_object_or_404

User = get_user_model()

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    permission_classes = (permissions.AllowAny,)
    serializer_class = UserSerializer

    def create(self, request, *args, **kwargs):
        try:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            user = serializer.save()

            # Get or create UserProfile (should exist due to signal, but safe check)
            try:
                user_profile = user.userprofile
            except UserProfile.DoesNotExist:
                user_profile = UserProfile.objects.create(user=user, email=user.email)

            # Generate verification token and set expiry
            token = uuid.uuid4().hex
            user_profile.verification_token = token
            user_profile.verification_token_expires_at = timezone.now() + timedelta(hours=24) # Token expires in 24 hours
            user_profile.is_verified = False # Ensure is_verified is False on registration
            user_profile.save()

            # Construct verification URL - **NOTE: Update settings.BASE_URL with your actual domain/IP**
            base_url = getattr(settings, 'BASE_URL', 'http://localhost:8000') # Default if not set
            verification_link = f"{base_url}/api/auth/verify-email/{token}/"

            # Send verification email using templates
            subject = 'Verify Your Email Address'
            from_email = settings.DEFAULT_FROM_EMAIL
            recipient_list = [user.email]

            # Render email templates
            context = {'username': user.username, 'verification_link': verification_link}
            text_content = render_to_string('emails/verification_email.txt', context)
            html_content = render_to_string('emails/verification_email.html', context)

            try:
                # Create the email with both plain text and HTML parts
                email = EmailMultiAlternatives(subject, text_content, from_email, recipient_list)
                email.attach_alternative(html_content, "text/html")
                email.send(fail_silently=False)
                print(f"Verification email sent to {user.email}")
            except Exception as e:
                print(f"Error sending verification email to {user.email}: {e}")
                # Consider logging this error properly and potentially informing the user
                # or marking the user for later email retry.

            refresh = RefreshToken.for_user(user)
            access_token = str(refresh.access_token)
            refresh_token = str(refresh)

            return Response({
                "user": UserSerializer(user, context=self.get_serializer_context()).data,
                "message": "User created successfully. Please check your email to verify your account.",
                "access": access_token,
                "refresh": refresh_token,
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            # Log the error with traceback for debugging
            import traceback
            print("="*80)
            print("An unexpected error occurred during registration:")
            traceback.print_exc()
            print("="*80)

            # Return a generic error message to the user, or a more specific one if appropriate
            return Response({
                'detail': 'An unexpected error occurred during registration.',
                'error': str(e) # Optionally include error detail in debug/dev mode
            }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

class EmailVerificationView(views.APIView):
    permission_classes = (permissions.AllowAny,)

    def get(self, request, token, *args, **kwargs):
        try:
            user_profile = UserProfile.objects.get(verification_token=token)
        except UserProfile.DoesNotExist:
            # Raise Http404 for invalid token
            raise Http404("Invalid or expired token.")

        # Check if token has expired
        if user_profile.verification_token_expires_at and timezone.now() > user_profile.verification_token_expires_at:
            # Raise Http404 for expired token
            raise Http404("Invalid or expired token.")

        # Check if user is already verified (optional - can show a different message)
        # if user_profile.is_verified:
        #      return Response({'detail': 'Email already verified.'}, status=status.HTTP_200_OK)

        # Verify the user's email
        user_profile.is_verified = True
        user_profile.verification_token = None # Clear token after use
        user_profile.verification_token_expires_at = None
        user_profile.save()

        # Render success template on successful verification
        return render(request, 'emails/verification_success.html', {'user': user_profile.user})


class ResendVerificationEmailView(views.APIView):
    permission_classes = (permissions.AllowAny,)

    def post(self, request, *args, **kwargs):
        email = request.data.get('email')
        if not email:
            return Response({'detail': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
            user_profile = user.userprofile
        except (User.DoesNotExist, UserProfile.DoesNotExist):
            return Response({'detail': 'User with this email does not exist.'}, status=status.HTTP_404_NOT_FOUND)

        if user_profile.is_verified:
            return Response({'detail': 'Email is already verified.'}, status=status.HTTP_200_OK)

        # Generate a new token and set new expiry
        token = uuid.uuid4().hex
        user_profile.verification_token = token
        user_profile.verification_token_expires_at = timezone.now() + timedelta(hours=24)
        user_profile.save()

        # Construct verification URL - **NOTE: Update settings.BASE_URL with your actual domain/IP**
        base_url = getattr(settings, 'BASE_URL', 'http://localhost:8000')
        verification_link = f"{base_url}/api/auth/verify-email/{token}/"

        # Send new verification email using templates
        subject = 'Verify Your Email Address - Resent'
        from_email = settings.DEFAULT_FROM_EMAIL
        recipient_list = [user.email]

        # Render email templates
        context = {'username': user.username, 'verification_link': verification_link}
        text_content = render_to_string('emails/verification_email.txt', context)
        html_content = render_to_string('emails/verification_email.html', context)

        try:
            # Create the email with both plain text and HTML parts
            email = EmailMultiAlternatives(subject, text_content, from_email, recipient_list)
            email.attach_alternative(html_content, "text/html")
            email.send(fail_silently=False)
            print(f"Resent verification email to {user.email}")
            return Response({'detail': 'Verification email resent.'}, status=status.HTTP_200_OK)
        except Exception as e:
            print(f"Error resending verification email to {user.email}: {e}")
            return Response({'detail': 'Failed to resend verification email.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)