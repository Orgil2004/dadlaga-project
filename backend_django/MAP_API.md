# Map, stores and clothing

Map frontend source lives in `flutter_login/lib/user/map_page.dart`,
`store_catalog.dart` and `store_detail_page.dart`. Existing login, feed,
saved ads, messaging and profile use their existing local data.

From `backend_django` in PowerShell:

```powershell
.\venv\Scripts\python.exe manage.py migrate
.\venv\Scripts\python.exe manage.py seed_map_demo
.\venv\Scripts\python.exe manage.py createsuperuser
.\venv\Scripts\python.exe manage.py runserver 127.0.0.1:8000
```

`seed_map_demo` is optional. It adds three explicitly labelled example shops
and seven example products. It preserves existing rows and can be rerun.

Admin: http://127.0.0.1:8000/admin/

1. Sign in using your Django staff/superuser account. The Flutter demo login
   is separate and has no admin privileges.
2. Add an Organization: name, category, address, latitude, longitude,
   phone and opening hours. Coordinates must be entered together. Shops
   without coordinates do not appear on the map.
3. Add Products and choose their Organization. Enter name, price in MNT,
   category, sizes, colors, description and an optional HTTPS image URL.
   `in_stock` controls availability; `is_active=False` hides the product
   from the public catalogue. Images currently use URLs, not file uploads.
4. Click the refresh button in the map or store details to fetch new inventory.

The admin is the existing global Django staff interface. Individual store
owner accounts and an organization dashboard are outside this map module.

Read endpoints:

| Endpoint | Response |
| --- | --- |
| `GET /api/organizations/` | Shops, coordinates and each shop's active products |
| `GET /api/organizations/{id}/` | One shop with its products |
| `GET /api/organizations/?search=...` | Server-side catalogue search |
| `GET /api/products/?organization={id}` | Active products for one shop |

Example shop payload:

```json
{
  "id": 1,
  "name": "Urban",
  "category": "Хувцас",
  "address": "Сүхбаатар дүүрэг",
  "latitude": 47.9185,
  "longitude": 106.9177,
  "phone": "99112233",
  "opening_hours": "10:00–20:00",
  "description": "Хувцасны дэлгүүр",
  "is_demo": false,
  "products": [
    {
      "id": 1,
      "organization": 1,
      "name": "Хүрэм",
      "category": "Гадуур хувцас",
      "description": "Намрын хүрэм",
      "price": "129000",
      "sizes": "M, L, XL",
      "colors": "Хар, Шаргал",
      "image_url": "",
      "in_stock": true,
      "is_active": true
    }
  ]
}
```

The map searches downloaded public shop/product data and sorts great-circle
distance from the selected point. Default point is central Ulaanbaatar; it
is labelled as such. Device location is requested only on button press and
stays in memory. Browser geolocation needs localhost or HTTPS. The app does
not send the user's coordinates to the catalogue API.

Public requests can read the catalogue. Mutations require authenticated
staff access. Local read-only CORS permits `http://127.0.0.1:5173` and
`http://localhost:5173`; other frontend origins must be supplied explicitly
using the comma-separated `MAP_ALLOWED_ORIGINS` environment variable.
Cross-origin credentialed writes are not enabled.

Tests:

```powershell
.\venv\Scripts\python.exe manage.py test organizations
```

## Categories (Ангилал)

Categories are managed in the admin under **Ангиллууд**: name, icon, sort
order and an active flag. Stores pick one category (a category used by a
store cannot be deleted; make it inactive instead). The Flutter app loads
`GET /api/categories/` for the feed chips and the "Зар нэмэх" form, and falls
back to its built-in list when the API is offline.

| Endpoint | Response |
| --- | --- |
| `GET /api/categories/` | Active categories in admin order, with `icon` and `store_count` |
| `GET /api/organizations/?category=Хувцас` | Stores in one category |
| `GET /api/products/?search=...` | Product search (name, type, colour, store) |

Rules added:

- A store must have a location. The admin store form has a map: click it or
  drag the pin to fill latitude/longitude. New stores then appear on the map
  and in the app's search by name.
- A product (store ad) must have a price of at least 1 ₮. User ads in the app
  also require a price.
- Search splits words; every word must match the store name, category,
  address, description, or an active product's name/type/colour.
