import 'package:flutter/material.dart';

/// Physical-material theme definitions for Anagrams.
/// Every theme describes a real workshop scene: wood bench background,
/// felt/leather letter tray, brass accents — never neon, never flat.
class TileThemeDef {
  final String id;
  final String name;
  final Color woodDark; // app background (dark wood)
  final Color woodMid; // card surfaces (mid wood)
  final Color woodDeep; // deepest shadow
  final Color accent; // brass / metal trim
  final Color accentLight;
  final Color accentDark;
  final Color ivory; // primary text
  final Color tray; // letter-tray surface
  final Color trayEdge; // letter-tray edge/frame
  final Color tileFace; // default letter-tile face
  final Color tileEdge; // default letter-tile edge
  final Color tileText; // default letter-tile text
  final List<Color> playerColors; // duel player accents [P1, P2]

  const TileThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.woodDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.ivory,
    required this.tray,
    required this.trayEdge,
    required this.tileFace,
    required this.tileEdge,
    required this.tileText,
    required this.playerColors,
  });
}

class TileThemes {
  /// First [freeCount] themes are free; the rest are Pro.
  static const freeCount = 12;

  static const List<TileThemeDef> all = [
    TileThemeDef(
      id: 'classic',
      name: 'Classic Oak',
      woodDark: Color(0xFF2E1D12),
      woodMid: Color(0xFF4A2F1C),
      woodDeep: Color(0xFF1A100A),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF5EFE0),
      tray: Color(0xFF1E4D3B),
      trayEdge: Color(0xFF3B2416),
      tileFace: Color(0xFFE8D5A3),
      tileEdge: Color(0xFFB89B5E),
      tileText: Color(0xFF2E1D12),
      playerColors: [Color(0xFFA31621), Color(0xFF1D4E9E)],
    ),
    TileThemeDef(
      id: 'walnut',
      name: 'Walnut Study',
      woodDark: Color(0xFF241A10),
      woodMid: Color(0xFF3D2C1B),
      woodDeep: Color(0xFF140D07),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      ivory: Color(0xFFF1E8D2),
      tray: Color(0xFF274B3E),
      trayEdge: Color(0xFF2B1E12),
      tileFace: Color(0xFFDFC88F),
      tileEdge: Color(0xFFA8894E),
      tileText: Color(0xFF241A10),
      playerColors: [Color(0xFFB33A2B), Color(0xFF2B6CB0)],
    ),
    TileThemeDef(
      id: 'cherry',
      name: 'Cherry Workshop',
      woodDark: Color(0xFF331A12),
      woodMid: Color(0xFF5C2E1E),
      woodDeep: Color(0xFF1C0E08),
      accent: Color(0xFFD9A441),
      accentLight: Color(0xFFF0CE7E),
      accentDark: Color(0xFF96621C),
      ivory: Color(0xFFF7EBD8),
      tray: Color(0xFF2A4A44),
      trayEdge: Color(0xFF38200F),
      tileFace: Color(0xFFF0DCA8),
      tileEdge: Color(0xFFC19A5B),
      tileText: Color(0xFF331A12),
      playerColors: [Color(0xFFC0392B), Color(0xFF2471A3)],
    ),
    TileThemeDef(
      id: 'ebony',
      name: 'Ebony & Ivory',
      woodDark: Color(0xFF12100D),
      woodMid: Color(0xFF26211A),
      woodDeep: Color(0xFF080706),
      accent: Color(0xFFB0B7C3),
      accentLight: Color(0xFFE3E7ED),
      accentDark: Color(0xFF6E7480),
      ivory: Color(0xFFF4F1E8),
      tray: Color(0xFF3A322A),
      trayEdge: Color(0xFF15120D),
      tileFace: Color(0xFFF4EEDC),
      tileEdge: Color(0xFFC9BFA4),
      tileText: Color(0xFF1A1611),
      playerColors: [Color(0xFFD64550), Color(0xFF4A90D9)],
    ),
    TileThemeDef(
      id: 'maple',
      name: 'Maple Bright',
      woodDark: Color(0xFF3B2A16),
      woodMid: Color(0xFF5E4525),
      woodDeep: Color(0xFF221806),
      accent: Color(0xFFE0B23C),
      accentLight: Color(0xFFF6DA8E),
      accentDark: Color(0xFF9A7418),
      ivory: Color(0xFFFAF3E2),
      tray: Color(0xFF2E5B4C),
      trayEdge: Color(0xFF402E15),
      tileFace: Color(0xFFF6E7BE),
      tileEdge: Color(0xFFD0AF6B),
      tileText: Color(0xFF3B2A16),
      playerColors: [Color(0xFFB03A2E), Color(0xFF1A6EA8)],
    ),
    TileThemeDef(
      id: 'rosewood',
      name: 'Rosewood',
      woodDark: Color(0xFF2C1216),
      woodMid: Color(0xFF4E2229),
      woodDeep: Color(0xFF160709),
      accent: Color(0xFFD4A24A),
      accentLight: Color(0xFFF2CD85),
      accentDark: Color(0xFF8F6420),
      ivory: Color(0xFFF6EAD9),
      tray: Color(0xFF23413B),
      trayEdge: Color(0xFF33151B),
      tileFace: Color(0xFFEBD3A0),
      tileEdge: Color(0xFFB98E52),
      tileText: Color(0xFF2C1216),
      playerColors: [Color(0xFFC0392B), Color(0xFF2E86C1)],
    ),
    TileThemeDef(
      id: 'mahogany',
      name: 'Mahogany',
      woodDark: Color(0xFF2B1610),
      woodMid: Color(0xFF4C2718),
      woodDeep: Color(0xFF150906),
      accent: Color(0xFFC9902E),
      accentLight: Color(0xFFEDC276),
      accentDark: Color(0xFF8A5F14),
      ivory: Color(0xFFF5EADA),
      tray: Color(0xFF1F4A3D),
      trayEdge: Color(0xFF311910),
      tileFace: Color(0xFFE6D09A),
      tileEdge: Color(0xFFB08A4F),
      tileText: Color(0xFF2B1610),
      playerColors: [Color(0xFFA93226), Color(0xFF1F6FB2)],
    ),
    TileThemeDef(
      id: 'driftwood',
      name: 'Driftwood',
      woodDark: Color(0xFF2A2620),
      woodMid: Color(0xFF46403A),
      woodDeep: Color(0xFF161310),
      accent: Color(0xFFC4A86A),
      accentLight: Color(0xFFE8D5A4),
      accentDark: Color(0xFF85703F),
      ivory: Color(0xFFF2EDE2),
      tray: Color(0xFF2E4B4A),
      trayEdge: Color(0xFF2F2A22),
      tileFace: Color(0xFFE9DEBE),
      tileEdge: Color(0xFFB5A47E),
      tileText: Color(0xFF2A2620),
      playerColors: [Color(0xFF9C3B2E), Color(0xFF2F6FA8)],
    ),
    TileThemeDef(
      id: 'cabin',
      name: 'Forest Cabin',
      woodDark: Color(0xFF1F2418),
      woodMid: Color(0xFF38402A),
      woodDeep: Color(0xFF0E110A),
      accent: Color(0xFFC9A24A),
      accentLight: Color(0xFFEDCD8A),
      accentDark: Color(0xFF8A6824),
      ivory: Color(0xFFF1EDDD),
      tray: Color(0xFF2C4436),
      trayEdge: Color(0xFF232A18),
      tileFace: Color(0xFFE3D49E),
      tileEdge: Color(0xFFAD9457),
      tileText: Color(0xFF1F2418),
      playerColors: [Color(0xFFB4452F), Color(0xFF3D7DB5)],
    ),
    TileThemeDef(
      id: 'barn',
      name: 'Autumn Barn',
      woodDark: Color(0xFF2E2013),
      woodMid: Color(0xFF503723),
      woodDeep: Color(0xFF191009),
      accent: Color(0xFFD18A35),
      accentLight: Color(0xFFF0BB72),
      accentDark: Color(0xFF8F5A18),
      ivory: Color(0xFFF7ECDA),
      tray: Color(0xFF7A2E1D),
      trayEdge: Color(0xFF362512),
      tileFace: Color(0xFFEFDAAC),
      tileEdge: Color(0xFFC29A5C),
      tileText: Color(0xFF2E2013),
      playerColors: [Color(0xFF9E2B1E), Color(0xFF1D5C8A)],
    ),
    TileThemeDef(
      id: 'coffee',
      name: 'Coffee House',
      woodDark: Color(0xFF211510),
      woodMid: Color(0xFF3B2518),
      woodDeep: Color(0xFF0F0906),
      accent: Color(0xFFC08552),
      accentLight: Color(0xFFE8B987),
      accentDark: Color(0xFF7E5527),
      ivory: Color(0xFFF3E7D5),
      tray: Color(0xFF2E3A35),
      trayEdge: Color(0xFF251913),
      tileFace: Color(0xFFE9D2A6),
      tileEdge: Color(0xFFB28F5D),
      tileText: Color(0xFF211510),
      playerColors: [Color(0xFFA63A2A), Color(0xFF2B6E96)],
    ),
    TileThemeDef(
      id: 'lighthouse',
      name: 'Lighthouse',
      woodDark: Color(0xFF1E2830),
      woodMid: Color(0xFF35434E),
      woodDeep: Color(0xFF0F1418),
      accent: Color(0xFFD9A441),
      accentLight: Color(0xFFF2CE7E),
      accentDark: Color(0xFF96621C),
      ivory: Color(0xFFEFF3F5),
      tray: Color(0xFF24435A),
      trayEdge: Color(0xFF1F2C36),
      tileFace: Color(0xFFF0E6C8),
      tileEdge: Color(0xFFC6B07E),
      tileText: Color(0xFF1E2830),
      playerColors: [Color(0xFFC0392B), Color(0xFFD98A2B)],
    ),
    // ------------------------------------------------ Pro themes (13..16)
    TileThemeDef(
      id: 'brasslib',
      name: 'Brass Library',
      woodDark: Color(0xFF241708),
      woodMid: Color(0xFF3F2A12),
      woodDeep: Color(0xFF100A03),
      accent: Color(0xFFEBD08A),
      accentLight: Color(0xFFFFEFB8),
      accentDark: Color(0xFFA88A3A),
      ivory: Color(0xFFF8F0DE),
      tray: Color(0xFF173F31),
      trayEdge: Color(0xFF291C0B),
      tileFace: Color(0xFFF2DEB0),
      tileEdge: Color(0xFFC9A45E),
      tileText: Color(0xFF241708),
      playerColors: [Color(0xFFD4453B), Color(0xFF4A9BD9)],
    ),
    TileThemeDef(
      id: 'midnight',
      name: 'Midnight Study',
      woodDark: Color(0xFF101623),
      woodMid: Color(0xFF1E2839),
      woodDeep: Color(0xFF070B12),
      accent: Color(0xFFB9C6DE),
      accentLight: Color(0xFFE4EBF8),
      accentDark: Color(0xFF74809C),
      ivory: Color(0xFFEFF2F7),
      tray: Color(0xFF1D3350),
      trayEdge: Color(0xFF111A29),
      tileFace: Color(0xFFF2ECDC),
      tileEdge: Color(0xFFC3B892),
      tileText: Color(0xFF101623),
      playerColors: [Color(0xFFD65348), Color(0xFF5FA8E0)],
    ),
    TileThemeDef(
      id: 'jade',
      name: 'Jade Garden',
      woodDark: Color(0xFF16241C),
      woodMid: Color(0xFF2A3F31),
      woodDeep: Color(0xFF0A100C),
      accent: Color(0xFFC9A24A),
      accentLight: Color(0xFFEDCD8A),
      accentDark: Color(0xFF8A6824),
      ivory: Color(0xFFEEF3E8),
      tray: Color(0xFF1F5C45),
      trayEdge: Color(0xFF192A20),
      tileFace: Color(0xFFEADBA8),
      tileEdge: Color(0xFFBE9F5C),
      tileText: Color(0xFF16241C),
      playerColors: [Color(0xFFC03A2B), Color(0xFF2F80B8)],
    ),
    TileThemeDef(
      id: 'copper',
      name: 'Copper Forge',
      woodDark: Color(0xFF241310),
      woodMid: Color(0xFF40211A),
      woodDeep: Color(0xFF120806),
      accent: Color(0xFFD18A5A),
      accentLight: Color(0xFFF2B98E),
      accentDark: Color(0xFF8F5527),
      ivory: Color(0xFFF6E9DA),
      tray: Color(0xFF4A1F16),
      trayEdge: Color(0xFF2A1611),
      tileFace: Color(0xFFEFD6A4),
      tileEdge: Color(0xFFC09658),
      tileText: Color(0xFF241310),
      playerColors: [Color(0xFFC23A28), Color(0xFF3A86C8)],
    ),
  ];

  static bool isProTheme(String id) {
    final i = all.indexWhere((t) => t.id == id);
    return i >= freeCount;
  }

  static TileThemeDef byId(String id, {TileThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Physical letter-tile styles. Face/edge/text materials; the shape also
/// varies (radius) so each style feels like a different real tile.
class TileStyle {
  final String name;
  final Color face;
  final Color edge;
  final Color text;
  final double radius; // corner radius fraction-ish (px used by widget)
  const TileStyle({
    required this.name,
    required this.face,
    required this.edge,
    required this.text,
    required this.radius,
  });
}

class TileStyles {
  /// First [freeCount] styles are free; the rest are Pro.
  static const freeCount = 8;

  static const List<TileStyle> all = [
    TileStyle(
        name: 'Maple',
        face: Color(0xFFE8D5A3),
        edge: Color(0xFFB89B5E),
        text: Color(0xFF2E1D12),
        radius: 10),
    TileStyle(
        name: 'Walnut',
        face: Color(0xFF8A6238),
        edge: Color(0xFF5C3F20),
        text: Color(0xFFF5EFE0),
        radius: 10),
    TileStyle(
        name: 'Cherry',
        face: Color(0xFFB45A3C),
        edge: Color(0xFF7E3A22),
        text: Color(0xFFF8EEDD),
        radius: 12),
    TileStyle(
        name: 'Ebony',
        face: Color(0xFF2B241C),
        edge: Color(0xFF100D08),
        text: Color(0xFFF4EEDC),
        radius: 8),
    TileStyle(
        name: 'Ivory',
        face: Color(0xFFF4EEDC),
        edge: Color(0xFFC9BFA4),
        text: Color(0xFF3B2A16),
        radius: 14),
    TileStyle(
        name: 'Marble',
        face: Color(0xFFE8E4DA),
        edge: Color(0xFF9A978C),
        text: Color(0xFF2E2A22),
        radius: 6),
    TileStyle(
        name: 'Bamboo',
        face: Color(0xFFDCC489),
        edge: Color(0xFFAB9257),
        text: Color(0xFF2F2410),
        radius: 16),
    TileStyle(
        name: 'Barn Red',
        face: Color(0xFFA83A2C),
        edge: Color(0xFF6E2118),
        text: Color(0xFFF8EEDD),
        radius: 10),
    // Pro styles (9..12)
    TileStyle(
        name: 'Midnight',
        face: Color(0xFF26314A),
        edge: Color(0xFF121828),
        text: Color(0xFFF2ECDC),
        radius: 10),
    TileStyle(
        name: 'Brass',
        face: Color(0xFFD9A441),
        edge: Color(0xFF96621C),
        text: Color(0xFF2B1E0C),
        radius: 12),
    TileStyle(
        name: 'Copper',
        face: Color(0xFFC97A4A),
        edge: Color(0xFF8A4E26),
        text: Color(0xFF2B1610),
        radius: 10),
    TileStyle(
        name: 'Pine Green',
        face: Color(0xFF2E6B4E),
        edge: Color(0xFF1B4A34),
        text: Color(0xFFF1EDDD),
        radius: 14),
  ];

  static bool isPro(int index) => index >= freeCount;
}
