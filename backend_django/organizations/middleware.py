from django.conf import settings
from django.http import HttpResponse
from django.utils.cache import patch_vary_headers


class MapReadCorsMiddleware:
    """Allow the local Flutter map to read the public API, without credentials."""

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        allowed = (
            request.path.startswith('/api/')
            and request.headers.get('Origin') in settings.MAP_ALLOWED_ORIGINS
            and request.method in ('GET', 'HEAD', 'OPTIONS')
        )
        response = HttpResponse(status=204) if allowed and request.method == 'OPTIONS' else self.get_response(request)
        if allowed:
            response['Access-Control-Allow-Origin'] = request.headers['Origin']
            response['Access-Control-Allow-Methods'] = 'GET, HEAD, OPTIONS'
            patch_vary_headers(response, ['Origin'])
        return response
