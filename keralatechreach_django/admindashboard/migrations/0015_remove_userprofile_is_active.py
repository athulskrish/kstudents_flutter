# Generated by Django 5.2 on 2025-06-05 05:56

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('admindashboard', '0014_userprofile_verification_token_and_more'),
    ]

    operations = [
        migrations.RemoveField(
            model_name='userprofile',
            name='is_active',
        ),
    ]
