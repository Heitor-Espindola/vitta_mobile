import 'package:flutter/material.dart';
import 'package:vitta_mobile/core/utils/date_text_formatters.dart';
import 'package:vitta_mobile/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/children/data/repositories/firebase_children_repository.dart';
import 'package:vitta_mobile/features/children/domain/models/child.dart';
import 'package:vitta_mobile/features/children/domain/repositories/children_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/data/repositories/firebase_vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';

class VaccinationCardScreen extends StatefulWidget {
  const VaccinationCardScreen({
    super.key,
    this.authRepository,
    this.childrenRepository,
    this.vaccinationRepository,
  });

  final AuthRepository? authRepository;
  final ChildrenRepository? childrenRepository;
  final VaccinationRepository? vaccinationRepository;

  @override
  State<VaccinationCardScreen> createState() => _VaccinationCardScreenState();
}

class _VaccinationCardScreenState extends State<VaccinationCardScreen> {
  late final AuthRepository _authRepository =
      widget.authRepository ?? FirebaseAuthRepository();
  late final ChildrenRepository _childrenRepository =
      widget.childrenRepository ?? FirebaseChildrenRepository();
  late final VaccinationRepository _vaccinationRepository =
      widget.vaccinationRepository ?? FirebaseVaccinationRepository();

  List<Child> _children = [];
  List<VaccinationRecord> _records = [];
  Child? _selectedChild;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
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
      final selectedChild = children.isEmpty ? null : children.first;
      final records = selectedChild == null
          ? <VaccinationRecord>[]
          : await _vaccinationRepository.getRecordsByChild(selectedChild.id);

      if (!mounted) {
        return;
      }
      setState(() {
        _children = children;
        _selectedChild = selectedChild;
        _records = records;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Erro ao buscar carteira vacinal.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectChild(Child? child) async {
    if (child == null) {
      return;
    }

    setState(() {
      _selectedChild = child;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await _vaccinationRepository.getRecordsByChild(child.id);
      if (!mounted) {
        return;
      }
      setState(() => _records = records);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Erro ao buscar registros vacinais.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carteira vacinal')),
      body: RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_children.isEmpty)
              const Text('Cadastre uma crianca primeiro para ver a carteira.')
            else ...[
              DropdownButtonFormField<Child>(
                initialValue: _selectedChild,
                decoration: const InputDecoration(labelText: 'Crianca'),
                items: _children.map((child) {
                  return DropdownMenuItem(
                    value: child,
                    child: Text(child.name),
                  );
                }).toList(),
                onChanged: _selectChild,
              ),
              const SizedBox(height: 16),
              if (_records.isEmpty)
                const Text('Nenhum registro vacinal encontrado ainda.')
              else
                ..._records.map(
                  (record) => Card(
                    child: ListTile(
                      title: Text(record.vaccineName),
                      subtitle: Text(
                        [
                          'Dose: ${record.dose}',
                          'Status: ${record.status}',
                          if (record.applicationDate != null)
                            'Aplicacao: ${formatBrazilianDate(record.applicationDate)}',
                          if (record.nextDoseDate != null)
                            'Proxima dose: ${formatBrazilianDate(record.nextDoseDate)}',
                        ].join('\n'),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
