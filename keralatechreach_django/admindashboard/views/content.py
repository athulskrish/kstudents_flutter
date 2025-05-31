from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from ..models import News, Event, Gallery, EventCategory, District, Initiative
from ..forms import NewsForm, EventForm, GalleryForm, EventCategoryForm, DistrictForm, InitiativeForm
from .activity_log import log_activity

# News Views
@login_required
def news_list(request):
    news_items = News.objects.all().order_by('-created_at')
    context = {
        'news_items': news_items,
        'news_table': render(request, 'admindashboard/news/table.html', {'news': news_items}).content.decode('utf-8')
    }
    return render(request, 'admindashboard/news/list.html', context)

@login_required
def news_create(request):
    if request.method == 'POST':
        print("DEBUG: POST request received")
        form = NewsForm(request.POST, request.FILES)
        print("DEBUG: Form data:", request.POST)
        print("DEBUG: Files:", request.FILES)
        if form.is_valid():
            print("DEBUG: Form is valid")
            news = form.save(commit=False)
            news.created_by = request.user.userprofile
            news.save()
            log_activity(
                user=request.user,
                action="Created news article",
                details=f"Created news article: {news.title}",
                request=request
            )
            messages.success(request, 'News article created successfully.')
            return redirect('admindashboard:news_list')
        else:
            print("DEBUG: Form errors:", form.errors)
    else:
        form = NewsForm()
    return render(request, 'admindashboard/news/form.html', {
        'form': form,
        'title': 'Create News Article'
    })

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
            messages.success(request, 'News article updated successfully.')
            return redirect('admindashboard:news_list')
    else:
        form = NewsForm(instance=news)
    return render(request, 'admindashboard/news/form.html', {
        'form': form,
        'title': 'Edit News Article',
        'news': news
    })

@login_required
def news_delete(request, pk):
    news = get_object_or_404(News, pk=pk)
    if request.method == 'POST':
        title = news.title
        news.delete()
        log_activity(
            user=request.user,
            action="Deleted news article",
            details=f"Deleted news article: {title}",
            request=request
        )
        messages.success(request, 'News article deleted successfully.')
        return redirect('admindashboard:news_list')
    return render(request, 'admindashboard/news/delete.html', {'news': news})

# Event Views
@login_required
def event_list(request):
    events = Event.objects.all().order_by('-event_start')
    context = {
        'events': events,
        'event_table': render(request, 'admindashboard/event/table.html', {'events': events}).content.decode('utf-8')
    }
    return render(request, 'admindashboard/event/list.html', context)

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
            return redirect('admindashboard:event_list')
        else:
            print("Form errors:", form.errors)
    else:
        form = EventForm()
    
    # Ensure proper context for datetime fields
    context = {
        'form': form,
        'title': 'Create Event'
    }
    return render(request, 'admindashboard/event/form.html', context)

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
            return redirect('admindashboard:event_list')
        else:
            print("Form errors:", form.errors)
    else:
        form = EventForm(instance=event)
    
    # Ensure proper context for datetime fields
    context = {
        'form': form,
        'title': 'Edit Event',
        'event': event
    }
    return render(request, 'admindashboard/event/form.html', context)

@login_required
def event_delete(request, pk):
    event = get_object_or_404(Event, pk=pk)
    if request.method == 'POST':
        name = event.name
        event.delete()
        log_activity(
            user=request.user,
            action="Deleted event",
            details=f"Deleted event: {name}",
            request=request
        )
        messages.success(request, 'Event deleted successfully.')
        return redirect('admindashboard:event_list')
    return render(request, 'admindashboard/event/delete.html', {'event': event})

# Gallery Views
@login_required
def gallery_list(request):
    gallery_items = Gallery.objects.all().order_by('-created_at')
    return render(request, 'admindashboard/gallery/list.html', {'gallery_items': gallery_items})

@login_required
def gallery_create(request):
    if request.method == 'POST':
        form = GalleryForm(request.POST, request.FILES)
        if form.is_valid():
            gallery = form.save(commit=False)
            gallery.created_by = request.user.userprofile
            gallery.save()
            messages.success(request, 'Gallery item created successfully.')
            return redirect('admindashboard:gallery_list')
    else:
        form = GalleryForm()
    return render(request, 'admindashboard/gallery/form.html', {
        'form': form,
        'title': 'Add Gallery Item'
    })

@login_required
def gallery_edit(request, pk):
    gallery = get_object_or_404(Gallery, pk=pk)
    if request.method == 'POST':
        form = GalleryForm(request.POST, request.FILES, instance=gallery)
        if form.is_valid():
            form.save()
            messages.success(request, 'Gallery item updated successfully.')
            return redirect('admindashboard:gallery_list')
    else:
        form = GalleryForm(instance=gallery)
    return render(request, 'admindashboard/gallery/form.html', {
        'form': form,
        'title': 'Edit Gallery Item'
    })

@login_required
def gallery_delete(request, pk):
    gallery = get_object_or_404(Gallery, pk=pk)
    if request.method == 'POST':
        gallery.delete()
        messages.success(request, 'Gallery item deleted successfully.')
        return redirect('admindashboard:gallery_list')
    return render(request, 'admindashboard/gallery/delete.html', {'gallery': gallery})

@login_required
def district_list(request):
    districts = District.objects.all().order_by('name')
    return render(request, 'admindashboard/districts/list.html', {'districts': districts})

@login_required
def district_create(request):
    if request.method == 'POST':
        form = DistrictForm(request.POST)
        if form.is_valid():
            district = form.save(commit=False)
            district.created_by = request.user.userprofile
            district.save()
            messages.success(request, 'District created successfully.')
            return redirect('admindashboard:district_list')
    else:
        form = DistrictForm()
    return render(request, 'admindashboard/districts/form.html', {
        'form': form,
        'title': 'Create District'
    })

@login_required
def district_edit(request, pk):
    district = get_object_or_404(District, pk=pk)
    if request.method == 'POST':
        form = DistrictForm(request.POST, instance=district)
        if form.is_valid():
            form.save()
            messages.success(request, 'District updated successfully.')
            return redirect('admindashboard:district_list')
    else:
        form = DistrictForm(instance=district)
    return render(request, 'admindashboard/districts/form.html', {
        'form': form,
        'title': 'Edit District',
        'district': district
    })

@login_required
def district_delete(request, pk):
    district = get_object_or_404(District, pk=pk)
    if request.method == 'POST':
        district.delete()
        messages.success(request, 'District deleted successfully.')
        return redirect('admindashboard:district_list')
    return render(request, 'admindashboard/districts/delete.html', {'district': district})

@login_required
def initiative_list(request):
    initiatives = Initiative.objects.all().order_by('-updated_at')
    return render(request, 'admindashboard/initiatives/list.html', {'initiatives': initiatives})

@login_required
def initiative_create(request):
    if request.method == 'POST':
        form = InitiativeForm(request.POST, request.FILES)
        if form.is_valid():
            initiative = form.save(commit=False)
            initiative.created_by = request.user.userprofile
            initiative.save()
            messages.success(request, 'Initiative created successfully.')
            return redirect('admindashboard:initiative_list')
    else:
        form = InitiativeForm()
    return render(request, 'admindashboard/initiatives/form.html', {
        'form': form,
        'title': 'Create Initiative'
    })

@login_required
def initiative_edit(request, pk):
    initiative = get_object_or_404(Initiative, pk=pk)
    if request.method == 'POST':
        form = InitiativeForm(request.POST, request.FILES, instance=initiative)
        if form.is_valid():
            form.save()
            messages.success(request, 'Initiative updated successfully.')
            return redirect('admindashboard:initiative_list')
    else:
        form = InitiativeForm(instance=initiative)
    return render(request, 'admindashboard/initiatives/form.html', {
        'form': form,
        'title': 'Edit Initiative',
        'initiative': initiative
    })

@login_required
def initiative_delete(request, pk):
    initiative = get_object_or_404(Initiative, pk=pk)
    if request.method == 'POST':
        initiative.delete()
        messages.success(request, 'Initiative deleted successfully.')
        return redirect('admindashboard:initiative_list')
    return render(request, 'admindashboard/initiatives/delete.html', {'initiative': initiative})

# Event Category Views
@login_required
def event_category_list(request):
    categories = EventCategory.objects.all().order_by('category')
    return render(request, 'admindashboard/event_category/list.html', {'categories': categories})

@login_required
def event_category_create(request):
    if request.method == 'POST':
        form = EventCategoryForm(request.POST)
        if form.is_valid():
            category = form.save(commit=False)
            category.created_by = request.user.userprofile
            category.save()
            log_activity(
                user=request.user,
                action="Created event category",
                details=f"Created event category: {category.category}",
                request=request
            )
            messages.success(request, 'Event category created successfully.')
            return redirect('admindashboard:event_category_list')
    else:
        form = EventCategoryForm()
    return render(request, 'admindashboard/event_category/form.html', {
        'form': form,
        'title': 'Create Event Category'
    })

@login_required
def event_category_edit(request, pk):
    category = get_object_or_404(EventCategory, pk=pk)
    if request.method == 'POST':
        form = EventCategoryForm(request.POST, instance=category)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated event category",
                details=f"Updated event category: {category.category}",
                request=request
            )
            messages.success(request, 'Event category updated successfully.')
            return redirect('admindashboard:event_category_list')
    else:
        form = EventCategoryForm(instance=category)
    return render(request, 'admindashboard/event_category/form.html', {
        'form': form,
        'title': 'Edit Event Category',
        'category': category
    })

@login_required
def event_category_delete(request, pk):
    category = get_object_or_404(EventCategory, pk=pk)
    if request.method == 'POST':
        name = category.category
        category.delete()
        log_activity(
            user=request.user,
            action="Deleted event category",
            details=f"Deleted event category: {name}",
            request=request
        )
        messages.success(request, 'Event category deleted successfully.')
        return redirect('admindashboard:event_category_list')
    return render(request, 'admindashboard/event_category/delete.html', {'category': category}) 