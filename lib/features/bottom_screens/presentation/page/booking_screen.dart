import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:matchpoint/core/api/api_endpoints.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AppTheme {
  static const white = Color(0xFFFFFFFF);
  static const textPrimary = Color(0xFF0B2239);
  static const textSecondary = Color(0xFF5B6777);
  static const pageTop = Color.fromARGB(255, 145, 240, 211);
  static const pageBottom = Color.fromARGB(255, 108, 238, 158);
  static const surface = Color(0xFFF5F8F7);
  static const surface2 = Color(0xFFFFFFFF);
  static const cardTint = Color.fromARGB(255, 236, 250, 243);
  static const softTint = Color.fromARGB(255, 230, 247, 239);
  static const greenBorder = Color.fromARGB(255, 178, 223, 205);
  static const divider = Color(0x1F000000);
  static const accentBlue = Color.fromARGB(255, 7, 151, 138);
}

class BookingItem {
  final String id;
  final String bookingCode;
  final DateTime? createdAt;
  final String venue;
  final String location;
  final String sport;
  final DateTime? date;
  final String rawDate;
  final String slot;
  final String start;
  final String end;
  final String status;
  final double price;
  final String? imageUrl;

  const BookingItem({
    required this.id,
    required this.bookingCode,
    required this.createdAt,
    required this.venue,
    required this.location,
    required this.sport,
    required this.date,
    required this.rawDate,
    required this.slot,
    required this.start,
    required this.end,
    required this.status,
    required this.price,
    required this.imageUrl,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    final rawSports = json['sports'];
    final sportValue = rawSports is List && rawSports.isNotEmpty
        ? rawSports.first?.toString() ?? 'Sport'
        : (json['sport']?.toString() ?? 'Sport');
    final rawDateValue = (json['date'] ?? '').toString();

    return BookingItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      bookingCode: (json['bookingCode'] ?? '').toString().toUpperCase(),
      createdAt: _parseDate(json['createdAt']),
      venue: (json['venue'] ?? 'Court').toString(),
      location: (json['location'] ?? 'Unknown').toString(),
      sport: sportValue,
      date: _parseDate(rawDateValue),
      rawDate: rawDateValue,
      slot: (json['slot'] ?? '').toString(),
      start: (json['start'] ?? '').toString(),
      end: (json['end'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      price: _parsePrice(json['price']),
      imageUrl: _resolveImageUrl(json['image']?.toString()),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed ?? 0;
  }

  static String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiEndpoints.serverUrl}$raw';
    return '${ApiEndpoints.serverUrl}/$raw';
  }
}

class MoviesScreen extends ConsumerStatefulWidget {
  const MoviesScreen({super.key});

  @override
  ConsumerState<MoviesScreen> createState() => _MoviesScreenState();
}

class _MoviesScreenState extends ConsumerState<MoviesScreen> {
  final _storage = const FlutterSecureStorage();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;

  List<BookingItem> _allBookings = const [];
  String _activeFilter = 'All';

    bool get _isDarkTheme => Theme.of(context).brightness == Brightness.dark;
    Color get _surface =>
      _isDarkTheme ? const Color.fromARGB(255, 16, 22, 28) : AppTheme.surface;
    Color get _surface2 =>
      _isDarkTheme ? const Color.fromARGB(255, 27, 36, 44) : AppTheme.surface2;
    Color get _pageTop => _isDarkTheme
      ? const Color.fromARGB(255, 32, 39, 46)
      : AppTheme.pageTop;
    Color get _pageBottom => _isDarkTheme
      ? const Color.fromARGB(255, 18, 23, 30)
      : AppTheme.pageBottom;
    Color get _cardTint => _isDarkTheme
      ? const Color.fromARGB(255, 33, 42, 50)
      : AppTheme.cardTint;
    Color get _softTint => _isDarkTheme
      ? const Color.fromARGB(255, 39, 49, 58)
      : AppTheme.softTint;
    Color get _greenBorder => _isDarkTheme ? Colors.white24 : AppTheme.greenBorder;
    Color get _textPrimary => _isDarkTheme ? Colors.white : AppTheme.textPrimary;
    Color get _textSecondary =>
      _isDarkTheme ? Colors.white70 : AppTheme.textSecondary;
    Color get _divider => _isDarkTheme ? Colors.white24 : AppTheme.divider;
    Color get _accent => _isDarkTheme
      ? const Color.fromARGB(255, 126, 215, 181)
      : AppTheme.accentBlue;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        throw Exception('Please login again.');
      }

      final response = await Dio().get(
        '${ApiEndpoints.serverUrl}/api/bookings/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        throw Exception('Unable to fetch bookings.');
      }

      final payload = response.data as Map<String, dynamic>;
      final data = payload['data'];
      if (data is! List) {
        throw Exception(payload['message']?.toString() ?? 'No booking data found.');
      }

      final mapped = data
          .whereType<Map<String, dynamic>>()
          .map(BookingItem.fromJson)
          .toList()
        ..sort((a, b) {
          final ad = a.createdAt ?? a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bd = b.createdAt ?? b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bd.compareTo(ad);
        });

      if (!mounted) return;
      setState(() {
        _allBookings = mapped;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _isUpcoming(BookingItem item) {
    if (item.status.toLowerCase() == 'cancelled') return false;
    final now = DateTime.now();
    final start = _bookingStartDateTime(item);
    if (start != null) {
      return start.isAfter(now);
    }

    final date = _bookingLocalDate(item);
    if (date == null) return false;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return !endOfDay.isBefore(now);
  }

  bool _isPast(BookingItem item) {
    if (item.status.toLowerCase() == 'cancelled') return false;
    final now = DateTime.now();
    final end = _bookingEndDateTime(item);
    if (end != null) {
      return end.isBefore(now);
    }

    final date = _bookingLocalDate(item);
    if (date == null) return false;
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return endOfDay.isBefore(now);
  }

  bool _isOngoing(BookingItem item) {
    if (item.status.toLowerCase() == 'cancelled') return false;
    final now = DateTime.now();
    final start = _bookingStartDateTime(item);
    final end = _bookingEndDateTime(item);
    if (start == null || end == null) return false;
    return !now.isBefore(start) && now.isBefore(end);
  }

  DateTime? _bookingLocalDate(BookingItem item) {
    final raw = item.rawDate.trim();
    if (raw.isNotEmpty) {
      final datePart = raw.contains('T') ? raw.split('T').first : raw;
      final pieces = datePart.split('-');
      if (pieces.length == 3) {
        final year = int.tryParse(pieces[0]);
        final month = int.tryParse(pieces[1]);
        final day = int.tryParse(pieces[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
    }

    final date = item.date;
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }

  DateTime? _bookingEndDateTime(BookingItem item) {
    final date = _bookingLocalDate(item);
    if (date == null) return null;

    if (item.end.trim().isNotEmpty) {
      final parsedEnd = DateTime.tryParse(item.end.trim());
      if (parsedEnd != null) {
        return parsedEnd.toLocal();
      }
    }

    final slot = item.slot.trim();
    if (slot.isEmpty) return null;

    final parts = slot.split('-').map((part) => part.trim()).toList();
    if (parts.length != 2) return null;
    final endTime = _parseClock(parts[1]);
    if (endTime == null) return null;

    return DateTime(date.year, date.month, date.day, endTime.hour, endTime.minute);
  }

  DateTime? _bookingStartDateTime(BookingItem item) {
    final date = _bookingLocalDate(item);
    if (date == null) return null;

    if (item.start.trim().isNotEmpty) {
      final parsedStart = DateTime.tryParse(item.start.trim());
      if (parsedStart != null) {
        return parsedStart.toLocal();
      }
    }

    final slot = item.slot.trim();
    if (slot.isEmpty) return null;

    final parts = slot.split('-').map((part) => part.trim()).toList();
    if (parts.length != 2) return null;
    final startTime = _parseClock(parts[0]);
    if (startTime == null) return null;

    return DateTime(date.year, date.month, date.day, startTime.hour, startTime.minute);
  }

  TimeOfDay? _parseClock(String text) {
    final normalized = text.toUpperCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3);
    if (hour == null || minute == null) return null;
    if (minute < 0 || minute > 59) return null;

    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    if (hour < 0 || hour > 23) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  List<BookingItem> get _filteredBookings {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = _allBookings.where((item) {
      final status = item.status.toLowerCase();
      final filterMatch = switch (_activeFilter) {
        'Upcoming' => _isUpcoming(item) || _isOngoing(item),
        'Past' => _isPast(item),
        'Cancelled' => status == 'cancelled',
        _ => true,
      };

      if (!filterMatch) return false;
      if (query.isEmpty) return true;

      return item.venue.toLowerCase().contains(query) ||
          item.location.toLowerCase().contains(query) ||
          item.sport.toLowerCase().contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aSortDate = a.createdAt ?? a.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bSortDate = b.createdAt ?? b.date ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bSortDate.compareTo(aSortDate);
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _filteredBookings;

    return Scaffold(
      backgroundColor: _surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_pageTop, _pageBottom],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _loadBookings)
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              Text(
                                'My Bookings',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: _isLoading ? null : _loadBookings,
                                icon: const Icon(Icons.refresh_rounded),
                                color: _textPrimary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildSearchField(),
                          const SizedBox(height: 14),
                          _buildFilterTabs(),
                          const SizedBox(height: 14),
                          _buildActionRow(),
                          const SizedBox(height: 14),
                          if (filteredBookings.isEmpty)
                            const _EmptyState()
                          else
                            ...filteredBookings.map(_buildBookingCard),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    const tabs = ['All', 'Upcoming', 'Past', 'Cancelled'];
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = tabs[index];
          final selected = _activeFilter == label;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _activeFilter = label),
            selectedColor: _accent,
            backgroundColor: _surface2,
            labelStyle: TextStyle(
              color: selected ? Colors.white : _textSecondary,
              fontWeight: FontWeight.w600,
            ),
            side: BorderSide(
              color: selected ? _accent : Colors.transparent,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: _textPrimary),
      cursorColor: _accent,
      decoration: InputDecoration(
        hintText: 'Search by venue, location, sport',
        hintStyle: TextStyle(color: _textSecondary),
        prefixIcon: Icon(Icons.search_rounded, color: _textSecondary),
        filled: true,
        fillColor: _surface2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: _divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: _divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(color: _accent, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildActionRow() {
    return Text(
      '${_filteredBookings.length} bookings',
      style: TextStyle(
        color: _textPrimary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildBookingCard(BookingItem item) {
    final statusLabel = _bookingStateLabel(item);
    final statusColor = switch (statusLabel) {
      'ongoing' => const Color.fromARGB(255, 25, 118, 210),
      'upcoming' => const Color.fromARGB(255, 0, 150, 136),
      'past' => const Color.fromARGB(255, 94, 53, 177),
      'cancelled' => const Color.fromARGB(255, 220, 53, 69),
      _ => const Color.fromARGB(255, 255, 152, 0),
    };

    final dateLabel = _displayDateLabel(item);
    final timeLabel = _displayTimeLabel(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _cardTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _greenBorder),
        boxShadow: [
          BoxShadow(
            color: _isDarkTheme ? Colors.black26 : const Color.fromARGB(70, 16, 94, 67),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: SizedBox(
              height: 140,
              width: double.infinity,
              child: item.imageUrl != null
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _fallbackImage(),
                    )
                  : _fallbackImage(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.venue,
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: _textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.location,
                        style: TextStyle(color: _textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.sports_tennis_rounded, size: 16, color: _textSecondary),
                    const SizedBox(width: 6),
                    Text(item.sport, style: TextStyle(color: _textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.calendar_month_rounded, size: 16, color: _textSecondary),
                    const SizedBox(width: 6),
                    Text(dateLabel, style: TextStyle(color: _textSecondary)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16, color: _textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      _formatTimeLabel(timeLabel),
                      style: TextStyle(color: _textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      'NPR ${item.price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: () => _showBookingDetails(item),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('View details'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _accent,
                      side: BorderSide(color: _accent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: _softTint,
      child: Center(
        child: Icon(Icons.event_available_rounded, color: _accent, size: 34),
      ),
    );
  }

  String _formatTimeLabel(String raw) {
    if (raw.isEmpty) return raw;

    String clean(String value) {
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) {
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }

      if (value.contains('T')) {
        final part = value.split('T').last;
        if (part.length >= 5) return part.substring(0, 5);
      }

      return value;
    }

    if (raw.contains(' - ')) {
      final pieces = raw.split(' - ');
      if (pieces.length == 2) {
        return '${clean(pieces[0])} - ${clean(pieces[1])}';
      }
    }
    return clean(raw);
  }

  String _displayDateLabel(BookingItem item) {
    final raw = item.rawDate.trim();
    if (raw.isNotEmpty) {
      final datePart = raw.contains('T') ? raw.split('T').first : raw;
      final parts = datePart.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
        }
      }

      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
      }
    }

    if (item.date != null) {
      return '${item.date!.day.toString().padLeft(2, '0')}/${item.date!.month.toString().padLeft(2, '0')}/${item.date!.year}';
    }
    return 'No date';
  }

  String _displayTimeLabel(BookingItem item) {
    final slot = item.slot.trim();
    if (slot.isNotEmpty) {
      final normalized = slot.replaceAll(RegExp(r'\s*-\s*'), ' - ');
      return _formatTimeLabel(normalized);
    }

    if (item.start.isNotEmpty && item.end.isNotEmpty) {
      return _formatTimeLabel('${item.start} - ${item.end}');
    }

    if (item.start.isNotEmpty) {
      return _formatTimeLabel(item.start);
    }

    return '-';
  }

  String _bookingStateLabel(BookingItem item) {
    final status = item.status.toLowerCase();
    if (status == 'cancelled') return 'cancelled';
    if (_isOngoing(item)) return 'ongoing';
    if (_isPast(item)) return 'past';
    if (_isUpcoming(item)) return 'upcoming';
    return status.isEmpty ? 'pending' : status;
  }

  Future<void> _showBookingDetails(BookingItem item) async {
    final statusLabel = _bookingStateLabel(item);
    final statusColor = switch (statusLabel) {
      'ongoing' => const Color.fromARGB(255, 25, 118, 210),
      'upcoming' => const Color.fromARGB(255, 0, 150, 136),
      'past' => const Color.fromARGB(255, 94, 53, 177),
      'cancelled' => const Color.fromARGB(255, 220, 53, 69),
      _ => const Color.fromARGB(255, 255, 152, 0),
    };

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Container(
              decoration: BoxDecoration(
                color: _cardTint,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isDarkTheme ? Colors.black26 : const Color.fromARGB(70, 16, 94, 67),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: SizedBox(
                        height: 170,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            item.imageUrl != null
                                ? Image.network(
                                    item.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _fallbackImage(),
                                  )
                                : _fallbackImage(),
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color.fromARGB(0, 0, 0, 0),
                                    Color.fromARGB(170, 0, 0, 0),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.venue,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item.location,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Booking Summary',
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'BOOKING ID',
                                  style: TextStyle(
                                    color: _accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                Text(
                                  _displayBookingCode(item),
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Paid',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'NPR ${item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                        decoration: BoxDecoration(
                          color: _softTint,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _greenBorder),
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: _qrPayload(item),
                              size: 108,
                              backgroundColor: _isDarkTheme ? Colors.white : Colors.white,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scan for Booking ID',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _softTint,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _greenBorder),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow(Icons.sports_tennis_rounded, 'Sport', item.sport),
                            const SizedBox(height: 8),
                            _detailRow(Icons.calendar_month_rounded, 'Date', _displayDateLabel(item)),
                            const SizedBox(height: 8),
                            _detailRow(
                              Icons.access_time_rounded,
                              'Time',
                              _displayTimeLabel(item),
                            ),
                            const SizedBox(height: 8),
                            _detailRow(
                              Icons.timer_outlined,
                              'Duration',
                              '${_durationMinutes(item)} minutes',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _divider),
                              foregroundColor: _textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: _textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _durationMinutes(BookingItem item) {
    DateTime? parse(String value) {
      if (value.isEmpty) return null;
      return DateTime.tryParse(value);
    }

    final start = parse(item.start);
    final end = parse(item.end);
    if (start != null && end != null && end.isAfter(start)) {
      return end.difference(start).inMinutes;
    }

    final slotParts = item.slot.split('-').map((s) => s.trim()).toList();
    if (slotParts.length == 2) {
      TimeOfDay? parseTime(String text) {
        final normalized = text.toUpperCase();
        final match = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)?$').firstMatch(normalized);
        if (match == null) return null;
        var hour = int.tryParse(match.group(1) ?? '');
        final minute = int.tryParse(match.group(2) ?? '');
        final period = match.group(3);
        if (hour == null || minute == null) return null;
        if (period == 'PM' && hour < 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }

      final startTime = parseTime(slotParts[0]);
      final endTime = parseTime(slotParts[1]);
      if (startTime != null && endTime != null) {
        final startMin = startTime.hour * 60 + startTime.minute;
        final endMin = endTime.hour * 60 + endTime.minute;
        if (endMin > startMin) return endMin - startMin;
      }
    }

    return 60;
  }

  String _displayBookingCode(BookingItem item) {
    final backendCode = item.bookingCode.trim().toUpperCase();
    final exactPattern = RegExp(r'^[A-Z]\d{3}$');
    if (exactPattern.hasMatch(backendCode)) return backendCode;
    return backendCode.isEmpty ? '-' : backendCode;
  }

  String _qrPayload(BookingItem item) {
    final code = _displayBookingCode(item);
    return 'BOOKING:$code|VENUE:${item.venue}|DATE:${_formatDate(item.date)}';
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDarkTheme ? Colors.white : AppTheme.textPrimary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 42),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textPrimary),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final cardTint = isDarkTheme
        ? const Color.fromARGB(255, 33, 42, 50)
        : AppTheme.cardTint;
    final borderColor = isDarkTheme ? Colors.white24 : AppTheme.greenBorder;
    final textPrimary = isDarkTheme ? Colors.white : AppTheme.textPrimary;
    final textSecondary = isDarkTheme ? Colors.white70 : AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 30),
      decoration: BoxDecoration(
        color: cardTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_rounded, size: 36, color: textSecondary),
          const SizedBox(height: 8),
          Text(
            'No bookings found',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'Your booking details will appear here.',
            style: TextStyle(color: textSecondary),
          ),
        ],
      ),
    );
  }
}
