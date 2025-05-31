from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from admindashboard.models import UserProfile, District, EventCategory

class Command(BaseCommand):
    help = 'Loads sample data for EventCategory and District models'

    def handle(self, *args, **kwargs):
        # Ensure we have at least one superuser
        if not User.objects.filter(is_superuser=True).exists():
            self.stdout.write(self.style.WARNING('No superuser found. Creating a default superuser...'))
            superuser = User.objects.create_superuser(
                username='admin',
                email='admin@example.com',
                password='adminpassword'
            )
            self.stdout.write(self.style.SUCCESS(f'Created superuser: {superuser.username}'))
        else:
            superuser = User.objects.filter(is_superuser=True).first()
            self.stdout.write(self.style.SUCCESS(f'Using existing superuser: {superuser.username}'))

        # Get the user profile for the superuser
        user_profile = UserProfile.objects.get(user=superuser)

        # Create Districts
        districts = [
            'Thiruvananthapuram',
            'Kollam',
            'Pathanamthitta',
            'Alappuzha',
            'Kottayam',
            'Idukki',
            'Ernakulam',
            'Thrissur',
            'Palakkad',
            'Malappuram',
            'Kozhikode',
            'Wayanad',
            'Kannur',
            'Kasaragod'
        ]

        for district_name in districts:
            district, created = District.objects.get_or_create(
                name=district_name,
                defaults={'created_by': user_profile}
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Created district: {district.name}'))
            else:
                self.stdout.write(self.style.WARNING(f'District already exists: {district.name}'))

        # Create Event Categories
        categories = [
            'Workshop',
            'Conference',
            'Seminar',
            'Webinar',
            'Hackathon',
            'Meetup',
            'Training',
            'Competition',
            'Celebration',
            'Exhibition'
        ]

        for category_name in categories:
            category, created = EventCategory.objects.get_or_create(
                category=category_name,
                defaults={'created_by': user_profile}
            )
            if created:
                self.stdout.write(self.style.SUCCESS(f'Created event category: {category.category}'))
            else:
                self.stdout.write(self.style.WARNING(f'Event category already exists: {category.category}'))

        self.stdout.write(self.style.SUCCESS('Sample data loaded successfully!')) 
 