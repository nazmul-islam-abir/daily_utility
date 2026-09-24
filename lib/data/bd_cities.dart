/// Shared Bangladesh city catalog used by the Prayer screen and the
/// Profile screen. Keys are stable slugs; values carry both Bangla and
/// English display labels and their lat/lng.
class BdCity {
  final String bn;
  final String en;
  final double lat;
  final double lng;
  const BdCity(this.bn, this.en, this.lat, this.lng);
}

const Map<String, BdCity> kBdCities = {
  'dhaka': BdCity('ঢাকা', 'Dhaka', 23.8103, 90.4125),
  'chattogram': BdCity('চট্টগ্রাম', 'Chattogram', 22.3569, 91.7832),
  'sylhet': BdCity('সিলেট', 'Sylhet', 24.8949, 91.8687),
  'khulna': BdCity('খুলনা', 'Khulna', 22.8456, 89.5403),
  'rajshahi': BdCity('রাজশাহী', 'Rajshahi', 24.3745, 88.6042),
  'rangpur': BdCity('রংপুর', 'Rangpur', 25.7439, 89.2752),
  'barishal': BdCity('বরিশাল', 'Barishal', 22.7010, 90.3535),
  'mymensingh': BdCity('ময়মনসিংহ', 'Mymensingh', 24.7471, 90.4203),
};
