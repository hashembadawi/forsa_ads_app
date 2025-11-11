import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A small reusable widget that shows a shimmer while an in-memory image
/// is being decoded/rendered, then fades the image in. Intended to replace
/// private copies of the same behavior across files.
class AsyncImageWithShimmer extends StatefulWidget {
  final Uint8List imageBytes;
  final BoxFit fit;

  const AsyncImageWithShimmer({Key? key, required this.imageBytes, this.fit = BoxFit.cover}) : super(key: key);

  @override
  State<AsyncImageWithShimmer> createState() => _AsyncImageWithShimmerState();
}

class _AsyncImageWithShimmerState extends State<AsyncImageWithShimmer> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isLoading)
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(color: Colors.grey[300]),
          ),
        Image.memory(
          widget.imageBytes,
          fit: widget.fit,
          frameBuilder: (context, child, frame, wasSync) {
            if (wasSync) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isLoading = false);
              });
              return child;
            }
            if (frame != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _isLoading = false);
              });
              return AnimatedOpacity(opacity: _isLoading ? 0 : 1, duration: const Duration(milliseconds: 250), child: child);
            }
            return const SizedBox.shrink();
          },
          errorBuilder: (context, error, stack) => Container(color: Colors.grey[300]),
        ),
      ],
    );
  }
}
