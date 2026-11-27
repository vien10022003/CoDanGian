Phát triển một game cờ dân gian Việt Nam, bao gồm 3 trò chơi: **Cờ Gánh, Cờ Chém và Cờ Ba Tướng**.

### Yêu cầu chung
- Giao diện đẹp, hiện đại, background bắt mắt, mang nét văn hóa Việt Nam.
- Thiết kế kiến trúc có thể mở rộng để bổ sung nhiều trò chơi cờ sau này.
- Hỗ trợ iOS và Android (dùng flutter).

### Giai đoạn 1: Phát triển Cờ Chém
- Xây dựng bàn cờ đúng theo thiết kế được cung cấp.
- Triển khai đầy đủ luật chơi Cờ Chém.
- Hiển thị quân cờ, lượt chơi, các nước đi hợp lệ và trạng thái thắng/thua.
- Tạo chế độ **2 người chơi local trên cùng một thiết bị**: người A đi trước, người B đi sau.
- Cho phép bắt đầu ván mới và chơi lại.

### Yêu cầu kỹ thuật
- Tách biệt logic luật chơi và giao diện.
- Xây dựng cấu trúc dữ liệu lưu trữ trạng thái bàn cờ, bao gồm vị trí và thông tin của từng quân cờ.
- Mỗi nước đi phải cập nhật trạng thái bàn cờ một cách nhất quán.
- Thiết kế Game Engine độc lập để sau này có thể tích hợp AI đánh cờ, lưu/tải ván đấu và chơi online.
- Không hardcode trạng thái bàn cờ vào giao diện.


## 1. Bàn cờ

Bàn cờ có dạng hình chữ nhật gồm 5 hàng và 5 cột, tổng cộng 25 vị trí.

Sơ đồ bàn cờ:

```text
 A-------A-------A-------A-------A
 | \     |     / | \     |     / |
 |   \   |   /   |   \   |   /   |
 |     \ | /     |     \ | /     |
 A-------A-------A-------A-------A
 |     / | \     |     / | \     |
 |   /   |   \   |   /   |   \   |
 | /     |     \ | /     |     \ |
 o-------o-------o-------o-------o
 | \     |     / | \     |     / |
 |   \   |   /   |   \   |   /   |
 |     \ | /     |     \ | /     |
 B-------B-------B-------B-------B
 |     / | \     |     / | \     |
 |   /   |   \   |   /   |   \   |
 | /     |     \ | /     |     \ |
 B-------B-------B-------B-------B
```

Trong đó:
- A: Quân phe A (màu đỏ).
- B: Quân phe B (màu xanh).
- o: Vị trí trống.

Các đường kẻ biểu thị những hướng di chuyển hợp lệ. Quân cờ chỉ được di chuyển đến vị trí liền kề có đường nối trực tiếp.

## 3. Luật di chuyển cơ bản

- Mỗi lượt, người chơi chọn một quân của mình để di chuyển.
- Quân chỉ được di chuyển đến vị trí liền kề có đường nối trực tiếp.
- Chỉ được di chuyển đến vị trí đang trống.
- Không được di chuyển đến vị trí không có đường nối.
- Không được di chuyển quân của đối phương.
- Phe A đi trước, sau đó đến phe B. Hai bên luân phiên nhau.

## 4. Chế độ chơi

Triển khai chế độ 2 người chơi trên cùng một thiết bị:
- Người chơi A sử dụng quân đỏ và đi trước.
- Người chơi B sử dụng quân xanh và đi sau.
- Hiển thị rõ lượt chơi hiện tại.
- Người chơi chạm vào quân cờ để chọn, sau đó chạm vào vị trí hợp lệ để di chuyển.
- Làm nổi bật các vị trí có thể di chuyển đến.

## 5. Cấu trúc dữ liệu và Game Engine

- Mỗi vị trí trên bàn cờ có ID cố định.
- Mỗi quân cờ có ID riêng, phe sở hữu và vị trí hiện tại.
- Lưu danh sách các đường nối giữa các vị trí trên bàn cờ.
- Lưu lịch sử nước đi, bao gồm quân cờ, vị trí xuất phát và vị trí đích.
- Lưu lượt chơi hiện tại.

Game Engine cần cung cấp:
- `getGameState()`: Lấy toàn bộ trạng thái bàn cờ.
- `getLegalMoves(pieceId)`: Xác định các vị trí mà một quân cờ có thể di chuyển đến.
- `makeMove(pieceId, targetPosition)`: Thực hiện nước đi hợp lệ và cập nhật trạng thái.
- `undoMove()`: Hoàn tác nước đi gần nhất.

Tách biệt hoàn toàn Game Engine, dữ liệu bàn cờ và giao diện. Thiết kế để có thể mở rộng logic ăn quân và AI sau này.

**Lưu ý:** Giai đoạn này chỉ triển khai bàn cờ, trạng thái ban đầu và cơ chế di chuyển cơ bản. Chưa triển khai logic ăn quân, điều kiện thắng/thua hoặc AI. Thiết kế kiến trúc để có thể bổ sung các chức năng này sau.

**Lưu ý:** Trước mắt chỉ triển khai Cờ Chém. Chưa cần phát triển AI, chơi online hoặc hai trò chơi còn lại.
