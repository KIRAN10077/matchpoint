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
    return Scaffold(
      // ✅ UI ONLY: theme background
      backgroundColor: const Color.fromARGB(255, 245, 248, 247),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 110, 80),
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
        selectedItemColor: const Color.fromARGB(255, 20, 110, 80),
        unselectedItemColor: Colors.black54,
        backgroundColor: Colors.white,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _priceSort,
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: const TextStyle(
            color: Colors.black87,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black12),
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
                hintStyle: const TextStyle(color: Colors.black45),
                border: InputBorder.none,
                isDense: true,
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),
          ),
          const Icon(Icons.search, color: Colors.black54),
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
              ? const Color.fromARGB(255, 7, 151, 138)
              : const Color.fromARGB(255, 240, 242, 243),
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color.fromARGB(90, 0, 122, 107),
                    blurRadius: 10,
                    offset: Offset(0, 4),
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
                : const Color.fromARGB(255, 28, 53, 84),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // ✅ UI ONLY: matchpoint theme background
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 145, 240, 211),
            Color.fromARGB(255, 108, 238, 158),
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

                    const Text(
                      'Sports',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
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
                        const Text(
                          'Available Courts',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
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
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text('No courts available for selected sport.'),
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
    required this.onViewSlots,
  });

  @override
  Widget build(BuildContext context) {
    final isNetworkImage = imagePath.startsWith('http');
    final shownSports = sports.take(3).toList();

    return Card(
      color: const Color.fromARGB(255, 236, 250, 243),
      shadowColor: const Color.fromARGB(70, 16, 94, 67),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color.fromARGB(255, 178, 223, 205)),
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
                        color: Colors.black12,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 40),
                        ),
                      );
                    },
                  )
                : Container(
                    color: Colors.black12,
                    child: const Center(
                      child: Icon(Icons.image_not_supported, size: 40),
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
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
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
                              color: const Color.fromARGB(255, 227, 248, 241),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color.fromARGB(255, 130, 224, 201),
                              ),
                            ),
                            child: Text(
                              sport,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color.fromARGB(255, 20, 110, 80),
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
                          const Text(
                            'From',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          RichText(
                            text: TextSpan(
                              text: pricePerHour != null
                                  ? '₹${pricePerHour!.toStringAsFixed(0)}'
                                  : 'N/A',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 9, 32, 68),
                                fontSize: 34,
                                fontWeight: FontWeight.w700,
                              ),
                              children: pricePerHour != null
                                  ? const [
                                      TextSpan(
                                        text: ' /hr',
                                        style: TextStyle(
                                          color: Colors.black54,
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
                        backgroundColor: const Color.fromARGB(255, 7, 151, 138),
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
