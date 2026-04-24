import 'dart:ui';

import 'package:flutter/material.dart';

class PostGalleryNavButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Alignment alignment;
  final IconData icon;
  const PostGalleryNavButton(
      {super.key,
      required this.onPressed,
      required this.alignment,
      required this.icon});

  @override
  State<PostGalleryNavButton> createState() => _PostGalleryNavButtonState();
}

class _PostGalleryNavButtonState extends State<PostGalleryNavButton> {
  bool hovering = false;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: 60,
      left: widget.alignment == Alignment.centerLeft ? 0 : null,
      right: widget.alignment == Alignment.centerRight ? 0 : null,
      child: FocusableActionDetector(
        onShowHoverHighlight: (value) {
          setState(() {
            hovering = value;
          });
        },
        child: Stack(children: [
          if (hovering)
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 1.0,
                  sigmaY: 1.0,
                ),
                child: Container(
                    decoration: const BoxDecoration(color: Colors.black12)),
              ),
            ),
          Center(
            child: MaterialButton(
                minWidth: 0,
                onPressed: widget.onPressed,
                child: Icon(widget.icon, size: 40, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}
