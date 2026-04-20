import 'package:flutter/material.dart';

class AppColors {
  
  static const primary        = Color(0xFF0F6E56); 
  static const primaryLight   = Color(0xFF1D9E75);
  static const primarySurface = Color(0xFFE1F5EE); 
  static const primaryDark    = Color(0xFF04342C); 

  static const carbonLow       = Color(0xFF0F6E56); 
  static const carbonMediumLow = Color(0xFF1D9E75); 
  static const carbonMedium    = Color(0xFFEF9F27); 
  static const carbonHigh      = Color(0xFFD85A30); 
  static const carbonVeryHigh  = Color(0xFFE24B4A); 


  static const solar      = Color(0xFFEF9F27);
  static const wind       = Color(0xFF5DCAA5);
  static const hydro      = Color(0xFF85B7EB);
  static const nuclear    = Color(0xFFAFA9EC);
  static const gas        = Color(0xFFB4B2A9);
  static const coal       = Color(0xFFF09595);
  static const oil        = Color(0xFFD85A30);
  static const biomass    = Color(0xFF97C459);
  static const geothermal = Color(0xFFF5C4B3);
  static const unknown    = Color(0xFFD3D1C7);


  static const background    = Color(0xFFF5F5F0); 
  static const surface       = Colors.white;      
  static const textPrimary   = Color(0xFF2C2C2A);
  static const textSecondary = Color(0xFF888780);
  static const warning       = Color(0xFFFAEEDA);
  static const warningText   = Color(0xFF854F0B); 
  static const error         = Color(0xFFE24B4A);

 
  static const Map<String, Color> sourceColors = {
    'solar':      solar,
    'wind':       wind,
    'hydro':      hydro,
    'nuclear':    nuclear,
    'gas':        gas,
    'coal':       coal,
    'oil':        oil,
    'biomass':    biomass,
    'geothermal': geothermal,
    'unknown':    unknown,
  };

  static const Map<String, String> sourceLabelsIt = {
    'solar':      'Solare',
    'wind':       'Eolico',
    'hydro':      'Idrico',
    'nuclear':    'Nucleare',
    'gas':        'Gas',
    'coal':       'Carbone',
    'oil':        'Petrolio',
    'biomass':    'Biomassa',
    'geothermal': 'Geotermico',
    'unknown':    'Altro',
  };


  static Color carbonColor(double intensity) {
    if (intensity < 100) return carbonLow;
    if (intensity < 200) return carbonMediumLow;
    if (intensity < 350) return carbonMedium;
    if (intensity < 500) return carbonHigh;
    return carbonVeryHigh;
  }


  static String carbonLevel(double intensity) {
    if (intensity < 100) return 'Molto basso';
    if (intensity < 200) return 'Basso';
    if (intensity < 350) return 'Medio';
    if (intensity < 500) return 'Alto';
    return 'Molto alto';
  }

  
  static Color sourceColor(String key) => sourceColors[key] ?? unknown;

  static String sourceLabel(String key) {
    final it = sourceLabelsIt[key];
    if (it != null) return it;
    if (key.isEmpty) return 'Altro';
    return key[0].toUpperCase() + key.substring(1);
  }
}
