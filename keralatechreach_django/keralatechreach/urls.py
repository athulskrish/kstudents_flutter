from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static
from django.urls import path, include
from django.contrib.auth import views as auth_views
from django.views.generic import RedirectView

urlpatterns = [
    # Django default admin
    path('admin/', admin.site.urls),
    
    # Admin Dashboard URLs
    path('admindashboard/', include('admindashboard.urls')),
    path('', include('publicpage.urls')),  # Landing page for non-logged-in users
    path('api/', include('api.urls')),

    # Redirect root to admin dashboard login
    # path('', RedirectView.as_view(url='/admindashboard/login/', permanent=False), name='root'),
]

# Serve media and static files during development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)