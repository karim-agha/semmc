# Generated by Django 2.0.7 on 2018-07-30 18:11

from django.db import migrations


class Migration(migrations.Migration):

    dependencies = [
        ('main', '0016_auto_20180730_1810'),
    ]

    operations = [
        migrations.RenameField(
            model_name='testinput',
            old_name='test_failure',
            new_name='test',
        ),
    ]
