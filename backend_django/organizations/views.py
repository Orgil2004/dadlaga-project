
from django.db.models import Prefetch, Q

from rest_framework import viewsets
from rest_framework.permissions import BasePermission, SAFE_METHODS

from .models import Organization, Product
from .serializers import (
    OrganizationSerializer,
    ProductSerializer,
)


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

    serializer_class = OrganizationSerializer
    permission_classes = [ReadOnlyOrStaff]

    queryset = Organization.objects.all()

    def get_queryset(self):
        queryset = Organization.objects.prefetch_related(
            Prefetch(
                'products',
                queryset=Product.objects.filter(
                    is_active=True
                )
            )
        ).order_by('id')

        search = self.request.query_params.get(
            'search', ''
        ).strip()

        category = self.request.query_params.get(
            'category', ''
        ).strip()

        if search:
            queryset = queryset.filter(
                Q(name__icontains=search)
                | Q(category__icontains=search)
                | Q(address__icontains=search)
                | Q(description__icontains=search)
                | Q(products__name__icontains=search)
            ).distinct()

        if category:
            queryset = queryset.filter(
                category__iexact=category
            )

        return queryset


class ProductViewSet(viewsets.ModelViewSet):

    serializer_class = ProductSerializer
    permission_classes = [ReadOnlyOrStaff]

    def get_queryset(self):
        queryset = Product.objects.select_related(
            'organization'
        ).all()

        if not (
            self.request.user.is_authenticated
            and self.request.user.is_staff
        ):
            queryset = queryset.filter(is_active=True)

        organization_id = self.request.query_params.get(
            'organization'
        )

        if organization_id:
            try:
                queryset = queryset.filter(
                    organization_id=int(organization_id)
                )
            except (ValueError, OverflowError):
                return queryset.none()

        return queryset
