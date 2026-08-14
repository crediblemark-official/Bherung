import 'package:flutter/material.dart';

enum TransactionType {
  eceran('Eceran', Icons.shopping_basket_rounded, Color(0xFF0D9488)),
  grosir('Grosir / Dus', Icons.inventory_2_rounded, Color(0xFF8B5CF6)),
  antar('Antar / Titip', Icons.delivery_dining_rounded, Color(0xFF3B82F6));

  final String label;
  final IconData icon;
  final Color color;

  const TransactionType(this.label, this.icon, this.color);
}
