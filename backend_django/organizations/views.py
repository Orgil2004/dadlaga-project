from django.db.models import Count, Prefetch, Q

from rest_framework import viewsets
from rest_framework.permissions import BasePermission, SAFE_METHODS

from .models import Category, Organization, Product
from .serializers import (
    CategorySerializer,
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


def search_words(request):
    """Split ?search= into words; every word must match somewhere."""
    return request.query_params.get('search', '').split()[:8]


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """Active categories, managed in the Django admin."""

    serializer_class = CategorySerializer
    pagination_class = None

    def get_queryset(self):
        return Category.objects.filter(is_active=True).annotate(
            store_count=Count('organizations', distinct=True)
        ).order_by('sort_order', 'name')


class OrganizationViewSet(viewsets.ModelViewSet):

    serializer_class = OrganizationSerializer
    permission_classes = [ReadOnlyOrStaff]

    queryset = Organization.objects.all()

    def get_queryset(self):
        queryset = Organization.objects.select_related(
            'category'
        ).prefetch_related(
            Prefetch(
                'products',
                queryset=Product.objects.filter(
                    is_active=True
                )
            )
        ).order_by('id')

        for word in search_words(self.request):
            # Store name, category, address, or any visible product.
            queryset = queryset.filter(
                Q(name__icontains=word)
                | Q(category__name__icontains=word)
                | Q(address__icontains=word)
                | Q(description__icontains=word)
                | Q(
                    products__is_active=True,
                    products__name__icontains=word,
                )
                | Q(
                    products__is_active=True,
                    products__category__icontains=word,
                )
                | Q(
                    products__is_active=True,
                    products__colors__icontains=word,
                )
            )

        category = self.request.query_params.get(
            'category', ''
        ).strip()

        if category:
            queryset = queryset.filter(
                category__name__iexact=category
            )

        return queryset.distinct()


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

        for word in search_words(self.request):
            queryset = queryset.filter(
                Q(name__icontains=word)
                | Q(category__icontains=word)
                | Q(description__icontains=word)
                | Q(colors__icontains=word)
                | Q(organization__name__icontains=word)
            )

        return queryset
