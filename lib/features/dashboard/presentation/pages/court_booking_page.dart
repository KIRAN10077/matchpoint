import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:matchpoint/core/api/api_endpoints.dart';
import 'package:matchpoint/core/services/storage/user_session_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CourtBookingPage extends ConsumerStatefulWidget {
  final String courtId;
  final String fallbackTitle;

  const CourtBookingPage({
    super.key,
    required this.courtId,
    required this.fallbackTitle,
  });

  @override
  ConsumerState<CourtBookingPage> createState() => _CourtBookingPageState();
}

class _CourtBookingPageState extends ConsumerState<CourtBookingPage> {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _loading = true;
  bool _loadingSlots = false;
  bool _submitting = false;
  bool _verifyingPayment = false;
  String? _error;

  Map<String, dynamic>? _court;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSport;
  String? _selectedSlot;
  Set<String> _bookedSlots = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(_prefillUserDetails);
    _loadCourt();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _prefillUserDetails() async {
    final session = ref.read(userSessionServiceProvider);

    String name = session.getCurrentUserFullName() ?? '';
    String email = session.getCurrentUserEmail() ?? '';

    if (name.trim().isEmpty || email.trim().isEmpty) {
      final token = await _secureStorage.read(key: 'auth_token');
      if (token != null && token.isNotEmpty && !JwtDecoder.isExpired(token)) {
        final decoded = JwtDecoder.decode(token);

        final firstName = (decoded['firstName'] ?? '').toString().trim();
        final lastName = (decoded['lastName'] ?? '').toString().trim();
        final combinedName = [firstName, lastName]
            .where((part) => part.isNotEmpty)
            .join(' ')
            .trim();
        final tokenName = (decoded['name'] ?? decoded['fullName'] ?? decoded['username'] ?? '')
            .toString()
            .trim();

        if (name.trim().isEmpty) {
          name = combinedName.isNotEmpty ? combinedName : tokenName;
        }

        if (email.trim().isEmpty) {
          email = (decoded['email'] ?? '').toString().trim();
        }
      }
    }

    _nameController.text = name;
    _emailController.text = email;

    if (mounted) setState(() {});
  }

  Future<void> _loadCourt() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await Dio().get(
        '${ApiEndpoints.serverUrl}/api/courts/${widget.courtId}',
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        throw Exception('Failed to fetch court details');
      }

      final payload = response.data as Map<String, dynamic>;
      final data = payload['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid court response');
      }

      final sports = data['sports'] is List
          ? (data['sports'] as List).map((e) => e.toString()).toList()
          : <String>[];

      setState(() {
        _court = data;
        _selectedSport = sports.isNotEmpty ? sports.first : null;
      });

      await _loadAvailability();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadAvailability() async {
    setState(() {
      _loadingSlots = true;
      _selectedSlot = null;
    });

    try {
      final response = await Dio().get(
        '${ApiEndpoints.serverUrl}/api/bookings/availability',
        queryParameters: {
          'courtId': widget.courtId,
          'date': _dateYmd(_selectedDate),
        },
        options: Options(validateStatus: (status) => status != null && status < 500),
      );

      if (response.statusCode != 200 || response.data is! Map<String, dynamic>) {
        throw Exception('Failed to fetch slot availability');
      }

      final payload = response.data as Map<String, dynamic>;
      final data = payload['data'];
      final booked = data is Map<String, dynamic> ? data['bookedSlots'] : null;

      setState(() {
        _bookedSlots = booked is List
            ? booked.map((e) => _normalizeSlot(e.toString())).toSet()
            : <String>{};
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bookedSlots = <String>{};
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSlots = false);
      }
    }
  }

  Future<void> _bookCourt() async {
    if (!_isPhoneValid) {
      _showSnack('Phone number must be exactly 10 digits');
      return;
    }

    if (_selectedSport == null || _selectedSport!.trim().isEmpty) {
      _showSnack('Please select sport');
      return;
    }

    if (_selectedSlot == null || _selectedSlot!.trim().isEmpty) {
      _showSnack('Please select slot');
      return;
    }

    if (_isBooked(_selectedSlot!)) {
      _showSnack('This slot is already booked. Please choose another slot.');
      return;
    }

    setState(() => _submitting = true);

    try {
      final amountPaisa = (_priceValue * 100).round();
      if (amountPaisa <= 0) {
        throw Exception('Invalid booking amount');
      }

      final initiateResponse = await Dio().post(
        '${ApiEndpoints.serverUrl}/api/payments/khalti/initiate',
        data: {
          'amountPaisa': amountPaisa,
          'purchaseOrderName': (_court?['name'] ?? widget.fallbackTitle).toString(),
          'customerName': _nameController.text.trim(),
          'customerEmail': _emailController.text.trim(),
          'customerPhone': _phoneController.text.trim(),
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (initiateResponse.statusCode != 200 || initiateResponse.data is! Map<String, dynamic>) {
        final message = initiateResponse.data is Map<String, dynamic>
            ? (initiateResponse.data['message']?.toString() ?? 'Failed to initiate Khalti payment')
            : 'Failed to initiate Khalti payment';
        throw Exception(message);
      }

      final initiatePayload = initiateResponse.data as Map<String, dynamic>;
      final data = initiatePayload['data'];
      final pidx = data is Map<String, dynamic> ? (data['pidx'] ?? '').toString() : '';
      final paymentUrl = data is Map<String, dynamic> ? (data['payment_url'] ?? '').toString() : '';

      if (pidx.isEmpty || paymentUrl.isEmpty) {
        throw Exception('Invalid payment initialization response');
      }

      final shouldOpenPayment = await _showBookingSummaryBeforePayment(
        amountPaisa: amountPaisa,
      );

      if (!shouldOpenPayment) {
        return;
      }

      final launchOk = await _openPaymentUrl(paymentUrl);
      if (!launchOk) {
        if (!mounted) return;
        await _showPaymentLinkFallback(paymentUrl);
      }

      if (!mounted) return;
      await _showVerifyPaymentSheet(pidx: pidx, amountPaisa: amountPaisa);
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Future<bool> _showBookingSummaryBeforePayment({
    required int amountPaisa,
  }) async {
    if (!mounted) return false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirm Booking Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                _summaryRow('Court', (_court?['name'] ?? widget.fallbackTitle).toString()),
                _summaryRow('Date', _formatDate(_selectedDate)),
                _summaryRow('Slot', _selectedSlot ?? '-'),
                _summaryRow('Sport', _selectedSport ?? '-'),
                _summaryRow('Name', _nameController.text.trim()),
                _summaryRow('Email', _emailController.text.trim()),
                _summaryRow('Phone', _phoneController.text.trim()),
                const SizedBox(height: 8),
                Text(
                  'Total: NPR ${(amountPaisa / 100).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color.fromARGB(255, 20, 110, 80),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 20, 110, 80),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue to Payment'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    return result == true;
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _openPaymentUrl(String url) async {
    try {
      final uri = Uri.parse(url);

      final openedExternal = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (openedExternal) return true;

      final openedDefault = await launchUrl(uri);
      return openedDefault;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  String _dateYmd(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _normalizeSlot(String slot) {
    final cleaned = slot.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final parts = cleaned.split('-').map((e) => e.trim()).toList();
    if (parts.length != 2) return cleaned.replaceAll(' ', '');

    final start = _normalizeTimePart(parts[0]);
    final end = _normalizeTimePart(parts[1]);
    if (start == null || end == null) {
      return cleaned.replaceAll(' ', '');
    }
    return '$start-$end';
  }

  String? _normalizeTimePart(String value) {
    final text = value.trim().toLowerCase();
    final match = RegExp(r'^(\d{1,2}):(\d{2})(?:\s*(am|pm))?$').firstMatch(text);
    if (match == null) return null;

    var hour = int.tryParse(match.group(1) ?? '');
    final minute = int.tryParse(match.group(2) ?? '');
    final period = match.group(3);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    if (period == 'pm' && hour < 12) hour += 12;
    if (period == 'am' && hour == 12) hour = 0;

    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  bool _isBooked(String slot) => _bookedSlots.contains(_normalizeSlot(slot));

  double _parsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  String? _imageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('/')) return '${ApiEndpoints.serverUrl}$raw';
    return '${ApiEndpoints.serverUrl}/$raw';
  }

  List<String> _allSlots() {
    final slots = <String>[];
    for (var hour = 6; hour < 22; hour++) {
      final start = '${hour.toString().padLeft(2, '0')}:00';
      final end = '${(hour + 1).toString().padLeft(2, '0')}:00';
      slots.add('$start-$end');
    }
    return slots;
  }

  double get _priceValue => _parsePrice(_court?['price']);

  bool get _isPhoneValid => RegExp(r'^\d{10}$').hasMatch(_phoneController.text.trim());

  bool get _canConfirm {
    final hasName = _nameController.text.trim().isNotEmpty;
    final hasEmail = _emailController.text.trim().isNotEmpty;
    final hasSport = _selectedSport != null && _selectedSport!.trim().isNotEmpty;
    final hasSlot = _selectedSlot != null && _selectedSlot!.trim().isNotEmpty;
    return !_submitting && hasName && hasEmail && _isPhoneValid && hasSport && hasSlot;
  }

  Future<void> _showPaymentLinkFallback(String url) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Open Khalti Manually'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Could not open Khalti automatically. Copy this link and open it in your browser:'),
              const SizedBox(height: 10),
              SelectableText(
                url,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: url));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
                _showSnack('Payment link copied');
              },
              child: const Text('Copy Link'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showVerifyPaymentSheet({
    required String pidx,
    required int amountPaisa,
  }) async {
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isDismissible: true,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Complete Khalti Payment',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'After successful payment in Khalti, tap Verify Payment to confirm booking.',
                      style: TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: _verifyingPayment
                            ? null
                            : () async {
                              final dialogNavigator = Navigator.of(dialogContext);
                              final pageNavigator = Navigator.of(this.context);

                                setState(() => _verifyingPayment = true);
                                setSheetState(() {});

                                final success = await _verifyKhaltiAndBook(
                                  pidx: pidx,
                                  amountPaisa: amountPaisa,
                                );

                                if (!mounted) return;
                                setState(() => _verifyingPayment = false);
                                setSheetState(() {});

                                if (success) {
                                  if (dialogNavigator.canPop()) {
                                    dialogNavigator.pop();
                                  }
                                  pageNavigator.pop(true);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 20, 110, 80),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _verifyingPayment
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Verify Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _verifyKhaltiAndBook({
    required String pidx,
    required int amountPaisa,
  }) async {
    final token = await _secureStorage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      _showSnack('Please login again');
      return false;
    }

    final range = _selectedSlot == null ? null : _slotRangeIso(_selectedDate, _selectedSlot!);
    if (range == null) {
      _showSnack('Invalid slot selected');
      return false;
    }

    try {
      final response = await Dio().post(
        '${ApiEndpoints.serverUrl}/api/payments/khalti/verify-and-book',
        data: {
          'pidx': pidx,
          'amountPaisa': amountPaisa,
          'booking': {
            'courtId': widget.courtId,
            'sport': _selectedSport,
            'price': _priceValue,
            'date': _dateYmd(_selectedDate),
            'slot': _selectedSlot,
            'start': range['start'],
            'end': range['end'],
          },
        },
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        _showSnack('Payment successful. Booking confirmed.');
        return true;
      }

      final message = response.data is Map<String, dynamic>
          ? (response.data['message']?.toString() ?? 'Payment verification failed')
          : 'Payment verification failed';
      _showSnack(message);
      return false;
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
      return false;
    }
  }

  Map<String, String>? _slotRangeIso(DateTime date, String slot) {
    final normalized = _normalizeSlot(slot);
    final parts = normalized.split('-');
    if (parts.length != 2) return null;

    final start = _toIsoFromDateTimeParts(date, parts[0]);
    final end = _toIsoFromDateTimeParts(date, parts[1]);
    if (start == null || end == null) return null;

    var endDate = end;
    if (!endDate.isAfter(start)) {
      endDate = endDate.add(const Duration(days: 1));
    }

    return {
      'start': start.toIso8601String(),
      'end': endDate.toIso8601String(),
    };
  }

  DateTime? _toIsoFromDateTimeParts(DateTime date, String hhmm) {
    final split = hhmm.split(':');
    if (split.length != 2) return null;
    final hour = int.tryParse(split[0]);
    final minute = int.tryParse(split[1]);
    if (hour == null || minute == null) return null;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final court = _court;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 20, 110, 80),
        title: Text(court?['name']?.toString() ?? widget.fallbackTitle),
      ),
      body: Container(
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(_error!, style: const TextStyle(color: Colors.red)),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageCard(),
                        const SizedBox(height: 14),
                        _buildAboutCard(),
                        const SizedBox(height: 14),
                        _buildBookingCard(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildImageCard() {
    final image = _imageUrl(_court?['image']?.toString());

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 190,
        width: double.infinity,
        color: const Color.fromARGB(255, 236, 250, 243),
        child: image == null
            ? const Center(
                child: Icon(Icons.image_not_supported, size: 42, color: Color.fromARGB(255, 20, 110, 80)),
              )
            : Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image, size: 42, color: Color.fromARGB(255, 20, 110, 80)),
                ),
              ),
      ),
    );
  }

  Widget _buildAboutCard() {
    final sports = _court?['sports'] is List
        ? (_court!['sports'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final amenities = _court?['amenities'] is List
        ? (_court!['amenities'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 250, 243),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 178, 223, 205)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Court',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color.fromARGB(255, 10, 38, 31)),
          ),
          const SizedBox(height: 8),
          Text(
            (_court?['description']?.toString().trim().isNotEmpty ?? false)
                ? _court!['description'].toString()
                : (_court?['location']?.toString() ?? ''),
            style: const TextStyle(color: Color.fromARGB(255, 44, 84, 68)),
          ),
          if (sports.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Sports Available',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sports
                  .map(
                    (sport) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 227, 248, 241),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color.fromARGB(255, 130, 224, 201)),
                      ),
                      child: Text(
                        sport,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color.fromARGB(255, 20, 110, 80),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (amenities.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Text(
              'Amenities & Facilities',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities
                  .map(
                    (amenity) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 245, 248, 247),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        amenity,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingCard() {
    final sports = _court?['sports'] is List
        ? (_court!['sports'] as List).map((e) => e.toString()).toList()
        : <String>[];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 230, 247, 239),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromARGB(255, 178, 223, 205)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hourly Rate  NPR ${_priceValue.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color.fromARGB(255, 12, 38, 32)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatDate(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final selected = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    initialDate: _selectedDate,
                  );
                  if (selected == null) return;
                  setState(() => _selectedDate = selected);
                  await _loadAvailability();
                },
                child: const Text('Select Date'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSport,
            decoration: const InputDecoration(
              labelText: 'Select Sport',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: sports
                .map((sport) => DropdownMenuItem<String>(
                      value: sport,
                      child: Text(sport),
                    ))
                .toList(),
            onChanged: (value) async {
              setState(() => _selectedSport = value);
              await _loadAvailability();
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter 10-digit number',
              border: const OutlineInputBorder(),
              isDense: true,
              errorText: _phoneController.text.isEmpty || _isPhoneValid
                  ? null
                  : 'Phone number must be exactly 10 digits',
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Select Slot',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (_loadingSlots)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allSlots().map((slot) {
                final isBooked = _isBooked(slot);
                final isSelected = _selectedSlot == slot;
                return ChoiceChip(
                  label: Text(slot),
                  selected: isSelected,
                  onSelected: isBooked
                      ? null
                      : (_) {
                          setState(() => _selectedSlot = slot);
                        },
                  selectedColor: const Color.fromARGB(255, 7, 151, 138),
                  disabledColor: Colors.red.shade100,
                  labelStyle: TextStyle(
                    color: isBooked
                        ? Colors.red.shade700
                        : isSelected
                            ? Colors.white
                            : Colors.black87,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isBooked
                        ? Colors.red.shade300
                        : const Color.fromARGB(255, 178, 223, 205),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: const [
              _SlotLegendItem(
                color: Color.fromARGB(255, 7, 151, 138),
                label: 'Selected',
              ),
              _SlotLegendItem(
                color: Color.fromARGB(255, 178, 223, 205),
                label: 'Available',
              ),
              _SlotLegendItem(
                color: Color.fromARGB(255, 239, 154, 154),
                label: 'Booked',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _canConfirm ? _bookCourt : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 20, 110, 80),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Confirm Booking',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _SlotLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color.fromARGB(255, 54, 86, 74),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
