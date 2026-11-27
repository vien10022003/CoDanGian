import 'package:material_ui/material_ui.dart';

import '../theme/viet_theme.dart';

/// Displays concise rules for Cờ Chém (Stage 1: board layout & basic movement).
class CoChemRulesDialog extends StatelessWidget {
  const CoChemRulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.menu_book_rounded, color: VietTheme.bronzeGoldLight),
          SizedBox(width: 10),
          Expanded(child: Text('Luật chơi Cờ Chém')),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _RuleSection(
              heading: '1. Bàn cờ & Quân cờ',
              body:
                  '• Bàn cờ gồm 5 hàng × 5 cột (25 giao điểm) nối với nhau bằng đường ngang, dọc và chéo.\n'
                  '• Người chơi A cầm 10 quân Đỏ (hai hàng trên), đi trước.\n'
                  '• Người chơi B cầm 10 quân Xanh (hai hàng dưới), đi sau.\n'
                  '• Hàng giữa ban đầu để trống.',
            ),
            SizedBox(height: 12),
            _RuleSection(
              heading: '2. Cách di chuyển',
              body:
                  '• Hai bên đi luân phiên, mỗi lượt chọn một quân của phe mình.\n'
                  '• Chạm vào quân cờ để xem các ô sáng màu xanh ngọc có thể đi.\n'
                  '• Quân cờ chỉ được đi đến vị trí liền kề đang trống có đường nối trực tiếp.\n'
                  '• Không thể đi đến ô không có đường nối hoặc di chuyển quân đối phương.',
            ),
            SizedBox(height: 12),
            _RuleSection(
              heading: '3. Ghi chú giai đoạn',
              body:
                  '• Phiên bản hiện tại triển khai bàn cờ chuẩn, chế độ 2 người chơi tại chỗ, hoàn tác nước đi và ván mới.\n'
                  '• Luật ăn quân, thắng/thua, AI và các trò chơi khác (Cờ Gánh, Cờ Ba Tướng) sẽ được mở rộng ở giai đoạn tiếp theo.',
            ),
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: VietTheme.bronzeGold,
            foregroundColor: VietTheme.lacquerDark,
          ),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Đã hiểu',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _RuleSection extends StatelessWidget {
  const _RuleSection({
    required this.heading,
    required this.body,
  });

  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: const TextStyle(
            color: VietTheme.bronzeGoldLight,
            fontWeight: FontWeight.w700,
            fontSize: 14.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: const TextStyle(
            color: VietTheme.parchmentSoft,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

