
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'api_service.dart';

class ProfessionalCVBuilderScreen extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback onLogout;
  final VoidCallback onHome;

  const ProfessionalCVBuilderScreen({
    super.key,
    required this.apiService,
    required this.onLogout,
    required this.onHome,
  });

  @override
  State<ProfessionalCVBuilderScreen> createState() =>
      _ProfessionalCVBuilderScreenState();
}

class _ProfessionalCVBuilderScreenState
    extends State<ProfessionalCVBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  final titleController = TextEditingController();
  final nameController = TextEditingController();
  final jobTitleController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final cityController = TextEditingController();
  final addressController = TextEditingController();
  final linkedinController = TextEditingController();
  final summaryController = TextEditingController();
  final skillsController = TextEditingController();
  final languagesController = TextEditingController();
  final certificationsController = TextEditingController();
  final cnicController = TextEditingController();

  final List<_CVEntry> experiences = [];
  final List<_CVEntry> education = [];

  String cvType = 'experienced';
  String? photoBase64;
  String? editingId;

  bool loading = true;
  bool saving = false;

  List<dynamic> savedCVs = [];

  static const Color primaryColor = Color(0xFF087E65);

  @override
  void initState() {
    super.initState();

    experiences.add(_CVEntry.experience());
    education.add(_CVEntry.education());

    _loadCVs();
  }

  @override
  void dispose() {
    titleController.dispose();
    nameController.dispose();
    jobTitleController.dispose();
    emailController.dispose();
    phoneController.dispose();
    cityController.dispose();
    addressController.dispose();
    linkedinController.dispose();
    summaryController.dispose();
    skillsController.dispose();
    languagesController.dispose();
    certificationsController.dispose();
    cnicController.dispose();

    for (final item in experiences) {
      item.dispose();
    }

    for (final item in education) {
      item.dispose();
    }

    super.dispose();
  }

  void _addExperience() {
    setState(() {
      experiences.add(_CVEntry.experience());
    });
  }

  void _addEducation() {
    setState(() {
      education.add(_CVEntry.education());
    });
  }

  Future<void> _loadCVs() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      // ApiService.getCVs() returns Map<String, dynamic>.
      final Map<String, dynamic> response =
          await widget.apiService.getCVs();

      List<dynamic> items = [];

      final data = response['data'] ?? response['cvs'];

      if (data is List) {
        items = data;
      } else if (data is Map && data['cvs'] is List) {
        items = data['cvs'] as List;
      }

      if (mounted) {
        setState(() {
          savedCVs = items;
        });
      }
    } catch (e) {
      _showMessage('Could not load saved CVs.');
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _pickPhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 35,
        maxWidth: 400,
        maxHeight: 400,
      );

      if (image == null) return;

      final bytes = await image.readAsBytes();

      if (bytes.length > 350 * 1024) {
        _showMessage(
          'Photo is too large. Please select a smaller image.',
        );
        return;
      }

      if (!mounted) return;

      setState(() {
        photoBase64 = base64Encode(bytes);
      });
    } catch (e) {
      _showMessage('Unable to select photo.');
    }
  }

  ImageProvider? _getProfileImage() {
    if (photoBase64 == null || photoBase64!.isEmpty) {
      return null;
    }

    try {
      return MemoryImage(base64Decode(photoBase64!));
    } catch (_) {
      return null;
    }
  }

  void _removePhoto() {
    setState(() => photoBase64 = null);
  }

  Map<String, dynamic> _makeContent() {
    return {
      'full_name': nameController.text.trim(),
      'professional_title': jobTitleController.text.trim(),
      'email': emailController.text.trim(),
      'phone': phoneController.text.trim(),
      'city': cityController.text.trim(),
      'address': addressController.text.trim(),
      'linkedin': linkedinController.text.trim(),
      'summary': summaryController.text.trim(),
      'skills': skillsController.text.trim(),
      'languages': languagesController.text.trim(),
      'certifications': certificationsController.text.trim(),
      'photo_base64': photoBase64,
      'experiences': experiences.map((e) => e.toMap()).toList(),
      'education': education.map((e) => e.toMap()).toList(),
    };
  }

  Future<void> _saveCV() async {
    if (!_formKey.currentState!.validate()) return;
    if (saving) return;

    setState(() => saving = true);

    try {
      final content = _makeContent();
      final title = titleController.text.trim();

      if (editingId == null) {
        await widget.apiService.createCV(
          title: title,
          cvType: cvType,
          templateName: 'professional',
          content: content,
        );
      } else {
        await widget.apiService.updateCV(
          id: editingId!,
          title: title,
          cvType: cvType,
          templateName: 'professional',
          content: content,
        );
      }

      if (!mounted) return;

      _showMessage('CV saved successfully.');

      setState(() {
        editingId = null;
      });

      await _loadCVs();
    } catch (e) {
      _showMessage('Could not save CV. Please try again.');
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  void _loadForEditing(Map<String, dynamic> cv) {
    final content = cv['content'];

    if (content is! Map) {
      _showMessage('This CV has invalid saved information.');
      return;
    }

    final data = Map<String, dynamic>.from(content);

    for (final item in experiences) {
      item.dispose();
    }

    for (final item in education) {
      item.dispose();
    }

    experiences.clear();
    education.clear();

    titleController.text = cv['title']?.toString() ?? '';
    nameController.text = data['full_name']?.toString() ?? '';
    jobTitleController.text =
        data['professional_title']?.toString() ?? '';
    emailController.text = data['email']?.toString() ?? '';
    phoneController.text = data['phone']?.toString() ?? '';
    cityController.text = data['city']?.toString() ?? '';
    addressController.text = data['address']?.toString() ?? '';
    linkedinController.text = data['linkedin']?.toString() ?? '';
    summaryController.text = data['summary']?.toString() ?? '';
    skillsController.text = data['skills']?.toString() ?? '';
    languagesController.text = data['languages']?.toString() ?? '';
    certificationsController.text =
        data['certifications']?.toString() ?? '';

    photoBase64 = data['photo_base64']?.toString();

    final savedType = cv['cv_type']?.toString() ?? 'experienced';

    const validTypes = [
      'fresh_graduate',
      'experienced',
      'banking',
    ];

    cvType = validTypes.contains(savedType) ? savedType : 'experienced';

    editingId = cv['id']?.toString();

    final exp = data['experiences'];

    if (exp is List) {
      for (final item in exp) {
        if (item is Map) {
          experiences.add(
            _CVEntry.experienceFrom(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    final edu = data['education'];

    if (edu is List) {
      for (final item in edu) {
        if (item is Map) {
          education.add(
            _CVEntry.educationFrom(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    if (experiences.isEmpty) {
      experiences.add(_CVEntry.experience());
    }

    if (education.isEmpty) {
      education.add(_CVEntry.education());
    }

    setState(() {});

    _showMessage('CV loaded for editing.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Scrollable.ensureVisible(
          _formKey.currentContext ?? context,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  Future<void> _deleteCV(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete CV?'),
        content: const Text(
          'Are you sure you want to delete this CV?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await widget.apiService.deleteCV(id);

      if (!mounted) return;

      _showMessage('CV deleted.');
      await _loadCVs();
    } catch (e) {
      _showMessage('Could not delete CV.');
    }
  }

  pw.Widget _pdfSectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.teal800,
        ),
      ),
    );
  }

  pw.Document _generatePDF() {
    final pdf = pw.Document();

    final skills = skillsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    pw.MemoryImage? profileImage;

    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      try {
        profileImage = pw.MemoryImage(
          base64Decode(photoBase64!),
        );
      } catch (_) {
        profileImage = null;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(38),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) {
          final widgets = <pw.Widget>[];

          widgets.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        nameController.text.trim(),
                        style: pw.TextStyle(
                          fontSize: 25,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        jobTitleController.text.trim(),
                        style: const pw.TextStyle(
                          fontSize: 13,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (profileImage != null)
                  pw.Container(
                    width: 75,
                    height: 85,
                    child: pw.Image(
                      profileImage,
                      fit: pw.BoxFit.cover,
                    ),
                  ),
              ],
            ),
          );

          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 12),
              height: 2,
              color: PdfColors.teal700,
            ),
          );

          final contact = [
            emailController.text.trim(),
            phoneController.text.trim(),
            cityController.text.trim(),
            addressController.text.trim(),
            linkedinController.text.trim(),
          ].where((e) => e.isNotEmpty).toList();

          if (contact.isNotEmpty) {
            widgets.add(
              pw.Text(
                contact.join('  |  '),
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            );
          }

          if (summaryController.text.trim().isNotEmpty) {
            widgets.add(_pdfSectionTitle('Professional Summary'));
            widgets.add(
              pw.Text(
                summaryController.text.trim(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          }

          if (skills.isNotEmpty) {
            widgets.add(_pdfSectionTitle('Key Skills'));
            widgets.add(
              pw.Wrap(
                spacing: 5,
                runSpacing: 5,
                children: skills.map((skill) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      skill,
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  );
                }).toList(),
              ),
            );
          }

          final validExperiences = experiences.where(
            (e) =>
                e.fields[0].text.trim().isNotEmpty ||
                e.fields[1].text.trim().isNotEmpty,
          );

          if (validExperiences.isNotEmpty) {
            widgets.add(_pdfSectionTitle('Work Experience'));

            for (final exp in validExperiences) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 9),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        exp.fields[1].text.trim(),
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        [
                          exp.fields[0].text.trim(),
                          exp.fields[2].text.trim(),
                        ].where((e) => e.isNotEmpty).join(' | '),
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.Text(
                        [
                          exp.fields[3].text.trim(),
                          exp.fields[4].text.trim(),
                        ].where((e) => e.isNotEmpty).join(' - '),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      if (exp.fields[5].text.trim().isNotEmpty)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(top: 3),
                          child: pw.Text(
                            exp.fields[5].text.trim(),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
          }

          final validEducation = education.where(
            (e) =>
                e.fields[0].text.trim().isNotEmpty ||
                e.fields[1].text.trim().isNotEmpty,
          );

          if (validEducation.isNotEmpty) {
            widgets.add(_pdfSectionTitle('Education'));

            for (final edu in validEducation) {
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        edu.fields[1].text.trim(),
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        [
                          edu.fields[0].text.trim(),
                          edu.fields[2].text.trim(),
                        ].where((e) => e.isNotEmpty).join(' | '),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        [
                          edu.fields[3].text.trim(),
                          edu.fields[4].text.trim(),
                        ].where((e) => e.isNotEmpty).join(' - '),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          if (languagesController.text.trim().isNotEmpty) {
            widgets.add(_pdfSectionTitle('Languages'));
            widgets.add(
              pw.Text(
                languagesController.text.trim(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          }

          if (certificationsController.text.trim().isNotEmpty) {
            widgets.add(_pdfSectionTitle('Certifications'));
            widgets.add(
              pw.Text(
                certificationsController.text.trim(),
                style: const pw.TextStyle(fontSize: 10),
              ),
            );
          }

          return widgets;
        },
      ),
    );

    return pdf;
  }

  Future<void> _previewPDF() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final document = _generatePDF();
      final bytes = await document.save();

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: 'HunarHub_CV.pdf',
      );
    } catch (e) {
      _showMessage('Could not generate PDF.');
    }
  }

  Future<void> _sharePDF() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final document = _generatePDF();
      final bytes = await document.save();

      await Printing.sharePdf(
        bytes: bytes,
        filename: 'HunarHub_CV.pdf',
      );
    } catch (e) {
      _showMessage('Could not share PDF.');
    }
  }

  void _newCV() {
    for (final item in experiences) {
      item.dispose();
    }

    for (final item in education) {
      item.dispose();
    }

    experiences.clear();
    education.clear();

    titleController.clear();
    nameController.clear();
    jobTitleController.clear();
    emailController.clear();
    phoneController.clear();
    cityController.clear();
    addressController.clear();
    linkedinController.clear();
    summaryController.clear();
    skillsController.clear();
    languagesController.clear();
    certificationsController.clear();
    cnicController.clear();

    cvType = 'experienced';
    photoBase64 = null;
    editingId = null;

    experiences.add(_CVEntry.experience());
    education.add(_CVEntry.education());

    setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryColor),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int lines = 1,
    TextInputType keyboard = TextInputType.text,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter $label';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Widget _entryCard(
    String title,
    _CVEntry entry,
    List<_CVEntry> collection,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: collection.length == 1
                      ? null
                      : () {
                          setState(() {
                            collection.remove(entry);
                            entry.dispose();
                          });
                        },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            for (int i = 0; i < entry.fields.length; i++)
              _field(
                entry.labels[i],
                entry.fields[i],
                lines: entry.labels[i] == 'Description' ? 3 : 1,
              ),
          ],
        ),
      ),
    );
  }

  Widget _savedCVCard(Map<String, dynamic> cv) {
    final id = cv['id']?.toString() ?? '';

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(
            Icons.description,
            color: primaryColor,
          ),
        ),
        title: Text(cv['title']?.toString() ?? 'Untitled CV'),
        subtitle: Text(
          cv['cv_type']?.toString() ?? 'Professional CV',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _loadForEditing(cv);
            } else if (value == 'delete' && id.isNotEmpty) {
              _deleteCV(id);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
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
        title: const Text('Professional CV Builder'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Home',
            onPressed: widget.onHome,
            icon: const Icon(Icons.home),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Build Your Professional CV',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Create, save and share a professional CV.',
                    style: TextStyle(color: Colors.grey),
                  ),

                  _sectionTitle('CV Information', Icons.description),

                  _field(
                    'CV Title',
                    titleController,
                    required: true,
                  ),

                  DropdownButtonFormField<String>(
                    value: cvType,
                    decoration: const InputDecoration(
                      labelText: 'CV Category',
                      border: OutlineInputBorder(),
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
                        setState(() => cvType = value);
                      }
                    },
                  ),

                  _sectionTitle('Profile Photo', Icons.camera_alt),

                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: _getProfileImage(),
                          child: _getProfileImage() == null
                              ? const Icon(
                                  Icons.person,
                                  size: 48,
                                  color: Colors.grey,
                                )
                              : null,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _pickPhoto,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Choose Photo'),
                            ),
                            if (photoBase64 != null)
                              TextButton(
                                onPressed: _removePhoto,
                                child: const Text('Remove'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  _sectionTitle('Personal Details', Icons.person),

                  _field(
                    'Full Name',
                    nameController,
                    required: true,
                  ),
                  _field('Professional Title', jobTitleController),
                  _field(
                    'Email Address',
                    emailController,
                    keyboard: TextInputType.emailAddress,
                  ),
                  _field(
                    'Phone Number',
                    phoneController,
                    keyboard: TextInputType.phone,
                  ),
                  _field('City / Country', cityController),
                  _field('Address', addressController),
                  _field(
                    'LinkedIn / Portfolio',
                    linkedinController,
                  ),

                  _field(
                    'CNIC (optional - private)',
                    cnicController,
                    keyboard: TextInputType.number,
                  ),

                  const Text(
                    'Privacy: CNIC is not saved or included in your PDF. '
                    'Avoid sharing sensitive identity information in a CV.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),

                  _sectionTitle(
                    'Professional Summary',
                    Icons.article_outlined,
                  ),

                  _field(
                    'Professional Summary',
                    summaryController,
                    lines: 5,
                  ),

                  _sectionTitle('Key Skills', Icons.star_outline),

                  _field(
                    'Skills (separate with commas)',
                    skillsController,
                    lines: 3,
                  ),

                  _sectionTitle(
                    'Work Experience',
                    Icons.work_outline,
                  ),

                  for (int i = 0; i < experiences.length; i++)
                    _entryCard(
                      'Experience ${i + 1}',
                      experiences[i],
                      experiences,
                    ),

                  OutlinedButton.icon(
                    onPressed: _addExperience,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Experience'),
                  ),

                  _sectionTitle('Education', Icons.school_outlined),

                  for (int i = 0; i < education.length; i++)
                    _entryCard(
                      'Education ${i + 1}',
                      education[i],
                      education,
                    ),

                  OutlinedButton.icon(
                    onPressed: _addEducation,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Another Qualification'),
                  ),

                  _sectionTitle('Languages', Icons.language),

                  _field(
                    'Languages',
                    languagesController,
                    lines: 2,
                  ),

                  _sectionTitle(
                    'Certifications',
                    Icons.workspace_premium,
                  ),

                  _field(
                    'Certifications and Training',
                    certificationsController,
                    lines: 3,
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: saving ? null : _saveCV,
                      icon: const Icon(Icons.save),
                      label: Text(
                        saving
                            ? 'Saving...'
                            : editingId == null
                                ? 'Save CV'
                                : 'Update CV',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _previewPDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('Preview / Print PDF'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _sharePDF,
                      icon: const Icon(Icons.share),
                      label: const Text('Share PDF'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton.icon(
                    onPressed: _newCV,
                    icon: const Icon(Icons.add),
                    label: const Text('Create New CV'),
                  ),

                  _sectionTitle(
                    'My Saved CVs',
                    Icons.folder_open,
                  ),

                  if (savedCVs.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No saved CVs yet. Create and save your first CV.',
                        textAlign: TextAlign.center,
                      ),
                    ),

                  for (final item in savedCVs)
                    if (item is Map)
                      _savedCVCard(
                        Map<String, dynamic>.from(item),
                      ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }
}

class _CVEntry {
  final List<String> labels;
  final List<TextEditingController> fields;

  _CVEntry._(this.labels, this.fields);

  factory _CVEntry.experience() {
    return _CVEntry._(
      [
        'Organization / Company',
        'Designation',
        'Location',
        'Start Date',
        'End Date',
        'Description',
      ],
      List.generate(6, (_) => TextEditingController()),
    );
  }

  factory _CVEntry.education() {
    return _CVEntry._(
      [
        'Institution',
        'Degree / Qualification',
        'Field of Study',
        'Start Date',
        'End Date',
      ],
      List.generate(5, (_) => TextEditingController()),
    );
  }

  factory _CVEntry.experienceFrom(Map<String, dynamic> data) {
    final entry = _CVEntry.experience();

    for (int i = 0; i < entry.fields.length; i++) {
      entry.fields[i].text =
          data['field_$i']?.toString() ?? '';
    }

    return entry;
  }

  factory _CVEntry.educationFrom(Map<String, dynamic> data) {
    final entry = _CVEntry.education();

    for (int i = 0; i < entry.fields.length; i++) {
      entry.fields[i].text =
          data['field_$i']?.toString() ?? '';
    }

    return entry;
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    for (int i = 0; i < fields.length; i++) {
      result['field_$i'] = fields[i].text.trim();
    }

    return result;
  }

  void dispose() {
    for (final field in fields) {
      field.dispose();
    }
  }
}
