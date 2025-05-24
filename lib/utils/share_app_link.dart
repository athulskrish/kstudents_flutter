import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareAppLink {
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }

  static Future<void> shareFile(String filePath, {String? text}) async {
    await Share.shareFiles([filePath], text: text);
  }

  static Future<void> shareToWhatsApp(String text) async {
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw Exception('Could not launch WhatsApp');
    }
  }

  static Future<void> shareAppPlayStoreLink() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.example.kerala_tech_reach';
    await shareText('Check out this app: $playStoreUrl');
  }

  static Future<void> shareDeepLink(String deepLink) async {
    await shareText('Check this out: $deepLink');
  }
} 