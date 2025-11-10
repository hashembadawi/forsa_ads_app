import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/ui/notifications.dart';

class Step3Images extends StatefulWidget {
  final Map<String, dynamic> adData;
  final Function(String key, dynamic value) onDataChanged;

  const Step3Images({
    super.key,
    required this.adData,
    required this.onDataChanged,
  });

  @override
  State<Step3Images> createState() => _Step3ImagesState();
}

class _Step3ImagesState extends State<Step3Images> {
  final ImagePicker _imagePicker = ImagePicker();
  String? _thumbnail;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    _thumbnail = widget.adData['thumbnail'];
    _images = List<String>.from(widget.adData['images'] ?? []);
  }

  Future<void> _pickThumbnail() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (file != null) {
        // Read file bytes and convert to base64 (no client-side compression)
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() => _thumbnail = base64Image);
        widget.onDataChanged('thumbnail', base64Image);
      }
    } catch (e) {
      if (mounted) {
        Notifications.showSnack(
          context,
          'فشل اختيار الصورة',
          type: NotificationType.error,
          icon: Icons.error,
        );
      }
    }
  }

  Future<void> _pickAdditionalImages() async {
    final remainingSlots = 5 - _images.length;
    
    if (remainingSlots <= 0) {
      Notifications.showSnack(
        context,
        'الحد الأقصى 5 صور إضافية',
        type: NotificationType.info,
        icon: Icons.info,
      );
      return;
    }

    try {
      final List<XFile> files = await _imagePicker.pickMultiImage(
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
      
      if (files.isEmpty) return;
      
      // Take only the remaining available slots
      final filesToProcess = files.take(remainingSlots).toList();
      
      // Show warning if user selected more than allowed
      if (files.length > remainingSlots) {
        Notifications.showSnack(
          context,
          'تم اختيار ${filesToProcess.length} صور فقط (الحد الأقصى $remainingSlots)',
          type: NotificationType.info,
          icon: Icons.info,
        );
      }
      
      // Process selected images (no compression)
      final List<String> newImages = [];
      for (final file in filesToProcess) {
        final bytes = await file.readAsBytes();
        newImages.add(base64Encode(bytes));
      }
      
      setState(() => _images.addAll(newImages));
      widget.onDataChanged('images', _images);
      
    } catch (e) {
      if (mounted) {
        Notifications.showSnack(
          context,
          'فشل اختيار الصور',
          type: NotificationType.error,
          icon: Icons.error,
        );
      }
    }
  }

  void _removeAdditionalImage(int index) {
    setState(() => _images.removeAt(index));
    widget.onDataChanged('images', _images);
  }

  Widget _buildImageContainer({
    String? base64Image,
    required VoidCallback onTap,
    bool isThumbnail = false,
    VoidCallback? onRemove,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isThumbnail ? 180 : null,
        decoration: BoxDecoration(
          border: Border.all(
            color: base64Image != null ? Colors.grey[400]! : Colors.grey[300]!,
            width: base64Image != null ? 2 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: base64Image != null ? Colors.white : Colors.grey[50],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (base64Image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  base64Decode(base64Image),
                  fit: BoxFit.cover,
                ),
              )
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isThumbnail ? Icons.add_photo_alternate_outlined : Icons.add_a_photo_outlined,
                    size: isThumbnail ? 48 : 36,
                    color: AppTheme.iconInactiveColor,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isThumbnail ? 'اختر الصورة' : 'إضافة',
                    style: TextStyle(
                      color: AppTheme.iconInactiveColor,
                      fontSize: isThumbnail ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            if (base64Image != null && onRemove != null)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thumbnail Section
          Text(
            'الصورة الرئيسية *',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildImageContainer(
            base64Image: _thumbnail,
            onTap: _pickThumbnail,
            isThumbnail: true,
          ),
          const SizedBox(height: 24),

          // Additional Images Header with Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'صور إضافية (اختيارية)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _images.length >= 5 ? Colors.red[50] : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _images.length >= 5 ? Colors.red[200]! : Colors.blue[200]!,
                  ),
                ),
                child: Text(
                  '${_images.length}/5',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _images.length >= 5 ? Colors.red[700] : Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid of additional images
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: _images.length + (_images.length < 5 ? 1 : 0),
            itemBuilder: (context, index) {
              if (index < _images.length) {
                // Show existing image
                return _buildImageContainer(
                  base64Image: _images[index],
                  onTap: () {},
                  onRemove: () => _removeAdditionalImage(index),
                );
              } else {
                // Show add button
                return _buildImageContainer(
                  onTap: _pickAdditionalImages,
                );
              }
            },
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'معلومات مهمة:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '• يمكنك إضافة حتى 6 صور (صورة رئيسية + 5 صور إضافية)\n• اختر عدة صور في نفس الوقت لتوفير الوقت\n• الصورة الرئيسية إلزامية',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
