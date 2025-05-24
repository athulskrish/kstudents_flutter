from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from admindashboard.models import UserProfile

class Command(BaseCommand):
    help = 'Creates UserProfile objects for users that do not have them'

    def handle(self, *args, **options):
        users_without_profile = User.objects.filter(userprofile__isnull=True)
        created_count = 0
        
        for user in users_without_profile:
            UserProfile.objects.create(
                user=user,
                email=user.email,
                is_staff=user.is_staff,
                is_superuser=user.is_superuser,
                is_active=user.is_active
            )
            created_count += 1
        
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully created {created_count} user profiles'
            )
        ) 