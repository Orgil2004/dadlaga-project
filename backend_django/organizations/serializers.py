
from django.core.exceptions import (
    ValidationError as ModelValidationError
)

from rest_framework import serializers

from .models import Organization, Product


class ProductSerializer(serializers.ModelSerializer):

    class Meta:
        model = Product
        fields = '__all__'


class OrganizationSerializer(serializers.ModelSerializer):

    products = serializers.SerializerMethodField()

    class Meta:
        model = Organization

        # Flutter-ийн өмнөх JSON талбарууд хэвээр
        fields = [
            'id',
            'name',
            'category',
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
        products = obj.products.filter(
            is_active=True
        )

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
