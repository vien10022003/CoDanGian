# Cờ Dân Gian Việt Nam

Ứng dụng cờ dân gian Việt Nam xây dựng bằng **Flutter** (hỗ trợ Android & iOS), với kiến trúc Game Engine độc lập giúp dễ dàng mở rộng cho nhiều trò chơi (**Cờ Chém**, **Cờ Gánh**, **Cờ Ba Tướng**), tích hợp AI, lưu/tải ván đấu và chơi trực tuyến ở các giai đoạn tiếp theo.

## Trạng thái hiện tại (Cờ Chém — Di chuyển & Ăn quân)

- **Bàn cờ 5×5 (25 vị trí cố định, 56 đường nối)** đúng theo sơ đồ trong [info.md](info.md).
- **Quân cờ ban đầu**: 10 quân Đỏ (Phe A, đi trước) ở 2 hàng trên, hàng giữa trống, 10 quân Xanh (Phe B, đi sau) ở 2 hàng dưới.
- **Luật chơi đã triển khai**:
  - Di chuyển đến vị trí trống liền kề có đường nối trực tiếp ([info.md](info.md)).
  - **Nhảy qua đầu ăn quân** theo đường thẳng có đường nối hợp lệ khi ô ngay phía sau trống ([info2.md](info2.md)).
  - **Ăn liên tiếp bắt buộc**: giữ lượt cho quân vừa ăn nếu còn hướng nhảy ăn tiếp, cho phép chọn hướng nếu có nhiều nhánh, rồi mới chuyển lượt khi hết nước ăn.
- **Chế độ 2 người chơi tại chỗ (local)** trên cùng một thiết bị:
  - Hiển thị rõ lượt đi, trạng thái ăn liên tiếp, số quân còn lại và số quân đã ăn.
  - Làm nổi bật ô đi thường (xanh ngọc) và ô nhảy ăn quân (đỏ-vàng).
  - Hoàn tác nước đi (`undoMove`) khôi phục chính xác quân bị ăn và trạng thái chuỗi ăn; xem lịch sử nước đi; bắt đầu ván mới / chơi lại.
- **Giao diện mang nét văn hóa Việt Nam**: Nền sơn mài kết hợp họa tiết Trống Đồng Đông Sơn, bàn cờ gỗ khắc chìm, quân cờ sơn mài/lam ngọc.

## Kiến trúc thư mục

- `lib/engine/`: Pure Dart Game Engine (hoàn toàn không phụ thuộc Flutter UI):
  - `models/`: `PlayerSide`, `BoardPosition`, `BoardEdge`, `BoardGraph`, `GamePiece`, `GameMove`, `GameState`, `MoveResult`, `UndoResult`, `CaptureMoveOption`.
  - `contracts/`: `GameEngine` (`getGameState`, `getCaptureMoves`, `getLegalMoves`, `makeMove`, `undoMove`, `resetGame`, `loadState`), `GameRules`, `CaptureRule`, `WinConditionRule`.
  - `games/`: `StandardGraphGameEngine`, `JumpCaptureRule`, và `co_chem/` (`CoChemBoard`, `CoChemRules`).
  - `registry/`: `FolkGameRegistry` đăng ký danh mục trò chơi mở rộng.
- `lib/application/`: `GameController` kết nối `GameEngine` với lớp giao diện.
- `lib/ui/`: Chủ đề văn hóa Việt (`VietTheme`), họa tiết nền (`VietCulturalBackground`), bàn cờ (`GameBoardWidget`, `GameBoardPainter`), quân cờ (`VietPieceWidget`), màn hình chọn trò chơi (`HomeScreen`) và màn chơi (`GamePlayScreen`).

## Kiểm thử & Chạy ứng dụng

```bash
flutter analyze
flutter test
flutter run
```
