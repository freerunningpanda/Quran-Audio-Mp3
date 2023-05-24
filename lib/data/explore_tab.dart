import 'package:quran/data/models/explore_tab_model.dart';

import '../screens/res/app_assets.dart';

class ExploreTab {
  static final List<ExploreTabModel> exploreItems = [
    ExploreTabModel(
      index: 0,
      assetName: AppAssets.quran,
    ),
    ExploreTabModel(
      index: 1,
      assetName: AppAssets.audio,
    ),
    ExploreTabModel(
      index: 2,
      assetName: AppAssets.time,
    ),
    ExploreTabModel(
      index: 3,
      assetName: AppAssets.translate,
    ),
    ExploreTabModel(
      index: 4,
      assetName: AppAssets.bookmark,
    ),
    ExploreTabModel(
      index: 5,
      assetName: AppAssets.settings,
    ),
  ];
}
