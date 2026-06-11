import 'package:flutter/material.dart';

const Map<String, IconData> kIconMap = {
  'free_breakfast':     Icons.free_breakfast,
  'lunch_dining':       Icons.lunch_dining,
  'dinner_dining':      Icons.dinner_dining,
  'restaurant':         Icons.restaurant,
  'local_cafe':         Icons.local_cafe,
  'cake':               Icons.cake,
  'directions_bus':     Icons.directions_bus,
  'directions_car':     Icons.directions_car,
  'local_taxi':         Icons.local_taxi,
  'local_gas_station':  Icons.local_gas_station,
  'flight':             Icons.flight,
  'shopping_bag':       Icons.shopping_bag,
  'checkroom':          Icons.checkroom,
  'spa':                Icons.spa,
  'local_hospital':     Icons.local_hospital,
  'fitness_center':     Icons.fitness_center,
  'sports_esports':     Icons.sports_esports,
  'movie':              Icons.movie,
  'home':               Icons.home,
  'electric_bolt':      Icons.electric_bolt,
  'phone_android':      Icons.phone_android,
  'menu_book':          Icons.menu_book,
  'pets':               Icons.pets,
  'card_giftcard':      Icons.card_giftcard,
  'savings':            Icons.savings,
  'payments':           Icons.payments,
  'emoji_events':       Icons.emoji_events,
  'category_outlined':  Icons.category_outlined,
};

IconData iconFromName(String? name) =>
    kIconMap[name] ?? Icons.category_outlined;
