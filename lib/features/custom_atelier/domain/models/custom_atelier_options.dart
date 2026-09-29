import 'package:flutter/material.dart';

class OccasionOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const OccasionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<OccasionOption> all = [
    OccasionOption(
      id: 'wedding',
      title: 'Bridal & Wedding',
      description: 'Grand bridal gown, reception couture, or bridesmaid ensemble.',
      icon: Icons.favorite_border,
    ),
    OccasionOption(
      id: 'traditional_event',
      title: 'Traditional Event',
      description: 'Ceremonial coronation, chieftaincy, or cultural celebration.',
      icon: Icons.flare,
    ),
    OccasionOption(
      id: 'red_carpet',
      title: 'Red Carpet & Gala',
      description: 'Showstopping silhouette engineered for spotlights and high glamour.',
      icon: Icons.camera_alt_outlined,
    ),
    OccasionOption(
      id: 'dinner',
      title: 'Private Dinner & Soirée',
      description: 'Refined evening elegance for exclusive VIP gatherings.',
      icon: Icons.wine_bar,
    ),
    OccasionOption(
      id: 'birthday',
      title: 'Birthday & Milestone',
      description: 'Unforgettable celebratory attire tailored to your personality.',
      icon: Icons.cake_outlined,
    ),
    OccasionOption(
      id: 'corporate',
      title: 'Executive Corporate',
      description: 'Impeccable architectural tailoring for high-stakes leadership.',
      icon: Icons.business_center_outlined,
    ),
    OccasionOption(
      id: 'photoshoot',
      title: 'Editorial Photoshoot',
      description: 'Dramatic concept styling for cover editorials and personal brand portraits.',
      icon: Icons.photo_camera_back_outlined,
    ),
    OccasionOption(
      id: 'party',
      title: 'Celebration & Party',
      description: 'Vibrant, fluid designs made for movement and celebration.',
      icon: Icons.celebration_outlined,
    ),
    OccasionOption(
      id: 'other',
      title: 'Other Atelier Vision',
      description: 'Unique bespoke concept designed collaboratively from scratch.',
      icon: Icons.auto_awesome,
    ),
  ];
}

class DirectionOption {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const DirectionOption({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });

  static const List<DirectionOption> all = [
    DirectionOption(
      id: 'gown',
      title: 'Architectural Gown',
      description: 'Full-length column, mermaid, ballgown, or peplum silhouette.',
      icon: Icons.woman,
    ),
    DirectionOption(
      id: 'two_piece',
      title: 'Bespoke Two-Piece',
      description: 'Sculpted corseted bodice paired with matching tailored skirt or pant.',
      icon: Icons.dry_cleaning_outlined,
    ),
    DirectionOption(
      id: 'kaftan',
      title: 'Atelier Kaftan & Boubou',
      description: 'Flowing regal silk or crepe kaftan with intricate hand embroidery.',
      icon: Icons.style_outlined,
    ),
    DirectionOption(
      id: 'suit',
      title: 'Tailored Power Suit',
      description: 'Double-breasted structured blazer with sharp cigarette or wide-leg trousers.',
      icon: Icons.accessibility_new,
    ),
    DirectionOption(
      id: 'traditional',
      title: 'Ceremonial Traditional',
      description: 'Bespoke George, Aso-Oke, or brocade garment with ceremonial accents.',
      icon: Icons.shield_outlined,
    ),
    DirectionOption(
      id: 'skirt',
      title: 'Sculptural Skirt',
      description: 'Pencil, accordion-pleated, or tiered statement skirt.',
      icon: Icons.filter_vintage_outlined,
    ),
    DirectionOption(
      id: 'blouse',
      title: 'Statement Bodice / Blouse',
      description: 'Draped organza, boned corset, or asymmetric tailored top.',
      icon: Icons.wb_shade,
    ),
    DirectionOption(
      id: 'other',
      title: 'Custom Direction',
      description: 'Avant-garde or personalized hybrid silhouette.',
      icon: Icons.brush_outlined,
    ),
  ];
}

class FabricOption {
  final String id;
  final String name;
  final String composition;
  final String feel;

  const FabricOption({
    required this.id,
    required this.name,
    required this.composition,
    required this.feel,
  });

  static const List<FabricOption> all = [
    FabricOption(
      id: 'lace',
      name: 'French Beaded Lace',
      composition: 'Hand-appliquéd corded lace with iridescent beadwork.',
      feel: 'Intricate, luminous, regal structure.',
    ),
    FabricOption(
      id: 'silk',
      name: 'Pure Mulberry Silk Crepe',
      composition: '100% natural silk with double-face satin weave.',
      feel: 'Ultra-luxurious fluid drape and liquid sheen.',
    ),
    FabricOption(
      id: 'ankara',
      name: 'Curated Artisan Ankara',
      composition: 'Premium 100% Dutch-wax combed cotton.',
      feel: 'Crisp body, vibrant indigenous narrative patterns.',
    ),
    FabricOption(
      id: 'velvet',
      name: 'Royal Silk Velvet',
      composition: 'Plush silk-blend velvet with deep light refraction.',
      feel: 'Sumptuous, heavyweight, theatrical depth.',
    ),
    FabricOption(
      id: 'crepe',
      name: 'Architectural Wool Crepe',
      composition: 'Mid-weight Italian high-twist wool crepe.',
      feel: 'Sharp tailoring retention with slight natural stretch.',
    ),
    FabricOption(
      id: 'satin',
      name: 'Heavy Silk Duchess Satin',
      composition: 'High-density pure silk duchess weave.',
      feel: 'Substantial structural body with peerless couture lustre.',
    ),
    FabricOption(
      id: 'custom',
      name: 'Client-Provided / Special Sourcing',
      composition: 'Specialist fabric sourced directly by our master tailor or client provided.',
      feel: 'Tailored to unique commission specifications.',
    ),
  ];
}

class ColourOption {
  final String id;
  final String name;
  final Color color;
  final String hex;

  const ColourOption({
    required this.id,
    required this.name,
    required this.color,
    required this.hex,
  });

  static const List<ColourOption> curatedPalette = [
    ColourOption(
      id: 'ochanya_gold',
      name: 'Atelier Royal Gold',
      color: Color(0xFFC9A96E),
      hex: '#C9A96E',
    ),
    ColourOption(
      id: 'midnight_black',
      name: 'Midnight Onyx',
      color: Color(0xFF141414),
      hex: '#141414',
    ),
    ColourOption(
      id: 'ivory_pearl',
      name: 'Ivory Pearl',
      color: Color(0xFFF7F5F0),
      hex: '#F7F5F0',
    ),
    ColourOption(
      id: 'emerald_imperial',
      name: 'Imperial Emerald',
      color: Color(0xFF0F3B2E),
      hex: '#0F3B2E',
    ),
    ColourOption(
      id: 'burgundy_wine',
      name: 'Deep Bordeaux Wine',
      color: Color(0xFF4A121A),
      hex: '#4A121A',
    ),
    ColourOption(
      id: 'sapphire_regal',
      name: 'Regal Sapphire',
      color: Color(0xFF13294B),
      hex: '#13294B',
    ),
    ColourOption(
      id: 'terracotta_sunset',
      name: 'Savannah Terracotta',
      color: Color(0xFFC85A32),
      hex: '#C85A32',
    ),
    ColourOption(
      id: 'dusty_rose',
      name: 'Desert Blush Rose',
      color: Color(0xFFD4A5A5),
      hex: '#D4A5A5',
    ),
    ColourOption(
      id: 'pure_champagne',
      name: 'Liquid Champagne',
      color: Color(0xFFE8D8B8),
      hex: '#E8D8B8',
    ),
  ];
}
