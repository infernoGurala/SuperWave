import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

/// Represents a Google Font item with metadata and download URL.
class GoogleFontItem {
  final String family;
  final String category; // 'sans-serif', 'serif', 'monospace', 'display', 'handwriting'
  final List<String> variants;
  final String? previewUrl;
  final String? ttfUrl;

  const GoogleFontItem({
    required this.family,
    required this.category,
    this.variants = const ['regular', '700'],
    this.previewUrl,
    this.ttfUrl,
  });

  Map<String, dynamic> toJson() => {
    'family': family,
    'category': category,
    'variants': variants,
    'ttfUrl': ttfUrl,
  };

  factory GoogleFontItem.fromJson(Map<String, dynamic> json) {
    return GoogleFontItem(
      family: json['family'] as String? ?? 'Inter',
      category: json['category'] as String? ?? 'sans-serif',
      variants: (json['variants'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const ['regular'],
      ttfUrl: json['ttfUrl'] as String?,
    );
  }
}

/// Target slots where custom fonts can be applied in SuperWave
enum TypographySlot {
  ui('General UI', 'Primary application user interface font'),
  headings('Headings & Titles', 'Section headers and note title text'),
  notes('Note Document', 'Markdown note reading and editor typography'),
  monospace('Code & Monospace', 'Code blocks, metadata chips, and terminal logs');

  final String label;
  final String description;
  const TypographySlot(this.label, this.description);
}

class FontManager {
  static final Set<String> _loadedFontFamilies = {};

  /// Get the local fonts directory: `<vaultPath>/.superwave/style/fonts`
  static String getFontsDir(String vaultPath) =>
      p.join(vaultPath, '.superwave', 'style', 'fonts');

  /// Get typeface folder: `<vaultPath>/.superwave/style/fonts/<typefacename>`
  static String getTypefaceDir(String vaultPath, String typefacename) =>
      p.join(getFontsDir(vaultPath), typefacename);

  /// Curated collection of top Google Fonts with pre-resolved reliable TTF sources
  static final List<GoogleFontItem> popularGoogleFonts = [
    // Sans-Serif
    const GoogleFontItem(
      family: 'Inter',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Roboto',
      category: 'sans-serif',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/roboto/Roboto%5Bwdth%2Cwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Outfit',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/outfit/Outfit%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Poppins',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/poppins/Poppins-Regular.ttf',
    ),
    const GoogleFontItem(
      family: 'Plus Jakarta Sans',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/plusjakartasans/PlusJakartaSans%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Montserrat',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/montserrat/Montserrat%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Open Sans',
      category: 'sans-serif',
      variants: ['regular', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/opensans/OpenSans%5Bwdth%2Cwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Geist',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/geist/Geist%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Rubik',
      category: 'sans-serif',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/rubik/Rubik%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Manrope',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/manrope/Manrope%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Work Sans',
      category: 'sans-serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/worksans/WorkSans%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Nunito',
      category: 'sans-serif',
      variants: ['regular', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/nunito/Nunito%5Bwght%5D.ttf',
    ),

    // Monospace
    const GoogleFontItem(
      family: 'JetBrains Mono',
      category: 'monospace',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Fira Code',
      category: 'monospace',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/firacode/FiraCode%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Space Mono',
      category: 'monospace',
      variants: ['regular', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/spacemono/SpaceMono-Regular.ttf',
    ),
    const GoogleFontItem(
      family: 'Inconsolata',
      category: 'monospace',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/inconsolata/Inconsolata%5Bwdth%2Cwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Geist Mono',
      category: 'monospace',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/geistmono/GeistMono%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'IBM Plex Mono',
      category: 'monospace',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexmono/IBMPlexMono-Regular.ttf',
    ),
    const GoogleFontItem(
      family: 'Source Code Pro',
      category: 'monospace',
      variants: ['regular', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/sourcecodepro/SourceCodePro%5Bwght%5D.ttf',
    ),

    // Serif
    const GoogleFontItem(
      family: 'Playfair Display',
      category: 'serif',
      variants: ['regular', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/playfairdisplay/PlayfairDisplay%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Merriweather',
      category: 'serif',
      variants: ['regular', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/merriweather/Merriweather-Regular.ttf',
    ),
    const GoogleFontItem(
      family: 'Lora',
      category: 'serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/lora/Lora%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Cinzel',
      category: 'serif',
      variants: ['regular', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/cinzel/Cinzel%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'EB Garamond',
      category: 'serif',
      variants: ['regular', '500', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/ebgaramond/EBGaramond%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Newsreader',
      category: 'serif',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/newsreader/Newsreader%5Bopsz%2Cwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Source Serif 4',
      category: 'serif',
      variants: ['regular', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/sourceserif4/SourceSerif4%5Bopsz%2Cwght%5D.ttf',
    ),

    // Display & Aesthetic
    const GoogleFontItem(
      family: 'Syne',
      category: 'display',
      variants: ['regular', '600', '700', '800'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/syne/Syne%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Oswald',
      category: 'display',
      variants: ['regular', '500', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/oswald/Oswald%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Cabinet Grotesk',
      category: 'display',
      variants: ['regular', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/cabinetgrotesk/CabinetGrotesk%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Clash Display',
      category: 'display',
      variants: ['regular', '600', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/clashdisplay/ClashDisplay%5Bwght%5D.ttf',
    ),
    const GoogleFontItem(
      family: 'Caveat',
      category: 'handwriting',
      variants: ['regular', '700'],
      ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/caveat/Caveat%5Bwght%5D.ttf',
    ),
  ];

  /// Search Google Fonts catalog and dynamic remote font registry
  static Future<List<GoogleFontItem>> searchFonts(String query, {String? category}) async {
    final cleanQuery = query.trim().toLowerCase();
    List<GoogleFontItem> results = popularGoogleFonts.where((f) {
      if (category != null && category != 'all' && f.category.toLowerCase() != category.toLowerCase()) {
        return false;
      }
      if (cleanQuery.isEmpty) return true;
      return f.family.toLowerCase().contains(cleanQuery);
    }).toList();

    // If query didn't find direct curated match and query is non-empty, try resolving from Google Fonts repo
    if (cleanQuery.isNotEmpty && results.isEmpty) {
      final sanitized = cleanQuery.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final formattedName = query.trim().split(' ').map((s) => s.isNotEmpty ? s[0].toUpperCase() + s.substring(1) : '').join(' ');
      results.add(
        GoogleFontItem(
          family: formattedName,
          category: category ?? 'sans-serif',
          ttfUrl: 'https://raw.githubusercontent.com/google/fonts/main/ofl/$sanitized/$formattedName-Regular.ttf',
        ),
      );
    }

    return results;
  }

  /// Check if a font is already downloaded locally in `<vaultPath>/.superwave/style/fonts/<typefaceName>`
  static bool isFontDownloaded(String vaultPath, String typefaceName) {
    try {
      final typefaceDir = Directory(getTypefaceDir(vaultPath, typefaceName));
      if (!typefaceDir.existsSync()) return false;
      final files = typefaceDir.listSync().whereType<File>().where((f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf'));
      return files.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Get list of all installed font families in the vault's `.superwave/style/fonts` directory
  static List<String> getInstalledFonts(String vaultPath) {
    final List<String> fonts = [];
    try {
      final dir = Directory(getFontsDir(vaultPath));
      if (dir.existsSync()) {
        for (final entity in dir.listSync()) {
          if (entity is Directory) {
            final name = p.basename(entity.path);
            final hasFontFiles = entity.listSync().whereType<File>().any((f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf'));
            if (hasFontFiles) {
              fonts.add(name);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error listing installed fonts: $e');
    }
    return fonts;
  }

  /// Load a single local font file into Flutter's FontLoader runtime
  static Future<bool> loadFontFamilyFromDisk(String familyName, File fontFile) async {
    if (_loadedFontFamilies.contains(familyName)) return true;
    try {
      final bytes = await fontFile.readAsBytes();
      final fontLoader = FontLoader(familyName);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer)));
      await fontLoader.load();
      _loadedFontFamilies.add(familyName);
      debugPrint('Successfully registered font family "$familyName" from ${fontFile.path}');
      return true;
    } catch (e) {
      debugPrint('Error registering font family "$familyName": $e');
      return false;
    }
  }

  /// Scan and dynamically register all font files in `<vaultPath>/.superwave/style/fonts`
  static Future<void> loadAllVaultFonts(String vaultPath) async {
    try {
      final fontsDir = Directory(getFontsDir(vaultPath));
      if (!fontsDir.existsSync()) return;

      for (final entity in fontsDir.listSync()) {
        if (entity is Directory) {
          final familyName = p.basename(entity.path);
          final fontFiles = entity.listSync().whereType<File>().where((f) => f.path.endsWith('.ttf') || f.path.endsWith('.otf')).toList();
          for (final file in fontFiles) {
            await loadFontFamilyFromDisk(familyName, file);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning and loading vault fonts: $e');
    }
  }

  /// Download a Google Font and save into `\.superwave\style\fonts\<typefacename>\<fontname>`
  /// Then dynamically registers the font in Flutter.
  static Future<File?> downloadAndInstallFont({
    required String vaultPath,
    required GoogleFontItem fontItem,
    void Function(double progress)? onProgress,
  }) async {
    try {
      final typefaceName = fontItem.family;
      final fontFileName = '${typefaceName.replaceAll(RegExp(r'\s+'), '')}-Regular.ttf';
      final targetDir = Directory(getTypefaceDir(vaultPath, typefaceName));

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final targetFile = File(p.join(targetDir.path, fontFileName));

      // Build primary & fallback download URLs
      final sanitized = typefaceName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final nameClean = typefaceName.replaceAll(' ', '');

      final List<String> candidateUrls = [
        if (fontItem.ttfUrl != null && fontItem.ttfUrl!.isNotEmpty) fontItem.ttfUrl!,
        'https://raw.githubusercontent.com/google/fonts/main/ofl/$sanitized/$nameClean%5Bwght%5D.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/$sanitized/$nameClean-Regular.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/ofl/$sanitized/$nameClean%5Bopsz%2Cwght%5D.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/apache/$sanitized/$nameClean%5Bwght%5D.ttf',
        'https://raw.githubusercontent.com/google/fonts/main/apache/$sanitized/$nameClean-Regular.ttf',
      ];

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 12);
      Uint8List? downloadedBytes;

      for (final url in candidateUrls) {
        try {
          final uri = Uri.parse(url);
          final request = await client.getUrl(uri);
          final response = await request.close();

          if (response.statusCode == 200) {
            final contentLength = response.contentLength;
            final bytesBuilder = BytesBuilder();
            int received = 0;

            await for (final chunk in response) {
              bytesBuilder.add(chunk);
              received += chunk.length;
              if (contentLength > 0 && onProgress != null) {
                onProgress(received / contentLength);
              }
            }

            final data = bytesBuilder.takeBytes();
            if (data.length > 500) { // Valid font file threshold
              downloadedBytes = data;
              break;
            }
          }
        } catch (_) {
          continue;
        }
      }

      client.close();

      if (downloadedBytes == null) {
        throw Exception('Unable to download font file for "${fontItem.family}" from Google Fonts mirrors.');
      }

      await targetFile.writeAsBytes(downloadedBytes);
      debugPrint('Font saved to: ${targetFile.path}');

      // Register font in Flutter runtime
      await loadFontFamilyFromDisk(typefaceName, targetFile);

      return targetFile;
    } catch (e) {
      debugPrint('Error downloading font ${fontItem.family}: $e');
      rethrow;
    }
  }

  /// Delete an installed font from `<vaultPath>/.superwave/style/fonts/<typefacename>`
  static bool deleteFont(String vaultPath, String typefaceName) {
    try {
      final dir = Directory(getTypefaceDir(vaultPath, typefaceName));
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting font $typefaceName: $e');
    }
    return false;
  }
}
