import 'package:flutter/material.dart';
import 'api_service.dart';
import 'login_screen.dart';

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
      home: const AppHome(),
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome({super.key});

  @override
  State<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  String? _token;

  void _handleLogin(String token) {
    setState(() {
      _token = token;
    });
  }

  void _logout() {
    setState(() {
      _token = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null) {
      return LoginScreen(onLogin: _handleLogin);
    }

    return CVBuilderScreen(
      apiService: ApiService(token: _token!),
      onLogout: _logout,
    );
  }
}

class CVBuilderScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLogout;

  const CVBuilderScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
  });

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
  bool _isSaving = false;

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

  Future<void> saveCV() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final result = await widget.apiService.createCV(
        title: _titleController.text.trim(),
        cvType: _cvType,
        templateName: 'professional',
        content: {
          'full_name': _nameController.text.trim(),
          'professional_title': _jobController.text.trim(),
          'professional_summary': _summaryController.text.trim(),
          'skills': _skillsController.text
              .split(',')
              .map((skill) => skill.trim())
              .where((skill) => skill.isNotEmpty)
              .toList(),
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'CV saved successfully.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HunarHub Pakistan'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
        ],
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
              const Text(
                'Create your professional CV for job applications.',
              ),
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
              buildField(
                'Professional Summary',
                _summaryController,
                lines: 4,
              ),
              buildField(
                'Skills (comma separated)',
                _skillsController,
                lines: 3,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : saveCV,
                  icon: const Icon(Icons.save),
                  label: Text(_isSaving ? 'Saving...' : 'Save CV'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
