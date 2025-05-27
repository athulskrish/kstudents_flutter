import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ShareAppLink {
  static Future<void> shareText(String text) async {
    await Share.share(text);
  }
  
  static Future<void> shareFile(String filePath, {String? text}) async {
    try {
      // Create XFile from the file path
      final xFile = XFile(filePath);
      
      // Use shareXFiles with XFile object
      await Share.shareXFiles(
        [xFile], 
        text: text,
      );
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }
  
  static Future<void> shareToWhatsApp(String text) async {
    // Using Uri.encodeComponent is good, but Uri constructor handles encoding for queryParameters.
    final Uri uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      queryParameters: {'text': text}, // Automatically encodes the text
    );
    // Use canLaunchUrl and launchUrl with Uri objects instead of deprecated canLaunch/launch with strings.
    if (await canLaunchUrl(uri)) {
      // It's good practice to specify the launch mode.
      // LaunchMode.externalApplication attempts to open the link in the native app.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('Could not launch WhatsApp. Is it installed? URL: $uri');
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