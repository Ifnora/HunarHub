import 'package:flutter/material.dart';
import 'api_service.dart';

class AdminJobsScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const AdminJobsScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
    required this.onHome,
  });

  @override
  State<AdminJobsScreen> createState() => _AdminJobsScreenState();
}

class _AdminJobsScreenState extends State<AdminJobsScreen> {
  bool _loading = false;
  bool _submitting = false;
  bool _collecting = false;
  bool _showCreateForm = false;

  String _selectedStatus = 'all';
  String? _error;

  List<Map<String, dynamic>> _jobs = [];
  List<Map<String, dynamic>> _categories = [];

  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _employerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _applyUrlController = TextEditingController();
  final _locationController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _salaryController = TextEditingController();
  final _deadlineController = TextEditingController();

  int? _selectedCategoryId;

  static const List<String> _statuses = [
    'all',
    'pending',
    'approved',
    'published',
    'rejected',
    'expired',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _employerController.dispose();
    _descriptionController.dispose();
    _applyUrlController.dispose();
    _locationController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _salaryController.dispose();
    _deadlineController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _extractList(
    Map<String, dynamic> response,
    List<String> possibleKeys,
  ) {
    dynamic value;

    for (final key in possibleKeys) {
      if (response[key] is List) {
        value = response[key];
        break;
      }
    }

    if (value == null && response['data'] is Map) {
      final data = Map<String, dynamic>.from(response['data']);

      for (final key in possibleKeys) {
        if (data[key] is List) {
          value = data[key];
          break;
        }
      }
    }

    if (value == null && response['data'] is List) {
      value = response['data'];
    }

    if (value is! List) return [];

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        widget.apiService.getAdminJobs(
          status: _selectedStatus == 'all'
              ? null
              : _selectedStatus,
        ),
        widget.apiService.getJobCategories(),
      ]);

      final jobs = _extractList(
        results[0],
        ['jobs', 'items', 'results'],
      );

      final categories = _extractList(
        results[1],
        ['categories', 'items', 'results'],
      );

      if (!mounted) return;

      setState(() {
        _jobs = jobs;
        _categories = categories;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // AUTOMATIC JOB COLLECTION
  Future<void> _runJobCollector() async {
    if (_collecting) return;

    setState(() => _collecting = true);

    try {
      final response =
          await widget.apiService.runJobCollector();

      final summary = response['summary'];

      if (summary is Map) {
        final sources = summary['sources_checked'] ?? 0;
        final found = summary['jobs_found'] ?? 0;
        final added = summary['jobs_added'] ?? 0;
        final duplicates = summary['duplicates'] ?? 0;
        final errors = summary['errors'] ?? 0;

        _showMessage(
          'Collection complete: $sources sources checked, '
          '$found jobs found, $added added, '
          '$duplicates duplicates, $errors errors.',
        );
      } else {
        _showMessage('Job collection completed.');
      }

      await _loadData();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _collecting = false);
      }
    }
  }

  Future<void> _createJob() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      _showMessage('Please select a job category.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.apiService.createAdminJob(
        title: _titleController.text.trim(),
        employer: _employerController.text.trim(),
        description: _descriptionController.text.trim(),
        officialApplyUrl: _applyUrlController.text.trim(),
        categoryId: _selectedCategoryId!,
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        country: 'Pakistan',
        qualification: _qualificationController.text.trim().isEmpty
            ? null
            : _qualificationController.text.trim(),
        experience: _experienceController.text.trim().isEmpty
            ? null
            : _experienceController.text.trim(),
        salaryInformation: _salaryController.text.trim().isEmpty
            ? null
            : _salaryController.text.trim(),
        deadline: _deadlineController.text.trim().isEmpty
            ? null
            : _deadlineController.text.trim(),
      );

      if (!mounted) return;

      _clearForm();

      setState(() => _showCreateForm = false);

      _showMessage('Job submitted for admin review.');

      await _loadData();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _employerController.clear();
    _descriptionController.clear();
    _applyUrlController.clear();
    _locationController.clear();
    _qualificationController.clear();
    _experienceController.clear();
    _salaryController.clear();
    _deadlineController.clear();
    _selectedCategoryId = null;
  }

  Future<void> _performAction(
    String jobId,
    String action,
  ) async {
    try {
      if (action == 'approve') {
        await widget.apiService.approveAdminJob(jobId);
      } else if (action == 'publish') {
        await widget.apiService.publishAdminJob(jobId);
      } else if (action == 'reject') {
        await widget.apiService.rejectAdminJob(jobId);
      }

      if (!mounted) return;

      _showMessage('Job $action successful.');

      await _loadData();
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required.';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _buildCreateForm() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Submit New Job',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              _buildTextField(
                'Job Title',
                _titleController,
                required: true,
              ),

              _buildTextField(
                'Employer / Company',
                _employerController,
                required: true,
              ),

              DropdownButtonFormField<int>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Job Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((category) {
                  final id = int.tryParse(
                    category['id'].toString(),
                  );

                  if (id == null) return null;

                  return DropdownMenuItem<int>(
                    value: id,
                    child: Text(
                      category['name']?.toString() ?? 'Category',
                    ),
                  );
                }).whereType<DropdownMenuItem<int>>().toList(),
                onChanged: (value) {
                  setState(() => _selectedCategoryId = value);
                },
              ),

              const SizedBox(height: 12),

              _buildTextField(
                'Job Description',
                _descriptionController,
                maxLines: 5,
                required: true,
              ),

              _buildTextField(
                'Official Apply URL (HTTPS)',
                _applyUrlController,
                keyboardType: TextInputType.url,
                required: true,
              ),

              _buildTextField(
                'Location',
                _locationController,
              ),

              _buildTextField(
                'Qualification',
                _qualificationController,
              ),

              _buildTextField(
                'Experience',
                _experienceController,
              ),

              _buildTextField(
                'Salary Information',
                _salaryController,
              ),

              _buildTextField(
                'Application Deadline',
                _deadlineController,
              ),

              ElevatedButton.icon(
                onPressed: _submitting ? null : _createJob,
                icon: const Icon(Icons.send),
                label: Text(
                  _submitting ? 'Submitting...' : 'Submit for Review',
                ),
              ),

              TextButton(
                onPressed: _submitting
                    ? null
                    : () {
                        _clearForm();
                        setState(() => _showCreateForm = false);
                      },
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    final jobId = job['id']?.toString() ?? '';
    final title = job['title']?.toString() ?? 'Untitled Job';
    final employer = job['employer']?.toString() ?? 'Employer';
    final status = job['status']?.toString().toLowerCase() ?? 'unknown';
    final location = job['location']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
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

            Text(employer),

            if (location.isNotEmpty) Text(location),

            const SizedBox(height: 8),

            Chip(
              label: Text(status.toUpperCase()),
            ),

            if (job['official_apply_url'] != null) ...[
              const SizedBox(height: 4),
              const Text(
                'Official application link:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SelectableText(
                job['official_apply_url'].toString(),
              ),
            ],

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (status == 'pending')
                  ElevatedButton(
                    onPressed: jobId.isEmpty
                        ? null
                        : () => _performAction(
                              jobId,
                              'approve',
                            ),
                    child: const Text('Approve'),
                  ),

                if (status == 'approved')
                  ElevatedButton(
                    onPressed: jobId.isEmpty
                        ? null
                        : () => _performAction(
                              jobId,
                              'publish',
                            ),
                    child: const Text('Publish'),
                  ),

                if (status == 'pending' || status == 'approved')
                  OutlinedButton(
                    onPressed: jobId.isEmpty
                        ? null
                        : () => _performAction(
                              jobId,
                              'reject',
                            ),
                    child: const Text('Reject'),
                  ),
              ],
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
        title: const Text('HunarHub Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: widget.onHome,
            icon: const Icon(Icons.home),
            tooltip: 'Home',
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),

      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Job Management',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _collecting
                      ? null
                      : _runJobCollector,
                  icon: _collecting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.sync),
                  label: Text(
                    _collecting
                        ? 'Collecting Jobs...'
                        : 'Collect Jobs Automatically',
                  ),
                ),

                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showCreateForm = !_showCreateForm;
                    });
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Job'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (_showCreateForm) _buildCreateForm(),

            const Text(
              'Filter Jobs',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Job Status',
              ),
              items: _statuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(
                    status == 'all'
                        ? 'All Jobs'
                        : status.toUpperCase(),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) return;

                setState(() => _selectedStatus = value);
                _loadData();
              },
            ),

            const SizedBox(height: 16),

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),

            if (!_loading && _error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(_error!),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!_loading && _error == null && _jobs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('No jobs found.'),
                ),
              ),

            if (!_loading && _error == null)
              ..._jobs.map(_buildJobCard),
          ],
        ),
      ),
    );
  }
}
