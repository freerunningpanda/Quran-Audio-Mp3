import 'dart:io';
import 'dart:ui' as ui;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quran/database/isarschema.dart';
import 'package:quran/utils/fastfunctions.dart';
import 'package:quran/widgets/reuseablewidgets.dart';
import 'package:share_plus/share_plus.dart';

import '../provider/interstitial_provider.dart';
import '../provider/revenue_cat_provider.dart';
import 'res/app_strings.dart';

final statusProvider = riverpod.ChangeNotifierProvider.autoDispose
    .family<StatusMakerController, int>((_, ayahNumber) => StatusMakerController(ayahNumber));

class StatusMakerController with ChangeNotifier {
  GlobalKey statusKey = GlobalKey();
  Ayah? ayahText;
  Ayah? ayahTranslation;
  Surah? surah;
  final int ayahNumber;
  int selectedBackground = 0;
  Color overlayColor = Colors.black;
  double overlay = 0.5;
  double minFontSize = 10.0;
  double maxFontSize = 30.0;
  double fontSize = 20.0;

  updateOverlayColor(Color newOverlayColor) {
    overlayColor = newOverlayColor;
    notifyListeners();
  }

  updateOverlay(double newOverlay) {
    overlay = newOverlay;
    notifyListeners();
  }

  updateFontSize(double newFontSize) {
    fontSize = newFontSize;
    notifyListeners();
  }

  StatusMakerController(this.ayahNumber) {
    genrateAyah(ayahNumber);
  }

  saveToGallery(double pixels) async {
    RenderRepaintBoundary boundary = statusKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: pixels);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    Uint8List pngBytes = byteData!.buffer.asUint8List();
    final directory = (await getApplicationDocumentsDirectory()).path;
    File imgFile = File('$directory/screenshot.png');
    await imgFile.writeAsBytes(pngBytes);
    Share.shareFiles([imgFile.path]);
  }

  updateSelectedBackgrond(int value) {
    selectedBackground = value;
    notifyListeners();
  }

  genrateAyah(int ayahNumber) async {
    List<dynamic> response = await compute(getAyahByNumber, ayahNumber);

    ayahText = response[0];
    ayahTranslation = response[1];
    surah = response[2];

    notifyListeners();
  }
}

class StatusMaker extends riverpod.ConsumerWidget {
  static const id = 'statusMaker';

  final int ayahNumber;

  const StatusMaker({Key? key, required this.ayahNumber}) : super(key: key);

  @override
  Widget build(BuildContext context, riverpod.WidgetRef ref) {
    final sM = ref.watch(statusProvider(ayahNumber));
    return SafeArea(
      child: Scaffold(
          backgroundColor: Theme.of(context).canvasColor,
          appBar: AppBar(backgroundColor: Theme.of(context).canvasColor, title: const Text('Status Maker')),
          body: SingleChildScrollView(
            controller: ScrollController(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RepaintBoundary(
                  key: sM.statusKey,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: GlassMorphism(
                        start: 0.2,
                        end: sM.overlay,
                        color: sM.overlayColor,
                        child: Container(
                          margin: const EdgeInsets.all(15.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: AutoSizeText(
                                  sM.ayahText != null
                                      ? '${sM.ayahText!.text}﴿${arabicNumeric(sM.ayahText!.numberInSurah)}﴾'
                                      : '',
                                  maxFontSize: sM.maxFontSize,
                                  minFontSize: sM.minFontSize,
                                  style: TextStyle(
                                    fontSize: sM.fontSize,
                                    fontFamily: "ScheherazadeNew-Bold",
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.justify,
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: AutoSizeText(
                                  sM.ayahText != null ? sM.ayahTranslation!.text : '',
                                  maxFontSize: sM.maxFontSize,
                                  minFontSize: sM.minFontSize,
                                  style: TextStyle(
                                    fontSize: sM.fontSize,
                                    fontFamily: "NotoNastaliqUrdu-Regular",
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.justify,
                                  textDirection: sM.ayahText != null
                                      ? sM.ayahTranslation!.direction == 'ltr'
                                          ? TextDirection.ltr
                                          : TextDirection.rtl
                                      : TextDirection.ltr,
                                ),
                              ),
                              Center(
                                child: AutoSizeText(
                                  '${sM.surah?.name ?? ''}  ${sM.ayahText?.numberInSurah ?? ''}',
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                  maxFontSize: 15.0,
                                  minFontSize: 10.0,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width / 3,
                                    child: ListTile(
                                      horizontalTitleGap: 0.0,
                                      leading: const FaIcon(
                                        FontAwesomeIcons.googlePlay,
                                        color: Colors.white,
                                      ),
                                      title: Text(
                                        'bit.ly/QuranApp',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white,
                                              fontSize: 9,
                                            ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width / 3,
                                    child: ListTile(
                                      horizontalTitleGap: 0.0,
                                      leading: const FaIcon(
                                        FontAwesomeIcons.instagram,
                                        color: Colors.white,
                                      ),
                                      title: Text(
                                        AppStrings.quranApp,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: Colors.white,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                        onPressed: () async {
                          Clipboard.setData(ClipboardData(
                              text:
                                  '${sM.ayahText!.text}﴿${arabicNumeric(sM.ayahText!.numberInSurah)}﴾\n${sM.ayahTranslation!.text}﴾${sM.ayahTranslation!.numberInSurah}﴿\n${sM.ayahTranslation!.text}\n\n${sM.surah!.englishName} ${sM.ayahText!.numberInSurah}'));
                          showToast(context: context, content: const Text('Copied to clipboard'));
                        },
                        child: const Text('Copy Text')),
                    ElevatedButton(
                        onPressed: () async {
                          await sM.saveToGallery(MediaQuery.of(context).devicePixelRatio);
                        },
                        child: const Text('Share Image')),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Select Overlay',
                        style: TextStyle(
                          height: 2.2,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Pick a color!'),
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: sM.overlayColor,
                                onColorChanged: sM.updateOverlayColor,
                              ),
                            ),
                            actions: <Widget>[
                              ElevatedButton(
                                child: const Text('Got it'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sM.overlayColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: sM.overlay,
                  onChanged: sM.updateOverlay,
                  activeColor: sM.overlayColor,
                  inactiveColor: sM.overlayColor.withOpacity(0.2),
                ),
                const Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Change Font Size',
                    style: TextStyle(
                      height: 2.2,
                      fontSize: 20,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
                Slider(
                  value: sM.fontSize,
                  onChanged: sM.updateFontSize,
                  min: sM.minFontSize,
                  max: sM.maxFontSize,
                  activeColor: sM.overlayColor,
                  inactiveColor: sM.overlayColor.withOpacity(0.2),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        'Select Background',
                        style: TextStyle(
                          height: 2.2,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                    Icon(Icons.arrow_forward)
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
