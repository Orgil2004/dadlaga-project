import django.core.validators
import django.db.models.deletion
from django.db import migrations, models


DEFAULT_CATEGORIES = [
    # (name, icon, sort_order) — the four ad categories the app already used
    ('Хувцас', 'checkroom', 10),
    ('Гутал', 'footwear', 20),
    ('Спорт', 'sports', 30),
    ('Электрон бараа', 'devices', 40),
    ('Гэр ахуй', 'chair', 50),
    ('Үйлчилгээ', 'handyman', 60),
]


def forwards(apps, schema_editor):
    Category = apps.get_model('organizations', 'Category')
    Organization = apps.get_model('organizations', 'Organization')

    for name, icon, order in DEFAULT_CATEGORIES:
        Category.objects.get_or_create(
            name=name, defaults={'icon': icon, 'sort_order': order}
        )

    for store in Organization.objects.all():
        name = ' '.join((store.category_text or '').split()) or 'Бусад'
        category, _ = Category.objects.get_or_create(
            name=name, defaults={'sort_order': 100}
        )
        store.category = category
        store.save(update_fields=['category'])


def backwards(apps, schema_editor):
    Organization = apps.get_model('organizations', 'Organization')
    for store in Organization.objects.select_related('category'):
        store.category_text = store.category.name if store.category else ''
        store.save(update_fields=['category_text'])


class Migration(migrations.Migration):

    dependencies = [
        ('organizations', '0003_organization_admin_email_organization_admin_name_and_more'),
    ]

    operations = [
        migrations.CreateModel(
            name='Category',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=100, unique=True, verbose_name='Нэр')),
                ('icon', models.CharField(choices=[('devices', 'Электрон'), ('chair', 'Гэр ахуй'), ('checkroom', 'Хувцас'), ('footwear', 'Гутал'), ('sports', 'Спорт'), ('restaurant', 'Хоол, кафе'), ('grocery', 'Хүнс'), ('spa', 'Гоо сайхан'), ('car', 'Авто'), ('book', 'Ном, бичиг хэрэг'), ('pets', 'Амьтан'), ('child', 'Хүүхэд'), ('handyman', 'Үйлчилгээ'), ('other', 'Бусад')], default='other', max_length=30, verbose_name='Дүрс')),
                ('sort_order', models.PositiveIntegerField(default=0, help_text='Бага тоотой нь эхэнд харагдана.', verbose_name='Эрэмбэ')),
                ('is_active', models.BooleanField(default=True, help_text='Идэвхгүй ангилал аппын сонголтод харагдахгүй.', verbose_name='Идэвхтэй')),
                ('created_at', models.DateTimeField(auto_now_add=True)),
            ],
            options={
                'verbose_name': 'Ангилал',
                'verbose_name_plural': 'Ангиллууд',
                'ordering': ['sort_order', 'name'],
            },
        ),
        migrations.RenameField(
            model_name='organization',
            old_name='category',
            new_name='category_text',
        ),
        migrations.AddField(
            model_name='organization',
            name='category',
            field=models.ForeignKey(null=True, on_delete=django.db.models.deletion.PROTECT, related_name='organizations', to='organizations.category', verbose_name='Ангилал'),
        ),
        migrations.RunPython(forwards, backwards),
        migrations.RemoveField(
            model_name='organization',
            name='category_text',
        ),
        migrations.AlterField(
            model_name='organization',
            name='category',
            field=models.ForeignKey(on_delete=django.db.models.deletion.PROTECT, related_name='organizations', to='organizations.category', verbose_name='Ангилал'),
        ),
        migrations.AlterField(
            model_name='product',
            name='price',
            field=models.DecimalField(decimal_places=0, help_text='Заавал. 1 ₮-өөс дээш дүн оруулна уу.', max_digits=12, validators=[django.core.validators.MinValueValidator(1)], verbose_name='Үнэ (₮)'),
        ),
    ]
