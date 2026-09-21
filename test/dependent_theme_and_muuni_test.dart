import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_mobile/features/auth/domain/models/app_user.dart';
import 'package:vitta_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:vitta_mobile/features/information/domain/models/news_response.dart';
import 'package:vitta_mobile/features/information/domain/repositories/news_repository.dart';
import 'package:vitta_mobile/features/information/presentation/information_screen.dart';
import 'package:vitta_mobile/features/people/application/wallet_selection_controller.dart';
import 'package:vitta_mobile/features/profile/presentation/profile_screen.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccination_record.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/models/vaccine.dart';
import 'package:vitta_mobile/features/vaccination_card/domain/repositories/vaccination_repository.dart';
import 'package:vitta_mobile/features/vaccination_card/presentation/vaccination_card_screen.dart';
import 'package:vitta_mobile/features/vaccines/presentation/vaccines_screen.dart';
import 'package:vitta_mobile/shared/widgets/muuni_sprite.dart';

void main() {
  testWidgets('Muuni advances through multiple sprite frames', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MuuniEntranceAnimation())),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 120)),
    );
    await tester.pump();

    final observedFrames = <int>{};
    for (var index = 0; index < 6; index++) {
      await tester.pump(const Duration(milliseconds: 360));
      observedFrames.add(
        tester
            .widget<MuuniSpriteFrame>(
              find.byKey(const Key('muuni-animated-sprite')),
            )
            .frame,
      );
    }

    expect(observedFrames.length, greaterThan(2));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Conteúdo keeps the dependent visual context', (tester) async {
    final wallet = _dependentWallet();

    await tester.pumpWidget(
      MaterialApp(
        home: InformationScreen(
          newsRepository: _EmptyNewsRepository(),
          walletController: wallet,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('information-dependent-theme')),
      findsOneWidget,
    );
    expect(find.byType(MuuniSeatedNavMascot), findsNothing);
    expect(find.byType(MuuniSpriteFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Carteira starts the Muuni animation for a dependent', (
    tester,
  ) async {
    final wallet = _dependentWallet();

    await tester.pumpWidget(
      MaterialApp(
        home: VaccinationCardScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: _VaccinationFake(),
          walletController: wallet,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('muuni-card-animation')), findsOneWidget);
    expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Vacinas shows only one Muuni per page', (tester) async {
    final wallet = _dependentWallet();

    await tester.pumpWidget(
      MaterialApp(
        home: VaccinesScreen(
          authRepository: _AuthFake(),
          vaccinationRepository: _VaccinationFake(),
          walletController: wallet,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MuuniSpriteFrame), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Perfil keeps the dependent visual context', (tester) async {
    final wallet = _dependentWallet();

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          authRepository: _AuthFake(),
          walletController: wallet,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('profile-dependent-theme')), findsOneWidget);
    expect(find.byType(MuuniSpriteFrame), findsNothing);
    expect(find.text('Editar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

WalletSelectionController _dependentWallet() {
  final wallet = WalletSelectionController();
  wallet.bindCurrentPerson(_owner);
  wallet.selectPerson(_child);
  return wallet;
}

const _owner = AppUser(
  uid: 'owner-auth',
  authUid: 'owner-auth',
  personId: 'owner-person',
  name: 'Pessoa Titular',
  email: 'titular@example.com',
  role: 'responsible',
);

const _child = AppUser(
  uid: 'child-person',
  personId: 'child-person',
  canAuthenticate: false,
  name: 'Criança Teste',
  email: '',
  role: 'dependent',
  guardianIds: ['owner-person'],
);

class _EmptyNewsRepository implements NewsRepository {
  @override
  Future<NewsResponse> getNews({
    required String query,
    required int page,
    bool forceRefresh = false,
  }) async => const NewsResponse(articles: [], totalResults: 0);

  @override
  void dispose() {}
}

class _AuthFake implements AuthRepository {
  @override
  Stream<AppUser?> authStateChanges() => Stream.value(_owner);

  @override
  Future<AppUser?> getCurrentUser() async => _owner;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async => _owner;

  @override
  Future<void> signOut() async {}

  @override
  Future<AppUser> signUp({
    required String name,
    required String email,
    required String password,
    required String cpf,
    required DateTime birthDate,
  }) async => _owner;

  @override
  Future<AppUser> updateProfile(AppUser user) async => user;
}

class _VaccinationFake implements VaccinationRepository {
  @override
  Future<List<Vaccine>> getVaccines() async => const [];

  @override
  Future<List<VaccinationRecord>> getRecordsByChild(String childId) async =>
      const [];

  @override
  Future<List<VaccinationRecord>> getRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) async => const [];

  @override
  Future<List<VaccinationRecord>> getRecordsByResponsible(
    String responsibleId,
  ) async => const [];

  @override
  Stream<List<VaccinationRecord>> watchRecordsByPerson({
    required String personId,
    required String responsibleId,
  }) => Stream.value(const []);

  @override
  Stream<List<VaccinationRecord>> watchPatientRecords(String patientId) =>
      Stream.value(const []);
}
