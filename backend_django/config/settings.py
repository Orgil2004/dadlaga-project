
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# =====================================
# SECURITY SETTINGS
# =====================================

SECRET_KEY = os.environ.get(
    'SECRET_KEY',
    'django-insecure-local-development-only'
)

DEBUG = os.environ.get(
    'DEBUG',
    'True'
).lower() == 'true'

ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '[::1]',
]

# Render hostname
RENDER_EXTERNAL_HOSTNAME = os.environ.get(
    'RENDER_EXTERNAL_HOSTNAME'
)

if RENDER_EXTERNAL_HOSTNAME:
    ALLOWED_HOSTS.append(RENDER_EXTERNAL_HOSTNAME)

# =====================================
# INSTALLED APPS
# =====================================

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Django REST Framework
    'rest_framework',

    # CORS
    'corsheaders',

    # Organization API
    'organizations',
]

# =====================================
# MIDDLEWARE
# =====================================

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',

    # Flutter Web CORS
    'corsheaders.middleware.CorsMiddleware',

    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# =====================================
# URL CONFIGURATION
# =====================================

ROOT_URLCONF = 'config.urls'

# =====================================
# TEMPLATES
# =====================================

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'

# =====================================
# DATABASE
# =====================================

# Local SQLite database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# =====================================
# PASSWORD VALIDATION
# =====================================

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME':
        'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME':
        'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME':
        'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME':
        'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# =====================================
# LANGUAGE AND TIME
# =====================================

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'Asia/Ulaanbaatar'

USE_I18N = True

USE_TZ = True

# =====================================
# STATIC FILES
# =====================================

STATIC_URL = '/static/'

STATIC_ROOT = BASE_DIR / 'staticfiles'

# =====================================
# DJANGO REST FRAMEWORK
# =====================================

REST_FRAMEWORK = {
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
        'rest_framework.renderers.BrowsableAPIRenderer',
    ],
}

# =====================================
# FLUTTER WEB CORS SETTINGS
# =====================================

# Local Flutter Web development
CORS_ALLOWED_ORIGIN_REGEXES = [
    r'^http://localhost:\d+$',
    r'^http://127\.0\.0\.1:\d+$',
]

# Production Flutter Web origin
FRONTEND_URL = os.environ.get('FRONTEND_URL')

if FRONTEND_URL:
    CORS_ALLOWED_ORIGINS = [
        FRONTEND_URL.rstrip('/')
    ]

# Allow standard HTTP methods
CORS_ALLOW_METHODS = [
    'DELETE',
    'GET',
    'OPTIONS',
    'PATCH',
    'POST',
    'PUT',
]

CORS_ALLOW_HEADERS = [
    'accept',
    'authorization',
    'content-type',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]

CORS_ALLOW_CREDENTIALS = False

# =====================================
# EMAIL SETTINGS
# =====================================

EMAIL_BACKEND = (
    'django.core.mail.backends.console.EmailBackend'
)

DEFAULT_FROM_EMAIL = 'noreply@haanave.local'
