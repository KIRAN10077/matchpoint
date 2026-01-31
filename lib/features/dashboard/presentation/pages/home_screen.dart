import 'package:flutter/material.dart';
import '../../../bottom_screens/presentation/page/booking_screen.dart';
import '../../../bottom_screens/presentation/page/profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePageBody(),
    MoviesScreen(),
    ProfileScreen(),
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

class HomePageBody extends StatelessWidget {
  const HomePageBody({super.key});

  Widget _searchBar() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: const [
          SizedBox(width: 16),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search courts, venues...',
                hintStyle: TextStyle(color: Colors.black45),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Icon(Icons.search, color: Colors.black54),
          SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _sportCard({
    required String title,
    required IconData icon,
  }) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 38, color: const Color.fromARGB(255, 20, 110, 80)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ UI ONLY content: sports + venue cards
    final venues = const [
      {
        'title': 'Hoops',
        'location': 'Thamel, Kathmandu',
        'image': 'assets/images/hoops.png'
      },
      {
        'title': 'Surya Futsal',
        'location': 'Kalimati, Kathmandu',
        'image': 'assets/images/surya_futsal.png'
      },
      {
        'title': 'ABC Court',
        'location': 'Baneshwor',
        'image': 'assets/images/abc_court.jpg'
      },
      {
        'title': 'XYZ Arena',
        'location': 'Lalitpur',
        'image': 'assets/images/xyz_arena.jpg'
      },
      {
        'title': 'Prime Court',
        'location': 'Bhaktapur',
        'image': 'assets/images/prime_court.jpg'
      },
      {
        'title': 'City Turf',
        'location': 'Koteshwor',
        'image': 'assets/images/city_turf.jpg'
      },
    ];

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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

              LayoutBuilder(
                builder: (context, constraints) {
                  final isTablet = constraints.maxWidth >= 600;

                  return SizedBox(
                    height: 130,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            isTablet ? (constraints.maxWidth - 90 * 4) / 2 : 0,
                      ),
                      children: [
                        _sportCard(title: 'Football', icon: Icons.sports_soccer),
                        _sportCard(title: 'Cricket', icon: Icons.sports_cricket),
                        _sportCard(
                            title: 'Basketball',
                            icon: Icons.sports_basketball),
                        _sportCard(title: 'Swimming', icon: Icons.pool),
                        _sportCard(
                            title: 'Badminton', icon: Icons.sports_tennis),
                        _sportCard(title: 'Tennis', icon: Icons.sports_tennis),
                        _sportCard(
                            title: 'Volleyball', icon: Icons.sports_volleyball),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              const Text(
                'Nearby Venues',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: venues.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width >= 600 ? 2 : 1,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.6,
                ),
                itemBuilder: (context, index) {
                  final v = venues[index];
                  return SimpleVenueCard(
                    title: v['title']!,
                    location: v['location']!,
                    imagePath: v['image']!,
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class SimpleVenueCard extends StatelessWidget {
  final String title;
  final String location;
  final String imagePath;

  const SimpleVenueCard({
    super.key,
    required this.title,
    required this.location,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(
            child: Image.asset(
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
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: Colors.black45),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.ellipsis,
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
