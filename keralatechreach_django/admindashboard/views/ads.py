from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from ..models import AdSettings
from ..forms import AdSettingsForm
from .activity_log import log_activity

@login_required
def ad_list(request):
    ads = AdSettings.objects.all()
    return render(request, 'admindashboard/ads/list.html', {'ads': ads})

@login_required
def ad_create(request):
    if request.method == 'POST':
        form = AdSettingsForm(request.POST)
        if form.is_valid():
            ad = form.save(commit=False)
            ad.created_by = request.user.userprofile
            ad.save()
            log_activity(
                user=request.user,
                action="Created ad setting",
                details=f"Created ad setting: {ad.name}",
                request=request
            )
            messages.success(request, 'Ad setting created successfully.')
            return redirect('admindashboard:ad_list')
    else:
        form = AdSettingsForm()
    return render(request, 'admindashboard/ads/form.html', {
        'form': form,
        'title': 'Create Ad Setting'
    })

@login_required
def ad_edit(request, pk):
    ad = get_object_or_404(AdSettings, pk=pk)
    if request.method == 'POST':
        form = AdSettingsForm(request.POST, instance=ad)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated ad setting",
                details=f"Updated ad setting: {ad.name}",
                request=request
            )
            messages.success(request, 'Ad setting updated successfully.')
            return redirect('admindashboard:ad_list')
    else:
        form = AdSettingsForm(instance=ad)
    return render(request, 'admindashboard/ads/form.html', {
        'form': form,
        'title': 'Edit Ad Setting',
        'ad': ad
    })

@login_required
def ad_delete(request, pk):
    ad = get_object_or_404(AdSettings, pk=pk)
    if request.method == 'POST':
        name = ad.name
        ad.delete()
        log_activity(
            user=request.user,
            action="Deleted ad setting",
            details=f"Deleted ad setting: {name}",
            request=request
        )
        messages.success(request, 'Ad setting deleted successfully.')
        return redirect('admindashboard:ad_list')
    return render(request, 'admindashboard/ads/delete.html', {'ad': ad}) 