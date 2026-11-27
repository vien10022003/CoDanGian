# Cờ Dân Gian Việt Nam

Ứng dụng cờ dân gian Việt Nam xây dựng bằng **Flutter** (hỗ trợ Android & iOS), với kiến trúc Game Engine độc lập giúp dễ dàng mở rộng cho nhiều trò chơi (**Cờ Chém**, **Cờ Gánh**, **Cờ Ba Tướng**), tích hợp AI, lưu/tải ván đấu và chơi trực tuyến ở các giai đoạn tiếp theo.

## Trạng thái hiện tại (Giai đoạn 1 — Cờ Chém)

- **Bàn cờ 5×5 (25 vị trí cố định, 56 đường nối)** đúng theo sơ đồ trong [info.md](info.md).
- **Quân cờ ban đầu**: 10 quân Đỏ (Phe A, đi trước) ở 2 hàng trên, hàng giữa trống, 10 quân Xanh (Phe B, đi sau) ở 2 hàng dưới.
- **Chế độ 2 người chơi tại chỗ (local)** trên cùng một thiết bị:
  - Hiển thị rõ lượt đi hiện tại và số quân mỗi bên.
  - Chạm quân cờ để làm nổi bật các nước đi hợp lệ.
  - Hoàn tác nước đi (`undoMove`), xem lịch sử nước đi, bắt đầu ván mới / chơi lại.
- **Giao diện mang nét văn hóa Việt Nam**: Nền sơn mài kết hợp họa tiết Trống Đồng Đông Sơn, bàn cờ gỗ khắc chìm, quân cờ sơn mài/lam ngọc.

## Kiến trúc thư mục

- `lib/engine/`: Pure Dart Game Engine (hoàn toàn không phụ thuộc Flutter UI):
  - `models/`: `PlayerSide`, `BoardPosition`, `BoardEdge`, `BoardGraph`, `GamePiece`, `GameMove`, `GameState`, `MoveResult`, `UndoResult`.
  - `contracts/`: `GameEngine` (`getGameState`, `getLegalMoves`, `makeMove`, `undoMove`, `resetGame`, `loadState`), `GameRules`, `CaptureRule`, `WinConditionRule`.
  - `games/co_chem/`: `CoChemBoard` và `CoChemRules`.
  - `registry/`: `FolkGameRegistry` đăng ký danh mục trò chơi mở rộng.
- `lib/application/`: `GameController` kết nối `GameEngine` với lớp giao diện.
- `lib/ui/`: Chủ đề văn hóa Việt (`VietTheme`), họa tiết nền (`VietCulturalBackground`), bàn cờ (`GameBoardWidget`, `GameBoardPainter`), quân cờ (`VietPieceWidget`), màn hình chọn trò chơi (`HomeScreen`) và màn chơi (`GamePlayScreen`).

## Kiểm thử & Chạy ứng dụng

```bash
flutter analyze
flutter test
flutter run
```
