// import 'package:flutter/material.dart';

// import '../screens/res/app_assets.dart';
// import '../screens/res/app_strings.dart';
// import '../screens/res/app_typography.dart';
// import 'rating_action_btn.dart';

// class RateAppWidget extends StatefulWidget {
//   static const String id = 'rateAppWidget';
//   const RateAppWidget({Key? key}) : super(key: key);

//   @override
//   State<RateAppWidget> createState() => _RateAppWidgetState();
// }

// class _RateAppWidgetState extends State<RateAppWidget> {
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final size = MediaQuery.of(context).size;

//     return Container(
//       height: size.height / 1.5,
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(50.0),
//           topRight: Radius.circular(50.0),
//         ),
//         color: theme.cardColor,
//       ),
//       child: Stack(
//         alignment: Alignment.center,
//         clipBehavior: Clip.none,
//         children: [
//           Positioned(
//             top: 27,
//             left: 30,
//             child: GestureDetector(
//               onTap: () => Navigator.of(context).pop(),
//               child: Icon(
//                 Icons.close_rounded,
//                 size: 24,
//                 color: theme.shadowColor.withOpacity(0.5),
//               ),
//             ),
//           ),
//           Positioned(
//             top: -90,
//             child: Image.asset(
//               AppAssets.ratingScreen1,
//               scale: 4,
//             ),
//           ),
//           Positioned(
//             bottom: size.height / 12,
//             child: Column(
//               children: const [
//                 RobotoRegular18(title: AppLocalizations.of(context)!.impressions),
//                 SizedBox(height: 10),
//                 RobotoSemiBold22(title: AppLocalizations.of(context)!.likeTheApp),
//                 SizedBox(height: 25),
//                 RatingActionBtn(isYes: true),
//                 SizedBox(height: 25),
//                 RatingActionBtn(isYes: false),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
