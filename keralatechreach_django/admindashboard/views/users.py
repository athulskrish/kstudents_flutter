from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.contrib.auth import get_user_model, logout
from django.contrib.auth.models import User
from django.contrib.auth.mixins import LoginRequiredMixin
from django.views.generic import ListView, CreateView, UpdateView, DeleteView
from django.urls import reverse_lazy
from django.db import transaction
from ..models import UserProfile
from ..forms import (
    CustomUserCreationForm, CustomUserChangeForm,
    UserProfileForm, UserProfileUpdateForm, UserManagementForm
)
from ..mixins import StaffRequiredMixin
from ..decorators import staff_required
from .activity_log import log_activity

def register(request):
    if request.method == 'POST':
        form = CustomUserCreationForm(request.POST)
        if form.is_valid():
            with transaction.atomic():
                user = form.save()
                # Create associated profile
                UserProfile.objects.create(
                    user=user,
                    email=form.cleaned_data['email']
                )
                log_activity(
                    user=request.user if request.user.is_authenticated else user,
                    action="User registration",
                    details=f"New user registered: {user.username}",
                    request=request
                )
                messages.success(request, 'Registration successful. You can now login.')
                return redirect('admindashboard:login')
    else:
        form = CustomUserCreationForm()
    return render(request, 'admindashboard/register.html', {'form': form})

@login_required
def profile(request):
    if request.method == 'POST':
        form = UserProfileForm(request.POST, request.FILES, instance=request.user.userprofile)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated profile",
                details="Updated user profile information",
                request=request
            )
            messages.success(request, 'Your profile has been updated.')
            return redirect('admindashboard:profile')
    else:
        form = UserProfileForm(instance=request.user.userprofile)
    return render(request, 'admindashboard/profile.html', {'form': form})

@login_required
@staff_required
def user_list(request):
    users = User.objects.all().order_by('-date_joined')
    return render(request, 'admindashboard/users/list.html', {'users': users})

@login_required
@staff_required
def user_detail(request, pk):
    user = get_object_or_404(User, pk=pk)
    if request.method == 'POST':
        form = UserManagementForm(request.POST, instance=user)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated user",
                details=f"Updated user details for: {user.username}",
                request=request
            )
            messages.success(request, 'User updated successfully.')
            return redirect('admindashboard:user_list')
    else:
        form = UserManagementForm(instance=user)
    return render(request, 'admindashboard/users/detail.html', {'form': form, 'user_obj': user})

@login_required
@staff_required
def user_delete(request, pk):
    user = get_object_or_404(User, pk=pk)
    if request.method == 'POST':
        username = user.username
        user.delete()
        log_activity(
            user=request.user,
            action="Deleted user",
            details=f"Deleted user: {username}",
            request=request
        )
        messages.success(request, 'User deleted successfully.')
        return redirect('admindashboard:user_list')
    return render(request, 'admindashboard/users/delete.html', {'user': user})

class UserListView(LoginRequiredMixin, StaffRequiredMixin, ListView):
    model = User
    template_name = 'admindashboard/user/list.html'
    context_object_name = 'users'
    paginate_by = 10

    def get_queryset(self):
        return User.objects.all().order_by('-date_joined')

class UserCreateView(LoginRequiredMixin, StaffRequiredMixin, CreateView):
    model = User
    template_name = 'admindashboard/user/form.html'
    form_class = CustomUserCreationForm
    success_url = reverse_lazy('admindashboard:user_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = 'Add New User'
        context['button_text'] = 'Create User'
        return context

    def form_valid(self, form):
        messages.success(self.request, 'User created successfully.')
        return super().form_valid(form)

class UserUpdateView(LoginRequiredMixin, StaffRequiredMixin, UpdateView):
    model = User
    template_name = 'admindashboard/user/form.html'
    form_class = CustomUserChangeForm
    success_url = reverse_lazy('admindashboard:user_list')

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        context['title'] = 'Edit User'
        context['button_text'] = 'Update User'
        return context

    def form_valid(self, form):
        messages.success(self.request, 'User updated successfully.')
        return super().form_valid(form)

class UserDeleteView(LoginRequiredMixin, StaffRequiredMixin, DeleteView):
    model = User
    template_name = 'admindashboard/user/delete.html'
    success_url = reverse_lazy('admindashboard:user_list')

    def delete(self, request, *args, **kwargs):
        messages.success(self.request, 'User deleted successfully.')
        return super().delete(request, *args, **kwargs)

def custom_logout(request):
    if request.user.is_authenticated:
        log_activity(
            user=request.user,
            action="User logout",
            details=f"User logged out: {request.user.username}",
            request=request
        )
        logout(request)
    return redirect('admindashboard:login') 