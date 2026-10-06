import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/app.dart';
import 'package:frontend/core/session/portero.dart';
import 'package:frontend/features/login/screens/login_screen.dart';
import 'package:frontend/features/voice/voice_screen.dart';

import 'tokens_de_prueba.dart';

void main() {
  // En los tests no hay micrófono: la pantalla de voz recibe "no disponible".
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugin.csdcorp.com/speech_to_text'),
      (_) async => false,
    );
  });

  testWidgets('al abrir sin sesión, va al login', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('al abrir con una sesión que sirve, entra directo', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': tokenVigenteDePrueba()});
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(VoiceScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('al abrir con una sesión vencida, va al login', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': tokenVencidoDePrueba()});
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('irAlLogin deja solo el login, sin poder volver atrás', (tester) async {
    FlutterSecureStorage.setMockInitialValues({'auth_token': tokenVigenteDePrueba()});
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(VoiceScreen), findsOneWidget);

    irAlLogin();
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(VoiceScreen), findsNothing);
    expect(navegador.currentState!.canPop(), isFalse);
  });
}
