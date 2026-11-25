import 'package:flutter/material.dart';
import '../models/job_model.dart';
import '../services/api_service.dart';
import 'auth_screen.dart';
import 'company_area_screen.dart';
import 'job_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Job> _jobs = [];
  bool _isLoading = true;
  String? _error;
  CompanySession? _session;

  @override
  void initState() {
    super.initState();
    _initScreen();
  }

  Future<void> _initScreen() async {
    await _checkLoginStatus();
    await _loadJobs();
  }

  Future<void> _checkLoginStatus() async {
    final session = await ApiService.getSavedSession();
    if (mounted) {
      setState(() => _session = session);
    }
  }

  Future<void> _loadJobs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final jobs = await ApiService.fetchJobs();
      if (mounted) {
        setState(() {
          _jobs = jobs;
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

  Future<void> _openAuthAndReservedArea() async {
    final session = await Navigator.push<CompanySession>(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
    if (session != null && mounted) {
      setState(() => _session = session);
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CompanyAreaScreen(session: session)),
      );
      await _checkLoginStatus();
      await _loadJobs();
    }
  }

  Future<void> _openCompanyArea() async {
    final session = _session;
    if (session == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CompanyAreaScreen(session: session)),
    );
    await _checkLoginStatus();
    await _loadJobs();
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      setState(() => _session = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logout effettuato')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacheca Annunci'),
        actions: [
          if (_session == null)
            TextButton.icon(
              icon: const Icon(Icons.business),
              label: const Text('Area Azienda'),
              onPressed: _openAuthAndReservedArea,
            )
          else ...[
            TextButton.icon(
              icon: const Icon(Icons.dashboard),
              label: const Text('Area Riservata'),
              onPressed: _openCompanyArea,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _logout,
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadJobs,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'Impossibile contattare il server.\n$_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _loadJobs,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Riprova'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (_jobs.isEmpty) {
      return ListView(
        children: const [
          Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                'Nessun annuncio pubblicato al momento.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _jobs.length,
      itemBuilder: (context, index) {
        final job = _jobs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Azienda: ${job.companyName}', style: TextStyle(color: Colors.indigo.shade700)),
                const SizedBox(height: 4),
                Text(job.description, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailScreen(job: job, session: _session),
                ),
              );
            },
          ),
        );
      },
    );
  }
}