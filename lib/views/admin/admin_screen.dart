import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loy_herbs/data/models/herb_model.dart';

class AdminScreen extends StatefulWidget {
  final Herb? herb; // Add this line to accept an existing herb
  const AdminScreen({super.key, this.herb});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificController = TextEditingController();
  final _descController = TextEditingController();
  final _prepController = TextEditingController();
  final _diseaseController = TextEditingController();
  List<String> _selectedDiseases = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if we are editing an existing herb
    if (widget.herb != null) {
      _nameController.text = widget.herb!.name;
      _scientificController.text = widget.herb!.scientificName ?? '';
      _descController.text = widget.herb!.description;
      _prepController.text = widget.herb!.preparation;
      _selectedDiseases = List.from(
        widget.herb!.diseases,
      ); // Load existing diseases
    }
  }

  Future<void> _saveHerb() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      String herbId;

      if (widget.herb == null) {
        // NEW RECORD: Insert
        final data = await supabase
            .from('herbs')
            .insert({
              'name': _nameController.text,
              'scientific_name': _scientificController.text,
              'description': _descController.text,
              'preparation_method': _prepController.text,
            })
            .select()
            .single();
        herbId = data['id'];
      } else {
        // EXISTING RECORD: Update
        herbId = widget.herb!.id;
        await supabase
            .from('herbs')
            .update({
              'name': _nameController.text,
              'scientific_name': _scientificController.text,
              'description': _descController.text,
              'preparation_method': _prepController.text,
            })
            .eq('id', herbId);

        // CLEANUP: Delete old disease links so we can re-add the current selection
        await supabase.from('herb_diseases').delete().eq('herb_id', herbId);
      }

      // Sync Diseases (Same for both New and Edit)
      for (String diseaseName in _selectedDiseases) {
        final diseaseData = await supabase
            .from('diseases')
            .upsert({'name': diseaseName})
            .select()
            .single();

        await supabase.from('herb_diseases').insert({
          'herb_id': herbId,
          'disease_id': diseaseData['id'],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Database updated!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Herb")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Basic Info
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: "Herb Name"),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    TextFormField(
                      controller: _scientificController,
                      decoration: const InputDecoration(
                        labelText: "Scientific Name (e.g. Vernonia amygdalina)",
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "What does this herb do?",
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _prepController,
                      decoration: const InputDecoration(
                        labelText: "How do you prepare it?",
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 30),

                    // 2. Target Diseases Section
                    const Text(
                      "Target Diseases",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _diseaseController,
                            decoration: const InputDecoration(
                              hintText: "Enter disease (e.g. Fever, Malaria)",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF1B5E20),
                            size: 32,
                          ),
                          onPressed: () {
                            if (_diseaseController.text.isNotEmpty) {
                              setState(() {
                                _selectedDiseases.add(
                                  _diseaseController.text.trim(),
                                );
                                _diseaseController.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Display selected diseases as Chips
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _selectedDiseases.map((disease) {
                        return Chip(
                          label: Text(disease),
                          backgroundColor: Colors.green.shade50,
                          onDeleted: () {
                            setState(() {
                              _selectedDiseases.remove(disease);
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 40),

                    // 3. Save Button
                    ElevatedButton(
                      onPressed: _saveHerb,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 55),
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Herb & Diseases",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
