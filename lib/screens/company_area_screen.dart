import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import 'create_job_screen.dart';
import 'job_detail_screen.dart';

class CompanyAreaScreen extends StatefulWidget {
  final CompanySession session;

  const CompanyAreaScreen({super.key, required this.session});

  @override
  State<CompanyAreaScreen> createState() => _CompanyAreaScreenState();
}

class _CompanyAreaScreenState extends State<CompanyAreaScreen> {
  List<Job> _myJobs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMyJobs();
  }

  Future<void> _loadMyJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final jobs = await ApiService.fetchMyJobs();
      if (mounted) {
        setState(() {
          _myJobs = jobs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _openCreateJob() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreateJobScreen()),
    );
    if (created == true) {
      _loadMyJobs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Area Riservata Azienda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.public),
            tooltip: 'Bacheca Pubblica',
            onPressed: () => Navigator.pop(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateJob,
        icon: const Icon(Icons.add),
        label: const Text('Nuovo Annuncio'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadMyJobs,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.companyName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if (widget.session.email.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(widget.session.email, style: TextStyle(color: Colors.grey.shade700)),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openCreateJob,
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Pubblica nuovo annuncio'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'I miei annunci',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else if (_error != null)
              Column(
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: _loadMyJobs, child: const Text('Riprova')),
                ],
              )
            else if (_myJobs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Non hai ancora pubblicato annunci. Premi "Nuovo Annuncio" per iniziare.'),
              )
            else
              ..._myJobs.map((job) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        job.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Chip(
                        label: Text('${job.applicationsCount} cand.'),
                      ),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailScreen(job: job, session: widget.session),
                          ),
                        );
                        _loadMyJobs();
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
