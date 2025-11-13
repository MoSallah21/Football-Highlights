// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:cached_network_image/cached_network_image.dart';
// import '../../data/models/banner_model.dart';
// import '../../logic/cubits/banner/banner_cubit.dart';
//
// /// Auto-rotating banner widget for promotional ads
// class BannerWidget extends StatefulWidget {
//   const BannerWidget({super.key});
//
//   @override
//   State<BannerWidget> createState() => _BannerWidgetState();
// }
//
// class _BannerWidgetState extends State<BannerWidget> {
//   final PageController _pageController = PageController();
//   Timer? _timer;
//   int _currentPage = 0;
//
//   @override
//   void dispose() {
//     _timer?.cancel();
//     _pageController.dispose();
//     super.dispose();
//   }
//
//   /// Start auto-rotation timer (5 seconds per banner)
//   void _startAutoRotation(int totalBanners) {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
//       if (_pageController.hasClients) {
//         _currentPage = (_currentPage + 1) % totalBanners;
//         _pageController.animateToPage(
//           _currentPage,
//           duration: const Duration(milliseconds: 400),
//           curve: Curves.easeInOut,
//         );
//       }
//     });
//   }
//
//   /// Open banner redirect URL in browser
//   // Future<void> _openBannerUrl(String url) async {
//   //   final uri = Uri.parse(url);
//   //   if (await canLaunchUrl(uri)) {
//   //     await launchUrl(uri, mode: LaunchMode.externalApplication);
//   //   } else {
//   //     debugPrint('Could not launch $url');
//   //   }
//   // }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<BannerCubit, BannerState>(
//         builder: (context, state) {
//       if (state is BannerLoading) {
//         return Container(
//           height: 180,
//           color: Colors.black12,
//           child: const Center(
//             child: CircularProgressIndicator(),
//           ),
//         );
//       }    if (state is BannerError) {
//         return Container(
//           height: 180,
//           color: Colors.black12,
//           child: Center(
//             child: Text(
//               'Banner ads unavailable',
//               style: Theme.of(context).textTheme.bodyMedium,
//             ),
//           ),
//         );
//       }
//
//       if (state is BannerLoaded) {
//         final banners = state.banners;
//
//         if (banners.isEmpty) {
//           return const SizedBox.shrink();
//         }
//
//         // Start auto-rotation when banners are loaded
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           _startAutoRotation(banners.length);
//         });
//
//         return Container(
//           height: 180,
//           margin: const EdgeInsets.all(20),
//           child: Stack(
//             children: [
//               // PageView for rotating banners
//               PageView.builder(
//                 controller: _pageController,
//                 itemCount: banners.length,
//                 onPageChanged: (index) {
//                   setState(() {
//                     _currentPage = index;
//                   });
//                 },
//                 itemBuilder: (context, index) {
//                   return _BannerItem(
//                     banner: banners[index],
//                     onTap: () {
//                     },
//                   );
//                 },
//               ),
//
//               // Page indicators
//               if (banners.length > 1)
//                 Positioned(
//                   bottom: 12,
//                   left: 0,
//                   right: 0,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: List.generate(
//                       banners.length,
//                           (index) => Container(
//                         width: 8,
//                         height: 8,
//                         margin: const EdgeInsets.symmetric(horizontal: 4),
//                         decoration: BoxDecoration(
//                           shape: BoxShape.circle,
//                           color: _currentPage == index
//                               ? Theme.of(context).colorScheme.primary
//                               : Colors.white38,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       }
//
//       return const SizedBox.shrink();
//         },
//     );
//   }
// }
// /// Individual banner item with focus support
// class _BannerItem extends StatefulWidget {
//   final BannerModel banner;
//   final VoidCallback onTap;
//
//   const _BannerItem({
//     required this.banner,
//     required this.onTap,
//   });
//
//   @override
//   State<_BannerItem> createState() => _BannerItemState();
// }
//
// class _BannerItemState extends State<_BannerItem> {
//   final FocusNode _focusNode = FocusNode();
//   bool _isFocused = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _focusNode.addListener(() {
//       setState(() {
//         _isFocused = _focusNode.hasFocus;
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return FocusableActionDetector(
//       focusNode: _focusNode,
//       actions: {
//         ActivateIntent: CallbackAction<ActivateIntent>(
//           onInvoke: (_) {
//             widget.onTap();
//             return null;
//           },
//         ),
//       },
//       child: AnimatedScale(
//         scale: _isFocused ? 1.02 : 1.0,
//         duration: const Duration(milliseconds: 120),
//         child: InkWell(
//           onTap: widget.onTap,
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(12),
//               border: _isFocused
//                   ? Border.all(
//                 color: Theme.of(context).colorScheme.primary,
//                 width: 3,
//               )
//                   : null,
//               boxShadow: _isFocused
//                   ? [
//                 BoxShadow(
//                   color: Theme.of(context)
//                       .colorScheme
//                       .primary
//                       .withOpacity(0.5),
//                   blurRadius: 12,
//                   spreadRadius: 2,
//                 ),
//               ]
//                   : null,
//             ),
//             child: ClipRRect(
//               borderRadius: BorderRadius.circular(12),
//               child: CachedNetworkImage(
//                 imageUrl: widget.banner.imageUrl,
//                 fit: BoxFit.cover,
//                 width: double.infinity,
//                 placeholder: (context, url) => Container(
//                   color: Colors.black26,
//                   child: const Center(
//                     child: CircularProgressIndicator(),
//                   ),
//                 ),
//                 errorWidget: (context, url, error) => Container(
//                   color: Colors.black38,
//                   child: const Center(
//                     child: Icon(
//                       Icons.image_not_supported,
//                       size: 48,
//                       color: Colors.white38,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }