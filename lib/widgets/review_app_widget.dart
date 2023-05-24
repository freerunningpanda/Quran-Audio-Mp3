import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../screens/res/app_colors.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/constants.dart';
import 'rating_action_btn.dart';

class ReviewAppWidget extends StatefulWidget {
  final int? sentRating;
  const ReviewAppWidget({
    Key? key,
    required this.sentRating,
  }) : super(key: key);

  @override
  State<ReviewAppWidget> createState() => _ReviewAppWidgetState();
}

class _ReviewAppWidgetState extends State<ReviewAppWidget> {
  final _key = GlobalKey<FormState>();

  TextEditingController email = TextEditingController();
  TextEditingController subject = TextEditingController(text: '*Quran Audio* Review');
  TextEditingController body = TextEditingController();
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String? brand, device;
  String? iosModel, iosName;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _getDeviceInfo();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.cardColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.improveTheApp,
          style: const TextStyle(fontSize: 22),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(33.0),
        child: Form(
          key: _key,
          child: Column(
            children: [
              TextFormField(
                autofocus: true,
                textInputAction: TextInputAction.done,
                minLines: 1,
                maxLines: 5,
                controller: body,
                // onFieldSubmitted: (value) {
                //   body.text = value;
                // _key.currentState!.save();
                //   debugPrint(body.text);
                //   sendEmail(
                //     subject: subject.text,
                //     body: body.text,
                //     recipientemail: recipientemail,
                //   );
                //   body.clear();
                // },
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.review,
                  hintStyle: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                  border: InputBorder.none,
                ),
              ),
              const Spacer(),
              RatingActionButton(
                title: AppLocalizations.of(context)!.done,
                onTap: () {
                  _key.currentState!.save();
                  debugPrint(body.text);
                  if (Platform.isAndroid) {
                    sendEmail(
                    subject: subject.text,
                    body: body.text,
                    recipientemail: recipientemail,
                    rating: widget.sentRating ?? 1,
                    packageInfo: _packageInfo,
                    brand: brand ?? 'null',
                    device: device ?? 'null',
                  );
                  } else if (Platform.isIOS) {
                    sendEmail(
                    subject: subject.text,
                    body: body.text,
                    recipientemail: recipientemail,
                    rating: widget.sentRating ?? 1,
                    packageInfo: _packageInfo,
                    brand: iosName ?? 'null',
                    device: device ?? 'null',
                  );
                  }
                  
                  body.clear();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Future<void> _getDeviceInfo() async {
    AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
    setState(() {
      brand = androidDeviceInfo.brand;
      device = androidDeviceInfo.device;
    });
  }
  Future<void> getIOSDeviceInfo() async {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    setState(() {
      iosModel = iosInfo.model;
      iosName = iosInfo.name;
    });
  }
}

void sendEmail({
  required String subject,
  required String body,
  required String recipientemail,
  required int rating,
  required PackageInfo packageInfo,
  required String brand,
  required String device,
}) async {
  final email = Email(
    body:
        '$body\nRate: $rating\nVersion: ${packageInfo.version}\nDevice:\n$brand\n$device / ${Platform.operatingSystem}\n[${Platform.operatingSystemVersion}]',
    subject: subject,
    recipients: [recipientemail],
    isHTML: false,
  );
  await FlutterEmailSender.send(email);
}
