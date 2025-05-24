from django.contrib.auth.mixins import UserPassesTestMixin
from django.core.exceptions import PermissionDenied
from .views.activity_log import log_activity

class StaffRequiredMixin(UserPassesTestMixin):
    def test_func(self):
        if self.request.user.is_authenticated and self.request.user.is_staff:
            return True
        return False

    def handle_no_permission(self):
        raise PermissionDenied

class ActivityLogMixin:
    def form_valid(self, form):
        response = super().form_valid(form)
        if hasattr(self, 'object'):
            action = 'Created' if self.object._state.adding else 'Updated'
            model_name = self.object._meta.verbose_name.title()
            details = f"{action} {model_name}: {str(self.object)}"
            
            log_activity(
                user=self.request.user,
                action=f"{action} {model_name}",
                details=details,
                request=self.request
            )
        return response

    def delete(self, request, *args, **kwargs):
        obj = self.get_object()
        model_name = obj._meta.verbose_name.title()
        details = f"Deleted {model_name}: {str(obj)}"
        
        response = super().delete(request, *args, **kwargs)
        
        log_activity(
            user=request.user,
            action=f"Deleted {model_name}",
            details=details,
            request=request
        )
        return response 