
from django.contrib import admin
from django.urls import path, include

from rest_framework.routers import DefaultRouter

from organizations.views import (
    OrganizationViewSet,
    ProductViewSet,
)

router = DefaultRouter()

router.register(
    r'organizations',
    OrganizationViewSet,
    basename='organization'
)

router.register(
    r'products',
    ProductViewSet,
    basename='product'
)

urlpatterns = [
    path('admin/', admin.site.urls),

    path('api/', include(router.urls)),

    path(
        'api-auth/',
        include('rest_framework.urls')
    ),

    path('', include(router.urls)),
]
