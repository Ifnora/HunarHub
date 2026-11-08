
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
          seedColor: const Color(0xFF087F5B),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F9FC),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF087F5B),
          foregroundColor: Colors.white,
        ),
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
  String? _selectedFeature;

  void openFeature(String feature) {
    if (_token == null) {
      setState(() => _selectedFeature = feature);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            onLoginSuccess: (token) {
              setState(() {
                _token = token;
              });

              Navigator.pop(context);
            },
          ),
        ),
      );
    } else {
      setState(() => _selectedFeature = feature);
    }
  }

  void logout() {
    setState(() {
      _token = null;
      _selectedFeature = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_token == null || _selectedFeature == null) {
      return HomeScreen(onFeatureSelected: openFeature);
    }

    final apiService = ApiService(token: _token!);

    switch (_selectedFeature) {
      case 'jobs':
        return JobsScreen(
          apiService: apiService,
          onLogout: logout,
          onHome: () => setState(() => _selectedFeature = null),
        );

      case 'cv':
        return CVBuilderScreen(
          apiService: apiService,
          onLogout: logout,
          onHome: () => setState(() => _selectedFeature = null),
        );

      case 'profile':
        return ProfileScreen(
          apiService: apiService,
          onLogout: logout,
          onHome: () => setState(() => _selectedFeature = null),
        );

      case 'preparation':
        return FeatureScreen(
          title: 'Interview & Test Preparation',
          onLogout: logout,
          onHome: () => setState(() => _selectedFeature = null),
        );

      default:
        return HomeScreen(onFeatureSelected: openFeature);
    }
  }
}

// HOME SCREEN

class HomeScreen extends StatelessWidget {
  final Function(String) onFeatureSelected;

  const HomeScreen({
    super.key,
    required this.onFeatureSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HunarHub Pakistan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Build Your Career With HunarHub',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your platform for jobs, professional CVs and career preparation.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 28),

            featureCard(
              context,
              icon: Icons.work_outline,
              title: 'Jobs & Internships',
              description: 'Explore career opportunities.',
              color: Colors.blue,
              onTap: () => onFeatureSelected('jobs'),
            ),

            featureCard(
              context,
              icon: Icons.description_outlined,
              title: 'Professional CV Builder',
              description: 'Create and manage your CV.',
              color: Colors.green,
              onTap: () => onFeatureSelected('cv'),
            ),

            featureCard(
              context,
              icon: Icons.school_outlined,
              title: 'Interview & Test Preparation',
              description: 'Prepare for interviews and tests.',
              color: Colors.orange,
              onTap: () => onFeatureSelected('preparation'),
            ),

            featureCard(
              context,
              icon: Icons.person_outline,
              title: 'Profile & Applications',
              description: 'Manage your profile and applications.',
              color: Colors.purple,
              onTap: () => onFeatureSelected('profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget featureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: color.withAlpha(25),
                child: Icon(icon, color: color, size: 29),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(description),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// JOBS SCREEN

class JobsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const JobsScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
    required this.onHome,
  });

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _jobs = [];

  @override
  void initState() {
    super.initState();
    loadJobs();
  }

  Future<void> loadJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.apiService.getJobs();
      if (!mounted) return;

      setState(() {
        _jobs = result['jobs'] ?? [];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void openApplications(bool saved) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => saved
            ? SavedJobsScreen(apiService: widget.apiService)
            : ApplicationsScreen(apiService: widget.apiService),
      ),
    );
  }

  Future<void> saveJob(String id) async {
    try {
      final result = await widget.apiService.saveJob(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Job saved.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> applyJob(String id) async {
    try {
      final result = await widget.apiService.applyForJob(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  'Application recorded.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jobs & Internships'),
        leading: IconButton(
          onPressed: widget.onHome,
          icon: const Icon(Icons.home),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'saved') openApplications(true);
              if (value == 'applications') openApplications(false);
              if (value == 'logout') widget.onLogout();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'saved',
                child: Text('Saved Jobs'),
              ),
              PopupMenuItem(
                value: 'applications',
                child: Text('My Applications'),
              ),
              PopupMenuItem(
                value: 'logout',
                child: Text('Logout'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      ElevatedButton(
                        onPressed: loadJobs,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _jobs.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadJobs,
                      child: ListView(
                        children: const [
                          SizedBox(height: 150),
                          Center(
                            child: Text('No Jobs Published Yet'),
                          ),
                          SizedBox(height: 10),
                          Center(
                            child: Text(
                              'New verified opportunities will appear here.',
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) {
                          final job = Map<String, dynamic>.from(
                            _jobs[index],
                          );

                          final id = job['id'].toString();

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job['title']?.toString() ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    job['employer']?.toString() ??
                                        'Employer not specified',
                                  ),
                                  Text(
                                    job['location']?.toString() ??
                                        'Location not specified',
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    job['description']?.toString() ?? '',
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => saveJob(id),
                                        icon: const Icon(Icons.bookmark),
                                        label: const Text('Save'),
                                      ),
                                      FilledButton(
                                        onPressed: () => applyJob(id),
                                        child: const Text('Apply'),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (job['official_apply_url'] != null)
                                    SelectableText(
                                      'Official application: ${job['official_apply_url']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

// SAVED JOBS SCREEN

class SavedJobsScreen extends StatefulWidget {
  final ApiService apiService;

  const SavedJobsScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  bool _loading = true;
  List<dynamic> _jobs = [];

  @override
  void initState() {
    super.initState();
    loadSavedJobs();
  }

  Future<void> loadSavedJobs() async {
    setState(() => _loading = true);

    try {
      final result = await widget.apiService.getSavedJobs();

      if (!mounted) return;

      setState(() {
        _jobs = result['jobs'] ?? result['saved_jobs'] ?? [];
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> removeJob(String id) async {
    try {
      await widget.apiService.removeSavedJob(id);
      await loadSavedJobs();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        actions: [
          IconButton(
            onPressed: loadSavedJobs,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _jobs.isEmpty
              ? const Center(child: Text('No saved jobs yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _jobs.length,
                  itemBuilder: (context, index) {
                    final job = Map<String, dynamic>.from(
                      _jobs[index],
                    );

                    return Card(
                      child: ListTile(
                        title: Text(
                          job['title']?.toString() ?? 'Job',
                        ),
                        subtitle: Text(
                          job['employer']?.toString() ?? '',
                        ),
                        trailing: IconButton(
                          onPressed: () =>
                              removeJob(job['id'].toString()),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// APPLICATION TRACKING SCREEN

class ApplicationsScreen extends StatefulWidget {
  final ApiService apiService;

  const ApplicationsScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<ApplicationsScreen> createState() =>
      _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _loading = true;
  List<dynamic> _applications = [];

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  Future<void> loadApplications() async {
    setState(() => _loading = true);

    try {
      final result = await widget.apiService.getApplications();

      if (!mounted) return;

      setState(() {
        _applications = result['applications'] ?? [];
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        actions: [
          IconButton(
            onPressed: loadApplications,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _applications.isEmpty
              ? const Center(
                  child: Text('No application recorded.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _applications.length,
                  itemBuilder: (context, index) {
                    final application =
                        Map<String, dynamic>.from(
                      _applications[index],
                    );

                    return Card(
                      child: ListTile(
                        title: Text(
                          application['title']?.toString() ??
                              'Job Application',
                        ),
                        subtitle: Text(
                          'Status: ${application['status'] ?? 'Applied'}',
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

// PROFILE SCREEN

class ProfileScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const ProfileScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
    required this.onHome,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  String _name = '';
  String _email = '';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _countryController.dispose();
    _educationController.dispose();
    _skillsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  String listToText(dynamic value) {
    if (value is List) {
      return value.join(', ');
    }
    return '';
  }

  List<String> textToList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> loadProfile() async {
    try {
      final result = await widget.apiService.getProfile();

      final profile = result['profile'] is Map
          ? Map<String, dynamic>.from(result['profile'])
          : result;

      if (!mounted) return;

      setState(() {
        _name = profile['full_name']?.toString() ?? '';
        _email = profile['email']?.toString() ?? '';
        _phone = profile['phone']?.toString() ?? '';

        _cityController.text =
            profile['city']?.toString() ?? '';
        _countryController.text =
            profile['country']?.toString() ?? 'Pakistan';

        _educationController.text =
            listToText(profile['education']);
        _skillsController.text =
            listToText(profile['skills']);
        _experienceController.text =
            listToText(profile['experience']);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> saveProfile() async {
    setState(() => _saving = true);

    try {
      final result = await widget.apiService.updateProfile(
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        education: textToList(_educationController.text),
        skills: textToList(_skillsController.text),
        experience: textToList(_experienceController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message']?.toString() ??
                  'Profile updated successfully.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget field(
    String label,
    TextEditingController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        leading: IconButton(
          onPressed: widget.onHome,
          icon: const Icon(Icons.home),
        ),
        actions: [
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    child: Icon(Icons.person, size: 38),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(_email),
                  Text(_phone),
                  const SizedBox(height: 24),
                  field('City', _cityController),
                  field('Country', _countryController),
                  field('Education (comma separated)',
                      _educationController),
                  field('Skills (comma separated)',
                      _skillsController),
                  field('Experience (comma separated)',
                      _experienceController),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : saveProfile,
                      child: Text(
                        _saving ? 'Saving...' : 'Save Profile',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// INTERVIEW AND TEST PREPARATION

class FeatureScreen extends StatelessWidget {
  final String title;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const FeatureScreen({
    super.key,
    required this.title,
    required this.onLogout,
    required this.onHome,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          onPressed: onHome,
          icon: const Icon(Icons.home),
        ),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Interview and Test Preparation content is under development.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17),
          ),
        ),
      ),
    );
  }
}

// CV BUILDER AND CV MANAGEMENT

class CVBuilderScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const CVBuilderScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
    required this.onHome,
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
  String? _editingCvId;

  bool _isSaving = false;
  bool _isLoadingCVs = false;

  List<Map<String, dynamic>> _savedCVs = [];

  @override
  void initState() {
    super.initState();
    loadCVs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _nameController.dispose();
    _jobController.dispose();
    _summaryController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadCVs() async {
    setState(() => _isLoadingCVs = true);

    try {
      final result = await widget.apiService.getCVs();
      final List<dynamic> cvs = result['cvs'] ?? [];

      if (!mounted) return;

      setState(() {
        _savedCVs = cvs
            .map((cv) => Map<String, dynamic>.from(cv as Map))
            .toList();
      });
    } catch (error) {
      if (mounted) {
        showMessage(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingCVs = false);
      }
    }
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

  void clearForm() {
    _titleController.clear();
    _nameController.clear();
    _jobController.clear();
    _summaryController.clear();
    _skillsController.clear();

    setState(() {
      _cvType = 'banking';
      _editingCvId = null;
    });
  }

  void editCV(Map<String, dynamic> cv) {
    final content = cv['content'] is Map
        ? Map<String, dynamic>.from(cv['content'])
        : <String, dynamic>{};

    final skills = content['skills'];

    _titleController.text = cv['title']?.toString() ?? '';
    _nameController.text =
        content['full_name']?.toString() ?? '';
    _jobController.text =
        content['professional_title']?.toString() ?? '';
    _summaryController.text =
        content['professional_summary']?.toString() ?? '';

    _skillsController.text = skills is List
        ? skills.join(', ')
        : skills?.toString() ?? '';

    setState(() {
      _cvType = cv['cv_type']?.toString() ?? 'banking';
      _editingCvId = cv['id'].toString();
    });

    showMessage('CV loaded for editing.');

    // Move the user back to the top of the form.
  }

  Future<void> saveCV() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final content = <String, dynamic>{
      'full_name': _nameController.text.trim(),
      'professional_title': _jobController.text.trim(),
      'professional_summary': _summaryController.text.trim(),
      'skills': _skillsController.text
          .split(',')
          .map((skill) => skill.trim())
          .where((skill) => skill.isNotEmpty)
          .toList(),
    };

    try {
      Map<String, dynamic> result;

      if (_editingCvId == null) {
        result = await widget.apiService.createCV(
          title: _titleController.text.trim(),
          cvType: _cvType,
          templateName: 'professional',
          content: content,
        );
      } else {
        result = await widget.apiService.updateCV(
          id: _editingCvId!,
          title: _titleController.text.trim(),
          cvType: _cvType,
          templateName: 'professional',
          content: content,
        );
      }

      if (!mounted) return;

      showMessage(
        result['message']?.toString() ?? 'CV saved successfully.',
      );

      clearForm();
      await loadCVs();
    } catch (error) {
      if (mounted) {
        showMessage(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void viewCV(Map<String, dynamic> cv) {
    final content = cv['content'] is Map
        ? Map<String, dynamic>.from(cv['content'])
        : <String, dynamic>{};

    final skills = content['skills'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(cv['title']?.toString() ?? 'My CV'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content['full_name']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content['professional_title']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Divider(height: 24),
                const Text(
                  'Professional Summary',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  content['professional_summary']?.toString() ?? '',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Skills',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  skills is List
                      ? skills.join(', ')
                      : skills?.toString() ?? '',
                ),
                const SizedBox(height: 16),
                Text('CV Type: ${cv['cv_type'] ?? ''}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteCV(Map<String, dynamic> cv) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete CV?'),
          content: Text(
            'Are you sure you want to delete "${cv['title']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      final result = await widget.apiService.deleteCV(
        cv['id'].toString(),
      );

      if (!mounted) return;

      if (_editingCvId == cv['id'].toString()) {
        clearForm();
      }

      showMessage(
        result['message']?.toString() ?? 'CV deleted successfully.',
      );

      await loadCVs();
    } catch (error) {
      if (mounted) {
        showMessage(
          error.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  Widget buildSavedCVs() {
    if (_isLoadingCVs) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_savedCVs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No saved CVs yet. Create your first CV above.',
        ),
      );
    }

    return Column(
      children: _savedCVs.map((cv) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cv['title']?.toString() ?? 'Untitled CV',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Type: ${cv['cv_type'] ?? 'Not specified'}',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => viewCV(cv),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View'),
                    ),
                    TextButton.icon(
                      onPressed: () => editCV(cv),
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => deleteCV(cv),
                      icon: const Icon(
                        Icons.delete,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HunarHub Pakistan'),
        leading: IconButton(
          onPressed: widget.onHome,
          icon: const Icon(Icons.home),
        ),
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
                'Create and manage your professional CVs.',
              ),
              const SizedBox(height: 24),
              Text(
                _editingCvId == null
                    ? 'Create New CV'
                    : 'Edit Existing CV',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : saveCV,
                  icon: const Icon(Icons.save),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _editingCvId == null
                            ? 'Save CV'
                            : 'Update CV',
                  ),
                ),
              ),
              if (_editingCvId != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: clearForm,
                    child: const Text('Cancel Editing'),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Saved CVs',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: loadCVs,
                    tooltip: 'Refresh CVs',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              buildSavedCVs(),
            ],
          ),
        ),
      ),
    );
  }
}
