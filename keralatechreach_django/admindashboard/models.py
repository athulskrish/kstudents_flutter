# api/models.py

from django.db import models
from django.db.models.signals import post_save
from django.dispatch import receiver
from django.contrib.auth.models import User
from django.utils import timezone
from django.utils.text import slugify

class QuestionPaper(models.Model):
    degree = models.ForeignKey('Degree', on_delete=models.CASCADE)
    semester = models.PositiveIntegerField()
    subject = models.CharField(max_length=200)
    file_path = models.FileField(upload_to='question_papers/', blank=True, null=True)
    year = models.PositiveIntegerField()
    university_id = models.ForeignKey('University', on_delete=models.CASCADE)
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    def __str__(self):
        return f"{self.degree} | Sem {self.semester} | {self.subject} ({self.year})"
    
class University(models.Model):
    name = models.CharField(max_length=200)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    def __str__(self):
        return self.name

class Degree(models.Model):
    name = models.CharField(max_length=200)
    university = models.ForeignKey(University, on_delete=models.CASCADE)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    def __str__(self):
        return f"{self.name} ({self.university.name})"

class Exam(models.Model):
    exam_name = models.CharField(max_length=255)
    exam_date = models.DateField()
    exam_url = models.URLField()
    degree_name = models.ForeignKey(Degree, on_delete=models.CASCADE)
    semester = models.CharField(max_length=10)
    admission_year = models.PositiveIntegerField()
    university = models.ForeignKey(University, on_delete=models.CASCADE)
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)


class Job(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField()
    last_date = models.DateField()
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    def __str__(self):
        return self.title

class District(models.Model):
    name = models.CharField(max_length=100)
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE, related_name='created_districts')
    def __str__(self):
        return self.name


class Initiative(models.Model):
    name = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    link = models.URLField(blank=True, null=True)
    photo = models.ImageField(upload_to='initiatives/', blank=True, null=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    def __str__(self):
        return self.name

class EventCategory(models.Model):
    category = models.CharField(max_length=255)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    def __str__(self):
        return self.category

class Event(models.Model):
    name = models.CharField(max_length=255)
    event_start = models.DateTimeField()
    event_end = models.DateTimeField(blank=True, null=True)
    place = models.CharField(max_length=255)
    link = models.URLField(blank=True, null=True)
    description = models.TextField(blank=True, null=True)
    map_link = models.URLField(blank=True, null=True)
    district = models.ForeignKey(District, on_delete=models.SET_NULL, null=True, blank=True)
    category = models.ForeignKey(EventCategory, on_delete=models.SET_NULL, null=True, blank=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    def __str__(self):
        return self.name

class News(models.Model):
    title = models.CharField(max_length=255)
    slug = models.SlugField(unique=True, max_length=255, blank=True, null=True)
    content = models.TextField()
    excerpt = models.TextField(blank=True, help_text="A short summary of the article")
    image = models.ImageField(upload_to='news/', blank=True, null=True)
    thumbnail = models.ImageField(upload_to='news/thumbnails/', blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    is_published = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    
    # SEO Fields
    meta_title = models.CharField(max_length=60, blank=True, help_text="SEO optimized title (max 60 characters)")
    meta_description = models.CharField(max_length=160, blank=True, help_text="SEO meta description (max 160 characters)")
    keywords = models.CharField(max_length=255, blank=True, help_text="Comma-separated keywords for SEO")
    
    # Additional Fields
    reading_time = models.PositiveIntegerField(default=0, help_text="Estimated reading time in minutes")
    views_count = models.PositiveIntegerField(default=0)
    likes_count = models.PositiveIntegerField(default=0)
    
    class Meta:
        verbose_name_plural = 'News'
        ordering = ['-created_at']
    
    def __str__(self):
        return self.title
    
    def save(self, *args, **kwargs):
        # Generate slug if not provided
        if not self.slug:
            base_slug = slugify(self.title)
            slug = base_slug
            counter = 1
            # Check if slug exists and generate a unique one
            while News.objects.filter(slug=slug).exclude(pk=self.pk).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1
            self.slug = slug
        
        # Calculate reading time
        words = len(self.content.split())
        self.reading_time = max(1, int(words / 200))  # Assuming 200 words per minute reading speed
        
        # Set meta title and description if not provided
        if not self.meta_title:
            self.meta_title = self.title[:60]
        if not self.meta_description and self.excerpt:
            self.meta_description = self.excerpt[:160]
        elif not self.meta_description:
            self.meta_description = self.content[:160]
            
        super().save(*args, **kwargs)

class ContactMessage(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField()
    subject = models.CharField(max_length=200)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.subject} - {self.name}"

class Gallery(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    image = models.ImageField(upload_to='gallery/')
    created_at = models.DateTimeField(auto_now_add=True)
    is_visible = models.BooleanField(default=True)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    class Meta:
        verbose_name_plural = "Galleries"

    def __str__(self):
        return self.title

class SiteSetting(models.Model):
    key = models.CharField(max_length=50, unique=True)
    value = models.TextField()
    description = models.TextField(blank=True)
    is_public = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    def __str__(self):
        return self.key

class UserProfile(models.Model):
    user = models.OneToOneField('auth.User', on_delete=models.CASCADE)
    phone = models.CharField(max_length=15, blank=True, null=True)
    district = models.ForeignKey(District, on_delete=models.SET_NULL, null=True, blank=True)
    profile_picture = models.ImageField(upload_to='profiles/', blank=True, null=True)
    bio = models.TextField(blank=True)
    email = models.EmailField()
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey('self', on_delete=models.CASCADE, null=True, blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    is_superuser = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)
    is_approved = models.BooleanField(default=False)
    is_blocked = models.BooleanField(default=False)
    is_deleted = models.BooleanField(default=False)
    
    def __str__(self):
        return self.user.username

# Signal to create UserProfile automatically when User is created
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(
            user=instance,
            email=instance.email,
            is_staff=instance.is_staff,
            is_superuser=instance.is_superuser,
            is_active=instance.is_active
        )

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    if hasattr(instance, 'userprofile'):
        instance.userprofile.save()

class ActivityLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    action = models.CharField(max_length=255)
    details = models.TextField(blank=True, null=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    timestamp = models.DateTimeField(default=timezone.now)
    
    class Meta:
        ordering = ['-timestamp']
        
    def __str__(self):
        return f"{self.user.username} - {self.action} - {self.timestamp}"

class Note(models.Model):
    title = models.CharField(max_length=255)
    subject = models.CharField(max_length=255)
    degree = models.ForeignKey('Degree', on_delete=models.CASCADE)
    semester = models.PositiveIntegerField()
    year = models.PositiveIntegerField()
    university = models.ForeignKey('University', on_delete=models.CASCADE)
    file = models.FileField(upload_to='notes/')
    uploaded_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)
    uploaded_at = models.DateTimeField(auto_now_add=True)
    is_published = models.BooleanField(default=False)

    def __str__(self):
        return f"Note: {self.title} ({self.university} - {self.degree} Sem {self.semester})"

class EntranceNotification(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    deadline = models.DateField()
    link = models.URLField(blank=True, null=True)
    published_date = models.DateField(default=timezone.now)
    is_published = models.BooleanField(default=False)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    def __str__(self):
        return self.title

# Affiliate Marketing Models
class AffiliateCategory(models.Model):
    name = models.CharField(max_length=255)
    image_url = models.URLField(blank=True, null=True)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    def __str__(self):
        return self.name

class AffiliateBudgetSelection(models.Model):
    title = models.CharField(max_length=255)
    category = models.ForeignKey(AffiliateCategory, on_delete=models.CASCADE)
    budget_limit = models.DecimalField(max_digits=10, decimal_places=2)
    image_url = models.URLField(blank=True, null=True)
    display_order = models.PositiveIntegerField(default=0)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    def __str__(self):
        return f"{self.title} ({self.category.name})"

class AffiliateSliderItem(models.Model):
    image_url = models.URLField()
    redirect_url = models.URLField(blank=True, null=True)
    display_order = models.PositiveIntegerField(default=0)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    def __str__(self):
        return f"Slider Item {self.display_order}"

class AffiliateProduct(models.Model):
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True, null=True)
    category = models.ForeignKey(AffiliateCategory, on_delete=models.CASCADE)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    image_url = models.URLField(blank=True, null=True)
    affiliate_url = models.URLField()
    affiliate_code = models.CharField(max_length=255, blank=True, null=True)
    rating = models.DecimalField(max_digits=3, decimal_places=2, blank=True, null=True)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    def __str__(self):
        return self.title

class Testimonial(models.Model):
    author_name = models.CharField(max_length=100)
    author_designation = models.CharField(max_length=100, blank=True, null=True)
    testimonial_text = models.TextField()
    is_approved = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Testimonial by {self.author_name}"

    class Meta:
        ordering = ['-created_at']

class FAQ(models.Model):
    question = models.CharField(max_length=255)
    answer = models.TextField()
    is_published = models.BooleanField(default=False)
    display_order = models.PositiveIntegerField(default=0)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.question

    class Meta:
        ordering = ['display_order', 'created_at']

class ContactUs(models.Model):
    name = models.CharField(max_length=100)
    email = models.EmailField()
    subject = models.CharField(max_length=200)
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    is_read = models.BooleanField(default=False)

    class Meta:
        verbose_name = 'Contact Message'
        verbose_name_plural = 'Contact Messages'
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.name} - {self.subject}"

class AdSettings(models.Model):
    name = models.CharField(max_length=100)
    ad_code = models.TextField(help_text="Paste your third-party ad code here (e.g., Google AdSense)")
    location = models.CharField(max_length=50, choices=[
        ('above_content', 'Above Content'),
        ('below_content', 'Below Content'),
        ('sidebar_top', 'Sidebar Top'),
        ('sidebar_bottom', 'Sidebar Bottom'),
        ('between_content', 'Between Content')
    ])
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey('UserProfile', on_delete=models.CASCADE)

    class Meta:
        verbose_name = 'Ad Setting'
        verbose_name_plural = 'Ad Settings'
        ordering = ['location', '-created_at']

    def __str__(self):
        return f"{self.name} ({self.get_location_display()})"