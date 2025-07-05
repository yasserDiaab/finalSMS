import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pro/cubit/offline_sync/offline_sync_cubit.dart';
import 'package:pro/cubit/offline_sync/offline_sync_state.dart';
import 'package:pro/models/supporter_phone_model.dart';

class OfflinePhonesScreen extends StatefulWidget {
  const OfflinePhonesScreen({Key? key}) : super(key: key);

  @override
  State<OfflinePhonesScreen> createState() => _OfflinePhonesScreenState();
}

class _OfflinePhonesScreenState extends State<OfflinePhonesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final OfflineSyncCubit _cubit = OfflineSyncCubit();

  @override
  void initState() {
    super.initState();
    // تحميل البيانات عند فتح الشاشة
    _cubit.loadSupporterPhones();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  // الاتصال برقم الهاتف
  Future<void> _callPhoneNumber(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        _showSnackBar('لا يمكن الاتصال بهذا الرقم');
      }
    } catch (e) {
      _showSnackBar('خطأ في الاتصال: $e');
    }
  }

  // إرسال رسالة نصية
  Future<void> _sendSMS(String phoneNumber) async {
    final Uri smsUri = Uri(scheme: 'sms', path: phoneNumber);
    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        _showSnackBar('لا يمكن إرسال رسالة نصية');
      }
    } catch (e) {
      _showSnackBar('خطأ في إرسال الرسالة: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'أرقام الهواتف المحفوظة',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF30C988),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _cubit.syncWithServer(forceSync: true),
              tooltip: 'تحديث من الخادم',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _showClearDataDialog(),
              tooltip: 'مسح البيانات المحلية',
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'البحث في أرقام الهواتف...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _cubit.loadSupporterPhones();
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  if (value.trim().isNotEmpty) {
                    _cubit.searchSupporterPhones(value);
                  } else {
                    _cubit.loadSupporterPhones();
                  }
                },
              ),
            ),
            // قائمة أرقام الهواتف
            Expanded(
              child: BlocBuilder<OfflineSyncCubit, OfflineSyncState>(
                builder: (context, state) {
                  if (state is OfflineSyncLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('جاري التحميل...'),
                        ],
                      ),
                    );
                  } else if (state is OfflineSyncSuccess) {
                    return _buildPhonesList(
                        state.supporterPhones, state.lastSyncTime);
                  } else if (state is OfflineSyncNoConnection) {
                    return _buildPhonesList(state.cachedPhones, null);
                  } else if (state is OfflineSyncSearchResult) {
                    return _buildPhonesList(state.searchResults, null);
                  } else if (state is OfflineSyncFailure) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            state.error,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _cubit.loadSupporterPhones(),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const Center(
                    child: Text('لا توجد بيانات'),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _cubit.syncWithServer(),
          backgroundColor: const Color(0xFF30C988),
          child: const Icon(Icons.sync, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildPhonesList(
      List<SupporterPhoneModel> phones, DateTime? lastSyncTime) {
    if (phones.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_disabled, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'لا توجد أرقام هواتف محفوظة',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // معلومات آخر مزامنة
        if (lastSyncTime != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sync, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Text(
                  'آخر تحديث: ${_formatDateTime(lastSyncTime)}',
                  style: const TextStyle(color: Colors.green, fontSize: 12),
                ),
              ],
            ),
          ),
        // قائمة الأرقام
        Expanded(
          child: ListView.builder(
            itemCount: phones.length,
            itemBuilder: (context, index) {
              final phone = phones[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFF30C988),
                    child: Text(
                      phone.supporterName.isNotEmpty
                          ? phone.supporterName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    phone.supporterName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phone.phoneNumber),
                      if (phone.email != null && phone.email!.isNotEmpty)
                        Text(
                          phone.email!,
                          style: const TextStyle(color: Colors.grey),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _callPhoneNumber(phone.phoneNumber),
                        tooltip: 'اتصال',
                      ),
                      IconButton(
                        icon: const Icon(Icons.message, color: Colors.blue),
                        onPressed: () => _sendSMS(phone.phoneNumber),
                        tooltip: 'رسالة نصية',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح البيانات المحلية'),
        content: const Text('هل أنت متأكد من مسح جميع أرقام الهواتف المحفوظة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _cubit.clearLocalData();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }
}
