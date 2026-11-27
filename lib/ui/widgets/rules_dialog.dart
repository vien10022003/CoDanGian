import 'package:material_ui/material_ui.dart';

import '../theme/viet_theme.dart';

/// Displays concise rules for Cờ Chém (movement, jump capture, and multi-capture chains).
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
              heading: '2. Di chuyển cơ bản',
              body:
                  '• Hai bên đi luân phiên, mỗi lượt chọn một quân của phe mình.\n'
                  '• Chạm quân cờ để xem các ô sáng xanh ngọc có thể đi thường.\n'
                  '• Quân cờ chỉ được đi tới vị trí trống liền kề có đường nối trực tiếp.',
            ),
            SizedBox(height: 12),
            _RuleSection(
              heading: '3. Luật ăn quân & Ăn liên tiếp',
              body:
                  '• Nếu quân đối phương đứng kề ngay trước trên cùng một đường thẳng hợp lệ và ô ngay phía sau đang trống, bạn có thể nhảy qua đầu để ăn quân đó (ô đáp hiển thị viền đỏ-vàng).\n'
                  '• Không được nhảy qua quân đồng minh hoặc nhảy xa hơn ô ngay sau quân bị ăn.\n'
                  '• Sau khi ăn, nếu chính quân vừa nhảy còn nước ăn tiếp theo, bạn bắt buộc phải tiếp tục dùng quân đó ăn liên tiếp (có thể chọn hướng nếu có nhiều hướng) cho đến khi hết nước ăn mới chuyển lượt.',
            ),
            SizedBox(height: 12),
            _RuleSection(
              heading: '4. Điều kiện chiến thắng',
              body:
                  '• Phe A thắng ngay lập tức khi toàn bộ quân của Phe B bị ăn hết.\n'
                  '• Phe B thắng ngay lập tức khi toàn bộ quân của Phe A bị ăn hết.\n'
                  '• Nếu đối phương hết quân ngay giữa chuỗi ăn liên tiếp, ván đấu kết thúc ngay và công bố phe thắng cuộc.',
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
