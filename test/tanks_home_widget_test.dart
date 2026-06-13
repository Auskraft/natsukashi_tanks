import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natsukashi_tanks/core/storage/game_storage.dart';
import 'package:natsukashi_tanks/features/tanks/app/tanks_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('витрина показывает все три режима', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await GameStorage.init();

    await tester.pumpWidget(const MaterialApp(home: TanksHomeScreen()));

    expect(find.text('Кампания'), findsOneWidget);
    expect(find.text('Выживание'), findsOneWidget);
    expect(find.text('Вызов дня'), findsOneWidget);
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('Документы'), findsOneWidget);
  });
}
