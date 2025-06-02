from django import forms
from django.contrib.auth.forms import UserCreationForm, UserChangeForm
from django.contrib.auth.models import User
from .models import (
    QuestionPaper, University, Degree, Exam, Job, District,
    Initiative, EventCategory, Event, News, ContactMessage,
    Gallery, SiteSetting, UserProfile, AdSettings, Note
)
from django.utils.text import slugify

class QuestionPaperForm(forms.ModelForm):
    class Meta:
        model = QuestionPaper
        fields = ['degree', 'semester', 'subject', 'file_path', 'year', 'university_id', 'is_published']
        widgets = {
            'subject': forms.TextInput(attrs={'class': 'form-control'}),
            'semester': forms.NumberInput(attrs={'class': 'form-control'}),
            'year': forms.NumberInput(attrs={'class': 'form-control'}),
            'file_path': forms.FileInput(attrs={'class': 'form-control'}),
            'university_id': forms.Select(attrs={'class': 'form-select'}),
            'degree': forms.Select(attrs={'class': 'form-select'}),
            'is_published': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class UniversityForm(forms.ModelForm):
    class Meta:
        model = University
        fields = ['name']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
        }

class DegreeForm(forms.ModelForm):
    class Meta:
        model = Degree
        fields = ['name', 'university']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'university': forms.Select(attrs={'class': 'form-select'}),
        }

class ExamForm(forms.ModelForm):
    class Meta:
        model = Exam
        fields = [
            'exam_name', 'exam_date', 'exam_url', 'degree_name', 
            'semester', 'admission_year', 'university', 'is_published', 'show_on_home'
        ]
        widgets = {
            'exam_name': forms.TextInput(attrs={'class': 'form-control'}),
            'exam_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'exam_url': forms.URLInput(attrs={'class': 'form-control'}),
            'semester': forms.TextInput(attrs={'class': 'form-control'}),
            'admission_year': forms.NumberInput(attrs={'class': 'form-control'}),
            'university': forms.Select(attrs={'class': 'form-select'}),
            'degree_name': forms.Select(attrs={'class': 'form-select'}),
            'is_published': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'show_on_home': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class NoteForm(forms.ModelForm):
    class Meta:
        model = Note
        fields = ['title', 'subject', 'degree', 'semester', 'year', 'university', 'file', 'is_published']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'subject': forms.TextInput(attrs={'class': 'form-control'}),
            'degree': forms.Select(attrs={'class': 'form-select'}),
            'semester': forms.NumberInput(attrs={'class': 'form-control'}),
            'year': forms.NumberInput(attrs={'class': 'form-control'}),
            'university': forms.Select(attrs={'class': 'form-select'}),
            'file': forms.FileInput(attrs={'class': 'form-control'}),
            'is_published': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class JobForm(forms.ModelForm):
    class Meta:
        model = Job
        fields = ['title', 'description', 'last_date', 'is_published']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control'}),
            'last_date': forms.DateInput(attrs={'class': 'form-control', 'type': 'date'}),
            'is_published': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class DistrictForm(forms.ModelForm):
    class Meta:
        model = District
        fields = ['name', 'is_active']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'})
        }

class InitiativeForm(forms.ModelForm):
    class Meta:
        model = Initiative
        fields = ['name', 'description', 'link', 'photo', 'is_published']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control'}),
            'link': forms.URLInput(attrs={'class': 'form-control'}),
            'photo': forms.FileInput(attrs={'class': 'form-control'}),
            'is_published': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class EventCategoryForm(forms.ModelForm):
    class Meta:
        model = EventCategory
        fields = ['category']
        widgets = {
            'category': forms.TextInput(attrs={'class': 'form-control'}),
        }

class EventForm(forms.ModelForm):
    # Add clean fields to ensure proper datetime formatting
    def clean_event_start(self):
        event_start = self.cleaned_data.get('event_start')
        return event_start

    def clean_event_end(self):
        event_end = self.cleaned_data.get('event_end')
        event_start = self.cleaned_data.get('event_start')
        
        # If event_end is provided, ensure it's after event_start
        if event_end and event_start and event_end < event_start:
            raise forms.ValidationError("Event end time must be after the start time.")
        
        return event_end
        
    class Meta:
        model = Event
        fields = ['name', 'event_start', 'event_end', 'place', 'link', 'description',
                 'map_link', 'district', 'category', 'is_published']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'event_start': forms.DateTimeInput(attrs={'class': 'form-control', 'type': 'datetime-local'}),
            'event_end': forms.DateTimeInput(attrs={'class': 'form-control', 'type': 'datetime-local'}),
            'place': forms.TextInput(attrs={'class': 'form-control'}),
            'link': forms.URLInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control'}),
            'map_link': forms.URLInput(attrs={'class': 'form-control'}),
            'district': forms.Select(attrs={'class': 'form-select'}),
            'category': forms.Select(attrs={'class': 'form-select'}),
            'is_published': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class NewsForm(forms.ModelForm):
    class Meta:
        model = News
        fields = [
            'title', 'slug', 'content', 'excerpt',
            'image', 'thumbnail', 'is_published',
            'meta_title', 'meta_description', 'keywords'
        ]
        widgets = {
            'title': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': ' ',
            }),
            'slug': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': ' ',
            }),
            'content': forms.Textarea(attrs={
                'class': 'form-control tinymce',
                'rows': 10
            }),
            'excerpt': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 3,
                'placeholder': 'Enter a brief summary of the article'
            }),
            'meta_title': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': ' ',
            }),
            'meta_description': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': ' ',
            }),
            'keywords': forms.TextInput(attrs={
                'class': 'form-control',
                'placeholder': ' ',
            }),
            'image': forms.FileInput(attrs={
                'class': 'form-control',
                'accept': 'image/*'
            }),
            'thumbnail': forms.FileInput(attrs={
                'class': 'form-control',
                'accept': 'image/*'
            }),
            'is_published': forms.CheckboxInput(attrs={
                'class': 'form-check-input',
                'role': 'switch'
            }),
        }

    def clean_slug(self):
        slug = self.cleaned_data.get('slug')
        if not slug:
            title = self.cleaned_data.get('title')
            if title:
                slug = slugify(title)
        return slug

class ContactMessageForm(forms.ModelForm):
    class Meta:
        model = ContactMessage
        fields = ['name', 'email', 'subject', 'message']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
            'subject': forms.TextInput(attrs={'class': 'form-control'}),
            'message': forms.Textarea(attrs={'class': 'form-control'}),
        }

class GalleryForm(forms.ModelForm):
    class Meta:
        model = Gallery
        fields = ['title', 'description', 'image', 'is_visible']
        widgets = {
            'title': forms.TextInput(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control'}),
            'image': forms.FileInput(attrs={'class': 'form-control'}),
            'is_visible': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class SiteSettingForm(forms.ModelForm):
    class Meta:
        model = SiteSetting
        fields = ['key', 'value', 'description', 'is_public']
        widgets = {
            'key': forms.TextInput(attrs={'class': 'form-control'}),
            'value': forms.Textarea(attrs={'class': 'form-control'}),
            'description': forms.Textarea(attrs={'class': 'form-control'}),
            'is_public': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class CustomUserCreationForm(UserCreationForm):
    email = forms.EmailField(required=True)
    first_name = forms.CharField(required=True)
    last_name = forms.CharField(required=True)
    is_staff = forms.BooleanField(required=False, label='Staff Status', widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    is_active = forms.BooleanField(required=False, initial=True, label='Active', widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))

    class Meta:
        model = User
        fields = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_active', 'password1', 'password2')

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for field_name, field in self.fields.items():
            if field_name not in ['is_staff', 'is_active']:
                field.widget.attrs.update({
                    'class': 'form-control',
                    'placeholder': '',  # Remove placeholder to avoid overlap with label
                })
            # Add help text for password fields
            if field_name == 'password1':
                field.help_text = 'Your password must contain at least 8 characters.'
            elif field_name == 'password2':
                field.help_text = 'Enter the same password as before, for verification.'

class CustomUserChangeForm(UserChangeForm):
    email = forms.EmailField(required=True)
    first_name = forms.CharField(required=True)
    last_name = forms.CharField(required=True)
    is_staff = forms.BooleanField(required=False, label='Staff Status', widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    is_active = forms.BooleanField(required=False, label='Active', widget=forms.CheckboxInput(attrs={'class': 'form-check-input'}))
    password = None  # Remove password field from form

    class Meta:
        model = User
        fields = ('username', 'email', 'first_name', 'last_name', 'is_staff', 'is_active')

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        for field_name, field in self.fields.items():
            if field_name not in ['is_staff', 'is_active']:
                field.widget.attrs.update({
                    'class': 'form-control',
                    'placeholder': '',  # Remove placeholder to avoid overlap with label
                })

class UserProfileForm(forms.ModelForm):
    class Meta:
        model = UserProfile
        fields = ['phone', 'district', 'profile_picture', 'bio', 'email']
        widgets = {
            'phone': forms.TextInput(attrs={'class': 'form-control'}),
            'bio': forms.Textarea(attrs={'class': 'form-control'}),
            'email': forms.EmailInput(attrs={'class': 'form-control'}),
            'profile_picture': forms.FileInput(attrs={'class': 'form-control'}),
        }

class UserProfileUpdateForm(forms.ModelForm):
    email = forms.EmailField(required=True, widget=forms.EmailInput(attrs={'class': 'form-control'}))
    first_name = forms.CharField(required=True, widget=forms.TextInput(attrs={'class': 'form-control'}))
    last_name = forms.CharField(required=True, widget=forms.TextInput(attrs={'class': 'form-control'}))

    class Meta:
        model = User
        fields = ['first_name', 'last_name', 'email']

class UserManagementForm(forms.ModelForm):
    class Meta:
        model = UserProfile
        fields = ['is_active', 'is_staff', 'is_verified', 'is_approved', 'is_blocked']
        widgets = {
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'is_staff': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'is_verified': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'is_approved': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            'is_blocked': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }

class AdSettingsForm(forms.ModelForm):
    class Meta:
        model = AdSettings
        fields = ['name', 'ad_code', 'location', 'is_active']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control'}),
            'ad_code': forms.Textarea(attrs={
                'class': 'form-control',
                'rows': 5,
                'placeholder': 'Paste your ad code here (e.g., Google AdSense code)'
            }),
            'location': forms.Select(attrs={'class': 'form-select'}),
            'is_active': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
        }
