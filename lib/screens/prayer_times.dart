import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:quran/screens/home.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PrayerList extends ConsumerWidget {
  const PrayerList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, ref) {
    final hP = ref.watch(homeProvider);
    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).canvasColor,
          title: Text(
            AppLocalizations.of(context)!.prayerTimes,
          ),
        ),
        backgroundColor: Theme.of(context).canvasColor,
        body: SizedBox(
          child: ListView.builder(
              itemExtent: 70,
              itemCount: hP.todayCalender.timings.prayers.length,
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemBuilder: (context, index) {
                return PrayerTimeBox(
                  time: DateFormat("h:mm a")
                      .format(DateTime.parse(hP.todayCalender.timings.prayers[index].time).toLocal()),
                  name: hP.todayCalender.timings.prayers[index].name,
                );
              }),
        ),
      ),
    );
  }
}

class PrayerTimeBox extends StatelessWidget {
  final String time;
  final String name;
  const PrayerTimeBox({
    Key? key,
    required this.time,
    required this.name,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).cardColor,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                  ),
                ),
                Text(
                  '${time.split(' ')[0]} ${time.split(' ')[1]}',
                  style: const TextStyle(
                    fontSize: 20,
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
