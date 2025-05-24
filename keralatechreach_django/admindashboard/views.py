from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from .models import (
    QuestionPaper, University, Degree, Exam, Job, District,
    Initiative, EventCategory, Event, News, ContactMessage,
    Gallery, SiteSetting, UserProfile, ActivityLog
)
from .forms import (
    QuestionPaperForm, UniversityForm, DegreeForm, ExamForm, JobForm,
    DistrictForm, InitiativeForm, EventCategoryForm, EventForm, NewsForm,
    ContactMessageForm, GalleryForm, SiteSettingForm, UserProfileForm,
    UserRegistrationForm, UserProfileUpdateForm, UserManagementForm
)
from django.contrib.auth import login, authenticate
from django.contrib.auth.models import User
from django.db import transaction
from django.contrib.auth.mixins import LoginRequiredMixin, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from django.core.paginator import Paginator
from .views.activity_log import log_activity
from .mixins import StaffRequiredMixin, ActivityLogMixin

@login_required
def dashboard(request):
    context = {
        'question_count': QuestionPaper.objects.count(),
        'exam_count': Exam.objects.count(),
        'job_count': Job.objects.count(),
        'event_count': Event.objects.count(),
        'news_count': News.objects.count(),
        'unread_messages': ContactMessage.objects.filter(is_read=False).count(),
    }
    return render(request, 'admindashboard/dashboard.html', context)

# QuestionPaper Views
@login_required
def question_list(request):
    questions = QuestionPaper.objects.all().order_by('-updated_at')
    return render(request, 'admindashboard/question_list.html', {'questions': questions})

@login_required
def question_create(request):
    if request.method == 'POST':
        form = QuestionPaperForm(request.POST, request.FILES)
        if form.is_valid():
            question = form.save(commit=False)
            question.created_by = request.user.userprofile
            question.save()
            log_activity(
                user=request.user,
                action="Created question paper",
                details=f"Created question paper for {question.subject} - {question.degree}",
                request=request
            )
            messages.success(request, 'Question paper created successfully.')
            return redirect('question_list')
    else:
        form = QuestionPaperForm()
    return render(request, 'admindashboard/question_form.html', {'form': form})

@login_required
def question_edit(request, pk):
    question = get_object_or_404(QuestionPaper, pk=pk)
    if request.method == 'POST':
        form = QuestionPaperForm(request.POST, request.FILES, instance=question)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated question paper",
                details=f"Updated question paper for {question.subject} - {question.degree}",
                request=request
            )
            messages.success(request, 'Question paper updated successfully.')
            return redirect('question_list')
    else:
        form = QuestionPaperForm(instance=question)
    return render(request, 'admindashboard/question_form.html', {'form': form})

@login_required
def question_delete(request, pk):
    question = get_object_or_404(QuestionPaper, pk=pk)
    details = f"Deleted question paper for {question.subject} - {question.degree}"
    question.delete()
    log_activity(
        user=request.user,
        action="Deleted question paper",
        details=details,
        request=request
    )
    messages.success(request, 'Question paper deleted successfully.')
    return redirect('question_list')

# Event Views
@login_required
def event_list(request):
    events = Event.objects.all().order_by('-event_start')
    return render(request, 'admindashboard/event_list.html', {'events': events})

@login_required
def event_create(request):
    if request.method == 'POST':
        form = EventForm(request.POST)
        if form.is_valid():
            event = form.save(commit=False)
            event.created_by = request.user.userprofile
            event.save()
            log_activity(
                user=request.user,
                action="Created event",
                details=f"Created event: {event.name}",
                request=request
            )
            messages.success(request, 'Event created successfully.')
            return redirect('event_list')
    else:
        form = EventForm()
    return render(request, 'admindashboard/event_form.html', {'form': form})

@login_required
def event_edit(request, pk):
    event = get_object_or_404(Event, pk=pk)
    if request.method == 'POST':
        form = EventForm(request.POST, instance=event)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated event",
                details=f"Updated event: {event.name}",
                request=request
            )
            messages.success(request, 'Event updated successfully.')
            return redirect('event_list')
    else:
        form = EventForm(instance=event)
    return render(request, 'admindashboard/event_form.html', {'form': form})

@login_required
def event_delete(request, pk):
    event = get_object_or_404(Event, pk=pk)
    details = f"Deleted event: {event.name}"
    event.delete()
    log_activity(
        user=request.user,
        action="Deleted event",
        details=details,
        request=request
    )
    messages.success(request, 'Event deleted successfully.')
    return redirect('event_list')

# News Views
@login_required
def news_list(request):
    news_items = News.objects.all().order_by('-created_at')
    return render(request, 'admindashboard/news_list.html', {'news_items': news_items})

@login_required
def news_create(request):
    if request.method == 'POST':
        form = NewsForm(request.POST, request.FILES)
        if form.is_valid():
            news = form.save(commit=False)
            news.created_by = request.user.userprofile
            news.save()
            log_activity(
                user=request.user,
                action="Created news article",
                details=f"Created news article: {news.title}",
                request=request
            )
            messages.success(request, 'News created successfully.')
            return redirect('news_list')
    else:
        form = NewsForm()
    return render(request, 'admindashboard/news_form.html', {'form': form})

@login_required
def news_edit(request, pk):
    news = get_object_or_404(News, pk=pk)
    if request.method == 'POST':
        form = NewsForm(request.POST, request.FILES, instance=news)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated news article",
                details=f"Updated news article: {news.title}",
                request=request
            )
            messages.success(request, 'News updated successfully.')
            return redirect('news_list')
    else:
        form = NewsForm(instance=news)
    return render(request, 'admindashboard/news_form.html', {'form': form})

@login_required
def news_delete(request, pk):
    news = get_object_or_404(News, pk=pk)
    details = f"Deleted news article: {news.title}"
    news.delete()
    log_activity(
        user=request.user,
        action="Deleted news article",
        details=details,
        request=request
    )
    messages.success(request, 'News deleted successfully.')
    return redirect('news_list')

# Job Views
@login_required
def job_list(request):
    jobs = Job.objects.all().order_by('-updated_at')
    return render(request, 'admindashboard/job_list.html', {'jobs': jobs})

@login_required
def job_create(request):
    if request.method == 'POST':
        form = JobForm(request.POST)
        if form.is_valid():
            job = form.save(commit=False)
            job.created_by = request.user.userprofile
            job.save()
            log_activity(
                user=request.user,
                action="Created job posting",
                details=f"Created job posting: {job.title}",
                request=request
            )
            messages.success(request, 'Job created successfully.')
            return redirect('job_list')
    else:
        form = JobForm()
    return render(request, 'admindashboard/job_form.html', {'form': form})

@login_required
def job_edit(request, pk):
    job = get_object_or_404(Job, pk=pk)
    if request.method == 'POST':
        form = JobForm(request.POST, instance=job)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated job posting",
                details=f"Updated job posting: {job.title}",
                request=request
            )
            messages.success(request, 'Job updated successfully.')
            return redirect('job_list')
    else:
        form = JobForm(instance=job)
    return render(request, 'admindashboard/job_form.html', {'form': form})

@login_required
def job_delete(request, pk):
    job = get_object_or_404(Job, pk=pk)
    details = f"Deleted job posting: {job.title}"
    job.delete()
    log_activity(
        user=request.user,
        action="Deleted job posting",
        details=details,
        request=request
    )
    messages.success(request, 'Job deleted successfully.')
    return redirect('job_list')

# Contact Message Views
@login_required
def contact_list(request):
    messages = ContactMessage.objects.all().order_by('-created_at')
    return render(request, 'admindashboard/contact_list.html', {'messages': messages})

@login_required
def contact_detail(request, pk):
    message = get_object_or_404(ContactMessage, pk=pk)
    if not message.is_read:
        message.is_read = True
        message.save()
    return render(request, 'admindashboard/contact_detail.html', {'message': message})

@login_required
def contact_delete(request, pk):
    message = get_object_or_404(ContactMessage, pk=pk)
    message.delete()
    messages.success(request, 'Message deleted successfully.')
    return redirect('contact_list')

# Gallery Views
@login_required
def gallery_list(request):
    gallery_items = Gallery.objects.all().order_by('-created_at')
    return render(request, 'admindashboard/gallery_list.html', {'gallery_items': gallery_items})

@login_required
def gallery_create(request):
    if request.method == 'POST':
        form = GalleryForm(request.POST, request.FILES)
        if form.is_valid():
            gallery = form.save(commit=False)
            gallery.created_by = request.user.userprofile
            gallery.save()
            log_activity(
                user=request.user,
                action="Created gallery item",
                details=f"Created gallery item: {gallery.title}",
                request=request
            )
            messages.success(request, 'Gallery item created successfully.')
            return redirect('gallery_list')
    else:
        form = GalleryForm()
    return render(request, 'admindashboard/gallery_form.html', {'form': form})

@login_required
def gallery_edit(request, pk):
    gallery = get_object_or_404(Gallery, pk=pk)
    if request.method == 'POST':
        form = GalleryForm(request.POST, request.FILES, instance=gallery)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated gallery item",
                details=f"Updated gallery item: {gallery.title}",
                request=request
            )
            messages.success(request, 'Gallery item updated successfully.')
            return redirect('gallery_list')
    else:
        form = GalleryForm(instance=gallery)
    return render(request, 'admindashboard/gallery_form.html', {'form': form})

@login_required
def gallery_delete(request, pk):
    gallery = get_object_or_404(Gallery, pk=pk)
    details = f"Deleted gallery item: {gallery.title}"
    gallery.delete()
    log_activity(
        user=request.user,
        action="Deleted gallery item",
        details=details,
        request=request
    )
    messages.success(request, 'Gallery item deleted successfully.')
    return redirect('gallery_list')

def register(request):
    if request.method == 'POST':
        form = UserRegistrationForm(request.POST)
        if form.is_valid():
            with transaction.atomic():
                user = form.save()
                # Create UserProfile
                UserProfile.objects.create(
                    user=user,
                    email=form.cleaned_data['email'],
                    created_by=request.user.userprofile if request.user.is_authenticated else None
                )
                log_activity(
                    user=user,
                    action="User registration",
                    details=f"New user registered: {user.username}",
                    request=request
                )
                messages.success(request, 'Registration successful. Please log in.')
                return redirect('admindashboard:login')
    else:
        form = UserRegistrationForm()
    return render(request, 'admindashboard/register.html', {'form': form})

@login_required
def profile(request):
    if request.method == 'POST':
        user_form = UserProfileUpdateForm(request.POST, instance=request.user)
        profile_form = UserProfileForm(request.POST, request.FILES, instance=request.user.userprofile)
        if user_form.is_valid() and profile_form.is_valid():
            user_form.save()
            profile_form.save()
            log_activity(
                user=request.user,
                action="Profile update",
                details="Updated user profile information",
                request=request
            )
            messages.success(request, 'Your profile has been updated successfully.')
            return redirect('admindashboard:profile')
    else:
        user_form = UserProfileUpdateForm(instance=request.user)
        profile_form = UserProfileForm(instance=request.user.userprofile)
    
    context = {
        'user_form': user_form,
        'profile_form': profile_form
    }
    return render(request, 'admindashboard/profile.html', context)

@login_required
def user_list(request):
    if not request.user.is_staff:
        messages.error(request, 'You do not have permission to access this page.')
        return redirect('admindashboard:dashboard')
    
    users = UserProfile.objects.select_related('user').all().order_by('-created_at')
    return render(request, 'admindashboard/user_list.html', {'users': users})

@login_required
def user_detail(request, pk):
    if not request.user.is_staff:
        messages.error(request, 'You do not have permission to access this page.')
        return redirect('admindashboard:dashboard')
    
    user_profile = get_object_or_404(UserProfile, pk=pk)
    if request.method == 'POST':
        form = UserManagementForm(request.POST, instance=user_profile)
        if form.is_valid():
            form.save()
            messages.success(request, f'User {user_profile.user.username} has been updated successfully.')
            return redirect('admindashboard:user_list')
    else:
        form = UserManagementForm(instance=user_profile)
    
    context = {
        'user_profile': user_profile,
        'form': form
    }
    return render(request, 'admindashboard/user_detail.html', context)

@login_required
def user_delete(request, pk):
    if not request.user.is_staff:
        messages.error(request, 'You do not have permission to access this page.')
        return redirect('admindashboard:dashboard')
    
    user_profile = get_object_or_404(UserProfile, pk=pk)
    user = user_profile.user
    details = f"Deleted user: {user.username}"
    
    if request.method == 'POST':
        log_activity(
            user=request.user,
            action="User deletion",
            details=details,
            request=request
        )
        user.delete()  # This will also delete the associated UserProfile due to CASCADE
        messages.success(request, f'User {user.username} has been deleted successfully.')
        return redirect('admindashboard:user_list')
    
    return render(request, 'admindashboard/user_confirm_delete.html', {'user_profile': user_profile})

@login_required
def tables(request):
    context = {
        'questions': QuestionPaper.objects.all().order_by('-updated_at')[:10],
        'events': Event.objects.all().order_by('-event_start')[:10],
        'jobs': Job.objects.all().order_by('-updated_at')[:10],
        'news': News.objects.all().order_by('-created_at')[:10],
        'users': UserProfile.objects.all().order_by('-created_at')[:10],
    }
    return render(request, 'admindashboard/tables.html', context)

class UserListView(LoginRequiredMixin, ListView):
    model = User
    template_name = 'admindashboard/user/list.html'
    context_object_name = 'users'
    paginate_by = 10

    def get_queryset(self):
        return User.objects.all().order_by('-date_joined')

class UserCreateView(LoginRequiredMixin, StaffRequiredMixin, ActivityLogMixin, CreateView):
    model = User
    template_name = 'admindashboard/user/form.html'
    form_class = UserCreationForm
    success_url = reverse_lazy('admindashboard:user_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = 'Add New User'
        context['button_text'] = 'Create User'
        return context

    def form_valid(self, form):
        messages.success(self.request, 'User created successfully.')
        return super().form_valid(form)

class UserUpdateView(LoginRequiredMixin, StaffRequiredMixin, ActivityLogMixin, UpdateView):
    model = User
    template_name = 'admindashboard/user/form.html'
    form_class = UserChangeForm
    success_url = reverse_lazy('admindashboard:user_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = 'Edit User'
        context['button_text'] = 'Update User'
        return context

    def form_valid(self, form):
        messages.success(self.request, 'User updated successfully.')
        return super().form_valid(form)

class UserDeleteView(LoginRequiredMixin, StaffRequiredMixin, ActivityLogMixin, DeleteView):
    model = User
    template_name = 'admindashboard/user/delete.html'
    success_url = reverse_lazy('admindashboard:user_list')

    def delete(self, request, *args, **kwargs):
        messages.success(self.request, 'User deleted successfully.')
        return super().delete(request, *args, **kwargs)

@login_required
def activity_log_view(request):
    if request.user.is_staff:
        # Staff can see all logs
        activities = ActivityLog.objects.all()
    else:
        # Regular users can only see their own logs
        activities = ActivityLog.objects.filter(user=request.user)
    
    paginator = Paginator(activities, 20)  # Show 20 activities per page
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)
    
    context = {
        'page_obj': page_obj,
        'title': 'Activity Log'
    }
    return render(request, 'admindashboard/activity_log.html', context)


