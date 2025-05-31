from django.core.management.base import BaseCommand
from django.contrib.auth.models import User
from admindashboard.models import UserProfile, District, EventCategory, Event
from django.utils import timezone
import datetime

class Command(BaseCommand):
    help = 'Creates sample events, event categories, and districts for testing'

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
        
        # Get the first superuser (or create one if needed)
        admin_user = User.objects.filter(is_superuser=True).first()
        admin_profile = UserProfile.objects.get(user=admin_user)
        
        # Create districts if they don't exist
        district_names = [
            'Alappuzha', 'Ernakulam', 'Idukki', 'Kannur', 'Kasaragod',
            'Kollam', 'Kottayam', 'Kozhikode', 'Malappuram', 'Palakkad',
            'Pathanamthitta', 'Thiruvananthapuram', 'Thrissur', 'Wayanad'
        ]
        
        districts = []
        for name in district_names:
            district, created = District.objects.get_or_create(
                name=name,
                defaults={
                    'is_active': True,
                    'created_by': admin_profile
                }
            )
            districts.append(district)
            if created:
                self.stdout.write(self.style.SUCCESS(f'Created district: {name}'))
            else:
                self.stdout.write(self.style.WARNING(f'District already exists: {name}'))
        
        # Create event categories if they don't exist
        category_names = [
            'Workshop', 'Conference', 'Seminar', 'Meetup', 'Hackathon',
            'Cultural', 'Sports', 'Academic', 'Placement', 'Training'
        ]
        
        categories = []
        for name in category_names:
            category, created = EventCategory.objects.get_or_create(
                category=name,
                defaults={
                    'created_by': admin_profile
                }
            )
            categories.append(category)
            if created:
                self.stdout.write(self.style.SUCCESS(f'Created event category: {name}'))
            else:
                self.stdout.write(self.style.WARNING(f'Event category already exists: {name}'))
        
        # Check if we already have events
        existing_events_count = Event.objects.count()
        if existing_events_count > 0:
            self.stdout.write(self.style.WARNING(f'Found {existing_events_count} existing events. Skipping event creation.'))
            return
        
        # Create sample events
        now = timezone.now()
        
        # Event 1 - Upcoming workshop
        Event.objects.create(
            name='Flutter Workshop',
            event_start=now + datetime.timedelta(days=7),
            event_end=now + datetime.timedelta(days=7, hours=4),
            place='College of Engineering, Trivandrum',
            link='https://example.com/flutter-workshop',
            description='Learn Flutter app development from scratch. Bring your laptop with Flutter installed.',
            map_link='https://maps.google.com/?q=College+of+Engineering+Trivandrum',
            district=districts[11],  # Thiruvananthapuram
            category=categories[0],  # Workshop
            is_published=True,
            created_by=admin_profile
        )
        self.stdout.write(self.style.SUCCESS('Created event: Flutter Workshop'))
        
        # Event 2 - Upcoming conference
        Event.objects.create(
            name='Kerala Tech Summit 2024',
            event_start=now + datetime.timedelta(days=14),
            event_end=now + datetime.timedelta(days=16),
            place='Lulu International Convention Centre, Thrissur',
            link='https://example.com/tech-summit-2024',
            description='Annual tech summit featuring keynotes, workshops, and networking opportunities.',
            map_link='https://maps.google.com/?q=Lulu+International+Convention+Centre+Thrissur',
            district=districts[12],  # Thrissur
            category=categories[1],  # Conference
            is_published=True,
            created_by=admin_profile
        )
        self.stdout.write(self.style.SUCCESS('Created event: Kerala Tech Summit 2024'))
        
        # Event 3 - Upcoming hackathon
        Event.objects.create(
            name='Code for Kerala Hackathon',
            event_start=now + datetime.timedelta(days=21),
            event_end=now + datetime.timedelta(days=22),
            place='Infopark, Kochi',
            link='https://example.com/code-for-kerala',
            description='24-hour hackathon to build solutions for local challenges. Teams of 3-5 participants.',
            map_link='https://maps.google.com/?q=Infopark+Kochi',
            district=districts[1],  # Ernakulam
            category=categories[4],  # Hackathon
            is_published=True,
            created_by=admin_profile
        )
        self.stdout.write(self.style.SUCCESS('Created event: Code for Kerala Hackathon'))
        
        # Event 4 - Past event (unpublished)
        Event.objects.create(
            name='Android Development Workshop',
            event_start=now - datetime.timedelta(days=30),
            event_end=now - datetime.timedelta(days=30, hours=-4),
            place='Model Engineering College, Kochi',
            link='https://example.com/android-workshop',
            description='Hands-on Android app development workshop for beginners.',
            map_link='https://maps.google.com/?q=Model+Engineering+College+Kochi',
            district=districts[1],  # Ernakulam
            category=categories[0],  # Workshop
            is_published=False,  # Unpublished past event
            created_by=admin_profile
        )
        self.stdout.write(self.style.SUCCESS('Created event: Android Development Workshop (unpublished)'))
        
        # Event 5 - Today's event
        Event.objects.create(
            name='Python Meetup',
            event_start=now.replace(hour=18, minute=0, second=0, microsecond=0),
            event_end=now.replace(hour=20, minute=0, second=0, microsecond=0),
            place='Technopark, Trivandrum',
            link='https://example.com/python-meetup',
            description='Monthly Python developer meetup with lightning talks and networking.',
            map_link='https://maps.google.com/?q=Technopark+Trivandrum',
            district=districts[11],  # Thiruvananthapuram
            category=categories[3],  # Meetup
            is_published=True,
            created_by=admin_profile
        )
        self.stdout.write(self.style.SUCCESS('Created event: Python Meetup'))
        
        total_events = Event.objects.count()
        published_events = Event.objects.filter(is_published=True).count()
        self.stdout.write(self.style.SUCCESS(f'Created {total_events} events in total ({published_events} published)')) 