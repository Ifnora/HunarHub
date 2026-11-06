import 'package:flutter/material.dart';

void main() {
  runApp(const HunarHubApp());
}

class HunarHubApp extends StatelessWidget {
  const HunarHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HunarHub Pakistan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087E65),
        ),
        useMaterial3: true,
      ),
      home: const CVBuilderScreen(),
    );
  }
}

class CVBuilderScreen extends StatefulWidget {
  const CVBuilderScreen({super.key});

  @override
  State<CVBuilderScreen> createState() => _CVBuilderScreenState();
}

class _CVBuilderScreenState extends State<CVBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _summaryController = TextEditingController();
  final _skillsController = TextEditingController();

  String _cvType = 'banking';

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _jobController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Widget buildField(
    String label,
    TextEditingController controller, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  void saveCV() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV form completed. API connection is next.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HunarHub Pakistan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Professional CV Builder',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Create your professional CV for job applications.'),
              const SizedBox(height: 24),

              const Text(
                'Select CV Category',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: _cvType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'CV Type',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'fresh_graduate',
                    child: Text('Fresh Graduate'),
                  ),
                  DropdownMenuItem(
                    value: 'experienced',
                    child: Text('Experienced Professional'),
                  ),
                  DropdownMenuItem(
                    value: 'banking',
                    child: Text('Banking Professional'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _cvType = value);
                  }
                },
              ),

              const SizedBox(height: 24),
              buildField('CV Title', _titleController),
              buildField('Full Name', _nameController),
              buildField('Professional Title', _jobController),
              buildField('Professional Summary', _summaryController, lines: 4),
              buildField('Skills (comma separated)', _skillsController, lines: 3),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saveCV,
                  icon: const Icon(Icons.save),
                  label: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
