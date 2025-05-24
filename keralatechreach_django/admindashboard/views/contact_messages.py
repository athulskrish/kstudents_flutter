from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from django.core.paginator import Paginator
from admindashboard.models import ContactUs

@login_required
def contact_messages(request):
    messages_list = ContactUs.objects.all()
    
    # Add pagination
    paginator = Paginator(messages_list, 10)  # Show 10 messages per page
    page = request.GET.get('page')
    messages_page = paginator.get_page(page)
    
    context = {
        'messages': messages_page,
        'unread_count': ContactUs.objects.filter(is_read=False).count()
    }
    return render(request, 'admindashboard/contact/list.html', context)

@login_required
def contact_message_detail(request, pk):
    contact_message = get_object_or_404(ContactUs, pk=pk)
    
    # Mark message as read
    if not contact_message.is_read:
        contact_message.is_read = True
        contact_message.save()
    
    return render(request, 'admindashboard/contact/detail.html', {
        'message': contact_message
    })

@login_required
def contact_message_delete(request, pk):
    contact_message = get_object_or_404(ContactUs, pk=pk)
    
    if request.method == 'POST':
        contact_message.delete()
        messages.success(request, 'Message deleted successfully.')
        return redirect('admindashboard:contact_messages')
    
    return render(request, 'admindashboard/contact/delete.html', {
        'message': contact_message
    }) 