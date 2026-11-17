
import math

from django.db import models
from django.core.exceptions import ValidationError
from django.core.validators import (
    MinValueValidator,
    MaxValueValidator,
)


class Category(models.Model):
    """Admin-managed category shared by stores and user ads."""

    ICON_CHOICES = [
        ('devices', 'Электрон'),
        ('chair', 'Гэр ахуй'),
        ('checkroom', 'Хувцас'),
        ('footwear', 'Гутал'),
        ('sports', 'Спорт'),
        ('restaurant', 'Хоол, кафе'),
        ('grocery', 'Хүнс'),
        ('spa', 'Гоо сайхан'),
        ('car', 'Авто'),
        ('book', 'Ном, бичиг хэрэг'),
        ('pets', 'Амьтан'),
        ('child', 'Хүүхэд'),
        ('handyman', 'Үйлчилгээ'),
        ('other', 'Бусад'),
    ]

    name = models.CharField(
        max_length=100,
        unique=True,
        verbose_name='Нэр'
    )

    icon = models.CharField(
        max_length=30,
        choices=ICON_CHOICES,
        default='other',
        verbose_name='Дүрс'
    )

    sort_order = models.PositiveIntegerField(
        default=0,
        verbose_name='Эрэмбэ',
        help_text='Бага тоотой нь эхэнд харагдана.'
    )

    is_active = models.BooleanField(
        default=True,
        verbose_name='Идэвхтэй',
        help_text='Идэвхгүй ангилал аппын сонголтод харагдахгүй.'
    )

    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['sort_order', 'name']
        verbose_name = 'Ангилал'
        verbose_name_plural = 'Ангиллууд'

    def save(self, *args, **kwargs):
        self.name = ' '.join(self.name.split())
        super().save(*args, **kwargs)

    def __str__(self):
        return self.name


class Organization(models.Model):

    VERIFICATION_CHOICES = [
        ('pending', 'Хүлээгдэж байгаа'),
        ('approved', 'Баталгаажсан'),
        ('rejected', 'Татгалзсан'),
    ]

    # Өмнө байсан талбарууд
    name = models.CharField(max_length=200)

    category = models.ForeignKey(
        Category,
        related_name='organizations',
        on_delete=models.PROTECT,
        verbose_name='Ангилал'
    )

    address = models.CharField(max_length=255)

    phone = models.CharField(
        max_length=20,
        blank=True
    )

    description = models.TextField(blank=True)

    latitude = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(-85),
            MaxValueValidator(85),
        ]
    )

    longitude = models.FloatField(
        null=True,
        blank=True,
        validators=[
            MinValueValidator(-180),
            MaxValueValidator(180),
        ]
    )

    opening_hours = models.CharField(
        max_length=200,
        blank=True
    )

    is_demo = models.BooleanField(default=False)

    # Шинээр нэмсэн бүртгэлийн мэдээлэл
    legal_name = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='Албан ёсны нэр'
    )

    registration_number = models.CharField(
        max_length=50,
        unique=True,
        null=True,
        blank=True,
        verbose_name='Байгууллагын регистр'
    )

    admin_name = models.CharField(
        max_length=150,
        blank=True,
        verbose_name='Админы нэр'
    )

    admin_email = models.EmailField(
        blank=True,
        verbose_name='Админы имэйл'
    )

    admin_phone = models.CharField(
        max_length=20,
        blank=True,
        verbose_name='Админы утас'
    )

    registration_document_reference = models.CharField(
        max_length=255,
        blank=True,
        verbose_name='Гэрчилгээний лавлагаа'
    )

    verification_status = models.CharField(
        max_length=20,
        choices=VERIFICATION_CHOICES,
        default='pending',
        verbose_name='Баталгаажуулалтын төлөв'
    )

    verified_at = models.DateTimeField(
        null=True,
        blank=True,
        verbose_name='Баталгаажуулсан огноо'
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    def clean(self):
        super().clean()

        if self.latitude is None or self.longitude is None:
            raise ValidationError(
                'Дэлгүүрийн байршлыг (өргөрөг, уртраг) заавал '
                'оруулна уу. Газрын зураг дээр дарж сонгож болно.'
            )

        for field in ('latitude', 'longitude'):
            value = getattr(self, field)

            if value is not None and not math.isfinite(value):
                raise ValidationError({
                    field: 'Бодит координат оруулна уу.'
                })

        if self.registration_number is not None:
            self.registration_number = (
                self.registration_number.strip() or None
            )

    def __str__(self):
        return self.name


class Product(models.Model):

    organization = models.ForeignKey(
        Organization,
        related_name='products',
        on_delete=models.CASCADE
    )

    name = models.CharField(max_length=200)

    category = models.CharField(
        max_length=100,
        blank=True
    )

    description = models.TextField(blank=True)

    price = models.DecimalField(
        max_digits=12,
        decimal_places=0,
        validators=[MinValueValidator(1)],
        verbose_name='Үнэ (₮)',
        help_text='Заавал. 1 ₮-өөс дээш дүн оруулна уу.'
    )

    sizes = models.CharField(
        max_length=150,
        blank=True,
        help_text='Жишээ: S, M, L, XL'
    )

    colors = models.CharField(
        max_length=150,
        blank=True,
        help_text='Жишээ: Хар, Цагаан'
    )

    image_url = models.URLField(
        max_length=1000,
        blank=True,
        help_text='Барааны зургийн HTTPS холбоос'
    )

    in_stock = models.BooleanField(default=True)

    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['-id']

    def __str__(self):
        return f'{self.organization.name} — {self.name}'
