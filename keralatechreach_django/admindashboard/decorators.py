from django.contrib.auth.decorators import user_passes_test
from django.shortcuts import redirect
from django.contrib import messages
from functools import wraps

def staff_required(view_func):
    @wraps(view_func)
    def _wrapped_view(request, *args, **kwargs):
        if not request.user.is_authenticated:
            return redirect('admindashboard:login')
        if not request.user.is_staff:
            messages.error(request, 'You do not have permission to access this page. Staff access required.')
            return redirect('admindashboard:dashboard')
        return view_func(request, *args, **kwargs)
    return _wrapped_view 