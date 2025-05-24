from django.db import migrations
from django.utils.text import slugify

def generate_slugs(apps, schema_editor):
    News = apps.get_model('admindashboard', 'News')
    for news in News.objects.all():
        if not news.slug:
            base_slug = slugify(news.title)
            slug = base_slug
            counter = 1
            while News.objects.filter(slug=slug).exists():
                slug = f"{base_slug}-{counter}"
                counter += 1
            news.slug = slug
            news.save()

class Migration(migrations.Migration):
    dependencies = [
        ('admindashboard', '0008_alter_news_options_news_excerpt_news_keywords_and_more'),
    ]

    operations = [
        migrations.RunPython(generate_slugs, reverse_code=migrations.RunPython.noop),
    ] 