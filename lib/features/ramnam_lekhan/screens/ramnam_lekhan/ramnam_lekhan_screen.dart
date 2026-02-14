// features/ramnam_lekhan/screens/ramnam_lekhan/ramnam_lekhan_screen.dart
import 'package:flutter/material.dart';
import '../mantras/mantras_screen.dart';

class NaamJapaScreen extends StatefulWidget {
  final String? initialDeityId;

  const NaamJapaScreen({super.key, this.initialDeityId});

  @override
  State<NaamJapaScreen> createState() => _NaamJapaScreenState();
}

class _NaamJapaScreenState extends State<NaamJapaScreen> {
  @override
  void initState() {
    super.initState();

    // If initialDeityId is provided, navigate to that deity's mantra page
    // NOTE: Since we removed hardcoded deities, we'll just show all mantras
    // Admin will need to set up categories properly in the database
  }

  void _navigateToDeityMantras(String deityId) {
    // DEPRECATED: Hardcoded deity lookup removed
    // Now we just navigate to mantras screen with 'All' category

    // Navigate directly to mantras with the specific deity category
    String category = 'All';
    switch (deityId) {
      case 'durga':
        category = 'Durga';
        break;
      case 'ganesha':
        category = 'Ganesha';
        break;
      case 'hanuman':
        category = 'Hanuman';
        break;
      case 'krishna':
        category = 'Krishna';
        break;
      case 'lakshmi':
        category = 'Lakshmi';
        break;
      case 'narasimha':
        category = 'Narasimha';
        break;
      case 'parvati':
        category = 'Parvati';
        break;
      case 'radha':
        category = 'Radha';
        break;
      case 'ram':
        category = 'Ram';
        break;
      case 'saraswati':
        category = 'Saraswati';
        break;
      case 'shani':
        category = 'Shani';
        break;
      case 'shiv':
        category = 'Shiv';
        break;
      case 'sita':
        category = 'Sita';
        break;
      case 'vishnu':
        category = 'Vishnu';
        break;
    }

    // Navigate to the deity's mantra page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MantrasScreen(initialCategory: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Skip deity selection and directly show mantras with all categories
    return MantrasScreen(initialCategory: 'All');
  }
}
