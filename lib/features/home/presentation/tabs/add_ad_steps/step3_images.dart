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

  Future<void> _pickAdditionalImage() async {
    if (_images.length >= 5) {
      Notifications.showSnack(
        context,
        'الحد الأقصى 5 صور إضافية',
        type: NotificationType.warning,
        icon: Icons.warning,
      );
      return;
    }

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (file != null) {
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() => _images.add(base64Image));
        widget.onDataChanged('images', _images);
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
        height: isThumbnail ? 200 : 120,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
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
                    Icons.add_photo_alternate_outlined,
                    size: isThumbnail ? 64 : 48,
                    color: AppTheme.iconInactiveColor,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isThumbnail ? 'الصورة الرئيسية *' : 'إضافة صورة',
                    style: TextStyle(
                      color: AppTheme.iconInactiveColor,
                      fontSize: isThumbnail ? 16 : 14,
                    ),
                  ),
                ],
              ),
            if (base64Image != null && onRemove != null)
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.errorColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Thumbnail
        _buildImageContainer(
          base64Image: _thumbnail,
          onTap: _pickThumbnail,
          isThumbnail: true,
        ),
        const SizedBox(height: 16),

        // Additional Images Header with Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'صور إضافية (اختيارية)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${_images.length}/5',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
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
                onTap: _pickAdditionalImage,
              );
            }
          },
        ),
        
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'يمكنك إضافة حتى 6 صور (صورة رئيسية + 5 صور إضافية)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
