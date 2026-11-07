
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

    switch (_selectedFeature) {
      case 'cv':
        return CVBuilderScreen(
          apiService: api,
          onLogout: _logout,
          onHome: _goHome,
        );

      case 'jobs':
        return JobsScreen(
          apiService: api,
          onLogout: _logout,
          onHome: _goHome,
          onSavedJobs: () => _openFeature('saved'),
          onApplications: () => _openFeature('applications'),
        );

      case 'profile':
        return ProfileScreen(
          apiService: api,
          onLogout: _logout,
          onHome: _goHome,
          onApplications: () => _openFeature('applications'),
        );

      case 'saved':
        return SavedJobsScreen(
          apiService: api,
          onLogout: _logout,
          onHome: _goHome,
          onJobs: () => _openFeature('jobs'),
        );

      case 'applications':
        return ApplicationsScreen(
          apiService: api,
          onLogout: _logout,
          onHome: _goHome,
          onJobs: () => _openFeature('jobs'),
        );

      default:
        return FeatureScreen(
          onHome: _goHome,
          onLogout: _logout,
        );
    }
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
  final VoidCallback onSavedJobs;
  final VoidCallback onApplications;

  const JobsScreen({
    super.key,
    required this.apiService,
    required this.onHome,
    required this.onLogout,
    required this.onSavedJobs,
    required this.onApplications,
  });

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _jobs = [];
  final Set<String> _savingIds = {};
  final Set<String> _applyingIds = {};

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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> saveJob(String jobId) async {
    if (_savingIds.contains(jobId)) return;

    setState(() => _savingIds.add(jobId));

    try {
      final result = await widget.apiService.saveJob(jobId);
      if (!mounted) return;
      showMessage(
        result['message']?.toString() ?? 'Job saved successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _savingIds.remove(jobId));
      }
    }
  }

  Future<void> applyForJob(String jobId) async {
    if (_applyingIds.contains(jobId)) return;

    setState(() => _applyingIds.add(jobId));

    try {
      final result = await widget.apiService.applyForJob(jobId);
      if (!mounted) return;

      showMessage(
        result['message']?.toString() ??
            'Application recorded successfully.',
      );
    } catch (error) {
      if (!mounted) return;
      showMessage(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _applyingIds.remove(jobId));
      }
    }
  }

  Widget jobCard(Map job) {
    final id = jobValue(job, 'id');
    final title = jobValue(job, 'title');
    final employer = jobValue(job, 'employer');
    final location = jobValue(job, 'location');
    final country = jobValue(job, 'country');
    final qualification = jobValue(job, 'qualification');
    final experience = jobValue(job, 'experience');
    final salary = jobValue(job, 'salary_information');
    final deadline = jobValue(job, 'deadline');
    final applyUrl = jobValue(job, 'official_apply_url');

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
            if (employer.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Employer: $employer'),
            ],
            if (location.isNotEmpty || country.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Location: ${[location, country].where((v) => v.isNotEmpty).join(', ')}'),
            ],
            if (qualification.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Qualification: $qualification'),
            ],
            if (experience.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Experience: $experience'),
            ],
            if (salary.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Salary: $salary'),
            ],
            if (deadline.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Deadline: $deadline'),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: id.isEmpty || _savingIds.contains(id)
                      ? null
                      : () => saveJob(id),
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: Text(
                    _savingIds.contains(id) ? 'Saving...' : 'Save Job',
                  ),
                ),
                FilledButton.icon(
                  onPressed: id.isEmpty || _applyingIds.contains(id)
                      ? null
                      : () => applyForJob(id),
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: Text(
                    _applyingIds.contains(id) ? 'Recording...' : 'Apply & Track',
                  ),
                ),
              ],
            ),
            if (applyUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Official application website:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                applyUrl,
                style: const TextStyle(
                  color: Color(0xFF087E65),
                  decoration: TextDecoration.underline,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Open this official link in your browser to apply with the employer.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
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
            onPressed: widget.onSavedJobs,
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'Saved Jobs',
          ),
          IconButton(
            onPressed: widget.onApplications,
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'My Applications',
          ),
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
                          final item = _jobs[index];
                          if (item is! Map) {
                            return const SizedBox.shrink();
                          }
                          return jobCard(item);
                        },
                      ),
                    ),
    );
  }
}

// SAVED JOBS SCREEN

class SavedJobsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onHome;
  final VoidCallback onLogout;
  final VoidCallback onJobs;

  const SavedJobsScreen({
    super.key,
    required this.apiService,
    required this.onHome,
    required this.onLogout,
    required this.onJobs,
  });

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _jobs = [];
  final Set<String> _removingIds = {};

  @override
  void initState() {
    super.initState();
    loadSavedJobs();
  }

  Future<void> loadSavedJobs() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.apiService.getSavedJobs();
      final data = result['jobs'];

      if (!mounted) return;
      setState(() {
        _jobs = data is List ? data : [];
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

  Future<void> removeJob(String id) async {
    if (_removingIds.contains(id)) return;

    setState(() => _removingIds.add(id));

    try {
      final result = await widget.apiService.removeSavedJob(id);
      if (!mounted) return;

      setState(() {
        _jobs.removeWhere(
          (item) => item is Map && item['id'].toString() == id,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Saved job removed.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _removingIds.remove(id));
      }
    }
  }

  Widget savedJobCard(Map job) {
    final id = job['id']?.toString() ?? '';
    final title = job['title']?.toString() ?? 'Job Opportunity';
    final employer = job['employer']?.toString() ?? '';
    final location = job['location']?.toString() ?? '';
    final country = job['country']?.toString() ?? '';
    final applyUrl = job['official_apply_url']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (employer.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text('Employer: $employer'),
            ],
            if (location.isNotEmpty || country.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Location: ${[location, country].where((v) => v.isNotEmpty).join(', ')}'),
            ],
            if (applyUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                applyUrl,
                style: const TextStyle(
                  color: Color(0xFF087E65),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: id.isEmpty || _removingIds.contains(id)
                  ? null
                  : () => removeJob(id),
              icon: const Icon(Icons.delete_outline),
              label: Text(
                _removingIds.contains(id) ? 'Removing...' : 'Remove Saved Job',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Jobs'),
        leading: IconButton(
          onPressed: widget.onHome,
          icon: const Icon(Icons.home),
        ),
        actions: [
          IconButton(
            onPressed: widget.onJobs,
            icon: const Icon(Icons.work_outline),
            tooltip: 'Browse Jobs',
          ),
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
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadSavedJobs,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _jobs.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadSavedJobs,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 130),
                          Icon(
                            Icons.bookmark_border,
                            size: 70,
                            color: Color(0xFF087E65),
                          ),
                          SizedBox(height: 18),
                          Center(
                            child: Text(
                              'No Saved Jobs Yet',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Save interesting jobs to find them here.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadSavedJobs,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _jobs.length,
                        itemBuilder: (context, index) {
                          final item = _jobs[index];
                          if (item is! Map) {
                            return const SizedBox.shrink();
                          }
                          return savedJobCard(item);
                        },
                      ),
                    ),
    );
  }
}

// APPLICATION TRACKING SCREEN

class ApplicationsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onHome;
  final VoidCallback onLogout;
  final VoidCallback onJobs;

  const ApplicationsScreen({
    super.key,
    required this.apiService,
    required this.onHome,
    required this.onLogout,
    required this.onJobs,
  });

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _applications = [];

  @override
  void initState() {
    super.initState();
    loadApplications();
  }

  Future<void> loadApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.apiService.getApplications();
      final data = result['applications'];

      if (!mounted) return;
      setState(() {
        _applications = data is List ? data : [];
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

  String statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'saved':
        return 'Saved';
      case 'applied':
        return 'Applied';
      case 'interview':
        return 'Interview';
      case 'rejected':
        return 'Rejected';
      case 'offered':
        return 'Offer Received';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return status.isEmpty ? 'Unknown' : status;
    }
  }

  Widget applicationCard(Map application) {
    final title = application['title']?.toString() ?? 'Job Opportunity';
    final employer = application['employer']?.toString() ?? '';
    final location = application['location']?.toString() ?? '';
    final country = application['country']?.toString() ?? '';
    final date = application['application_date']?.toString() ?? '';
    final status = application['status']?.toString() ?? '';
    final notes = application['notes']?.toString() ?? '';
    final applyUrl =
        application['official_apply_url']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (employer.isNotEmpty) ...[
              const SizedBox(height: 7),
              Text('Employer: $employer'),
            ],
            if (location.isNotEmpty || country.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Location: ${[location, country].where((v) => v.isNotEmpty).join(', ')}'),
            ],
            if (date.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Application Date: $date'),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(statusLabel(status)),
                  backgroundColor: const Color(0xFFE0F2ED),
                ),
              ],
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text('Notes: $notes'),
            ],
            if (applyUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Official application website:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              SelectableText(
                applyUrl,
                style: const TextStyle(
                  color: Color(0xFF087E65),
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Applications'),
        leading: IconButton(
          onPressed: widget.onHome,
          icon: const Icon(Icons.home),
        ),
        actions: [
          IconButton(
            onPressed: widget.onJobs,
            icon: const Icon(Icons.work_outline),
            tooltip: 'Browse Jobs',
          ),
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
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: loadApplications,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _applications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: loadApplications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 130),
                          Icon(
                            Icons.assignment_outlined,
                            size: 70,
                            color: Color(0xFF087E65),
                          ),
                          SizedBox(height: 18),
                          Center(
                            child: Text(
                              'No Applications Recorded',
                              style: TextStyle(
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                'Use Apply & Track on a job to record it here.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadApplications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final item = _applications[index];
                          if (item is! Map) {
                            return const SizedBox.shrink();
                          }
                          return applicationCard(item);
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
  final VoidCallback onApplications;

  const ProfileScreen({
    super.key,
    required this.apiService,
    required this.onHome,
    required this.onLogout,
    required this.onApplications,
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
            result['message']?.toString() ?? 'Profile updated successfully.',
          ),
        ),
      );

      await loadProfile();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
            onPressed: widget.onApplications,
            icon: const Icon(Icons.assignment_outlined),
            tooltip: 'My Applications',
          ),
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
                        _readOnlyField('Full Name', _fullName, Icons.person_outline),
                        _readOnlyField('Email Address', _email, Icons.email_outlined),
                        _readOnlyField('Phone Number', _phone, Icons.phone_outlined),
                        _sectionTitle('Location'),
                        _editField('City', _cityController, Icons.location_city),
                        _editField('Country', _countryController, Icons.public),
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
                            label: Text(_saving ? 'Saving...' : 'Save Profile'),
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
  final VoidCallback onHome;
  final VoidCallback onLogout;

  const FeatureScreen({
    super.key,
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
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
