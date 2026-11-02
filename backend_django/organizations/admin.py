from django.contrib import admin
from .models import Organization, Product


class ProductInline(admin.TabularInline):
    model = Product
    extra = 0
    show_change_link = True
    fields = ['name', 'price', 'sizes', 'colors', 'in_stock', 'is_active']


@admin.register(Organization)
class OrganizationAdmin(admin.ModelAdmin):
    list_display = ['name', 'category', 'address', 'latitude', 'longitude', 'is_demo']
    search_fields = ['name', 'address']
    list_filter = ['category', 'is_demo']
    inlines = [ProductInline]


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ['name', 'organization', 'price', 'in_stock', 'is_active']
    list_filter = ['organization', 'category', 'in_stock', 'is_active']
    search_fields = ['name', 'organization__name']
    autocomplete_fields = ['organization']
