## 6. Logic ăn quân (Capture)

Quân cờ có thể ăn quân đối phương bằng cách nhảy qua đầu.

- Một quân có thể nhảy qua một quân đối phương nếu hai quân nằm cạnh nhau trên cùng một đường thẳng có các đường nối hợp lệ.
- Vị trí ngay phía sau quân đối phương phải đang trống.
- Quân đang di chuyển nhảy qua quân đối phương và đáp xuống vị trí trống ngay phía sau.
- Quân bị nhảy qua sẽ bị loại khỏi bàn cờ.
- Không được nhảy qua quân đồng minh.
- Không được nhảy qua quân đối phương nếu vị trí đáp xuống đã có quân.
- Không được nhảy xa hơn vị trí ngay sau quân bị ăn.

### Ăn liên tiếp

Sau khi ăn quân, phải kiểm tra xem chính quân vừa di chuyển có thể tiếp tục ăn quân khác hay không.

- Nếu còn nước ăn hợp lệ, người chơi tiếp tục di chuyển chính quân đó để ăn tiếp.
- Nếu có nhiều hướng ăn, người chơi được chọn hướng.
- Không được chuyển sang quân khác trong quá trình ăn liên tiếp.
- Khi không còn nước ăn hợp lệ, lượt chơi kết thúc và chuyển sang đối thủ.

### Yêu cầu kỹ thuật

- Xây dựng hàm `getCaptureMoves(pieceId)` để tìm tất cả nước ăn hợp lệ của một quân.
- Xây dựng hàm `getLegalMoves(pieceId)` để trả về cả nước đi thường và nước ăn hợp lệ.
- Xây dựng cơ chế bắt buộc tiếp tục ăn khi còn nước ăn liên tiếp.
- Trong quá trình ăn liên tiếp, chỉ cho phép di chuyển quân đang thực hiện chuỗi ăn.
- Cập nhật vị trí quân và trạng thái quân bị ăn sau mỗi lần di chuyển.
- Lưu toàn bộ chuỗi ăn vào lịch sử để hỗ trợ hoàn tác.

Tách biệt logic ăn quân khỏi giao diện.