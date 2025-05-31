from rest_framework import serializers
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
    District
)

class UniversitySerializer(serializers.ModelSerializer):
    class Meta:
        model = University
        fields = ['id', 'name']

class DegreeSerializer(serializers.ModelSerializer):
    university_name = serializers.CharField(source='university.name', read_only=True)
    
    class Meta:
        model = Degree
        fields = ['id', 'name', 'university', 'university_name']

class QuestionPaperSerializer(serializers.ModelSerializer):
    degree_name = serializers.CharField(source='degree.name', read_only=True)
    university_name = serializers.CharField(source='university_id.name', read_only=True)
    
    class Meta:
        model = QuestionPaper
        fields = [
            'id', 'degree', 'degree_name', 'semester', 
            'subject', 'file_path', 'year', 
            'university_id', 'university_name', 
            'is_published'
        ]

class NoteSerializer(serializers.ModelSerializer):
    degree_name = serializers.CharField(source='degree.name', read_only=True)
    university_name = serializers.CharField(source='university.name', read_only=True)
    module = serializers.CharField(source='subject', read_only=True)
    subject = serializers.CharField(read_only=True)
    
    def to_representation(self, instance):
        print(f"DEBUG - Note instance: id={instance.id}, title={instance.title}, subject={instance.subject}")
        ret = super().to_representation(instance)
        print(f"DEBUG - Serialized note: {ret}")
        return ret
    
    class Meta:
        model = Note
        fields = [
            'id', 'title', 'module', 'subject', 'degree',
            'degree_name', 'semester', 'year',
            'university', 'university_name', 'file'
        ]

class ExamSerializer(serializers.ModelSerializer):
    degree_name = serializers.CharField(source='degree_name.name', read_only=True)
    university_name = serializers.CharField(source='university.name', read_only=True)
    
    class Meta:
        model = Exam
        fields = [
            'id', 'exam_name', 'exam_date', 'exam_url',
            'degree_name', 'semester', 'admission_year',
            'university', 'university_name', 'is_published'
        ]

class EntranceNotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = EntranceNotification
        fields = [
            'id', 'title', 'description', 'deadline',
            'link', 'published_date', 'is_published'
        ]

class NewsSerializer(serializers.ModelSerializer):
    created_by_username = serializers.CharField(source='created_by.user.username', read_only=True)

    class Meta:
        model = News
        fields = [
            'id', 'title', 'slug', 'content', 'excerpt', 'image',
            'thumbnail', 'created_at', 'updated_at', 'is_published',
            'created_by', 'created_by_username', 'meta_title', 'meta_description',
            'keywords', 'reading_time', 'views_count', 'likes_count'
        ]

class JobSerializer(serializers.ModelSerializer):
    created_by_username = serializers.CharField(source='created_by.user.username', read_only=True)

    class Meta:
        model = Job
        fields = [
            'id', 'title', 'description', 'last_date', 'updated_at',
            'is_published', 'created_by', 'created_by_username'
        ]

# api/serializers/auth.py
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password

User = get_user_model()

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('id', 'username', 'email', 'password')
        extra_kwargs = {'password': {'write_only': True}}

    def validate_password(self, value):
        validate_password(value)
        return value

    def create(self, validated_data):
        user = User.objects.create_user(
            username=validated_data['username'],
            email=validated_data.get('email', ''),
            password=validated_data['password']
        )
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    user = UserSerializer(read_only=True)

    def validate(self, attrs):
        data = super().validate(attrs)
        data['user'] = UserSerializer(self.user).data
        return data

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token['username'] = user.username
        token['email'] = user.email
        return token

class AffiliateProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = AffiliateProduct
        fields = '__all__'

class AffiliateCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = AffiliateCategory
        fields = '__all__'

class ContactMessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ContactMessage
        fields = ['id', 'name', 'email', 'subject', 'message', 'created_at']

class EventCategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = EventCategory
        fields = ['id', 'category']

class DistrictSerializer(serializers.ModelSerializer):
    class Meta:
        model = District
        fields = ['id', 'name', 'is_active']

class EventSerializer(serializers.ModelSerializer):
    # Add fields to map Django model to Flutter expectations
    title = serializers.CharField(source='name')
    date = serializers.DateTimeField(source='event_start')
    location = serializers.CharField(source='place')
    category_name = serializers.CharField(source='category.category', read_only=True)
    district_name = serializers.CharField(source='district.name', read_only=True)
    
    class Meta:
        model = Event
        fields = [
            'id', 'title', 'name', 'date', 'event_start', 'event_end', 
            'location', 'place', 'description', 'link', 'map_link',
            'category', 'category_name', 'district', 'district_name',
            'is_published'
        ]