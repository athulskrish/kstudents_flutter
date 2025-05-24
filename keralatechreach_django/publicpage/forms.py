from django import forms
from .models import NewsletterSubscriber

class NewsletterSignupForm(forms.ModelForm):
    email = forms.EmailField(
        widget=forms.EmailInput(
            attrs={
                'class': 'form-control',
                'placeholder': 'Enter your email address',
            }
        )
    )

    class Meta:
        model = NewsletterSubscriber
        fields = ['email']

    def clean_email(self):
        email = self.cleaned_data['email']
        if NewsletterSubscriber.objects.filter(email=email).exists():
            raise forms.ValidationError('This email is already subscribed to our newsletter.')
        return email 