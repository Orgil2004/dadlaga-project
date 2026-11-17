
from django.core.exceptions import (
    ValidationError as ModelValidationError
)

from rest_framework import serializers

from .models import Category, Organization, Product


class CategorySerializer(serializers.ModelSerializer):

    store_count = serializers.IntegerField(read_only=True, default=0)

    class Meta:
        model = Category
        fields = ['id', 'name', 'icon', 'sort_order', 'store_count']


class ProductSerializer(serializers.ModelSerializer):

    class Meta:
        model = Product
        fields = '__all__'


class OrganizationSerializer(serializers.ModelSerializer):

    products = serializers.SerializerMethodField()

    # Flutter reads the category as its name, so keep it a plain string.
    category = serializers.SlugRelatedField(
        slug_field='name',
        queryset=Category.objects.all()
    )

    category_icon = serializers.CharField(
        source='category.icon',
        read_only=True
    )

    class Meta:
        model = Organization

        # Flutter-ийн өмнөх JSON талбарууд хэвээр
        fields = [
            'id',
            'name',
            'category',
            'category_icon',
            'address',
            'phone',
            'description',
            'latitude',
            'longitude',
            'opening_hours',
            'is_demo',
            'products',
        ]

        read_only_fields = [
            'id',
            'products',
        ]

    def get_products(self, obj):
        # The view prefetches only active products; .all() reuses that cache.
        products = obj.products.all()

        return ProductSerializer(
            products,
            many=True
        ).data

    def validate(self, attrs):
        latitude = attrs.get(
            'latitude',
            getattr(self.instance, 'latitude', None)
        )

        longitude = attrs.get(
            'longitude',
            getattr(self.instance, 'longitude', None)
        )

        try:
            Organization(
                latitude=latitude,
                longitude=longitude
            ).clean()

        except ModelValidationError as error:
            raise serializers.ValidationError(
                error.message_dict
                if hasattr(error, 'message_dict')
                else error.messages
            )

        return attrs
