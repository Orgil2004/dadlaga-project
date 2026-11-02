
from django.contrib import admin
from django.utils import timezone

from .models import Organization, Product


class ProductInline(admin.TabularInline):
    model = Product
    extra = 0
    show_change_link = True

    fields = [
        'name',
        'price',
        'sizes',
        'colors',
        'in_stock',
        'is_active',
    ]


@admin.register(Organization)
class OrganizationAdmin(admin.ModelAdmin):

    list_display = [
        'name',
        'category',
        'registration_number',
        'address',
        'verification_status',
        'is_demo',
    ]

    search_fields = [
        'name',
        'legal_name',
        'registration_number',
        'admin_email',
        'address',
    ]

    list_filter = [
        'category',
        'verification_status',
        'is_demo',
    ]

    readonly_fields = [
        'verified_at',
        'created_at',
    ]

    fieldsets = [
        (
            'Байгууллагын үндсэн мэдээлэл',
            {
                'fields': [
                    'name',
                    'legal_name',
                    'registration_number',
                    'category',
                    'description',
                ]
            }
        ),
        (
            'Холбоо барих мэдээлэл',
            {
                'fields': [
                    'address',
                    'phone',
                    'admin_name',
                    'admin_email',
                    'admin_phone',
                ]
            }
        ),
        (
            'Байршил, ажиллах цаг',
            {
                'fields': [
                    'latitude',
                    'longitude',
                    'opening_hours',
                ]
            }
        ),
        (
            'Гэрчилгээ, баталгаажуулалт',
            {
                'fields': [
                    'registration_document_reference',
                    'verification_status',
                    'verified_at',
                    'created_at',
                    'is_demo',
                ]
            }
        ),
    ]

    inlines = [ProductInline]

    def save_model(self, request, obj, form, change):
        if obj.verification_status == 'approved':
            if obj.verified_at is None:
                obj.verified_at = timezone.now()
        else:
            obj.verified_at = None

        super().save_model(
            request,
            obj,
            form,
            change
        )


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):

    list_display = [
        'name',
        'organization',
        'price',
        'in_stock',
        'is_active',
    ]

    list_filter = [
        'organization',
        'category',
        'in_stock',
        'is_active',
    ]

    search_fields = [
        'name',
        'organization__name',
    ]

    autocomplete_fields = [
        'organization',
    ]
