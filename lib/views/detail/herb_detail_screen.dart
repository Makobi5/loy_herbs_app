import 'package:flutter/material.dart';
import 'package:loy_herbs/data/models/herb_model.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HerbDetailScreen extends StatelessWidget {
  final Herb herb;

  const HerbDetailScreen({super.key, required this.herb});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(herb.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERB IMAGE
            if (herb.imageUrl != null)
              CachedNetworkImage(
                imageUrl: herb.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. SCIENTIFIC NAME
                  Text(
                    herb.scientificName ?? "Species unknown",
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const Divider(height: 30),

                  // 3. DESCRIPTION
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(herb.description),
                  const SizedBox(height: 24),

                  // 4. TREATS (Diseases)
                  const Text(
                    "Commonly used for:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8,
                    children: herb.diseases
                        .map((d) => Chip(label: Text(d)))
                        .toList(),
                  ),
                  const SizedBox(height: 24),

                  // 5. PREPARATION
                  const Text(
                    "Preparation Method",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(herb.preparation),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
