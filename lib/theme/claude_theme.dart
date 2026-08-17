import 'package:flutter/material.dart';
import 'render_colors.dart';

enum AppThemeId {
  claudeWarmDark,
  obsidianOnyx,
  forestEvergreen,
  nordicArctic,
  espressoAmber,
}

class AppThemeData {
  final AppThemeId id;
  final String name;
  final String description;

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgSidebar;
  final Color bgCard;
  final Color bgCardHover;
  final Color bgElevated;
  final Color bgCode;
  final Color bgInput;

  final Color accent;
  final Color accentHover;
  final Color accentSubtle;
  final Color accentGlow;
  final Color amber;
  final Color sage;
  final Color sky;
  final Color lavender;
  final Color crimson;

  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  final Color border;
  final Color borderSubtle;
  final Color borderHover;
  final Color borderFocus;

  final Color cardBaseColor;
  final Color cardHoverColor;
  final Color folderAccent;
  final Color noteAccent;
  final Color searchBarBg;

  final List<Color> previewPalette;

  const AppThemeData({
    required this.id,
    required this.name,
    required this.description,
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgSidebar,
    required this.bgCard,
    required this.bgCardHover,
    required this.bgElevated,
    required this.bgCode,
    required this.bgInput,
    required this.accent,
    required this.accentHover,
    required this.accentSubtle,
    required this.accentGlow,
    required this.amber,
    required this.sage,
    required this.sky,
    required this.lavender,
    required this.crimson,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.borderSubtle,
    required this.borderHover,
    required this.borderFocus,
    required this.cardBaseColor,
    required this.cardHoverColor,
    required this.folderAccent,
    required this.noteAccent,
    required this.searchBarBg,
    required this.previewPalette,
  });

  static const AppThemeData claudeWarmDark = AppThemeData(
    id: AppThemeId.claudeWarmDark,
    name: 'Claude Warm Dark',
    description: 'Signature warm charcoal, cozy espresso & terracotta accents.',
    bgCanvas: Color(0xFF181816),
    bgSurface: Color(0xFF1F1E1B),
    bgSidebar: Color(0xFF141312),
    bgCard: Color(0xFF21201D),
    bgCardHover: Color(0xFF282724),
    bgElevated: Color(0xFF2D2C28),
    bgCode: Color(0xFF1C1B19),
    bgInput: Color(0xFF21201D),
    accent: Color(0xFFD97757),
    accentHover: Color(0xFFE58B6D),
    accentSubtle: Color(0x26D97757),
    accentGlow: Color(0x40D97757),
    amber: Color(0xFFD49B55),
    sage: Color(0xFF7EBF8E),
    sky: Color(0xFF6CB6EB),
    lavender: Color(0xFFB57EDC),
    crimson: Color(0xFFE06C75),
    textPrimary: Color(0xFFECEBE6),
    textSecondary: Color(0xFFA8A69E),
    textTertiary: Color(0xFF737169),
    textDisabled: Color(0xFF52504B),
    border: Color(0xFF2B2A26),
    borderSubtle: Color(0xFF242320),
    borderHover: Color(0xFF403E38),
    borderFocus: Color(0xFFD97757),
    cardBaseColor: Color(0xFF292928),
    cardHoverColor: Color(0xFF343433),
    folderAccent: Color(0xFFE5C07B),
    noteAccent: Color(0xFF9893A5),
    searchBarBg: Color(0xFF24221F),
    previewPalette: [
      Color(0xFF181816),
      Color(0xFF292928),
      Color(0xFFD97757),
      Color(0xFFE5C07B),
    ],
  );

  static const AppThemeData obsidianOnyx = AppThemeData(
    id: AppThemeId.obsidianOnyx,
    name: 'Obsidian Onyx',
    description: 'Deep pitch-black canvas with refined slate-violet & lilac accents.',
    bgCanvas: Color(0xFF0E0E11),
    bgSurface: Color(0xFF141418),
    bgSidebar: Color(0xFF09090C),
    bgCard: Color(0xFF18181F),
    bgCardHover: Color(0xFF202029),
    bgElevated: Color(0xFF23232C),
    bgCode: Color(0xFF121217),
    bgInput: Color(0xFF16161D),
    accent: Color(0xFF908CAA),
    accentHover: Color(0xFFA5A1C2),
    accentSubtle: Color(0x26908CAA),
    accentGlow: Color(0x40908CAA),
    amber: Color(0xFFEBBCBA),
    sage: Color(0xFF9CCFD8),
    sky: Color(0xFF31748F),
    lavender: Color(0xFFC4A7E7),
    crimson: Color(0xFFEB6F92),
    textPrimary: Color(0xFFE0DEF4),
    textSecondary: Color(0xFF908CAA),
    textTertiary: Color(0xFF6E6A86),
    textDisabled: Color(0xFF524F67),
    border: Color(0xFF26233A),
    borderSubtle: Color(0xFF1F1D2E),
    borderHover: Color(0xFF393552),
    borderFocus: Color(0xFF908CAA),
    cardBaseColor: Color(0xFF181822),
    cardHoverColor: Color(0xFF242432),
    folderAccent: Color(0xFFEB6F92),
    noteAccent: Color(0xFF9CCFD8),
    searchBarBg: Color(0xFF161620),
    previewPalette: [
      Color(0xFF0E0E11),
      Color(0xFF181822),
      Color(0xFF908CAA),
      Color(0xFFEB6F92),
    ],
  );

  static const AppThemeData forestEvergreen = AppThemeData(
    id: AppThemeId.forestEvergreen,
    name: 'Evergreen Forest',
    description: 'Calm deep pine greens paired with fresh sage and golden straw.',
    bgCanvas: Color(0xFF101613),
    bgSurface: Color(0xFF161E1A),
    bgSidebar: Color(0xFF0C110E),
    bgCard: Color(0xFF1C2721),
    bgCardHover: Color(0xFF23322B),
    bgElevated: Color(0xFF26362F),
    bgCode: Color(0xFF131A16),
    bgInput: Color(0xFF18221D),
    accent: Color(0xFF4EAD7B),
    accentHover: Color(0xFF65C492),
    accentSubtle: Color(0x264EAD7B),
    accentGlow: Color(0x404EAD7B),
    amber: Color(0xFFE0AF68),
    sage: Color(0xFF73DACA),
    sky: Color(0xFF7AA2F7),
    lavender: Color(0xFFBB9AF7),
    crimson: Color(0xFFF7768E),
    textPrimary: Color(0xFFE6F0EB),
    textSecondary: Color(0xFFA1B8AC),
    textTertiary: Color(0xFF688073),
    textDisabled: Color(0xFF475B50),
    border: Color(0xFF22342A),
    borderSubtle: Color(0xFF1B2A22),
    borderHover: Color(0xFF334C3E),
    borderFocus: Color(0xFF4EAD7B),
    cardBaseColor: Color(0xFF1A2620),
    cardHoverColor: Color(0xFF24352C),
    folderAccent: Color(0xFFE0AF68),
    noteAccent: Color(0xFF73DACA),
    searchBarBg: Color(0xFF18231D),
    previewPalette: [
      Color(0xFF101613),
      Color(0xFF1A2620),
      Color(0xFF4EAD7B),
      Color(0xFFE0AF68),
    ],
  );

  static const AppThemeData nordicArctic = AppThemeData(
    id: AppThemeId.nordicArctic,
    name: 'Nordic Arctic',
    description: 'Polar twilight slate & glacier frost blue inspired by Nordic palettes.',
    bgCanvas: Color(0xFF12161F),
    bgSurface: Color(0xFF181D28),
    bgSidebar: Color(0xFF0E1119),
    bgCard: Color(0xFF1F2635),
    bgCardHover: Color(0xFF273144),
    bgElevated: Color(0xFF2B364A),
    bgCode: Color(0xFF151A24),
    bgInput: Color(0xFF1A212E),
    accent: Color(0xFF5E81AC),
    accentHover: Color(0xFF81A1C1),
    accentSubtle: Color(0x265E81AC),
    accentGlow: Color(0x405E81AC),
    amber: Color(0xFFEBCB8B),
    sage: Color(0xFFA3BE8C),
    sky: Color(0xFF88C0D0),
    lavender: Color(0xFFB48EAD),
    crimson: Color(0xFFBF616A),
    textPrimary: Color(0xFFECEFF4),
    textSecondary: Color(0xFFD8DEE9),
    textTertiary: Color(0xFF7B88A1),
    textDisabled: Color(0xFF4C566A),
    border: Color(0xFF2E3440),
    borderSubtle: Color(0xFF242933),
    borderHover: Color(0xFF434C5E),
    borderFocus: Color(0xFF88C0D0),
    cardBaseColor: Color(0xFF1E2638),
    cardHoverColor: Color(0xFF28334A),
    folderAccent: Color(0xFF88C0D0),
    noteAccent: Color(0xFF81A1C1),
    searchBarBg: Color(0xFF1A2232),
    previewPalette: [
      Color(0xFF12161F),
      Color(0xFF1E2638),
      Color(0xFF5E81AC),
      Color(0xFF88C0D0),
    ],
  );

  static const AppThemeData espressoAmber = AppThemeData(
    id: AppThemeId.espressoAmber,
    name: 'Espresso Amber',
    description: 'Warm roasted coffee bean tones with rich honey amber & cinnamon highlights.',
    bgCanvas: Color(0xFF191410),
    bgSurface: Color(0xFF211B16),
    bgSidebar: Color(0xFF130F0C),
    bgCard: Color(0xFF2A231C),
    bgCardHover: Color(0xFF352B23),
    bgElevated: Color(0xFF3B3027),
    bgCode: Color(0xFF1B1511),
    bgInput: Color(0xFF231C16),
    accent: Color(0xFFE08D46),
    accentHover: Color(0xFFEE9E59),
    accentSubtle: Color(0x26E08D46),
    accentGlow: Color(0x40E08D46),
    amber: Color(0xFFD9A05B),
    sage: Color(0xFF8EA672),
    sky: Color(0xFF7EA2B6),
    lavender: Color(0xFFB896B0),
    crimson: Color(0xFFD96B6B),
    textPrimary: Color(0xFFF2ECE6),
    textSecondary: Color(0xFFB8AA9D),
    textTertiary: Color(0xFF7A6D60),
    textDisabled: Color(0xFF574C41),
    border: Color(0xFF382F26),
    borderSubtle: Color(0xFF2E261E),
    borderHover: Color(0xFF4F4236),
    borderFocus: Color(0xFFE08D46),
    cardBaseColor: Color(0xFF2B231D),
    cardHoverColor: Color(0xFF382D24),
    folderAccent: Color(0xFFD9A05B),
    noteAccent: Color(0xFFB8AA9D),
    searchBarBg: Color(0xFF251E18),
    previewPalette: [
      Color(0xFF191410),
      Color(0xFF2B231D),
      Color(0xFFE08D46),
      Color(0xFFD9A05B),
    ],
  );

  static const List<AppThemeData> allThemes = [
    claudeWarmDark,
    obsidianOnyx,
    forestEvergreen,
    nordicArctic,
    espressoAmber,
  ];

  static AppThemeData fromId(AppThemeId id) {
    return allThemes.firstWhere(
      (t) => t.id == id,
      orElse: () => claudeWarmDark,
    );
  }

  ThemeData toThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgCanvas,
      canvasColor: bgCanvas,
      primaryColor: accent,
      colorScheme: ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: amber,
        surface: bgCard,
        onSurface: textPrimary,
        error: crimson,
        outline: border,
      ),
      fontFamily: 'Segoe UI',
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 13,
          height: 1.5,
          color: textSecondary,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: textTertiary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: textTertiary,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(
        color: textSecondary,
        size: 20,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: TextStyle(color: textTertiary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(textTertiary.withValues(alpha: 0.3)),
        radius: const Radius.circular(8),
        thickness: WidgetStateProperty.all(6),
      ),
    );
  }
}

/// Global theme accessor with dynamic theme switching support.
class ClaudeTheme {
  static AppThemeData _current = AppThemeData.claudeWarmDark;
  static RenderColors _renderColors = RenderColors.defaultsFor(AppThemeData.claudeWarmDark);
  static Map<String, int> _renderOverrides = {};
  static Map<String, String> _fontAssignments = {
    'ui': 'Inter',
    'headings': 'Inter',
    'notes': 'Inter',
    'monospace': 'JetBrains Mono',
  };

  static AppThemeData get current => _current;
  static RenderColors get renderColors => _renderColors;
  static Map<String, int> get renderOverrides => _renderOverrides;
  static Map<String, String> get fontAssignments => Map.unmodifiable(_fontAssignments);

  static String get uiFont => _fontAssignments['ui'] ?? 'Inter';
  static String get headingsFont => _fontAssignments['headings'] ?? 'Inter';
  static String get notesFont => _fontAssignments['notes'] ?? 'Inter';
  static String get monospaceFont => _fontAssignments['monospace'] ?? 'JetBrains Mono';

  static void setFontAssignment(String slot, String? family) {
    if (family == null || family.isEmpty || family == 'Default') {
      _fontAssignments.remove(slot);
    } else {
      _fontAssignments[slot] = family;
    }
  }

  static void setAllFontAssignments(Map<String, String> fonts) {
    _fontAssignments = Map.from(fonts);
  }

  static void setTheme(AppThemeId id) {
    _current = AppThemeData.fromId(id);
    _renderColors = RenderColors.merge(RenderColors.defaultsFor(_current), _renderOverrides);
  }

  static void setRenderOverride(String key, int? argbColor) {
    if (argbColor == null) {
      _renderOverrides.remove(key);
    } else {
      _renderOverrides[key] = argbColor;
    }
    _renderColors = RenderColors.merge(RenderColors.defaultsFor(_current), _renderOverrides);
  }

  static void setAllRenderOverrides(Map<String, int> overrides) {
    _renderOverrides = Map.from(overrides);
    _renderColors = RenderColors.merge(RenderColors.defaultsFor(_current), _renderOverrides);
  }

  static void resetAllRenderOverrides() {
    _renderOverrides.clear();
    _renderColors = RenderColors.defaultsFor(_current);
  }

  // ── Palette Accessors ──
  static Color get bgCanvas => _current.bgCanvas;
  static Color get bgSurface => _current.bgSurface;
  static Color get bgSidebar => _current.bgSidebar;
  static Color get bgCard => _current.bgCard;
  static Color get bgCardHover => _current.bgCardHover;
  static Color get bgElevated => _current.bgElevated;
  static Color get bgCode => _current.bgCode;
  static Color get bgInput => _current.bgInput;

  static Color get accent => _current.accent;
  static Color get accentHover => _current.accentHover;
  static Color get accentSubtle => _current.accentSubtle;
  static Color get accentGlow => _current.accentGlow;
  static Color get amber => _current.amber;
  static Color get sage => _current.sage;
  static Color get sky => _current.sky;
  static Color get lavender => _current.lavender;
  static Color get crimson => _current.crimson;

  static Color get textPrimary => _current.textPrimary;
  static Color get textSecondary => _current.textSecondary;
  static Color get textTertiary => _current.textTertiary;
  static Color get textDisabled => _current.textDisabled;

  static Color get border => _current.border;
  static Color get borderSubtle => _current.borderSubtle;
  static Color get borderHover => _current.borderHover;
  static Color get borderFocus => _current.borderFocus;

  static Color get cardBaseColor => _current.cardBaseColor;
  static Color get cardHoverColor => _current.cardHoverColor;
  static Color get folderAccent => _current.folderAccent;
  static Color get noteAccent => _current.noteAccent;
  static Color get searchBarBg => _current.searchBarBg;

  // ── Shadows ──
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get popupShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get subtleGlow => [
        BoxShadow(
          color: _current.accent.withValues(alpha: 0.2),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ];

  static ThemeData get darkTheme => _current.toThemeData();
}
