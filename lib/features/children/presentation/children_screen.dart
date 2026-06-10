import 'package:flutter/material.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/children/data/repositories/firebase_children_repository.dart';
import 'package:vitta_mobile/features/children/domain/models/child.dart';
import 'package:vitta_mobile/features/children/domain/repositories/children_repository.dart';

class ChildrenScreen extends StatefulWidget {
  const ChildrenScreen({
    super.key,
    this.authRepository,
    this.childrenRepository,
  });

  final AuthRepository? authRepository;
  final ChildrenRepository? childrenRepository;

  @override
  State<ChildrenScreen> createState() => _ChildrenScreenState();
}

class _ChildrenScreenState extends State<ChildrenScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final ChildrenRepository _childrenRepository =
      widget.childrenRepository ?? FirebaseChildrenRepository();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _genderController = TextEditingController();

  AppUser? _currentUser;
  List<Child> _children = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authRepository.getCurrentUser();
      if (user == null) {
        throw Exception('Usuario nao autenticado.');
      }
      final children = await _childrenRepository.getChildrenByResponsible(
        user.uid,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _currentUser = user;
        _children = children;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Erro ao buscar criancas.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChild() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _childrenRepository.createChild(
        Child(
          id: '',
          responsibleId: _currentUser!.uid,
          name: _nameController.text.trim(),
          birthDate: _birthDateController.text.trim().isEmpty
              ? null
              : parseBrazilianDate(_birthDateController.text),
          gender: _genderController.text.trim().isEmpty
              ? null
              : _genderController.text.trim(),
        ),
      );
      _nameController.clear();
      _birthDateController.clear();
      _genderController.clear();
      await _loadChildren();
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Erro ao salvar crianca.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criancas')),
      body: RefreshIndicator(
        onRefresh: _loadChildren,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Adicionar crianca',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Informe o nome.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _birthDateController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(
                      labelText: 'Data de nascimento',
                      hintText: 'dd/mm/aaaa',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isNotEmpty && parseBrazilianDate(text) == null) {
                        return 'Use o formato dd/mm/aaaa.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _genderController,
                    decoration: const InputDecoration(
                      labelText: 'Genero opcional',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveChild,
                    child: Text(_isSaving ? 'Salvando...' : 'Adicionar'),
                  ),
                ],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Dependentes cadastrados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_children.isEmpty)
              const Text('Nenhuma crianca cadastrada ainda.')
            else
              ..._children.map(
                (child) => Card(
                  child: ListTile(
                    title: Text(child.name),
                    subtitle: Text(
                      [
                        if (child.birthDate != null)
                          formatBrazilianDate(child.birthDate),
                        if ((child.gender ?? '').isNotEmpty) child.gender!,
                      ].join(' - '),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
