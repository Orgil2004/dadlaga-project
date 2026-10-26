
from rest_framework import viewsets
from rest_framework.permissions import IsAdminUser, SAFE_METHODS
from rest_framework.permissions import BasePermission

from .models import Organization
from .serializers import OrganizationSerializer


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
    queryset = Organization.objects.all()
    serializer_class = OrganizationSerializer
    permission_classes = [ReadOnlyOrStaff]
