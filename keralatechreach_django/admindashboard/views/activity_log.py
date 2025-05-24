from django.contrib.auth.decorators import login_required
from django.core.paginator import Paginator
from django.shortcuts import render
from ..models import ActivityLog

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

def log_activity(user, action, details=None, request=None):
    """
    Helper function to log user activities
    """
    ip_address = None
    if request:
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip_address = x_forwarded_for.split(',')[0]
        else:
            ip_address = request.META.get('REMOTE_ADDR')
            
    ActivityLog.objects.create(
        user=user,
        action=action,
        details=details,
        ip_address=ip_address
    ) 