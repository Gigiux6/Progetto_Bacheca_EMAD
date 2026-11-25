import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/application_model.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import 'application_detail_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;
  final CompanySession? session;

  const JobDetailScreen({
    super.key,
    required this.job,
    this.session,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String? _cvFileName;
  Uint8List? _cvBytes;
  bool _isSubmitting = false;

  List<Application> _applications = [];
  bool _isLoadingApps = false;
  String? _appsError;

  bool get _isOwnerCompany =>
      widget.session != null && widget.session!.companyId == widget.job.companyId;

  bool get _isOtherCompany =>
      widget.session != null && widget.session!.companyId != widget.job.companyId;

  @override
  void initState() {
    super.initState();
    if (_isOwnerCompany) {
      _loadApplications();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoadingApps = true;
      _appsError = null;
    });
    try {
      final apps = await ApiService.fetchApplications(widget.job.id);
      if (mounted) {
        setState(() {
          _applications = apps;
          _isLoadingApps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _appsError = e.toString();
          _isLoadingApps = false;
        });
      }
    }
  }

  Future<void> _pickCv() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _cvBytes = bytes;
          _cvFileName = file.name;
        });
      }
    }
  }

  Future<void> _submitCandidate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cvFileName == null || _cvBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allega il tuo curriculum in formato PDF prima di inviare.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.submitApplication(
        jobId: widget.job.id,
        firstName: _firstNameCtrl.text,
        lastName: _lastNameCtrl.text,
        email: _emailCtrl.text,
        cvBytes: _cvBytes,
        cvFileName: _cvFileName!,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Candidatura inviata con successo!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red.shade700),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.job.title)),
      body: RefreshIndicator(
        onRefresh: _isOwnerCompany ? _loadApplications : () async {},
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.job.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Azienda: ${widget.job.companyName}',
                style: TextStyle(fontWeight: FontWeight.w600, color: Colors.indigo.shade700),
              ),
              const SizedBox(height: 12),
              Text(widget.job.description, style: const TextStyle(fontSize: 15, height: 1.4)),
              const Divider(height: 32),
              if (widget.session == null) _buildCandidateForm(),
              if (_isOtherCompany)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.indigo),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Sei autenticato come azienda. Le aziende non possono candidarsi agli annunci.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isOwnerCompany) _buildApplicationsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Candidati all\'offerta',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _firstNameCtrl,
            decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci il nome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _lastNameCtrl,
            decoration: const InputDecoration(labelText: 'Cognome', border: OutlineInputBorder()),
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Inserisci il cognome' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: (v) {
              final text = v?.trim() ?? '';
              if (text.isEmpty || !text.contains('@')) {
                return 'Inserisci un indirizzo email valido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _pickCv,
            icon: const Icon(Icons.attach_file),
            label: Text(_cvFileName != null ? 'CV: $_cvFileName' : 'Allega Curriculum (PDF)'),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitCandidate,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Invia Candidatura'),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Candidature Ricevute (${_applications.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (_isLoadingApps)
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
        else if (_appsError != null)
          Column(
            children: [
              Text(_appsError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              OutlinedButton(onPressed: _loadApplications, child: const Text('Riprova')),
            ],
          )
        else if (_applications.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('Nessuna candidatura ricevuta finora per questo annuncio.'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _applications.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final app = _applications[index];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(
                    '${app.firstName} ${app.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(app.email),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplicationDetailScreen(
                          application: app,
                          jobTitle: widget.job.title,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}