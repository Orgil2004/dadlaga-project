
from django.core.exceptions import ValidationError as ModelValidationError
from rest_framework import serializers
from .models import Organization, Product


class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = '__all__'


class OrganizationSerializer(serializers.ModelSerializer):
    products = ProductSerializer(many=True, read_only=True)

    class Meta:
        model = Organization
        fields = '__all__'

    def validate(self, attrs):
        latitude = attrs.get('latitude', getattr(self.instance, 'latitude', None))
        longitude = attrs.get('longitude', getattr(self.instance, 'longitude', None))
        try:
            Organization(latitude=latitude, longitude=longitude).clean()
        except ModelValidationError as error:
            raise serializers.ValidationError(error.messages) from error
        return attrs
