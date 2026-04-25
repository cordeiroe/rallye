import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'colors.dart';

// Space Grotesk — títulos, valores monetários, horários
// Outfit — corpo, labels, navegação

TextStyle spaceGrotesk({
  double fontSize = 16,
  FontWeight fontWeight = FontWeight.w400,
  Color color = textPrimary,
}) =>
    GoogleFonts.spaceGrotesk(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );

TextStyle outfit({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = textPrimary,
}) =>
    GoogleFonts.outfit(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
