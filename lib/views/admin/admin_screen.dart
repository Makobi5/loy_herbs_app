import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:loy_herbs/data/models/herb_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AdminScreen extends StatefulWidget {
  final Herb? herb; // Add this line to accept an existing herb
  const AdminScreen({super.key, this.herb});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  XFile? _imageFile; // To store the picked image
  final ImagePicker _picker = ImagePicker();
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

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  // Function to upload to Supabase
  Future<String?> _uploadImage(String herbId) async {
    if (_imageFile == null) return null;

    final bytes = await _imageFile!.readAsBytes();
    final fileExt = _imageFile!.name.split('.').last;
    final fileName = '$herbId.$fileExt';
    final filePath = fileName;

    await Supabase.instance.client.storage
        .from('herb-images')
        .uploadBinary(filePath, bytes);

    // Get the Public URL
    return Supabase.instance.client.storage
        .from('herb-images')
        .getPublicUrl(filePath);
  }

  Future<void> _saveHerb() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      String? imageUrl =
          widget.herb?.imageUrl; // Keep old image if no new one is picked

      // 1. UPLOAD IMAGE IF SELECTED
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        final fileExt = _imageFile!.name.split('.').last;
        // Use timestamp for a unique filename
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';

        await supabase.storage
            .from('herb-images')
            .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );

        imageUrl = supabase.storage.from('herb-images').getPublicUrl(fileName);
      }

      String herbId;
      final Map<String, dynamic> herbData = {
        'name': _nameController.text,
        'scientific_name': _scientificController.text,
        'description': _descController.text,
        'preparation_method': _prepController.text,
        'image_url': imageUrl, // Save the image URL here
      };

      // 2. INSERT OR UPDATE HERB
      if (widget.herb == null) {
        final data = await supabase
            .from('herbs')
            .insert(herbData)
            .select()
            .single();
        herbId = data['id'];
      } else {
        herbId = widget.herb!.id;
        await supabase.from('herbs').update(herbData).eq('id', herbId);
        // Clean old disease links for update
        await supabase.from('herb_diseases').delete().eq('herb_id', herbId);
      }

      // 3. SYNC DISEASES
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
        ).showSnackBar(const SnackBar(content: Text("Success!")));
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
      appBar: AppBar(
        title: Text(widget.herb == null ? "Add New Herb" : "Edit Herb"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- IMAGE PICKER SECTION ---
                    Center(
                      child: GestureDetector(
                        onTap: () async {
                          final XFile? image = await _picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null) setState(() => _imageFile = image);
                        },
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: kIsWeb
                                      ? Image.network(
                                          _imageFile!.path,
                                          fit: BoxFit.cover,
                                        )
                                      : FutureBuilder(
                                          future: _imageFile!.readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData)
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                              );
                                            return const CircularProgressIndicator();
                                          },
                                        ),
                                )
                              : widget.herb?.imageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    widget.herb!.imageUrl!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.green,
                                    ),
                                    Text(
                                      "Add Photo",
                                      style: TextStyle(color: Colors.green),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // --- TEXT FIELDS ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Herb Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _scientificController,
                      decoration: const InputDecoration(
                        labelText: "Scientific Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _descController,
                      decoration: const InputDecoration(
                        labelText: "What does this herb do?",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _prepController,
                      decoration: const InputDecoration(
                        labelText: "How do you prepare it?",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 30),

                    // --- DISEASES SECTION ---
                    const Text(
                      "Target Diseases",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _diseaseController,
                            decoration: const InputDecoration(
                              hintText: "Enter disease",
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Color(0xFF1B5E20),
                            size: 35,
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
                    Wrap(
                      spacing: 8.0,
                      children: _selectedDiseases
                          .map(
                            (disease) => Chip(
                              label: Text(disease),
                              onDeleted: () => setState(
                                () => _selectedDiseases.remove(disease),
                              ),
                            ),
                          )
                          .toList(),
                    ),

                    const SizedBox(height: 40),

                    // --- SAVE BUTTON ---
                    ElevatedButton(
                      onPressed: _saveHerb,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 60),
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Save Everything",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
