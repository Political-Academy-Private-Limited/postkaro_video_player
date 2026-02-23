import 'package:flutter/material.dart';
//
// class VideoRouteObserver extends NavigatorObserver {
//   final List<VoidCallback> _onOverlayOpenListeners = [];
//   final List<VoidCallback> _onOverlayCloseListeners = [];
//
//   /// ---------------------------
//   /// Route Handling
//   /// ---------------------------
//
//   void addListener({
//     required VoidCallback onOpen,
//     required VoidCallback onClose,
//   }) {
//     _onOverlayOpenListeners.add(onOpen);
//     _onOverlayCloseListeners.add(onClose);
//   }
//
//   void removeListener({
//     required VoidCallback onOpen,
//     required VoidCallback onClose,
//   }) {
//     _onOverlayOpenListeners.remove(onOpen);
//     _onOverlayCloseListeners.remove(onClose);
//   }
//
//   bool _isOverlay(Route route) {
//     return route is PopupRoute ||
//         route.runtimeType.toString().contains("ModalBottomSheet");
//   }
//
//   @override
//   void didPush(Route route, Route? previousRoute) {
//     if (_isOverlay(route)) {
//       for (final listener in _onOverlayOpenListeners) {
//         listener();
//       }
//     }
//   }
//
//   @override
//   void didPop(Route route, Route? previousRoute) {
//     if (_isOverlay(route)) {
//       for (final listener in _onOverlayCloseListeners) {
//         listener();
//       }
//     }
//   }
// }

class VideoRouteObserver extends NavigatorObserver {
  final List<void Function(Route?)> _onOverlayOpenListeners = [];
  final List<void Function(Route?)> _onOverlayCloseListeners = [];

  void addListener({
    required void Function(Route?) onOpen,
    required void Function(Route?) onClose,
  }) {
    _onOverlayOpenListeners.add(onOpen);
    _onOverlayCloseListeners.add(onClose);
  }

  void removeListener({
    required void Function(Route?) onOpen,
    required void Function(Route?) onClose,
  }) {
    _onOverlayOpenListeners.remove(onOpen);
    _onOverlayCloseListeners.remove(onClose);
  }

  bool _isOverlay(Route route) {
    return route is PopupRoute ||
        route.runtimeType.toString().contains("ModalBottomSheet");
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    if (_isOverlay(route)) {
      for (final listener in _onOverlayOpenListeners) {
        listener(previousRoute); // 🔥 pass owner
      }
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (_isOverlay(route)) {
      for (final listener in _onOverlayCloseListeners) {
        listener(previousRoute); // 🔥 pass owner
      }
    }
  }
}