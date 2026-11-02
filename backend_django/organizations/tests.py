from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.test import TestCase
from rest_framework.test import APIClient

from .models import Organization, Product


class StoreMapAPITests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.store = Organization.objects.create(name='Urban', category='Хувцас', address='Төв', latitude=47.9185, longitude=106.9177)
        cls.other = Organization.objects.create(name='Step', category='Гутал', address='Баянзүрх', latitude=47.92, longitude=106.94)
        cls.product = Product.objects.create(organization=cls.store, name='Хүрэм', price=129000, sizes='M, L', colors='Хар')
        Product.objects.create(organization=cls.store, name='Нуугдсан бараа', price=1000, is_active=False)
        Product.objects.create(organization=cls.other, name='Кет', price=159000)
        cls.staff = get_user_model().objects.create_user(username='test-staff', password='test-password', is_staff=True)

    def setUp(self):
        self.client = APIClient()

    def test_public_store_contains_only_its_visible_products(self):
        response = self.client.get(f'/api/organizations/{self.store.pk}/')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['latitude'], 47.9185)
        self.assertEqual([p['name'] for p in response.data['products']], ['Хүрэм'])
        self.assertEqual(response.data['products'][0]['sizes'], 'M, L')

    def test_store_search_by_clothing_name(self):
        response = self.client.get('/api/organizations/', {'search': 'Хүрэм'})
        self.assertEqual([store['name'] for store in response.data], ['Urban'])

    def test_public_cannot_modify_store_or_inventory(self):
        self.assertIn(self.client.post('/api/products/', {'name': 'Бараа'}).status_code, [401, 403])
        self.assertIn(self.client.patch(f'/api/organizations/{self.store.pk}/', {'name': 'Changed'}).status_code, [401, 403])
        self.assertEqual(self.client.get('/api/products/', {'organization': self.store.pk}).data[0]['name'], 'Хүрэм')
        self.assertEqual(len(self.client.get('/api/products/', {'organization': self.store.pk}).data), 1)

    def test_staff_added_product_is_visible_in_store_immediately(self):
        self.client.force_authenticate(user=self.staff)
        response = self.client.post('/api/products/', {
            'organization': self.store.pk, 'name': 'Шинэ футболк', 'price': '45000', 'sizes': 'S, M',
        }, format='json')
        self.assertEqual(response.status_code, 201)
        self.client.force_authenticate(user=None)
        names = [product['name'] for product in self.client.get(f'/api/organizations/{self.store.pk}/').data['products']]
        self.assertIn('Шинэ футболк', names)

    def test_coordinate_validation(self):
        self.client.force_authenticate(user=self.staff)
        data = {'name': 'Invalid', 'category': 'Хувцас', 'address': 'Төв', 'latitude': 100, 'longitude': 106}
        self.assertEqual(self.client.post('/api/organizations/', data).status_code, 400)
        data['latitude'] = 47
        del data['longitude']
        self.assertEqual(self.client.post('/api/organizations/', data).status_code, 400)

    def test_non_finite_coordinates_are_rejected(self):
        self.client.force_authenticate(user=self.staff)
        response = self.client.post('/api/organizations/', {
            'name': 'Invalid', 'category': 'Хувцас', 'address': 'Төв',
            'latitude': 'NaN', 'longitude': 106,
        })
        self.assertEqual(response.status_code, 400)

    def test_cors_is_limited_to_allowed_read_origins(self):
        allowed = self.client.get('/api/organizations/', HTTP_ORIGIN='http://127.0.0.1:5173')
        self.assertEqual(allowed['Access-Control-Allow-Origin'], 'http://127.0.0.1:5173')
        blocked = self.client.get('/api/organizations/', HTTP_ORIGIN='https://untrusted.example')
        self.assertNotIn('Access-Control-Allow-Origin', blocked)
        self.assertNotIn('Access-Control-Allow-Credentials', allowed)

    def test_seed_is_repeatable_without_overwriting_inventory(self):
        call_command('seed_map_demo', verbosity=0)
        count = Product.objects.count()
        call_command('seed_map_demo', verbosity=0)
        self.assertEqual(Product.objects.count(), count)
        self.assertEqual(Organization.objects.filter(is_demo=True).count(), 3)
