
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

    if (_selectedFeature == 'profile') {
      return ProfileScreen(
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

// JOBS SCREEN

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
                        const Icon(Icons.cloud_off, size: 55),
                        const SizedBox(height: 15),
                        Text(_error!, textAlign: TextAlign.center),
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
                        physics: const AlwaysScrollableScrollPhysics(),
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
                            padding: EdgeInsets.symmetric(horizontal: 30),
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
                          final company = jobValue(job, 'company_name');
                          final location = jobValue(job, 'location');
                          final jobType = jobValue(job, 'employment_type');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title.isEmpty ? 'Job Opportunity' : title,
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

// PROFILE SCREEN

class ProfileScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.apiService,
    required this.onHome,
    required this.onLogout,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _educationController = TextEditingController();
  final _skillsController = TextEditingController();
  final _experienceController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  String _fullName = '';
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

  String _listToText(dynamic value) {
    if (value is List) {
      return value.map((item) {
        if (item is Map) {
          return item.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join(' | ');
        }
        return item.toString();
      }).join(', ');
    }

    if (value is String) return value;

    return '';
  }

  List<String> _textToList(String value) {
    return value
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<void> loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.apiService.getProfile();
      final dynamic data = result['profile'];

      if (data is! Map) {
        throw Exception('Profile data is unavailable.');
      }

      if (!mounted) return;

      setState(() {
        _fullName = data['full_name']?.toString() ?? '';
        _email = data['email']?.toString() ?? '';
        _phone = data['phone']?.toString() ?? '';

        _cityController.text = data['city']?.toString() ?? '';
        _countryController.text = data['country']?.toString() ?? '';

        _educationController.text = _listToText(data['education']);
        _skillsController.text = _listToText(data['skills']);
        _experienceController.text = _listToText(data['experience']);

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

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final result = await widget.apiService.updateProfile(
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        education: _textToList(_educationController.text),
        skills: _textToList(_skillsController.text),
        experience: _textToList(_experienceController.text),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ??
                'Profile updated successfully.',
          ),
        ),
      );

      await loadProfile();
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
        setState(() => _saving = false);
      }
    }
  }

  Widget _readOnlyField(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _editField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
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

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Color(0xFF087E65),
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
            tooltip: 'Logout',
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
                        const Icon(Icons.person_off, size: 55),
                        const SizedBox(height: 15),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: loadProfile,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Color(0xFF087E65),
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            _fullName.isEmpty ? 'My Account' : _fullName,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _sectionTitle('Personal Information'),
                        _readOnlyField(
                          'Full Name',
                          _fullName,
                          Icons.person_outline,
                        ),
                        _readOnlyField(
                          'Email Address',
                          _email,
                          Icons.email_outlined,
                        ),
                        _readOnlyField(
                          'Phone Number',
                          _phone,
                          Icons.phone_outlined,
                        ),
                        _sectionTitle('Location'),
                        _editField(
                          'City',
                          _cityController,
                          Icons.location_city,
                        ),
                        _editField(
                          'Country',
                          _countryController,
                          Icons.public,
                        ),
                        _sectionTitle('Professional Information'),
                        _editField(
                          'Education',
                          _educationController,
                          Icons.school_outlined,
                          lines: 3,
                        ),
                        _editField(
                          'Skills',
                          _skillsController,
                          Icons.star_outline,
                          lines: 3,
                        ),
                        _editField(
                          'Work Experience',
                          _experienceController,
                          Icons.work_outline,
                          lines: 4,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'For Education, Skills and Experience, '
                          'separate each entry with a comma.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : saveProfile,
                            icon: const Icon(Icons.save),
                            label: Text(
                              _saving ? 'Saving...' : 'Save Profile',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: loadProfile,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}

// INTERVIEW & TEST PREPARATION PLACEHOLDER

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
                Icons.quiz_outlined,
                size: 60,
                color: Color(0xFF087E65),
              ),
              const SizedBox(height: 18),
              const Text(
                'Interview & Test Preparation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Career preparation for banking, government jobs, '
                'private sector and other professions.',
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
