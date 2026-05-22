/// Country data for country-code pickers in the app.
/// Emoji flags render natively on web, Android, and iOS.
class Country {
  final String name;
  final String flag;
  final String dialCode;
  final String code;
  const Country({
    required this.name,
    required this.flag,
    required this.dialCode,
    required this.code,
  });
}

const List<Country> kCountries = [
  Country(name: 'United States', flag: '🇺🇸', dialCode: '+1', code: 'US'),
  Country(name: 'United Kingdom', flag: '🇬🇧', dialCode: '+44', code: 'GB'),
  Country(name: 'Pakistan', flag: '🇵🇰', dialCode: '+92', code: 'PK'),
  Country(name: 'Canada', flag: '🇨🇦', dialCode: '+1', code: 'CA'),
  Country(name: 'Australia', flag: '🇦🇺', dialCode: '+61', code: 'AU'),
  Country(name: 'India', flag: '🇮🇳', dialCode: '+91', code: 'IN'),
  Country(name: 'UAE', flag: '🇦🇪', dialCode: '+971', code: 'AE'),
  Country(name: 'Saudi Arabia', flag: '🇸🇦', dialCode: '+966', code: 'SA'),
  Country(name: 'Germany', flag: '🇩🇪', dialCode: '+49', code: 'DE'),
  Country(name: 'France', flag: '🇫🇷', dialCode: '+33', code: 'FR'),
  Country(name: 'Italy', flag: '🇮🇹', dialCode: '+39', code: 'IT'),
  Country(name: 'Spain', flag: '🇪🇸', dialCode: '+34', code: 'ES'),
  Country(name: 'Netherlands', flag: '🇳🇱', dialCode: '+31', code: 'NL'),
  Country(name: 'Sweden', flag: '🇸🇪', dialCode: '+46', code: 'SE'),
  Country(name: 'Norway', flag: '🇳🇴', dialCode: '+47', code: 'NO'),
  Country(name: 'Denmark', flag: '🇩🇰', dialCode: '+45', code: 'DK'),
  Country(name: 'Switzerland', flag: '🇨🇭', dialCode: '+41', code: 'CH'),
  Country(name: 'Turkey', flag: '🇹🇷', dialCode: '+90', code: 'TR'),
  Country(name: 'China', flag: '🇨🇳', dialCode: '+86', code: 'CN'),
  Country(name: 'Japan', flag: '🇯🇵', dialCode: '+81', code: 'JP'),
  Country(name: 'South Korea', flag: '🇰🇷', dialCode: '+82', code: 'KR'),
  Country(name: 'Singapore', flag: '🇸🇬', dialCode: '+65', code: 'SG'),
  Country(name: 'Malaysia', flag: '🇲🇾', dialCode: '+60', code: 'MY'),
  Country(name: 'Indonesia', flag: '🇮🇩', dialCode: '+62', code: 'ID'),
  Country(name: 'Philippines', flag: '🇵🇭', dialCode: '+63', code: 'PH'),
  Country(name: 'Bangladesh', flag: '🇧🇩', dialCode: '+880', code: 'BD'),
  Country(name: 'Nigeria', flag: '🇳🇬', dialCode: '+234', code: 'NG'),
  Country(name: 'Egypt', flag: '🇪🇬', dialCode: '+20', code: 'EG'),
  Country(name: 'South Africa', flag: '🇿🇦', dialCode: '+27', code: 'ZA'),
  Country(name: 'Kenya', flag: '🇰🇪', dialCode: '+254', code: 'KE'),
  Country(name: 'Brazil', flag: '🇧🇷', dialCode: '+55', code: 'BR'),
  Country(name: 'Mexico', flag: '🇲🇽', dialCode: '+52', code: 'MX'),
  Country(name: 'Argentina', flag: '🇦🇷', dialCode: '+54', code: 'AR'),
  Country(name: 'Colombia', flag: '🇨🇴', dialCode: '+57', code: 'CO'),
  Country(name: 'Portugal', flag: '🇵🇹', dialCode: '+351', code: 'PT'),
  Country(name: 'Ireland', flag: '🇮🇪', dialCode: '+353', code: 'IE'),
  Country(name: 'New Zealand', flag: '🇳🇿', dialCode: '+64', code: 'NZ'),
  Country(name: 'Russia', flag: '🇷🇺', dialCode: '+7', code: 'RU'),
  Country(name: 'Poland', flag: '🇵🇱', dialCode: '+48', code: 'PL'),
  Country(name: 'Ukraine', flag: '🇺🇦', dialCode: '+380', code: 'UA'),
];
