
from django.db.models import Prefetch
from rest_framework import filters, viewsets
from rest_framework.permissions import SAFE_METHODS
from rest_framework.permissions import BasePermission

from .models import Organization, Product
from .serializers import OrganizationSerializer, ProductSerializer


class ReadOnlyOrStaff(BasePermission):
    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return bool(
            request.user
            and request.user.is_authenticated
            and request.user.is_staff
        )


class OrganizationViewSet(viewsets.ModelViewSet):
    queryset = Organization.objects.order_by('id').prefetch_related(
        Prefetch('products', queryset=Product.objects.filter(is_active=True))
    )
    serializer_class = OrganizationSerializer
    permission_classes = [ReadOnlyOrStaff]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'category', 'address', 'products__name', 'products__category']


class ProductViewSet(viewsets.ModelViewSet):
    serializer_class = ProductSerializer
    permission_classes = [ReadOnlyOrStaff]

    def get_queryset(self):
        queryset = Product.objects.select_related('organization').all()
        if not self.request.user.is_staff:
            queryset = queryset.filter(is_active=True)
        organization = self.request.query_params.get('organization')
        if organization:
            try:
                queryset = queryset.filter(organization_id=int(organization))
            except (ValueError, OverflowError):
                return queryset.none()
        return queryset
