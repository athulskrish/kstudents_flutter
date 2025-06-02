# Kerala Tech Reach - Django Project Documentation
changes in the Backend should be updated here.
## Project Overview

This is a Django-based web application for Kerala Tech Reach, a platform that provides educational resources, news, events, and other services for students. The application consists of multiple modules including an admin dashboard, API endpoints, and public-facing pages.

## Tech Stack

- **Backend Framework**: Django 
- **API Framework**: Django REST Framework
- **Authentication**: JWT (JSON Web Tokens)
- **Database**: SQLite (development)
- **Frontend Integration**: CORS enabled for cross-origin requests
- **Security**: Multiple security middlewares implemented

## Project Structure

### Core Applications

1. **keralatechreach_django**: Main project configuration
2. **admindashboard**: Admin interface for content management
3. **api**: REST API endpoints for mobile/web clients
4. **publicpage**: Public-facing website pages

### Key Features

- User authentication and authorization
- Content management system
- REST API for mobile applications
- Educational resources (question papers, notes)
- Events and news publication
- Affiliate marketing integration
- File uploads and management
- Newsletter subscription

## Database Models

### Educational Resources

- **University**: Educational institutions
- **Degree**: Academic programs offered by universities
- **QuestionPaper**: Past examination papers
- **Note**: Study materials
- **Exam**: Upcoming examinations
- **EntranceNotification**: Notifications about entrance exams

### Content Management

- **News**: Articles and updates
- **Event**: Upcoming events with details
- **EventCategory**: Categories for events
- **Initiative**: Organization initiatives
- **Gallery**: Image gallery
- **Testimonial**: User testimonials
- **FAQ**: Frequently asked questions

### User Management

- **UserProfile**: Extended user information
- **District**: Geographic districts for user categorization
- **ActivityLog**: User activity tracking

### Marketing & Communication

- **AffiliateCategory**: Categories for affiliate products
- **AffiliateProduct**: Products for affiliate marketing
- **AffiliateSliderItem**: Slider items for affiliate section
- **AffiliateBudgetSelection**: Budget-based product recommendations
- **ContactMessage**: Messages from contact forms
- **NewsletterSubscriber**: Newsletter subscription management
- **AdSettings**: Advertisement placement and management

## API Endpoints

The API provides RESTful endpoints for:

- User authentication (login, registration)
- Educational resources (universities, degrees, question papers, notes)
- Content (news, events, exams, notifications)
- Affiliate marketing products
- Contact form submissions

All API endpoints follow REST conventions and most are read-only for public consumption, with protected endpoints for data modification.

## Security Features

- JWT-based authentication
- CSRF protection
- XSS prevention
- Content-Type sniffing protection
- HSTS implementation
- Secure cookies
- Session security (timeouts, HTTP-only cookies)
- Strong password validation

## Development Setup

### Requirements

Required packages are listed in requirements.txt and include:
- Django
- Django REST Framework
- Django REST Framework SimpleJWT
- Django CORS Headers
- Django Filter
- Pillow (for image processing)
- Channels (for WebSocket support)
- Django Jazzmin (for admin UI enhancements)

### Configuration

The project uses environment variables for sensitive configuration settings.

### Static Files

Static files are managed using WhiteNoise middleware, with static and media directories configured for file serving.

## Public Pages

The website offers several public-facing pages:
- Home page with featured content
- News listings and detail pages
- Events calendar and details
- Search functionality
- Contact form
- About and services pages

## Admin Dashboard

The admin dashboard provides an interface for content management with:
- User management
- Content creation and publication
- File uploads
- Analytics tracking
- Settings management

## Security Considerations

- Environment-specific security settings (development vs production)
- Rate limiting implementation
- User activity logging
- Secure file upload handling
- Authorization checks throughout the application

## Deployment Notes

For production deployment:
- Enable production security settings
- Configure a production-grade database
- Set up proper static file serving
- Implement HTTPS
- Configure proper hosting environment

## Future Development

Potential areas for enhancement:
- Advanced analytics integration
- Enhanced mobile API features
- More educational resource types
- Improved search functionality
- Social media integration 


I've successfully implemented a Notes option in the admin dashboard's sidebar, positioned right after the Questions option. The implementation includes:
Added note-related view functions (note_list, note_create, note_edit, note_delete) in admindashboard/views/academic.py
Added the NoteForm class in admindashboard/forms.py
Added the note-related URL routes in admindashboard/urls.py
Added the Notes link in the sidebar navigation in base.html
Created the following templates:
note_list.html: Main page for viewing all notes
note_form.html: Form for adding and editing notes
note_table.html: Partial template for rendering the notes table
These changes allow administrators to:
View a list of all notes
Add new notes
Edit existing notes
Delete notes
Download note files
The notes feature follows the same pattern as the existing question papers feature, maintaining consistency in the UI and functionality.


Fixed the EventForm to include proper widget definitions for district and category fields.
Added views for EventCategory management (list, create, edit, delete).
Added URL patterns for EventCategory management.
Created templates for EventCategory (list, form, delete).
Updated the event form template to add quick links to manage categories and districts.
Added EventCategory to the sidebar menu in base.html.
Created a management command to load sample data for districts and event categories.
Now users can:
View existing event categories and districts
Create new event categories and districts
Edit existing event categories and districts
Delete event categories and districts



Updated the form template to:
Clearly label the fields as requiring both date and time
Add format guidance text (YYYY-MM-DD HH:MM)
Add custom CSS styling for the datetime inputs
Include an error alert at the top of the form
Ensure proper z-index for the datetime picker calendar
Enhanced the EventForm class with:
Validation for event_start and event_end fields
Logic to ensure the end time is after the start time
Improved the flatpickr datetime picker configuration:
Added minute increments of 15 minutes for easier selection
Enabled manual input to allow typing dates
Added proper handling of the "is-filled" class for styling
Added the flatpickr CSS directly in the template
Updated the views to:
Print form errors for debugging
Provide proper context for rendering the form

## Ad Slider Implementation

I've implemented an Ad Slider management system in the admin dashboard to control the banner advertisements displayed in the mobile app. The implementation includes:

### Database Model
Added a new model `AdSlider` in `admindashboard/models.py`:
```python
class AdSlider(models.Model):
    title = models.CharField(max_length=100)
    description = models.CharField(max_length=255, blank=True, null=True)
    image = models.ImageField(upload_to='ad_sliders/')
    link_url = models.URLField(blank=True, null=True)
    background_color = models.CharField(max_length=7, default="#2563EB", help_text="Color in hex format, e.g. #2563EB")
    text_color = models.CharField(max_length=7, default="#FFFFFF", help_text="Color in hex format, e.g. #FFFFFF")
    is_active = models.BooleanField(default=True)
    position = models.PositiveIntegerField(default=0, help_text="Order in which the slider appears")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    class Meta:
        ordering = ['position']
        verbose_name = 'Ad Slider'
        verbose_name_plural = 'Ad Sliders'
    
    def __str__(self):
        return self.title
```

### Form Implementation
Added a form for creating and editing ad sliders in `admindashboard/forms.py`:
```python
class AdSliderForm(forms.ModelForm):
    class Meta:
        model = AdSlider
        fields = ['title', 'description', 'image', 'link_url', 'background_color', 'text_color', 'is_active', 'position']
        widgets = {
            'background_color': forms.TextInput(attrs={'type': 'color'}),
            'text_color': forms.TextInput(attrs={'type': 'color'}),
        }
```

### Views Implementation
Added view functions for ad slider management in `admindashboard/views/marketing.py`:
```python
@login_required
def ad_slider_list(request):
    ad_sliders = AdSlider.objects.all()
    return render(request, 'admindashboard/ad_slider_list.html', {'ad_sliders': ad_sliders})

@login_required
def ad_slider_create(request):
    if request.method == 'POST':
        form = AdSliderForm(request.POST, request.FILES)
        if form.is_valid():
            form.save()
            messages.success(request, 'Ad slider created successfully!')
            return redirect('admin:ad_slider_list')
    else:
        form = AdSliderForm()
    
    return render(request, 'admindashboard/ad_slider_form.html', {'form': form, 'title': 'Create Ad Slider'})

@login_required
def ad_slider_edit(request, slider_id):
    ad_slider = get_object_or_404(AdSlider, id=slider_id)
    
    if request.method == 'POST':
        form = AdSliderForm(request.POST, request.FILES, instance=ad_slider)
        if form.is_valid():
            form.save()
            messages.success(request, 'Ad slider updated successfully!')
            return redirect('admin:ad_slider_list')
    else:
        form = AdSliderForm(instance=ad_slider)
    
    return render(request, 'admindashboard/ad_slider_form.html', {'form': form, 'title': 'Edit Ad Slider'})

@login_required
def ad_slider_delete(request, slider_id):
    ad_slider = get_object_or_404(AdSlider, id=slider_id)
    
    if request.method == 'POST':
        ad_slider.delete()
        messages.success(request, 'Ad slider deleted successfully!')
        return redirect('admin:ad_slider_list')
    
    return render(request, 'admindashboard/ad_slider_delete.html', {'ad_slider': ad_slider})
```

### URL Patterns
Added URL patterns in `admindashboard/urls.py`:
```python
# Ad Slider URLs
path('marketing/ad-sliders/', views.marketing.ad_slider_list, name='ad_slider_list'),
path('marketing/ad-sliders/create/', views.marketing.ad_slider_create, name='ad_slider_create'),
path('marketing/ad-sliders/<int:slider_id>/edit/', views.marketing.ad_slider_edit, name='ad_slider_edit'),
path('marketing/ad-sliders/<int:slider_id>/delete/', views.marketing.ad_slider_delete, name='ad_slider_delete'),
```

### Templates
Created the following templates:
- `ad_slider_list.html`: Main page for viewing all ad sliders
- `ad_slider_form.html`: Form for adding and editing ad sliders
- `ad_slider_delete.html`: Confirmation page for deleting ad sliders

### API Endpoint
Added an API endpoint in `api/views.py` to serve ad sliders to the mobile app:
```python
class AdSliderViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AdSlider.objects.filter(is_active=True)
    serializer_class = AdSliderSerializer
    permission_classes = [permissions.AllowAny]
```

And the corresponding serializer in `api/serializers.py`:
```python
class AdSliderSerializer(serializers.ModelSerializer):
    class Meta:
        model = AdSlider
        fields = ['id', 'title', 'description', 'image', 'link_url', 'background_color', 'text_color', 'position']
```

### Navigation
Added the Ad Sliders link in the sidebar navigation under the Marketing section in `base.html`.

These changes allow administrators to:
- View a list of all ad sliders
- Add new ad sliders with images, colors, and links
- Edit existing ad sliders
- Delete ad sliders
- Control the order of sliders through the position field
- Toggle sliders on/off using the is_active field

The mobile app can fetch active ad sliders through the API endpoint and display them in the home screen slider.