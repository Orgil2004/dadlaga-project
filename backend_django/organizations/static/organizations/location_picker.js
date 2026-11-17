// Organization admin: pick the store location on a map.
// Clicking (or dragging the pin) fills the latitude/longitude fields,
// and typing coordinates moves the pin.
(function () {
  'use strict';

  function init() {
    var lat = document.getElementById('id_latitude');
    var lng = document.getElementById('id_longitude');
    if (!lat || !lng || typeof L === 'undefined') return;

    var row = lng.closest('.form-row') || lng.parentElement;
    var box = document.createElement('div');
    box.className = 'location-picker';
    box.innerHTML =
      '<p class="help">Газрын зураг дээр дарж эсвэл тэмдэгтийг чирж ' +
      'дэлгүүрийн байршлыг сонгоно уу. Байршилгүй дэлгүүр аппын газрын ' +
      'зураг дээр гарахгүй.</p><div class="location-picker__map"></div>';
    row.parentNode.insertBefore(box, row.nextSibling);

    var start = [parseFloat(lat.value), parseFloat(lng.value)];
    var hasPoint = isFinite(start[0]) && isFinite(start[1]);
    var map = L.map(box.querySelector('.location-picker__map')).setView(
      hasPoint ? start : [47.9185, 106.9177],
      hasPoint ? 16 : 12
    );
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(map);

    var marker = null;
    function place(point, fill) {
      if (!marker) {
        marker = L.marker(point, { draggable: true }).addTo(map);
        marker.on('dragend', function () { place(marker.getLatLng(), true); });
      } else {
        marker.setLatLng(point);
      }
      if (fill) {
        lat.value = point.lat.toFixed(6);
        lng.value = point.lng.toFixed(6);
      }
    }
    if (hasPoint) place(L.latLng(start[0], start[1]), false);
    map.on('click', function (e) { place(e.latlng, true); });

    function typed() {
      var a = parseFloat(lat.value), b = parseFloat(lng.value);
      if (isFinite(a) && isFinite(b) && Math.abs(a) <= 85 && Math.abs(b) <= 180) {
        place(L.latLng(a, b), false);
        map.panTo([a, b]);
      }
    }
    lat.addEventListener('change', typed);
    lng.addEventListener('change', typed);
    // Fieldsets can render collapsed/hidden at first; fix tile sizing.
    setTimeout(function () { map.invalidateSize(); }, 300);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
