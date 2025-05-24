from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from ..models import Job
from ..forms import JobForm
from .activity_log import log_activity

@login_required
def job_list(request):
    jobs = Job.objects.all().order_by('-updated_at')
    return render(request, 'admindashboard/jobs/list.html', {'jobs': jobs})

@login_required
def job_create(request):
    if request.method == 'POST':
        form = JobForm(request.POST)
        if form.is_valid():
            job = form.save(commit=False)
            job.created_by = request.user.userprofile
            job.save()
            log_activity(
                user=request.user,
                action="Created job posting",
                details=f"Created job posting: {job.title}",
                request=request
            )
            messages.success(request, 'Job posting created successfully.')
            return redirect('admindashboard:job_list')
    else:
        form = JobForm()
    return render(request, 'admindashboard/jobs/form.html', {
        'form': form,
        'title': 'Create Job Posting'
    })

@login_required
def job_edit(request, pk):
    job = get_object_or_404(Job, pk=pk)
    if request.method == 'POST':
        form = JobForm(request.POST, instance=job)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated job posting",
                details=f"Updated job posting: {job.title}",
                request=request
            )
            messages.success(request, 'Job posting updated successfully.')
            return redirect('admindashboard:job_list')
    else:
        form = JobForm(instance=job)
    return render(request, 'admindashboard/jobs/form.html', {
        'form': form,
        'title': 'Edit Job Posting',
        'job': job
    })

@login_required
def job_delete(request, pk):
    job = get_object_or_404(Job, pk=pk)
    if request.method == 'POST':
        title = job.title
        job.delete()
        log_activity(
            user=request.user,
            action="Deleted job posting",
            details=f"Deleted job posting: {title}",
            request=request
        )
        messages.success(request, 'Job posting deleted successfully.')
        return redirect('admindashboard:job_list')
    return render(request, 'admindashboard/jobs/delete.html', {'job': job}) 