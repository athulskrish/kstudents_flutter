# Backend Implementation Instructions

## Overview
To complete the home screen implementation, we need to add the ability to mark exams as "featured on home" and create an API endpoint to fetch these featured exams.

## Tasks

### 1. Update Exam Model
Add a `show_on_home` boolean field to the Exam model:

```python
# In admindashboard/models.py
class Exam(models.Model):
    # ... existing fields ...
    show_on_home = models.BooleanField(default=False, help_text="Display this exam on the home page")
    # ... other fields ...
```

After adding this field, run migrations:
```bash
python manage.py makemigrations
python manage.py migrate
```

### 2. Update Exam Admin Form
Update the ExamForm in `admindashboard/forms.py` to include the new field:

```python
# In admindashboard/forms.py
class ExamForm(forms.ModelForm):
    class Meta:
        model = Exam
        fields = [
            'exam_name', 'exam_date', 'exam_url', 'degree_name', 
            'semester', 'admission_year', 'university', 'is_published', 'show_on_home'
        ]
        widgets = {
            'exam_date': forms.DateInput(attrs={'type': 'date'}),
            'show_on_home': forms.CheckboxInput(attrs={'class': 'form-check-input'}),
            # ... other widgets ...
        }
```

### 3. Update Exam Admin Template
Add the checkbox to the exam form template in `templates/admindashboard/exam_form.html`:

```html
<div class="card mb-4">
    <div class="card-header">
        <h5 class="card-title mb-0">Home Page Visibility</h5>
    </div>
    <div class="card-body">
        <div class="form-check mb-3">
            {{ form.show_on_home }}
            <label class="form-check-label" for="{{ form.show_on_home.id_for_label }}">
                Show on Home Page
            </label>
            <small class="form-text text-muted d-block">
                Check this to display this exam on the mobile app home page.
                Only a few selected exams will be shown on the home page.
            </small>
        </div>
    </div>
</div>
```

### 4. Update Exam List Template
Update the exam list template in `templates/admindashboard/exam_table.html` to show which exams are featured:

```html
<table class="table table-striped table-hover">
    <thead>
        <tr>
            <th>Exam Name</th>
            <th>Date</th>
            <th>University</th>
            <th>Published</th>
            <th>Featured</th>
            <th>Actions</th>
        </tr>
    </thead>
    <tbody>
        {% for exam in exams %}
        <tr>
            <td>{{ exam.exam_name }}</td>
            <td>{{ exam.exam_date|date:"M d, Y" }}</td>
            <td>{{ exam.university_name }}</td>
            <td>
                {% if exam.is_published %}
                <span class="badge bg-success">Yes</span>
                {% else %}
                <span class="badge bg-danger">No</span>
                {% endif %}
            </td>
            <td>
                {% if exam.show_on_home %}
                <span class="badge bg-primary">Featured</span>
                {% else %}
                <span class="badge bg-secondary">No</span>
                {% endif %}
            </td>
            <td>
                <!-- Action buttons -->
            </td>
        </tr>
        {% empty %}
        <tr>
            <td colspan="6" class="text-center">No exams found.</td>
        </tr>
        {% endfor %}
    </tbody>
</table>
```

### 5. Create Featured Exams API Endpoint
Add a new ViewSet in `api/views.py`:

```python
class FeaturedExamsViewSet(viewsets.ReadOnlyModelViewSet):
    """
    API endpoint that returns exams marked to show on the home page
    """
    queryset = Exam.objects.filter(show_on_home=True, is_published=True).order_by('exam_date')[:5]
    serializer_class = ExamSerializer
    permission_classes = [permissions.AllowAny]
```

### 6. Register the API Endpoint
Add the endpoint to `api/urls.py`:

```python
router.register(r'featured-exams', views.FeaturedExamsViewSet, basename='featured-exams')
```

### 7. Update Exam Serializer (if needed)
Ensure the ExamSerializer in `api/serializers.py` includes the new field:

```python
class ExamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Exam
        fields = [
            'id', 'exam_name', 'exam_date', 'exam_url', 'degree_name', 
            'degree_name_str', 'semester', 'admission_year', 'university', 
            'university_name', 'is_published', 'show_on_home'
        ]
```

## Testing
After implementing these changes:

1. Log in to the admin dashboard
2. Edit some exams and mark them as "show_on_home"
3. Test the API endpoint by accessing `/api/featured-exams/`
4. Verify that only exams marked as "show_on_home" and "is_published" are returned
5. Test the mobile app to ensure the featured exams appear on the home screen 