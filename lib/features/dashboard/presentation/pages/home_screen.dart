import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:matchpoint/core/api/api_endpoints.dart';
import 'package:matchpoint/features/dashboard/presentation/pages/court_booking_page.dart';
import '../../../bottom_screens/presentation/page/booking_screen.dart';
import '../../../bottom_screens/presentation/page/profile.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 2);
  }

  List<Widget> get _pages => [
        HomePageBody(
          onGoBookings: () => setState(() => _currentIndex = 1),
        ),
        const MoviesScreen(),
        const ProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkTheme = theme.brightness == Brightness.dark;

    final shellBackground = isDarkTheme
        ? const Color.fromARGB(255, 16, 22, 28)
        : const Color.fromARGB(255, 245, 248, 247);
    final appBarColor = isDarkTheme
        ? const Color.fromARGB(255, 24, 30, 36)
        : const Color.fromARGB(255, 20, 110, 80);
    final navBackground = isDarkTheme
        ? const Color.fromARGB(255, 24, 30, 36)
        : Colors.white;
    final selectedColor = isDarkTheme
        ? const Color.fromARGB(255, 126, 215, 181)
        : const Color.fromARGB(255, 20, 110, 80);

    return Scaffold(
      // ✅ UI ONLY: theme background
      backgroundColor: shellBackground,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/matchpoint_logo_final.png',
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            const Text(
              "MatchPoint",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),

      body: _pages[_currentIndex],

      // ✅ UI ONLY: themed bottom nav
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: selectedColor,
        unselectedItemColor: isDarkTheme ? Colors.white60 : Colors.black54,
        backgroundColor: navBackground,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.book_online_rounded), label: 'Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomePageBody extends StatefulWidget {
  final VoidCallback? onGoBookings;

  const HomePageBody({
    super.key,
    this.onGoBookings,
  });

  @override
  State<HomePageBody> createState() => _HomePageBodyState();
}

class _HomePageBodyState extends State<HomePageBody> {
  String _selectedSport = 'All Sports';
  String _priceSort = 'Latest';
  bool _loadingCourts = true;
  String? _courtsError;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sports = const [
    'All Sports',
    'Badminton',
    'Tennis',
    'Pickleball',
    'Futsal',
    'Box Cricket',
  ];

  List<Map<String, dynamic>> _venues = [];

    bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;
    Color get _bgTop => _isDarkTheme
      ? const Color.fromARGB(255, 32, 39, 46)
      : const Color.fromARGB(255, 145, 240, 211);
    Color get _bgBottom => _isDarkTheme
      ? const Color.fromARGB(255, 18, 23, 30)
      : const Color.fromARGB(255, 108, 238, 158);
    Color get _surface =>
      _isDarkTheme ? const Color.fromARGB(255, 27, 36, 44) : Colors.white;
    Color get _textPrimary => _isDarkTheme ? Colors.white : Colors.black;
    Color get _textSecondary => _isDarkTheme ? Colors.white70 : Colors.black54;
    Color get _accent => _isDarkTheme
      ? const Color.fromARGB(255, 126, 215, 181)
      : const Color.fromARGB(255, 7, 151, 138);
    Color get _border => _isDarkTheme ? Colors.white24 : Colors.black12;

  double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();

    if (value is Map<String, dynamic>) {
      final decimal = value[r'$numberDecimal'];
      if (decimal != null) {
        return _parsePrice(decimal);
      }
      final numberDouble = value[r'$numberDouble'];
      if (numberDouble != null) {
        return _parsePrice(numberDouble);
      }
      final numberInt = value[r'$numberInt'];
      if (numberInt != null) {
        return _parsePrice(numberInt);
      }
      final numberLong = value[r'$numberLong'];
      if (numberLong != null) {
        return _parsePrice(numberLong);
      }
    }

    final cleaned = value
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.]'), '')
        .trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  @override
  void initState() {
    super.initState();
    _fetchCourts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourts() async {
    try {
      setState(() {
        _loadingCourts = true;
        _courtsError = null;
      });

      final dio = Dio(
        BaseOptions(
          connectTimeout: ApiEndpoints.connectionTimeout,
          receiveTimeout: ApiEndpoints.receiveTimeout,
        ),
      );

      final response = await dio.get('${ApiEndpoints.serverUrl}/api/courts');
      final data = response.data['data'];

      if (data is! List) {
        throw Exception('Invalid courts response');
      }

      final parsed = data.map<Map<String, dynamic>>((item) {
        final court = item as Map<String, dynamic>;
        final sportsRaw = court['sports'];
        final sports = sportsRaw is List
            ? sportsRaw.map((s) => s.toString()).toList()
            : <String>[];

        final rawImage = (court['image'] ?? '').toString();
        String imageUrl = '';
        if (rawImage.isNotEmpty) {
          imageUrl = rawImage.startsWith('http')
              ? rawImage
              : '${ApiEndpoints.serverUrl}$rawImage';
        }

        return {
          'id': (court['_id'] ?? '').toString(),
          'title': (court['name'] ?? 'Court').toString(),
          'location': (court['location'] ?? 'Unknown location').toString(),
          'description': (court['description'] ?? '').toString(),
          'image': imageUrl,
          'sports': sports,
          'amenities': court['amenities'] is List
              ? (court['amenities'] as List).map((e) => e.toString()).toList()
              : <String>[],
          'price': _parsePrice(court['price']),
          'createdAt': (court['createdAt'] ?? '').toString(),
        };
      }).toList();

      parsed.sort((a, b) {
        final aDate = DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;
      setState(() {
        _venues = parsed;
        _loadingCourts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCourts = false;
        _courtsError = 'Failed to load courts';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredVenues {
    final query = _searchController.text.trim().toLowerCase();

    Iterable<Map<String, dynamic>> filtered = _venues;

    if (_selectedSport != 'All Sports') {
      filtered = filtered.where((venue) {
        final sports = (venue['sports'] as List<String>? ?? []);
        return sports.any((sport) =>
            sport.toLowerCase().trim() == _selectedSport.toLowerCase().trim());
      });
    }

    if (query.isNotEmpty) {
      filtered = filtered.where((venue) {
        final title = (venue['title'] ?? '').toString().toLowerCase();
        final location = (venue['location'] ?? '').toString().toLowerCase();
        final sports = (venue['sports'] as List<String>? ?? []);
        final sportsMatch =
            sports.any((sport) => sport.toLowerCase().contains(query));

        return title.contains(query) || location.contains(query) || sportsMatch;
      });
    }

    final result = filtered.toList();

    if (_priceSort == 'Low to High') {
      result.sort((a, b) {
        final aPrice = (a['price'] as double?) ?? double.infinity;
        final bPrice = (b['price'] as double?) ?? double.infinity;
        return aPrice.compareTo(bPrice);
      });
    } else if (_priceSort == 'High to Low') {
      result.sort((a, b) {
        final aPrice = (a['price'] as double?) ?? double.negativeInfinity;
        final bPrice = (b['price'] as double?) ?? double.negativeInfinity;
        return bPrice.compareTo(aPrice);
      });
    }

    return result;
  }

  Widget _priceSortDropdown() {
    const options = ['Latest', 'Low to High', 'High to Low'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _priceSort,
          borderRadius: BorderRadius.circular(12),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: _textSecondary),
          style: TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _priceSort = value);
          },
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search courts, venues...',
                hintStyle: TextStyle(color: _textSecondary),
                border: InputBorder.none,
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close, size: 18, color: _textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          Icon(Icons.search, color: _textSecondary),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _sportFilterChip(String sport) {
    final isSelected = _selectedSport == sport;

    return GestureDetector(
      onTap: () => setState(() => _selectedSport = sport),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _accent
              : _surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _isDarkTheme
                        ? Colors.black38
                        : const Color.fromARGB(90, 0, 122, 107),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          sport,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? Colors.white
                : _textPrimary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ UI ONLY: matchpoint theme background
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _bgTop,
            _bgBottom,
          ],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    

                    const SizedBox(height: 18),

                    _searchBar(),

                    const SizedBox(height: 16),

                    Text(
                      'Sports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 56,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (int index = 0; index < _sports.length; index++)
                                    Padding(
                                      padding: EdgeInsets.only(
                                        right: index == _sports.length - 1 ? 0 : 10,
                                      ),
                                      child: _sportFilterChip(_sports[index]),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 18),

                    Row(
                      children: [
                        Text(
                          'Available Courts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _textPrimary,
                          ),
                        ),
                        const Spacer(),
                        _priceSortDropdown(),
                      ],
                    ),

                    const SizedBox(height: 10),

                    if (_loadingCourts)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_courtsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _courtsError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      )
                    else if (_filteredVenues.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'No courts available for selected sport.',
                          style: TextStyle(color: _textSecondary),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredVenues.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final v = _filteredVenues[index];
                          return SimpleVenueCard(
                            courtId: (v['id'] ?? '').toString(),
                            title: (v['title'] ?? 'Court').toString(),
                            location: (v['location'] ?? '').toString(),
                            description: (v['description'] ?? '').toString(),
                            imagePath: (v['image'] ?? '').toString(),
                            sports:
                                (v['sports'] as List<String>? ?? const <String>[]),
                            amenities: (v['amenities'] as List<String>? ?? const <String>[]),
                            pricePerHour: v['price'] as double?,
                            isDarkTheme: _isDarkTheme,
                            onViewSlots: () async {
                              final courtId = (v['id'] ?? '').toString();
                              if (courtId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Unable to open court details.'),
                                  ),
                                );
                                return;
                              }

                              final result = await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => CourtBookingPage(
                                    courtId: courtId,
                                    fallbackTitle: (v['title'] ?? 'Court').toString(),
                                  ),
                                ),
                              );

                              if (result == true) {
                                widget.onGoBookings?.call();
                              }
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SimpleVenueCard extends StatelessWidget {
  final String courtId;
  final String title;
  final String location;
  final String description;
  final String imagePath;
  final List<String> sports;
  final List<String> amenities;
  final double? pricePerHour;
  final bool isDarkTheme;
  final VoidCallback onViewSlots;

  const SimpleVenueCard({
    super.key,
    required this.courtId,
    required this.title,
    required this.location,
    required this.description,
    required this.imagePath,
    required this.sports,
    required this.amenities,
    required this.pricePerHour,
    required this.isDarkTheme,
    required this.onViewSlots,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = isDarkTheme
        ? const Color.fromARGB(255, 33, 42, 50)
        : const Color.fromARGB(255, 236, 250, 243);
    final cardBorder = isDarkTheme ? Colors.white24 : const Color.fromARGB(255, 178, 223, 205);
    final primaryText = isDarkTheme ? Colors.white : Colors.black;
    final secondaryText = isDarkTheme ? Colors.white70 : Colors.black54;
    final accent = isDarkTheme
        ? const Color.fromARGB(255, 126, 215, 181)
        : const Color.fromARGB(255, 20, 110, 80);
    final chipBg = isDarkTheme
        ? const Color.fromARGB(255, 39, 49, 58)
        : const Color.fromARGB(255, 227, 248, 241);

    final isNetworkImage = imagePath.startsWith('http');
    final shownSports = sports.take(3).toList();

    return Card(
      color: cardColor,
      shadowColor: isDarkTheme ? Colors.black26 : const Color.fromARGB(70, 16, 94, 67),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 190,
            width: double.infinity,
            child: isNetworkImage
                ? Image.network(
                    imagePath,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDarkTheme ? Colors.white10 : Colors.black12,
                        child: Center(
                          child: Icon(Icons.broken_image, size: 40, color: secondaryText),
                        ),
                      );
                    },
                  )
                : Container(
                    color: isDarkTheme ? Colors.white10 : Colors.black12,
                    child: Center(
                      child: Icon(Icons.image_not_supported, size: 40, color: secondaryText),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on,
                        size: 14, color: secondaryText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (shownSports.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: shownSports
                        .map(
                          (sport) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: chipBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: cardBorder,
                              ),
                            ),
                            child: Text(
                              sport,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: accent,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'From',
                            style: TextStyle(
                              color: secondaryText,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              text: pricePerHour != null
                                  ? '₹${pricePerHour!.toStringAsFixed(0)}'
                                  : 'N/A',
                              style: TextStyle(
                                color: primaryText,
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                              children: pricePerHour != null
                                  ? [
                                      TextSpan(
                                        text: ' /hr',
                                        style: TextStyle(
                                          color: secondaryText,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ]
                                  : const [],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onViewSlots,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                      ),
                      child: const Text(
                        'View Slots',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
