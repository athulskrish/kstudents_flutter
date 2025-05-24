from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib import messages
from ..models import QuestionPaper, University, Degree, Exam
from ..forms import QuestionPaperForm, UniversityForm, DegreeForm, ExamForm
from .activity_log import log_activity

# QuestionPaper Views
@login_required
def question_list(request):
    questions = QuestionPaper.objects.all().order_by('-updated_at')
    context = {
        'questions': questions,
        'question_table': render(request, 'admindashboard/academic/question_table.html', {'questions': questions}).content.decode('utf-8')
    }
    return render(request, 'admindashboard/academic/question_list.html', context)

@login_required
def question_create(request):
    if request.method == 'POST':
        form = QuestionPaperForm(request.POST, request.FILES)
        if form.is_valid():
            question = form.save(commit=False)
            question.created_by = request.user.userprofile
            question.save()
            log_activity(
                user=request.user,
                action="Created question paper",
                details=f"Created question paper for {question.subject} - {question.degree}",
                request=request
            )
            messages.success(request, 'Question paper created successfully.')
            return redirect('admindashboard:question_list')
    else:
        form = QuestionPaperForm()
    
    return render(request, 'admindashboard/academic/question_form.html', {
        'form': form,
        'title': 'Add Question Paper'
    })

@login_required
def question_edit(request, pk):
    question = get_object_or_404(QuestionPaper, pk=pk)
    if request.method == 'POST':
        form = QuestionPaperForm(request.POST, request.FILES, instance=question)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated question paper",
                details=f"Updated question paper for {question.subject} - {question.degree}",
                request=request
            )
            messages.success(request, 'Question paper updated successfully.')
            return redirect('admindashboard:question_list')
    else:
        form = QuestionPaperForm(instance=question)
    
    return render(request, 'admindashboard/academic/question_form.html', {
        'form': form,
        'title': 'Edit Question Paper',
        'question': question
    })

@login_required
def question_delete(request, pk):
    question = get_object_or_404(QuestionPaper, pk=pk)
    details = f"Deleted question paper for {question.subject} - {question.degree}"
    question.delete()
    log_activity(
        user=request.user,
        action="Deleted question paper",
        details=details,
        request=request
    )
    messages.success(request, 'Question paper deleted successfully.')
    return redirect('admindashboard:question_list')

# University Views
@login_required
def university_list(request):
    universities = University.objects.all()
    return render(request, 'admindashboard/university/list.html', {'universities': universities})

@login_required
def university_create(request):
    if request.method == 'POST':
        form = UniversityForm(request.POST)
        if form.is_valid():
            university = form.save(commit=False)
            university.created_by = request.user.userprofile
            university.save()
            log_activity(
                user=request.user,
                action="Created university",
                details=f"Created university: {university.name}",
                request=request
            )
            messages.success(request, 'University created successfully.')
            return redirect('admindashboard:university_list')
    else:
        form = UniversityForm()
    return render(request, 'admindashboard/university/form.html', {
        'form': form,
        'title': 'Create University'
    })

@login_required
def university_edit(request, pk):
    university = get_object_or_404(University, pk=pk)
    if request.method == 'POST':
        form = UniversityForm(request.POST, instance=university)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated university",
                details=f"Updated university: {university.name}",
                request=request
            )
            messages.success(request, 'University updated successfully.')
            return redirect('admindashboard:university_list')
    else:
        form = UniversityForm(instance=university)
    return render(request, 'admindashboard/university/form.html', {
        'form': form,
        'title': 'Edit University'
    })

@login_required
def university_delete(request, pk):
    university = get_object_or_404(University, pk=pk)
    if request.method == 'POST':
        name = university.name
        university.delete()
        log_activity(
            user=request.user,
            action="Deleted university",
            details=f"Deleted university: {name}",
            request=request
        )
        messages.success(request, 'University deleted successfully.')
        return redirect('admindashboard:university_list')
    return render(request, 'admindashboard/university/delete.html', {'university': university})

# Degree Views
@login_required
def degree_list(request):
    degrees = Degree.objects.all()
    return render(request, 'admindashboard/degree/list.html', {'degrees': degrees})

@login_required
def degree_create(request):
    if request.method == 'POST':
        form = DegreeForm(request.POST)
        if form.is_valid():
            degree = form.save(commit=False)
            degree.created_by = request.user.userprofile
            degree.save()
            messages.success(request, 'Degree created successfully.')
            return redirect('admindashboard:degree_list')
    else:
        form = DegreeForm()
    return render(request, 'admindashboard/degree/form.html', {
        'form': form,
        'title': 'Create Degree'
    })

@login_required
def degree_edit(request, pk):
    degree = get_object_or_404(Degree, pk=pk)
    if request.method == 'POST':
        form = DegreeForm(request.POST, instance=degree)
        if form.is_valid():
            form.save()
            messages.success(request, 'Degree updated successfully.')
            return redirect('admindashboard:degree_list')
    else:
        form = DegreeForm(instance=degree)
    return render(request, 'admindashboard/degree/form.html', {
        'form': form,
        'title': 'Edit Degree'
    })

@login_required
def degree_delete(request, pk):
    degree = get_object_or_404(Degree, pk=pk)
    if request.method == 'POST':
        degree.delete()
        messages.success(request, 'Degree deleted successfully.')
        return redirect('admindashboard:degree_list')
    return render(request, 'admindashboard/degree/delete.html', {'degree': degree})

# Exam Views
@login_required
def exam_list(request):
    exams = Exam.objects.all().order_by('-exam_date')
    return render(request, 'admindashboard/exam/list.html', {'exams': exams})

@login_required
def exam_create(request):
    if request.method == 'POST':
        form = ExamForm(request.POST)
        if form.is_valid():
            exam = form.save(commit=False)
            exam.created_by = request.user.userprofile
            exam.save()
            log_activity(
                user=request.user,
                action="Created exam",
                details=f"Created exam: {exam.exam_name}",
                request=request
            )
            messages.success(request, 'Exam created successfully.')
            return redirect('admindashboard:exam_list')
    else:
        form = ExamForm()
    return render(request, 'admindashboard/exam/form.html', {
        'form': form,
        'title': 'Create Exam'
    })

@login_required
def exam_edit(request, pk):
    exam = get_object_or_404(Exam, pk=pk)
    if request.method == 'POST':
        form = ExamForm(request.POST, instance=exam)
        if form.is_valid():
            form.save()
            log_activity(
                user=request.user,
                action="Updated exam",
                details=f"Updated exam: {exam.exam_name}",
                request=request
            )
            messages.success(request, 'Exam updated successfully.')
            return redirect('admindashboard:exam_list')
    else:
        form = ExamForm(instance=exam)
    return render(request, 'admindashboard/exam/form.html', {
        'form': form,
        'title': 'Edit Exam'
    })

@login_required
def exam_delete(request, pk):
    exam = get_object_or_404(Exam, pk=pk)
    if request.method == 'POST':
        name = exam.exam_name
        exam.delete()
        log_activity(
            user=request.user,
            action="Deleted exam",
            details=f"Deleted exam: {name}",
            request=request
        )
        messages.success(request, 'Exam deleted successfully.')
        return redirect('admindashboard:exam_list')
    return render(request, 'admindashboard/exam/delete.html', {'exam': exam}) 