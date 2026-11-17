
from django.contrib import admin
from django.db.models import Count
from django.utils import timezone

from .models import Category, Organization, Product


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):

    list_display = [
        'name',
        'icon',
        'sort_order',
        'is_active',
        'store_count',
    ]

    list_editable = [
        'sort_order',
        'is_active',
    ]

    list_filter = ['is_active']

    search_fields = ['name']

    def get_queryset(self, request):
        return super().get_queryset(request).annotate(
            _store_count=Count('organizations')
        )

    @admin.display(description='Дэлгүүр', ordering='_store_count')
    def store_count(self, obj):
        return obj._store_count


class ProductInline(admin.TabularInline):
    model = Product
    extra = 0
    show_change_link = True

    fields = [
        'name',
        'category',
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

    autocomplete_fields = ['category']

    list_select_related = ['category']

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

    class Media:
        # Click the map to fill latitude/longitude (Leaflet + OSM tiles).
        css = {
            'all': [
                'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css',
                'organizations/location_picker.css',
            ]
        }
        js = [
            'https://unpkg.com/leaflet@1.9.4/dist/leaflet.js',
            'organizations/location_picker.js',
        ]

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
        'category',
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
        'category',
        'organization__name',
    ]

    list_select_related = ['organization']

    autocomplete_fields = [
        'organization',
    ]
