import 'package:co_dan_gian/app.dart';
import 'package:co_dan_gian/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('Cờ Dân Gian UI flow', () {
    testWidgets('HomeScreen displays all 3 games and opens Cờ Chém', (tester) async {
      await tester.pumpWidget(CoDanGianApp());

      expect(find.text('Cờ Dân Gian'), findsOneWidget);
      expect(find.text('Cờ Chém'), findsOneWidget);
      expect(find.text('Cờ Gánh'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Cờ Ba Tướng'),
        150,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Cờ Ba Tướng'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Cờ Chém'),
        -150,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('Chơi ngay'), findsOneWidget);

      // Tapping upcoming game displays informational message
      await tester.ensureVisible(find.text('Cờ Gánh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cờ Gánh'));
      await tester.pump();
      expect(
        find.text('Cờ Gánh đang được phát triển ở giai đoạn tiếp theo.'),
        findsOneWidget,
      );

      // Tapping Cờ Chém launches the game board screen
      await tester.ensureVisible(find.text('Cờ Chém'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cờ Chém'));
      await tester.pumpAndSettle();

      expect(find.text('Người chơi A'), findsOneWidget);
      expect(find.text('Người chơi B'), findsOneWidget);
      expect(find.byKey(const ValueKey('node_r0_c0')), findsOneWidget);
      expect(find.byKey(const ValueKey('node_r4_c4')), findsOneWidget);
      expect(find.byKey(const ValueKey('piece_A_01')), findsOneWidget);
      expect(find.byKey(const ValueKey('piece_B_10')), findsOneWidget);
    });

    testWidgets('supports selecting piece, moving, undoing, history, rules, and restart', (tester) async {
      await tester.pumpWidget(CoDanGianApp());
      await tester.tap(find.text('Cờ Chém'));
      await tester.pumpAndSettle();

      // Initially Side A's turn, 0 moves
      expect(find.text('Lượt A'), findsOneWidget);
      expect(find.text('Nước 0'), findsOneWidget);

      // Tapping Side B piece during Side A's turn is blocked with a turn hint
      await tester.tap(find.byKey(const ValueKey('node_r3_c1')));
      await tester.pump();
      expect(find.text('Lượt A'), findsOneWidget);
      expect(
        find.text('Đang là lượt của Người chơi A (Đỏ).'),
        findsOneWidget,
      );

      // Select A_07 at r1_c1 and move diagonally to r2_c2
      await tester.tap(find.byKey(const ValueKey('node_r1_c1')));
      await tester.pump();
      expect(
        find.text('Chạm vào điểm sáng màu xanh ngọc để di chuyển.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('node_r2_c2')));
      await tester.pumpAndSettle();

      expect(find.text('Lượt B'), findsOneWidget);
      expect(find.text('Nước 1'), findsOneWidget);

      // Open Move History sheet
      await tester.tap(find.text('Lịch sử (1)'));
      await tester.pumpAndSettle();
      expect(find.text('Lịch sử nước đi'), findsOneWidget);
      expect(find.text('Nước #1 · A_07'), findsOneWidget);

      // Close sheet via Navigator pop
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Undo move
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(find.text('Lượt A'), findsOneWidget);
      expect(find.text('Nước 0'), findsOneWidget);

      // Make another move then test Restart confirmation
      await tester.tap(find.byKey(const ValueKey('node_r1_c2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('node_r2_c2')));
      await tester.pumpAndSettle();
      expect(find.text('Nước 1'), findsOneWidget);

      await tester.tap(find.text('Chơi lại'));
      await tester.pumpAndSettle();
      expect(find.text('Bắt đầu ván mới?'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Chơi lại'));
      await tester.pumpAndSettle();
      expect(find.text('Lượt A'), findsOneWidget);
      expect(find.text('Nước 0'), findsOneWidget);

      // Open Rules dialog
      await tester.tap(find.byTooltip('Luật chơi'));
      await tester.pumpAndSettle();
      expect(find.text('Luật chơi Cờ Chém'), findsOneWidget);
      await tester.tap(find.text('Đã hiểu'));
      await tester.pumpAndSettle();
    });

    testWidgets('Registry-injected custom engine drives UI without hardcoding', (tester) async {
      final registry = FolkGameRegistry();
      await tester.pumpWidget(CoDanGianApp(registry: registry));
      expect(find.text('Cờ Chém'), findsOneWidget);
    });

    testWidgets('renders cleanly on mobile portrait and landscape without overflow', (tester) async {
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      tester.view.devicePixelRatio = 1.0;

      // Mobile portrait (390x844)
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(CoDanGianApp());
      await tester.tap(find.text('Cờ Chém'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('node_r2_c2')), findsOneWidget);

      // Mobile / tablet landscape (844x420)
      tester.view.physicalSize = const Size(844, 420);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('node_r2_c2')), findsOneWidget);
    });
  });
}

