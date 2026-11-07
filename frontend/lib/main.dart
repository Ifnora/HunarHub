
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
  String? _selectedFeature;

  void _openFeature(String feature) {
    setState(() => _selectedFeature = feature);
  }

  void _handleLogin(String token) {
    setState(() => _token = token);
  }

  void _goHome() {
    setState(() => _selectedFeature = null);
  }

  void _logout() {
    setState(() {
      _token = null;
      _selectedFeature = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedFeature == null) {
      return HomeScreen(onSelect: _openFeature);
    }

    if (_token == null) {
      return LoginScreen(onLogin: _handleLogin);
    }

    final api = ApiService(token: _token!);

    if (_selectedFeature == 'cv') {
      return CVBuilderScreen(
        apiService: api,
        onLogout: _logout,
        onHome: _goHome,
      );
    }

    if (_selectedFeature == 'jobs') {
      return JobsScreen(
        apiService: api,
        onLogout: _logout,
        onHome: _goHome,
      );
    }

    return FeatureScreen(
      feature: _selectedFeature!,
      onHome: _goHome,
      onLogout: _logout,
    );
  }
}

// PUBLIC HOME SCREEN

class HomeScreen extends StatelessWidget {
  final ValueChanged<String> onSelect;

  const HomeScreen({
    super.key,
    required this.onSelect,
  });

  Widget featureCard({
    required IconData icon,
    required String title,
    required String description,
    required String feature,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onSelect(feature),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 38,
                color: const Color(0xFF087E65),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text(
                'Explore →',
                style: TextStyle(
                  color: Color(0xFF087E65),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HunarHub Pakistan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const Center(
              child: Icon(
                Icons.school,
                size: 65,
                color: Color(0xFF087E65),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Your Career. Your Future.',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Find jobs, build your CV and prepare for success.',
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Explore HunarHub',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
              children: [
                featureCard(
                  icon: Icons.work_outline,
                  title: 'Jobs & Internships',
                  description: 'Explore career opportunities in Pakistan.',
                  feature: 'jobs',
                ),
                featureCard(
                  icon: Icons.description_outlined,
                  title: 'CV Builder',
                  description: 'Create your professional CV.',
                  feature: 'cv',
                ),
                featureCard(
                  icon: Icons.quiz_outlined,
                  title: 'Interview & Test Preparation',
                  description: 'Prepare for interviews and career tests.',
                  feature: 'preparation',
                ),
                featureCard(
                  icon: Icons.person_outline,
                  title: 'Profile & Applications',
                  description: 'Manage your profile and applications.',
                  feature: 'profile',
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'HunarHub Pakistan',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// JOBS SCREEN CONNECTED TO API

class JobsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const JobsScreen({
    super.key,
    required this.apiService,
    required this.onHome,
    required this.onLogout,
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

      final dynamic jobsData = result['jobs'];

      if (!mounted) return;

      setState(() {
        _jobs = jobsData is List ? jobsData : [];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String jobValue(Map job, String key) {
    return job[key]?.toString() ?? '';
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
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 55,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: loadJobs,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _jobs.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadJobs,
                      child: ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 130),
                          Icon(
                            Icons.work_outline,
                            size: 75,
                            color: Color(0xFF087E65),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              'No Jobs Published Yet',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30,
                            ),
                            child: Text(
                              'New jobs and internships will appear here. '
                              'Please check again later.',
                              textAlign: TextAlign.center,
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
                          final dynamic item = _jobs[index];

                          if (item is! Map) {
                            return const SizedBox.shrink();
                          }

                          final job = item;

                          final title = jobValue(job, 'title');
                          final company =
                              jobValue(job, 'company_name');
                          final location =
                              jobValue(job, 'location');
                          final jobType =
                              jobValue(job, 'employment_type');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty
                                        ? 'Job Opportunity'
                                        : title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (company.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text('Company: $company'),
                                  ],
                                  if (location.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text('Location: $location'),
                                  ],
                                  if (jobType.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text('Type: $jobType'),
                                  ],
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

// OTHER FEATURE SCREENS

class FeatureScreen extends StatelessWidget {
  final String feature;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const FeatureScreen({
    super.key,
    required this.feature,
    required this.onHome,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final details = {
      'preparation': (
        'Interview & Test Preparation',
        'Prepare for interviews and professional tests.'
      ),
      'profile': (
        'Profile & Applications',
        'Manage your personal profile and job applications.'
      ),
    };

    final item = details[feature]!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('HunarHub Pakistan'),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.construction,
                size: 60,
                color: Color(0xFF087E65),
              ),
              const SizedBox(height: 18),
              Text(
                item.$1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.$2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              const Text(
                'This section is under development.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onHome,
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// CV BUILDER

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
                'Create your professional CV for job applications.',
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _cvType,
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
