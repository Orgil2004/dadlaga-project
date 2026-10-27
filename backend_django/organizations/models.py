
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

    def __str__(self):
        return self.name
