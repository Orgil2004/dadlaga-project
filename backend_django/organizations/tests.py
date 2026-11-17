from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.test import TestCase
from rest_framework.test import APIClient

from .models import Category, Organization, Product


class StoreMapAPITests(TestCase):
    @classmethod
    def setUpTestData(cls):
        cls.clothes, _ = Category.objects.get_or_create(name='Хувцас')
        cls.shoes, _ = Category.objects.get_or_create(name='Гутал')
        cls.store = Organization.objects.create(name='Urban', category=cls.clothes, address='Төв', latitude=47.9185, longitude=106.9177)
        cls.other = Organization.objects.create(name='Step', category=cls.shoes, address='Баянзүрх', latitude=47.92, longitude=106.94)
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

    def test_categories_endpoint_lists_active_categories_in_order(self):
        Category.objects.create(name='Нуугдсан', is_active=False)
        Category.objects.create(name='Эхнийх', sort_order=0)
        data = self.client.get('/api/categories/').data
        names = [row['name'] for row in data]
        self.assertEqual(names[0], 'Эхнийх')
        self.assertNotIn('Нуугдсан', names)
        self.assertEqual(next(r for r in data if r['name'] == 'Хувцас')['store_count'], 1)

    def test_store_payload_keeps_category_as_name(self):
        data = self.client.get(f'/api/organizations/{self.store.pk}/').data
        self.assertEqual(data['category'], 'Хувцас')
        self.assertIn('category_icon', data)

    def test_new_store_appears_in_search_and_category_filter(self):
        self.client.force_authenticate(user=self.staff)
        response = self.client.post('/api/organizations/', {
            'name': 'Nomin Shoes', 'category': 'Гутал', 'address': 'Хан-Уул',
            'latitude': 47.89, 'longitude': 106.9,
        }, format='json')
        self.assertEqual(response.status_code, 201, response.data)
        self.client.force_authenticate(user=None)
        found = self.client.get('/api/organizations/', {'search': 'nomin'}).data
        self.assertEqual([s['name'] for s in found], ['Nomin Shoes'])
        by_category = self.client.get('/api/organizations/', {'category': 'Гутал'}).data
        self.assertIn('Nomin Shoes', [s['name'] for s in by_category])

    def test_store_requires_existing_category_and_location(self):
        self.client.force_authenticate(user=self.staff)
        base = {'name': 'X', 'address': 'Төв', 'latitude': 47.9, 'longitude': 106.9}
        self.assertEqual(self.client.post('/api/organizations/', {**base, 'category': 'Байхгүй'}).status_code, 400)
        no_point = {'name': 'X', 'address': 'Төв', 'category': 'Хувцас'}
        self.assertEqual(self.client.post('/api/organizations/', no_point).status_code, 400)

    def test_multi_word_search_matches_across_fields(self):
        names = [s['name'] for s in self.client.get('/api/organizations/', {'search': 'Urban Хар'}).data]
        self.assertEqual(names, ['Urban'])
        self.assertEqual(self.client.get('/api/organizations/', {'search': 'Urban Кет'}).data, [])

    def test_hidden_product_does_not_make_store_searchable(self):
        self.assertEqual(self.client.get('/api/organizations/', {'search': 'Нуугдсан'}).data, [])

    def test_product_price_is_required_and_positive(self):
        self.client.force_authenticate(user=self.staff)
        for price in [None, '0', '-5']:
            body = {'organization': self.store.pk, 'name': 'Үнэгүй'}
            if price is not None:
                body['price'] = price
            self.assertEqual(self.client.post('/api/products/', body, format='json').status_code, 400, price)

    def test_category_in_use_cannot_be_deleted(self):
        from django.db.models import ProtectedError
        with self.assertRaises(ProtectedError):
            self.clothes.delete()

    def test_admin_pages_render(self):
        admin = get_user_model().objects.create_superuser('root', 'r@example.com', 'pw')
        self.client.force_login(admin)
        for url in ['/admin/organizations/category/', '/admin/organizations/category/add/',
                    '/admin/organizations/organization/add/',
                    f'/admin/organizations/organization/{self.store.pk}/change/']:
            response = self.client.get(url)
            self.assertEqual(response.status_code, 200, url)
        self.assertContains(self.client.get('/admin/organizations/organization/add/'), 'location_picker.js')
