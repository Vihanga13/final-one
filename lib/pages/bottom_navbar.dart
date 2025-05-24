import 'package:flutter/material.dart';
import 'package:health_app_3/pages/home_page.dart'; // Import HomePage

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  static const Color primaryGreen = Color(0xFF86BF3E);

  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.selectedIndex;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void didUpdateWidget(CustomBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _previousIndex = oldWidget.selectedIndex;
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hide the bottom navbar if the scan page is open (selectedIndex == 1)
    if (widget.selectedIndex == 1) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0), // Reduced vertical padding to bring icons closer to indicator
          child: Stack(
            children: [
              // Background indicator that slides between selected items
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: _getIndicatorPosition(context),
                bottom: 10,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: widget.selectedIndex == 1
                      ? 0
                      : MediaQuery.of(context).size.width * 0.12,
                  height: 3,
                  decoration: BoxDecoration(
                    color: CustomBottomNavBar.primaryGreen,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, ''),
                  _buildNavItem(1, Icons.qr_code_scanner_rounded, 'Scan'),
                  _buildNavItem(2, Icons.person_outline_rounded, ''),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getIndicatorPosition(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Account for padding (16 from each side)
    final availableWidth = screenWidth - 32;

    // If center button is selected, hide indicator
    if (widget.selectedIndex == 1) {
      return -50; // Move off-screen
    }

    // For side buttons
    if (widget.selectedIndex == 0) {
      return availableWidth * 0.11; // Position for first item
    } else {
      return availableWidth * 0.76; // Position for last item
    }
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = widget.selectedIndex == index;
    final wasSelected = _previousIndex == index;

    // Special styling for the center scan button
    if (index == 1) {
      return GestureDetector(
        onTap: () => widget.onItemSelected(index),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(
            begin: 1.0,
            end: isSelected ? 1.0 : 0.9,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double finalScale = scale;
                if (isSelected && wasSelected) {
                  finalScale = scale * _bounceAnimation.value;
                }

                return Transform.scale(
                  scale: finalScale,
                  child: child,
                );
              },
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: CustomBottomNavBar.primaryGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: CustomBottomNavBar.primaryGreen.withOpacity(0.4),
                      blurRadius: isSelected ? 15 : 5,
                      spreadRadius: isSelected ? 2 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            );
          },
        ),
      );
    }

    return GestureDetector(
      onTap: () => widget.onItemSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: .0), // Reduced padding for less vertical gap
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double scale = 1.0;
            if (isSelected && wasSelected) {
              scale = _bounceAnimation.value;
            }
            return Transform.scale(
              scale: scale,
              alignment: Alignment.center,
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                transform: isSelected
                    ? Matrix4.translationValues(0, -1, 0) // Less lift
                    : Matrix4.translationValues(0, 0, 0),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  switchInCurve: Curves.easeInOut,
                  switchOutCurve: Curves.easeInOut,
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    );
                  },
                  child: Icon(
                    icon,
                    key: ValueKey<bool>(isSelected),
                    color: isSelected
                        ? CustomBottomNavBar.primaryGreen
                        : Colors.grey,
                    size: isSelected ? 35 : 30, // Slightly smaller
                  ),
                ),
              ),
              const SizedBox(height: 2), // Less vertical gap
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected
                      ? CustomBottomNavBar.primaryGreen
                      : Colors.grey,
                  fontSize: isSelected ? 6 : 5, // Slightly smaller
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
      );
  }
}