import 'package:flutter/material.dart';
import '../repo/supabase_projects_repo.dart';

class SubmitProposalScreen extends StatefulWidget {
  const SubmitProposalScreen({super.key});

  @override
  State<SubmitProposalScreen> createState() => _SubmitProposalScreenState();
}

class _SubmitProposalScreenState extends State<SubmitProposalScreen> {
  final _form = GlobalKey<FormState>();
  String _groupId = '';
  String _title = '';
  String _abstract = '';
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Proposal')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Your Group ID'),
                onChanged: (v) => _groupId = v.trim(),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter group id' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Project Title'),
                onChanged: (v) => _title = v.trim(),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Abstract'),
                minLines: 4, maxLines: 8,
                onChanged: (v) => _abstract = v.trim(),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter abstract' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _busy ? null : _submit,
                icon: const Icon(Icons.upload_file_outlined),
                label: Text(_busy ? 'Submitting...' : 'Submit'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final id = await ProjectsRepo.instance.submitProposal(
        groupId: _groupId,
        title: _title,
        abstractText: _abstract,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submitted (proposal id: $id)')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
