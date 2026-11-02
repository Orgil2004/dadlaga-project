from django.core.management.base import BaseCommand
from django.db import transaction

from organizations.models import Organization, Product


class Command(BaseCommand):
    help = 'Add clearly labelled example stores and clothing without replacing existing data.'

    @transaction.atomic
    def handle(self, *args, **options):
        samples = [
            ('Urban хувцас — Жишээ', 'Хувцас', 'Сүхбаатар дүүрэг, төв талбайн баруун тал', 47.9189, 106.9135,
             [('Oversize футболк', 'Футболк', 45000, 'S, M, L, XL', 'Хар, Цагаан'),
              ('Намрын хүрэм', 'Гадуур хувцас', 129000, 'M, L, XL', 'Шаргал, Хар'),
              ('Жийнсэн өмд', 'Өмд', 89000, '28, 30, 32, 34', 'Цэнхэр')]),
            ('Step гутал — Жишээ', 'Гутал', 'Чингэлтэй дүүрэг, 4-р хороо', 47.924, 106.908,
             [('Өдөр тутмын кет', 'Кет', 159000, '37, 38, 39, 40, 41', 'Цагаан'),
              ('Намрын гутал', 'Гутал', 189000, '38, 39, 40, 41, 42', 'Хар, Бор')]),
            ('Active спорт — Жишээ', 'Спорт', 'Баянзүрх дүүрэг, 6-р хороо', 47.918, 106.945,
             [('Спорт цамц', 'Спорт хувцас', 69000, 'S, M, L', 'Саарал, Хар'),
              ('Бэлтгэлийн өмд', 'Өмд', 79000, 'S, M, L, XL', 'Хар')]),
        ]
        for name, category, address, latitude, longitude, products in samples:
            store, _ = Organization.objects.get_or_create(name=name, is_demo=True, defaults={
                'category': category, 'address': address, 'latitude': latitude, 'longitude': longitude,
                'opening_hours': '10:00–20:00 (жишээ)',
                'description': 'Туршилтын дэлгүүр. Байршил, бараа, үнэ нь жишээ өгөгдөл юм.',
            })
            for title, product_category, price, sizes, colors in products:
                Product.objects.get_or_create(organization=store, name=title, defaults={
                    'category': product_category, 'price': price, 'sizes': sizes, 'colors': colors,
                    'description': 'Загварын туршилтад зориулсан жишээ бараа.',
                })
        self.stdout.write(self.style.SUCCESS('Example stores and clothing are ready (3 stores).'))
