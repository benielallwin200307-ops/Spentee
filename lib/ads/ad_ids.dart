// AdMob IDs for Spentee
// Switch `kUseProductionAds` to true for a production build.

const bool kUseProductionAds = false; // <- toggle before release

// Test IDs (Google provided)
const String kTestAppId = 'ca-app-pub-3940256099942544~3347511713';
const String kTestBannerHome = 'ca-app-pub-3940256099942544/6300978111';
const String kTestBannerInsights = 'ca-app-pub-3940256099942544/6300978111';
const String kTestBannerChat = 'ca-app-pub-3940256099942544/6300978111';

// Production IDs (provided by the user)
const String kProdAppId = 'ca-app-pub-9526005860341067~7604632541';
const String kProdBannerHome = 'ca-app-pub-9526005860341067/7221489161';
const String kProdBannerInsights = 'ca-app-pub-9526005860341067/2678797822';
const String kProdBannerChat = 'ca-app-pub-9526005860341067/9052634485';

String getAppId() => kUseProductionAds ? kProdAppId : kTestAppId;
String getBannerAdUnitIdHome() => kUseProductionAds ? kProdBannerHome : kTestBannerHome;
String getBannerAdUnitIdInsights() => kUseProductionAds ? kProdBannerInsights : kTestBannerInsights;
String getBannerAdUnitIdChat() => kUseProductionAds ? kProdBannerChat : kTestBannerChat;
