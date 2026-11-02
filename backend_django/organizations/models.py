
import math
from django.core.exceptions import ValidationError
from django.core.validators import MinValueValidator, MaxValueValidator
from django.db import models

class Organization(models.Model):
    name = models.CharField(max_length=200)

    category = models.CharField(max_length=100)

    address = models.CharField(max_length=255)

    phone = models.CharField(
        max_length=20,
        blank=True
    )

    description = models.TextField(
        blank=True
    )

    latitude = models.FloatField(null=True, blank=True, validators=[MinValueValidator(-85), MaxValueValidator(85)])
    longitude = models.FloatField(null=True, blank=True, validators=[MinValueValidator(-180), MaxValueValidator(180)])
    opening_hours = models.CharField(max_length=200, blank=True)
    is_demo = models.BooleanField(default=False)

    def clean(self):
        super().clean()
        if (self.latitude is None) != (self.longitude is None):
            raise ValidationError('Өргөрөг, уртрагыг хамтад нь оруулна уу.')
        for field in ('latitude', 'longitude'):
            value = getattr(self, field)
            if value is not None and not math.isfinite(value):
                raise ValidationError({field: 'Бодит координат оруулна уу.'})

    def __str__(self):
        return self.name


class Product(models.Model):
    organization = models.ForeignKey(Organization, related_name='products', on_delete=models.CASCADE)
    name = models.CharField(max_length=200)
    category = models.CharField(max_length=100, blank=True)
    description = models.TextField(blank=True)
    price = models.DecimalField(max_digits=12, decimal_places=0, validators=[MinValueValidator(0)])
    sizes = models.CharField(max_length=150, blank=True, help_text='Жишээ: S, M, L, XL')
    colors = models.CharField(max_length=150, blank=True, help_text='Жишээ: Хар, Цагаан')
    image_url = models.URLField(max_length=1000, blank=True, help_text='Барааны зургийн https холбоос (заавал биш)')
    in_stock = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ['-id']

    def __str__(self):
        return f'{self.organization.name} — {self.name}'
