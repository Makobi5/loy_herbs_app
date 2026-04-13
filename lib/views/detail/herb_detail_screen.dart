import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loy_herbs/data/models/herb_model.dart';
import 'package:loy_herbs/views/admin/admin_screen.dart'; // Import AdminScreen
import 'package:cached_network_image/cached_network_image.dart';

class HerbDetailScreen extends StatelessWidget {
  final Herb herb;

  const HerbDetailScreen({super.key, required this.herb});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(herb.name),
        actions: [
          // ONLY SHOW EDIT ICON IF USER IS THE ADMIN
          if (Supabase.instance.client.auth.currentUser?.email ==
              'makobisimon@gmail.com')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      AdminScreen(herb: herb), // Pass the existing herb
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE SECTION
            if (herb.imageUrl != null)
              CachedNetworkImage(
                imageUrl: herb.imageUrl!,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.broken_image, size: 50),
              )
            else
              Container(
                height: 150,
                width: double.infinity,
                color: Colors.green.shade50,
                child: const Icon(Icons.eco, size: 80, color: Colors.green),
              ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. SCIENTIFIC NAME
                  Text(
                    herb.scientificName ?? "Species unknown",
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Divider(height: 40),

                  // 3. TARGET DISEASES (Tags)
                  const Text(
                    "Commonly used for:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  herb.diseases.isEmpty
                      ? const Text(
                          "No specific diseases listed yet.",
                          style: TextStyle(color: Colors.grey),
                        )
                      : Wrap(
                          spacing: 8,
                          children: herb.diseases
                              .map(
                                (disease) => Chip(
                                  label: Text(disease),
                                  backgroundColor: Colors.green.shade50,
                                  side: BorderSide(
                                    color: Colors.green.shade200,
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                  const SizedBox(height: 30),

                  // 4. DESCRIPTION
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    herb.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  const SizedBox(height: 30),

                  // 5. PREPARATION
                  const Text(
                    "Preparation Method",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Text(
                      herb.preparation,
                      style: const TextStyle(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
