# VDB Studio — Checklist triển khai giao diện desktop

Ngày cập nhật: 18/11/2026

Mục tiêu: xây dựng môi trường quản trị SQL desktop có đầy đủ các khu vực làm việc trong ảnh MySQL Workbench tham chiếu, sử dụng nhận diện VDB Studio và engine V++ hiện tại. Giữ nguyên các chức năng đã có và kết nối mọi thao tác mới với engine thực tế.

Quy ước:

- `[x]` Đã có mã triển khai trong VDB hiện tại hoặc đã được người dùng nghiệm thu theo ghi chú; chưa đồng nghĩa mọi kiểm thử GUI đều đã chạy tự động.
- `[ ]` Cần triển khai hoặc nghiệm thu thêm.
- **P0**: cần cho phiên bản desktop sử dụng được; **P1**: hoàn thiện quy trình quản trị; **P2**: chức năng nâng cao cần mở rộng engine.
- Các mục 1–9 tương ứng với số đánh dấu trong ảnh. Result Grid và nghiệm thu desktop được bổ sung để hoàn thiện quy trình SQL.

## 1. Home — Trang chủ và quản lý kết nối

- [x] P0 — Nút Home luôn truy cập được từ thanh điều hướng.
- [x] P0 — Trang chủ liệt kê các catalog VDB cục bộ đã lưu và catalog gần đây.
- [x] P0 — Tạo kết nối mới, chọn tệp catalog, đặt tên hiển thị, kiểm tra kết nối.
- [x] P0 — Mở lại catalog đã lưu; tạo catalog mới khi người dùng yêu cầu.
- [x] P1 — Sửa, xóa hồ sơ kết nối (không xóa tệp dữ liệu), tìm kiếm và sắp xếp.
- [ ] P2 — Hồ sơ máy chủ từ xa, host/port, xác thực và TLS khi VDB có giao thức mạng riêng.

Nghiệm thu: mở được hai catalog thử nghiệm khác nhau từ Home và nhận diện đúng catalog đang hoạt động.

## 2. Connection Tabs — Tab kết nối

- [x] P0 — Thanh tab phiên kết nối phía trên các tab SQL.
- [x] P0 — Mỗi kết nối có tên, trạng thái và nút đóng.
- [x] P0 — Tách biệt schema, tab SQL, kết quả và nhật ký của từng catalog.
- [x] P1 — Chuyển đổi giữa các kết nối, kết nối lại và cảnh báo SQL chưa lưu khi đóng.
- [x] P1 — Khôi phục hồ sơ kết nối và phiên làm việc phù hợp khi mở lại Studio.

Nghiệm thu: chuyển tab không làm lẫn truy vấn hoặc dữ liệu giữa hai catalog.

## 3. Query Editor — Tab và trình soạn SQL

- [x] P0 — Tạo, chọn và đóng nhiều tab SQL.
- [x] P0 — Trình soạn có số dòng, tô màu cú pháp, vị trí dòng/cột và thụt lề.
- [x] P0 — Mở/lưu tệp SQL, chạy toàn bộ nội dung hoặc vùng chọn, chọn database cho từng tab.
- [x] P0 — Phím tắt Cmd/Ctrl+Enter và Cmd/Ctrl+S; kéo thay đổi chiều cao editor.
- [x] P0 — Thanh công cụ riêng của Query Editor với các thao tác phổ biến và tooltip/phím tắt.
- [x] P1 — Chạy câu SQL tại con trỏ, tìm kiếm/thay thế, format SQL, undo/redo đầy đủ.
- [x] P1 — Autocomplete từ khóa, database, table, column dựa trên catalog; kiểm tra lỗi cú pháp.
- [x] P1 — Đánh dấu tab chưa lưu, lưu phiên, lịch sử truy vấn và tùy chọn giới hạn hàng SELECT.
- [x] P2 — EXPLAIN SELECT từ câu tại con trỏ/vùng chọn, hiển thị kế hoạch engine trong tab riêng.
- [ ] P2 — Hủy truy vấn đang chạy và thực thi bất đồng bộ có hỗ trợ từ engine.
- [ ] P2 — Điều khiển autocommit/commit/rollback xuyên nhiều lần chạy khi engine hỗ trợ phiên giao dịch dài hạn.

Nghiệm thu: chạy SQL nhiều câu, chạy vùng chọn và mở/lưu UTF-8 chính xác; báo lỗi SQL đúng tại khu vực editor/output. Không bật nút giao dịch dài hạn trước khi engine hỗ trợ.

## 4. Menu Bar — Thanh menu

- [x] P0 — Menu macOS VDB Studio (Quit) và Edit (Undo, Cut, Copy, Paste, Select All) đã có trong lớp Cocoa.
- [x] P0 — File: New Query, Open SQL, Save, Save As, Close Tab, Quit.
- [x] P0 — Edit: Undo, Redo, Cut, Copy, Paste, Select All, Find/Replace.
- [x] P0 — View: hiện/ẩn Navigator, Information, SQL Additions, Output; reset layout.
- [x] P0 — Query: Run All, Run Selection, Run Current Statement.
- [x] P1 — Database: quản lý kết nối, refresh schemas, tạo database/table, xem cấu trúc.
- [x] P1 — Tools: import/export dữ liệu, tùy chọn Studio; Help: tài liệu SQL VDB, About.
- [ ] P2 — Server và Scripting: quản trị server, tự động hóa khi engine có API tương ứng.
- [x] P1 — Đồng bộ trạng thái enabled/disabled và phím tắt giữa menu Cocoa và giao diện WKWebView.

Nghiệm thu: menu và toolbar gọi cùng hành động; thao tác bị thiếu hỗ trợ phải vô hiệu hóa kèm lý do.

## 5. Main Toolbar — Thanh công cụ chính

- [x] P0 — Nút tab mới, mở/lưu SQL, chạy SQL/vùng chọn và refresh.
- [x] P0 — Nút tạo database, mẫu tạo table và chọn database đã có ở các khu vực giao diện hiện tại.
- [x] P0 — Sắp xếp nhóm thao tác kết nối, tệp SQL và schema thành toolbar rõ ràng.
- [x] P0 — Nút Home/New Connection; nút tạo database và table từ toolbar.
- [x] P1 — Nút tìm đối tượng database, import/export, thông tin đối tượng và tùy chọn bố cục; quản lý hồ sơ kết nối qua Home.
- [x] P1 — Trạng thái nút theo kết nối, truy vấn đang thực thi và chức năng engine hỗ trợ.
- [x] P2 — Nút tạo view mở bản nháp CREATE VIEW theo schema và đối tượng đã chọn.
- [x] P2 — Nút Administration mở quản trị catalog cục bộ và sao lưu/phục hồi.
- [x] P2 — Nút Mô hình hiển thị sơ đồ quan hệ chỉ đọc từ metadata bảng/cột/khóa ngoại.
- [ ] P2 — Nút tạo routine và quản trị máy chủ từ xa khi có backend tương ứng.

Nghiệm thu: mọi nút có tooltip và hành động thật, không tạo nút trang trí hoặc báo thành công giả.

## 6. Layout Controls — Điều khiển bố cục

- [x] P0 — Splitter thay đổi chiều cao SQL Editor; cửa sổ Cocoa có khả năng thay đổi kích thước.
- [x] P0 — Nút hiện/ẩn Navigator bên trái, SQL Additions bên phải và Output phía dưới.
- [x] P0 — Splitter ngang/dọc cho Navigator, Information, Editor, Result Grid, SQL Additions và Output.
- [x] P1 — Lưu kích thước, trạng thái panel và khôi phục bố cục mặc định.
- [x] P1 — Bố cục phù hợp khi thu nhỏ, phóng to, fullscreen hoặc dùng màn hình nhỏ.

Nghiệm thu: từng panel ẩn/hiện độc lập; editor và result grid tự mở rộng; không mất dữ liệu khi đổi bố cục.

## 7. Navigator & Information — Điều hướng và thông tin đối tượng

### Navigator

- [x] P0 — Cây database/schema và nhóm Tables, tìm kiếm, mở rộng/thu gọn, refresh.
- [x] P0 — Chọn database; nhấp một lần để xem Object Info, nhấp đúp hoặc Enter để xem dữ liệu; chuột phải để chạy DESCRIBE.
- [x] P0 — Tạo database từ hộp thoại và tạo SQL CREATE TABLE qua trình thiết kế bảng.
- [x] P0 — Menu chuột phải: Set Default Schema, Select Rows, Table Inspector, Copy Name, Refresh.
- [x] P1 — Mở cây cột và ràng buộc của từng bảng, hiển thị PK/UNIQUE/NOT NULL.
- [x] P1 — Trình tạo bảng trực quan gồm tên cột, kiểu dữ liệu, độ dài và ràng buộc engine đang hỗ trợ.
- [x] P1 — DROP TABLE với xác nhận tên bảng; tạo và xóa bảng theo khả năng engine (ALTER TABLE ở P2).
- [x] P2 — Metadata index từ SHOW INDEX, trình tạo/xóa index (kể cả UNIQUE) và ALTER TABLE có xem trước SQL.
- [x] P2 — Foreign keys: metadata, xem tham chiếu và tạo/xóa ràng buộc với preview SQL.
- [x] P2 — Views: nhóm Navigator, Object Info, tạo/xóa qua bản nháp SQL, SELECT/DESCRIBE, autocomplete và Context Help.
- [ ] P2 — Stored Procedures và Functions khi engine có metadata và SQL tương ứng.
- [x] P2 — Hộp thoại Administration: trạng thái đọc catalog, số database/kết nối Studio/Action Output, sao lưu và phục hồi catalog mới.
- [ ] P2 — Administration mở rộng: server status, users/privileges, sessions, logs phía máy chủ.

### Information

- [x] P0 — Tóm tắt số database và số bảng ở đáy sidebar.
- [x] P0 — Panel Object Info cập nhật theo đối tượng được chọn: tên, loại, danh sách cột, kiểu và ràng buộc.
- [x] P1 — Tab Session: catalog, database hiện tại, trạng thái kết nối, phiên bản engine.
- [x] P2 — Object Info/Table Inspector hiển thị cột index, entries, cardinality, height, UNIQUE.
- [x] P2 — Kích thước lưu trữ, thống kê phân bố và metadata nâng cao khi engine hỗ trợ (byte JSON logic, NULL, distinct, MIN/MAX; chưa có thống kê trang vật lý).

Nghiệm thu: lựa chọn bảng cập nhật Object Info đúng với DESCRIBE; thao tác quản trị cập nhật cây và dữ liệu chính xác.

## 8. SQL Additions — Context Help và Snippets

- [x] P0 — Panel bên phải, hai tab Context Help và Snippets như ảnh.
- [x] P1 — Context Help theo từ khóa/câu lệnh tại con trỏ; ví dụ dựa trên cú pháp VDB thực sự hỗ trợ.
- [x] P1 — Danh sách snippets dựng sẵn: SELECT, INSERT, UPDATE, DELETE, CREATE TABLE, giao dịch batch.
- [x] P1 — My Snippets: thêm, sửa, xóa, tìm kiếm và lưu snippet cá nhân.
- [x] P1 — Chèn snippet vào vị trí con trỏ hoặc tab mới; người dùng chủ động chạy SQL.

Nghiệm thu: chọn từ khóa hiển thị tài liệu tương ứng; snippet lưu được qua lần mở lại và chèn chính xác vào editor.

## 9. Output — Action Output và nhật ký

- [x] P0 — Panel Action Output gồm số thứ tự, thời gian, SQL, kết quả và thời lượng.
- [x] P0 — Hiển thị thành công/thất bại, nội dung lỗi và xóa nhật ký giao diện.
- [x] P0 — Mở rộng/thu gọn Output độc lập; xem chi tiết nội dung SQL/lỗi dài.
- [x] P1 — Lọc theo trạng thái, kết nối hoặc thời gian; copy và xuất nhật ký.
- [x] P1 — Tab History lưu lịch sử truy vấn theo kết nối; chạy lại câu SQL đã chọn.
- [x] P2 — Phân tách thời gian thực thi và lấy dữ liệu, thông báo server khi engine cung cấp số liệu tương ứng.

Nghiệm thu: truy vấn thành công, lỗi cú pháp và lỗi ràng buộc có bản ghi riêng; thời lượng đúng với phạm vi đo được.

## Bổ sung — Result Grid

- [x] P0 — Hiển thị cột, hàng, NULL, số dòng và nhiều kết quả từ một batch.
- [x] P0 — Lọc kết quả, xuất CSV, xem số hàng bị ảnh hưởng và lỗi truy vấn.
- [x] P1 — Copy ô/hàng, sắp xếp tại grid, thay đổi chiều rộng cột, hiển thị giá trị đầy đủ.
- [x] P1 — Chỉnh sửa/thêm/xóa hàng có khóa chính xác định được; xem trước SQL, Apply/Revert, xử lý lỗi ràng buộc.
- [x] P1 — Import CSV có xem trước, ánh xạ kiểu/cột, kiểm tra dữ liệu và xử lý lỗi.
- [x] P2 — Phân trang/lấy dữ liệu từng phần và bảng lớn khi engine có cơ chế truy vấn phù hợp (LIMIT/OFFSET, 100 hàng/trang; catalog và ORDER BY vẫn nạp bộ nhớ).

Nghiệm thu: kết quả đúng với CLI, CSV giữ Unicode và chỉnh sửa dữ liệu chỉ được áp dụng khi người dùng xác nhận.

## Nền tảng desktop và nghiệm thu cuối

- [x] P0 — Cửa sổ Cocoa/WKWebView ARM64, đóng gói `.app`, launcher desktop mặc định trên macOS Apple Silicon.
- [x] P0 — Server V++ và engine V++ được tích hợp; đường dẫn mã phiên, kiểm tra Host và token hiện có.
- [x] P0 — Cầu nối hộp thoại mở/lưu SQL và CSV, cơ chế dọn server khi đóng cửa sổ đã có mã.
- [x] P0 — Build V++/ASM, kiểm tra cú pháp shell, JavaScript, Info.plist và integration test CLI đã PASS trong lần triển khai trước.
- [x] P0 — Nghiệm thu cửa sổ desktop thật: mở từ `./vdb studio`, render HTML, thao tác SQL, hộp thoại tệp, đóng cửa sổ/Cmd+Q và xác nhận server dừng. Người dùng xác nhận nghiệm thu giai đoạn 0 ngày 18/11/2026.
- [ ] P0 — Kiểm thử lỗi cổng bận, catalog không hợp lệ, server ngừng chạy và khởi động lại.
- [ ] P0 — Kiểm thử quyền truy cập API, cô lập catalog, rollback batch khi có lỗi và không mất dữ liệu khi đóng kết nối.
- [x] P1 — Bundle `.app` tự chứa engine/server/CLI, icon VDB, cấu hình và thư mục dữ liệu riêng macOS.
- [ ] P1 — Nghiệm thu khởi động trực tiếp từ Finder/Dock và định danh ứng dụng.
- [ ] P1 — Kiểm thử từng chức năng qua giao diện với catalog thử nghiệm, kiểm tra phím tắt và hồi quy CLI.
- [ ] P2 — Đóng gói Windows/Linux desktop khi có lớp cửa sổ tương ứng.

**Nghiệm thu giai đoạn 0 — 18/11/2026:** Người dùng xác nhận hoàn thành và cung cấp ảnh cửa sổ VDB Studio độc lập trên macOS. Ảnh thể hiện Local connection, hai database DEFAULT và KHO, SQL Editor, Result Grid và Action Output. Trạng thái nghiệm thu được ghi nhận theo xác nhận của người dùng. Ảnh xác minh cửa sổ và bố cục đã hiển thị; kết quả thực thi SQL, hộp thoại tệp và việc server dừng khi đóng cửa sổ chưa được xác minh độc lập qua ảnh hoặc kiểm thử GUI tự động.

Lưu ý kiểm thử: lần chạy desktop end-to-end trước đây trong sandbox thất bại với `socket: OS transport failed` và bind loopback trả về `Operation not permitted`; yêu cầu kiểm thử ngoài sandbox bị hệ thống xét duyệt tự động từ chối do hết hạn mức. Các kiểm thử lỗi, bảo mật và hồi quy GUI còn lại tiếp tục được theo dõi riêng trong checklist.

**Tiến độ checklist chính hiện tại: 80/92 (87.0%).**

## Thứ tự triển khai

| Giai đoạn | Phạm vi | Điều kiện hoàn thành | Trạng thái |
| --- | --- | --- | --- |
| 0 | Nghiệm thu desktop hiện tại | Cửa sổ mở, chạy SQL thật, mở/lưu tệp và đóng sạch tiến trình | Đã nghiệm thu 18/11/2026 |
| 1 | Home (1), Connection Tabs (2) | Quản lý nhiều catalog cục bộ với trạng thái tách biệt | Đã nghiệm thu 18/11/2026 |
| 2 | Menu (4), Toolbar (5), Layout (6) | Điều hướng desktop hoàn chỉnh, panel có thể điều chỉnh | Đã triển khai, chờ nghiệm thu GUI |
| 3 | Navigator và Object Info (7) | Quản lý bảng và metadata thực tế | Đã triển khai, chờ nghiệm thu GUI |
| 4 | Query Editor (3), Output (9), Result Grid | Quy trình soạn, chạy, xem, sửa và xuất dữ liệu | Đã triển khai, chờ nghiệm thu GUI |
| 5 | SQL Additions (8) | Context Help và snippets hoạt động, lưu cấu hình | Đã triển khai, chờ nghiệm thu GUI |
| 6 | Mở rộng engine (P2) | Thêm tính năng SQL, metadata và server trước khi kích hoạt UI phụ thuộc | Đang triển khai |

### Giai đoạn 1 — Kết quả triển khai ngày 18/11/2026

- 10/10 mục Home và Connection Tabs dành cho catalog cục bộ đã có mã. Tổng checklist: 31/82 mục đã đánh dấu theo quy ước trên. Kết nối từ xa vẫn thuộc P2.
- `make all build/vdb-studio studio-macos`, `make test`, `node --check`, `sh -n`, kiểm tra native `--check` và `plutil -lint`: PASS. CLI kiểm tra mở catalog thiếu, tạo catalog đã tồn tại, dữ liệu catalog độc lập, liên kết cứng/tượng trưng và rollback.
- `make test-studio-state`: PASS với API/render mô phỏng. Kiểm tra chuyển kết nối khi truy vấn đang chờ, kết quả/nhật ký độc lập, khôi phục bản nháp và thứ tự ghi cấu hình.
- `make test-studio`: đã bổ sung bộ kiểm thử HTTP thật. Chưa chạy được do sandbox từ chối bind loopback (`PermissionError: [Errno 1] Operation not permitted`). Lần yêu cầu khởi động server thử nghiệm bị hệ thống xét duyệt tự động từ chối do hết hạn mức, nên chưa kiểm chứng API, khóa cấu hình và vòng đời server ở lần này.
- SHA-256 của `data/vdb.json` trước và sau kiểm thử CLI trùng nhau. Các bài kiểm thử dùng dữ liệu tạm.

Các bước nghiệm thu giai đoạn 1: mở hai catalog thử nghiệm bằng Home, chạy truy vấn trên từng kết nối, chuyển qua lại, kiểm tra xác nhận đóng bản nháp, lưu/mở lại Studio và xác nhận dữ liệu đúng. Kiểm tra hộp thoại chọn catalog, lưu SQL, Cmd+Q và phục hồi phiên trên cửa sổ desktop thật. Người dùng xác nhận hoàn thành giai đoạn 1 ngày 18/11/2026 và yêu cầu tiếp tục giai đoạn 2.

#### Sửa lỗi khởi động giai đoạn 1 — 18/11/2026

- Lỗi `error=22 opcode=229` tại thao tác khóa tệp AOT. Launcher `studio/serve` giữ khóa hệ điều hành qua descriptor 9 (`lockf` trên macOS/FreeBSD, `flock` trên Linux) và chạy server bằng `exec`. Không xóa tệp khóa khi thoát. Kiểm thử tranh chấp khóa, giữ khóa qua `exec` và giải phóng khi tiến trình kết thúc: PASS trên macOS.
- Sửa lỗi `error=16 opcode=224` phát hiện khi kiểm thử khởi động sau sửa khóa. So sánh đường dẫn chuẩn của cấu hình khi tồn tại; CLI tiếp tục từ chối catalog có liên kết cứng.
- Build server, CLI và state tests: PASS. Khởi động với catalog tạm và cả hai trường hợp có/không có cấu hình đã vượt qua opcode 229 và 224, đến bước mở socket (`opcode=191`). `make test-studio` vẫn bị sandbox từ chối bind loopback; yêu cầu cấp quyền bị hệ thống xét duyệt tự động từ chối do hết hạn mức. Sau lần sửa lỗi, người dùng xác nhận hoàn thành giai đoạn 1. Kiểm thử HTTP tự động vẫn chưa thực hiện được.

### Giai đoạn 2 — Kết quả triển khai ngày 18/11/2026

- Tổng checklist hiện tại: **44/82 mục (53.7%)** đã có mã triển khai hoặc được nghiệm thu theo quy ước.
- Menu Cocoa File, Edit, View, Query, Database, Tools và Help được nối với cùng bộ điều phối hành động của giao diện; trạng thái enabled/disabled và dấu chọn panel được đồng bộ. Redo dùng Cmd+Shift+Z. Server/Scripting dành cho giai đoạn 6.
- Toolbar nhóm thao tác kết nối, SQL, schema, CSV và bố cục. Import CSV bị vô hiệu hóa có ghi chú giai đoạn 4. Tạo bảng mở mẫu CREATE TABLE; xem cấu trúc chạy DESCRIBE thật.
- Bốn panel có thể bật/tắt độc lập, năm splitter điều chỉnh kích thước; tự giới hạn theo kích thước cửa sổ, lưu cấu hình và khôi phục mặc định. SQL Additions chỉ có khung; nội dung Context Help và Snippets thuộc giai đoạn 5.
- Chạy toàn bộ, vùng chọn và câu SQL tại con trỏ; Find/Replace cơ bản. Save ghi vào URL đã chọn trong phiên desktop, Save As chọn URL mới. Khôi phục phiên giữ bản nháp và tên tệp; cần chọn lại đường dẫn khi Save lần đầu sau khởi động. Các mục tổng hợp còn chứa chức năng chưa triển khai (import, format SQL, autocomplete, chi tiết Output) giữ nguyên chưa đánh dấu.
- Kiểm thử CLI, logic trạng thái Node.js, build Cocoa/ASM, kiểm tra cú pháp JS/shell/Info.plist và native --check: PASS. Kiểm thử Node.js bao gồm ba chế độ chạy SQL, phân tách câu SQL, trạng thái menu, ẩn/hiện layout, Save/Save As hủy hoặc thành công, callback về đúng tab/kết nối và xác nhận đóng tab chưa lưu.
- SHA-256 của `data/vdb.json` trước và sau kiểm thử trùng nhau: `469dc066185fa4febc8a8e55eaa9b05f2745bb15b69f316b59f2b73d00971c7f`.
- Kiểm thử HTTP thật vẫn bị từ chối bind loopback trong sandbox (`PermissionError: [Errno 1] Operation not permitted`). Chưa kiểm chứng GUI giai đoạn 2 trên cửa sổ thật. Find/Replace, Undo/Redo, menu Cocoa, kích thước panel khi resize và hộp thoại tệp cần nghiệm thu tương tác.

Nghiệm thu giai đoạn 2 bằng catalog thử nghiệm:

1. Mở `./vdb studio --db data/demo.json`, kiểm tra menu File/Edit/View/Query/Database/Tools/Help, phím tắt và trạng thái vô hiệu hóa.
2. Bật/tắt từng panel, kéo cả năm splitter, thu nhỏ/phóng to cửa sổ và reset layout. Đóng/mở lại để kiểm tra lưu bố cục.
3. Chạy cả batch, vùng chọn và câu SQL tại con trỏ bằng truy vấn đọc; kiểm tra kết quả và Action Output. Thử Find/Replace và Undo/Redo.
4. Mở SQL UTF-8, sửa, Save, Save As, hủy hộp thoại; mở lại nội dung để đối chiếu. Chuyển kết nối và kiểm tra bản nháp không bị lẫn.
5. Người dùng yêu cầu tiếp tục sang giai đoạn 3. Điều này xác nhận chuyển giai đoạn; kiểm thử GUI độc lập vẫn chưa thực hiện.

### Giai đoạn 3 — Kết quả triển khai ngày 18/11/2026

- Tổng checklist: **50/82 mục (61.0%)**. Mục 7 hoàn thành sáu hạng mục bổ sung; chờ người dùng nghiệm thu trực tiếp.
- Navigator mở rộng database, table và column, tìm kiếm theo cả ba cấp, hiển thị PK/UNIQUE/NOT NULL từ DESCRIBE thật. Chọn bảng/cột cập nhật Object Info; nhấp đúp hoặc Enter chạy SELECT tối đa 100 hàng trong đúng database. Default Schema của tab độc lập với lựa chọn đối tượng bảng/cột.
- Menu chuột phải theo loại đối tượng, Table Inspector, Copy Name, Select Rows, DESCRIBE, Refresh, Create Table và DROP TABLE. Copy Name có hộp thoại cho phép sao chép thủ công nếu trình duyệt không cho sao chép tự động.
- Trình thiết kế bảng hỗ trợ INT, INTEGER, REAL, TEXT, VARCHAR(n), BOOLEAN và một PRIMARY KEY, NOT NULL, UNIQUE. Có xem trước SQL, mở bản nháp trong editor hoặc thực thi. DROP TABLE yêu cầu nhập đúng tên bảng và giữ đích catalog/database đã chọn. Tạo/xóa bảng bằng giao diện bị vô hiệu hóa khi metadata có thể đã cũ; refresh thành công mới bật lại.
- Object Info hiển thị database, table, column, kiểu và ràng buộc. Session hiển thị tên kết nối, đường dẫn catalog, database của tab, trạng thái, nhãn phiên bản VDB 0.1.0 của bản dựng hiện tại.
- Metadata nạp theo từng kết nối bằng SHOW DATABASES, SHOW TABLES và các batch DESCRIBE (tối đa 64 bảng và khoảng 16 KiB SQL mỗi batch thông thường). Metadata chưa có cơ chế phân trang/lazy loading và chỉ phản ánh lần refresh gần nhất; nếu refresh lỗi, dữ liệu cũ được giữ với cảnh báo. Nếu một công cụ khác thay đổi catalog trong lúc mở Studio, cần refresh để đồng bộ. Engine chưa có định danh bảng bất biến hoặc giao dịch nhiều lần gọi để bảo đảm đối tượng không bị thay thế giữa xem và xác nhận xóa.
- Kiểm thử CLI, Node.js state tests, build engine/server/Cocoa, cú pháp JS và shell, Info.plist và native --check: PASS. Bổ sung kiểm thử DESCRIBE và mọi kiểu/ràng buộc hỗ trợ, batch metadata, cô lập catalog/database, xóa metadata không còn tồn tại, lỗi refresh, tạo SQL, bản nháp/thực thi, định tuyến SELECT/DESCRIBE và xác nhận DROP. CLI kiểm tra các câu CREATE TABLE sai không thay đổi catalog.
- SHA-256 catalog chính `data/vdb.json` trước/sau kiểm thử không đổi: `469dc066185fa4febc8a8e55eaa9b05f2745bb15b69f316b59f2b73d00971c7f`.
- HTTP test `make test-studio` chưa chạy được vì sandbox từ chối bind loopback (`PermissionError: [Errno 1] Operation not permitted`). Một lệnh CLI kiểm tra thủ công bị xét duyệt tự động từ chối do hết hạn mức; bộ kiểm thử CLI có sẵn chạy thành công. Chưa kiểm chứng trực tiếp tương tác WKWebView và hộp thoại.

Nghiệm thu giai đoạn 3 với catalog riêng mới:

1. Chạy `./vdb studio --db "$(mktemp -d)/phase3.json"`. Chọn đúng hồ sơ catalog vừa tạo ở Home.
2. Tạo database KHO, mở trình thiết kế bảng, thử đủ kiểu và ràng buộc. Kiểm tra SQL xem trước, mở bản nháp, sau đó tạo bảng. Thử tên cột trùng, VARCHAR không hợp lệ, hai khóa chính.
3. Mở cây cột, tìm theo database/table/column; chọn từng đối tượng và xem Object Info, Session. Mở Table Inspector, Select Rows, DESCRIBE và Copy Name từ menu chuột phải.
4. Thử DROP TABLE bằng tên sai, hủy hộp thoại, rồi nhập đúng tên bảng thử nghiệm để xóa. Kiểm tra cây schema được cập nhật. Xác nhận kết nối khác giữ dữ liệu và tab riêng.
5. Nghiệm thu giai đoạn 3 trước khi chuyển sang giai đoạn 4 (Query Editor, Action Output và Result Grid).

### Giai đoạn 4 — Kết quả triển khai ngày 18/11/2026

- Tổng checklist: **62/82 mục (75.6%)** đã có mã hoặc được nghiệm thu theo quy ước.
- Query Editor có toolbar riêng, format SQL cơ bản, autocomplete từ khóa/schema/bảng/cột, kiểm tra cú pháp qua engine, giới hạn hàng cho SELECT * đơn giản và Undo/Redo độc lập từng tab (tối đa 100 bước trong phiên). Menu native Undo SQL/Redo SQL luôn tác động vào tab SQL đang chọn. Kiểm tra cú pháp không thực thi câu lệnh, không xác minh tên bảng hay ràng buộc dữ liệu.
- Result Grid có sắp xếp, kéo cột, copy/xem giá trị, thêm/sửa/xóa có xem trước SQL và Apply/Revert. Chỉ bật chỉnh sửa kết quả SELECT * từ một bảng có một khóa chính và metadata hợp lệ. UPDATE/DELETE khớp toàn bộ giá trị gốc, yêu cầu đúng một hàng bị tác động; lỗi sẽ giữ bản xem trước và rollback cả batch. Mọi nguồn chỉnh sửa cũ trong kết nối bị vô hiệu hóa sau ghi hoặc refresh. Engine chưa có định danh bảng bất biến.
- Import CSV có chọn tệp UTF-8/dán dữ liệu, ánh xạ cột và kiểm tra kiểu/ràng buộc; tối đa 500 hàng, 128 KB CSV, 32 KB SQL xem trước. Export giữ Unicode và bảo vệ một số chuỗi giống công thức spreadsheet bằng dấu nháy đơn; lưu ý khi round-trip.
- Action Output/History có lọc trạng thái/ngày, chi tiết, copy, CSV và mở SQL từ History. Action Output tối đa 100 bản ghi trong phiên; History tối đa 50 truy vấn cho mỗi kết nối đang mở, lưu theo workspace; đóng kết nối bỏ History của phiên. Thời lượng là round-trip HTTP phía client.
- Bổ sung kiểm thử CLI validate/guarded writes/rollback, HTTP endpoints và Node.js state tests cho editor, routing Apply, CSV, metadata và nguồn grid. HTTP test chưa thực hiện được do sandbox từ chối bind loopback (`PermissionError: [Errno 1] Operation not permitted`); xét duyệt tự động yêu cầu chạy ngoài sandbox bị từ chối do hết hạn mức. Cần nghiệm thu tương tác thực tế trong WKWebView.

Nghiệm thu giai đoạn 4 với catalog riêng mới:

1. Chạy `./vdb studio --db "$(mktemp -d)/phase4.json"`. Chọn hồ sơ catalog vừa tạo. Tạo bảng `SP` với ID INT PRIMARY KEY, NAME TEXT, ACTIVE BOOLEAN, PRICE REAL và thêm vài hàng thử nghiệm.
2. Thử chạy toàn bộ/vùng chọn/câu tại con trỏ, format, Ctrl+Space, validate SQL đúng và sai, giới hạn hàng, Undo/Redo khi chuyển giữa hai tab.
3. Chạy `SELECT * FROM SP;`, sắp xếp, kéo cột, copy và nhấp đúp ô. Thử thêm/sửa/xóa với preview, Revert, Apply; thử khóa trùng và thay đổi hàng từ bên ngoài trước Apply để kiểm tra rollback.
4. Import CSV UTF-8 chứa dấu phẩy, xuống dòng, NULL và chuỗi rỗng, kiểm tra mapping, preview, lỗi kiểu và ghi nguyên tử. Xuất kết quả và đối chiếu Unicode.
5. Thử Action Output/History, lọc, xem chi tiết, copy, CSV, mở lại câu SQL. Thoát Studio khi đã hoàn tất các thao tác và mở lại cùng hồ sơ để kiểm tra History. Chạy `make test-studio` trong môi trường có quyền bind loopback.
6. Nghiệm thu giai đoạn 4 trước khi triển khai Context Help và Snippets (giai đoạn 5).

### Giai đoạn 5 — Kết quả triển khai ngày 18/11/2026

- Tổng checklist: **67/82 mục (81.7%)** đã có mã hoặc được nghiệm thu theo quy ước.
- Bật panel phải bằng nút SQL+ hoặc menu View. Context Help nhận từ khóa tại con trỏ và câu lệnh hiện tại, bỏ qua từ khóa trong chuỗi và comment. Tài liệu và ví dụ chỉ dùng cú pháp engine VDB đã hỗ trợ.
- Snippets có sáu mẫu dựng sẵn, bộ lọc Built-in/My Snippets, tìm kiếm theo tên hoặc SQL, xem trước và quản lý snippet cá nhân. Mẫu dựng sẵn không thể sửa/xóa; snippet cá nhân lưu chung trong workspace phiên bản 1, tương thích cấu hình cũ. Giới hạn 40 snippet, 100 ký tự tên, 4000 ký tự SQL mỗi mục và tổng 64 KB JSON.
- Chèn vào con trỏ/vùng chọn có Undo/Redo; mở tab mới giữ database đang chọn và đánh dấu SQL chưa lưu. Người dùng tự chạy SQL.
- `make test`, `make test-studio-state`, build server và desktop thành công. Engine xác nhận cú pháp 15 ví dụ SQL khác nhau của Context Help và Snippets trên catalog tạm. HTTP test đã bổ sung fixture snippet Unicode để kiểm tra qua lần mở lại nhưng chưa chạy được do sandbox từ chối bind loopback (`PermissionError: [Errno 1] Operation not permitted`). Chưa nghiệm thu WKWebView.

Nghiệm thu giai đoạn 5:

1. Mở Studio, chọn kết nối rồi bật SQL+. Chọn Context Help, đặt con trỏ vào SELECT, WHERE, JOIN, CREATE TABLE và ORDER BY; kiểm tra nội dung cập nhật khi đổi câu lệnh/tab. Thử từ khóa bên trong chuỗi và comment.
2. Chọn Snippets, thử sáu mẫu dựng sẵn, bộ lọc, tìm kiếm, xem trước; xác nhận mẫu dựng sẵn không sửa/xóa được.
3. Thêm snippet cá nhân có tiếng Việt và nhiều dòng, sửa tên/SQL, tìm lại, chèn tại con trỏ hoặc thay vùng chọn; thử Undo/Redo và mở tab mới. Xác nhận không có truy vấn tự chạy và database giữ nguyên.
4. Thoát và mở Studio lại, chọn My Snippets; kiểm tra nội dung còn nguyên, thử xóa một mẫu cá nhân và mở lại để kiểm tra. Chạy `make test-studio` trong môi trường có quyền bind loopback.

### Phụ thuộc engine cho P2

Engine hiện hỗ trợ catalog cục bộ, CREATE DATABASE/TABLE, DROP TABLE, SHOW/DESCRIBE, CRUD và giao dịch trong một batch. Các bước mở rộng SELECT đã có mã:

- [x] Logic ba trị NULL, NOT/AND/OR, ngoặc, IN, BETWEEN, LIKE cho WHERE.
- [x] INNER/LEFT JOIN, GROUP BY nhiều cột, COUNT/SUM/AVG/MIN/MAX, HAVING theo nhãn, DISTINCT, ORDER BY nhiều cột, LIMIT/OFFSET.
- [x] Merge sort ổn định và bảng băm tạm cho equi-join, GROUP BY, DISTINCT, kiểm tra collision bằng khóa gốc.
- [x] Tách module V++ cho HASH_JOIN, HASH_AGGREGATE, HASH_DISTINCT, MERGE_SORT; planner chọn thuật toán cố định.
- [x] Điều phối các thuật toán trên qua hàm chung trong `src/algorithm/dispatch.vi` theo trường `algorithm`.
- [x] Tập trung hằng chuỗi của engine tại `src/constants.vi`, tạo bản ghi bằng khóa dùng chung trong `src/records.vi` và kiểm tra hồi quy bằng `make test-constants`.
- [x] EXPLAIN SELECT kế hoạch vật lý, dùng chung kiểm tra ngữ nghĩa với SELECT, hiển thị thứ tự toán tử và số hàng bảng nguồn.
- [x] B+ tree một cột INT/INTEGER/TEXT/VARCHAR, CREATE/DROP/SHOW INDEX, lưu catalog và đồng bộ sau ghi/DDL/rollback.
- [x] INDEX_SCAN cho truy vấn một bảng với điều kiện bằng literal cùng kiểu; thống kê entries/cardinality/height và lựa chọn quét bảng hoặc chỉ mục theo chi phí ước lượng; EXPLAIN.
- [x] Range scan B+ tree cho <, <=, >, >=, BETWEEN; chọn theo số khóa ứng viên.
- [x] NESTED_LOOP_JOIN và HASH_JOIN; lựa chọn theo chi phí ước lượng ở JOIN đầu tiên.
- [x] Chỉ mục nhiều cột và index-assisted JOIN (giai đoạn 6.6).
- [x] Ước lượng cardinality trung gian, EXPLAIN cho nhiều JOIN và chọn lại thuật toán theo số hàng thực tế khi chạy.
- [x] INSERT cập nhật B+ tree theo nút logic, tách nút, duy trì rank và thống kê tiền tố.
- [ ] UPDATE/DELETE theo trang, thống kê nâng cao và tối ưu thứ tự JOIN.
- [x] ALTER TABLE ADD/DROP/RENAME COLUMN, RENAME TO; DROP DATABASE (bảo vệ DEFAULT), hỗ trợ rollback.
- [x] Foreign keys đơn/nhiều cột, kiểm tra tham chiếu khi DML/DDL, SHOW FOREIGN KEYS.
- [x] Views chỉ đọc, lưu AST SELECT và metadata, kiểm tra phụ thuộc, hỗ trợ truy vấn lồng và EXPLAIN.
- [x] Backup/restore catalog cục bộ: kiểm tra snapshot, dựng lại index khi phục hồi, công bố nguyên tử vào tệp mới.
- [ ] Routines và quản trị máy chủ.
- [ ] Storage theo trang, WAL, MVCC, phiên giao dịch dài hạn, hủy truy vấn và kết nối từ xa.

Mỗi tính năng UI phụ thuộc phải có kiểm thử engine trước khi nghiệm thu.


### Giai đoạn 6 — SQL engine, phần 6.1–6.3

- EXPLAIN SELECT dùng chung bước binding với SELECT, không chạy các thuật toán xử lý hàng. Trả về TABLE_SCAN, HASH_JOIN, FILTER, HASH_AGGREGATE, PROJECT, HAVING_FILTER, HASH_DISTINCT, MERGE_SORT và LIMIT tùy câu lệnh.
- ALTER TABLE thêm/xóa/đổi tên cột và đổi tên bảng. Cột mới nhận NULL, kiểm tra ràng buộc trước khi thay dữ liệu; bảo vệ cột cuối cùng. DROP DATABASE tự chuyển database đang chọn về DEFAULT và bảo vệ DEFAULT.
- Các câu lệnh mới dùng chung hằng chuỗi và constructor bản ghi; hỗ trợ highlight, completion, Context Help trong SQL Editor. Chưa có trình chỉnh sửa schema trực quan cho ALTER.
- Kiểm thử CLI bao gồm kế hoạch vật lý, không thực thi toán tử khi EXPLAIN, validation, bảo toàn dữ liệu, rollback DDL và xóa database. State test bao gồm Context Help cho lệnh mới. Các mục P2 tổng hợp vẫn đang mở; tổng checklist chính giữ 67/82.
- Tiếp theo: chỉ mục B+ tree, index scan, thống kê và optimizer; views, foreign keys, routines; storage/WAL/MVCC.

### Giai đoạn 6 — SQL engine, phần 6.4 (chỉ mục bằng nhau)

- B+ tree viết bằng V++, bulk load từ dữ liệu đã sắp xếp ổn định; nút tối đa 16 khóa/con, lá liên kết và hỗ trợ khóa trùng xuyên nhiều lá. Chỉ mục lưu trong catalog JSON; NULL không được đưa vào cây.
- SQL CREATE INDEX, DROP INDEX, SHOW INDEX/INDEXES; EXPLAIN báo INDEX_SCAN và số hàng ước lượng khi chi phí thấp hơn TABLE_SCAN. SELECT kiểm tra lại WHERE sau khi tìm ứng viên.
- Tự xây lại chỉ mục khi INSERT/UPDATE/DELETE/ALTER; đổi tên cột cập nhật metadata, yêu cầu DROP INDEX trước khi xóa cột đang có chỉ mục; rollback khôi phục catalog.
- SQL Editor hỗ trợ highlight, completion và Context Help cho lệnh chỉ mục. Navigator metadata và trình quản lý index trực quan vẫn thuộc P2.
- Kiểm thử CLI: 320 hàng, cây 3 tầng, khóa trùng qua lá, NULL, tìm kiếm khóa không tồn tại, chuỗi, chọn kế hoạch, lưu/reload, thay đổi dữ liệu, DDL và rollback. make test và make test-studio-state đạt. Checklist chính vẫn 67/82 vì các mục P2 tổng hợp còn mở.
- Tiếp theo: range scan, thuật toán join thay thế và thống kê nâng cao; views, foreign keys, routines; storage/WAL/MVCC.

### Giai đoạn 6 — SQL engine, phần 6.5 (range scan và lựa chọn JOIN)

- B+ tree tìm lower/upper bound theo rank, xử lý khóa trùng qua nhiều lá, khoảng đảo/ngoài miền và cây rỗng. INDEX_RANGE_SCAN đọc khoảng ứng viên và sắp xếp theo vị trí vật lý trước khi kiểm tra WHERE; bảo toàn thứ tự của TABLE_SCAN.
- Planner dùng số ứng viên theo biên khóa thay cho ước lượng phân bố đều. Chi phí TABLE_SCAN = n, INDEX_SCAN = h + k, INDEX_RANGE_SCAN = 2h + 2k. Chỉ dùng index khi chi phí thấp hơn quét bảng; điều kiện phức hợp, literal NULL/khác kiểu và truy vấn có JOIN vẫn quét bảng.
- NESTED_LOOP_JOIN triển khai INNER/LEFT equijoin bằng V++, điều phối qua dispatch.vi. JOIN đầu tiên chọn nested loop nếu L × R <= L + R + 17, các JOIN sau dùng hash do chưa ước lượng số hàng trung gian. Mô hình chi phí chưa hiệu chỉnh bằng benchmark.
- EXPLAIN SELECT báo thuật toán scan/JOIN được chọn và số ứng viên index, không chạy toán tử truy vấn. Context Help đã cập nhật.
- Kiểm thử ngày 18/11/2026: make test PASS (260 hàm hằng, toàn bộ SQL integration); kiểm tra parity với full scan trên cây 320 hàng, biên lá, khóa trùng, Unicode, NULL, khoảng rỗng, thay đổi/rollback và thứ tự vật lý. Cả HASH_JOIN và NESTED_LOOP_JOIN có kiểm thử kế hoạch và kết quả, gồm khóa trùng, NULL, bảng phải rỗng và INT/REAL.
- make test-studio-state PASS; các target build/vdb-studio và studio-macos đã cập nhật. make test-studio bị chặn tại probe.bind(('127.0.0.1', 0)) với PermissionError: [Errno 1] Operation not permitted; chưa nghiệm thu tương tác WKWebView.
- Catalog chính trước/sau kiểm thử giữ SHA-256 d97df2bca7c55410a3a9a3ade19a60b05628a1d5808f24d899d0376fd0fba40e.
- Checklist chính vẫn **67/82 (81.7%)**; các mục P2 tổng hợp còn mở. Tiếp theo 6.6: điều kiện phức hợp, chỉ mục nhiều cột, index nested-loop JOIN và cải thiện ước lượng cardinality/chi phí.

### Giai đoạn 6 — SQL engine, phần 6.6 (composite index và index JOIN)

- [x] B+ tree nhiều cột, thứ tự khóa theo tiền tố, giữ thành phần NULL, thống kê cardinality cho từng tiền tố và tương thích catalog chỉ mục một cột cũ.
- [x] CREATE INDEX nhiều cột, kiểm tra trùng cột, cập nhật chỉ mục khi DML/ALTER, bảo vệ mọi cột thuộc chỉ mục khi DROP COLUMN.
- [x] Giao biên khóa cho các điều kiện AND, tiền tố bằng liên tiếp và khoảng ở cột kế tiếp; WHERE luôn được kiểm tra lại. OR/NOT không tạo biên trực tiếp.
- [x] INDEX_NESTED_LOOP_JOIN cho INNER/LEFT equijoin ở JOIN đầu tiên; planner so sánh chi phí hash, nested loop và index dựa trên chiều cao cây và cardinality tiền tố. EXPLAIN hiển thị INDEX_LOOKUP.
- [x] Kiểm thử 18/11/2026: build lại engine, make test PASS (264 hàm hằng), parity với quét bảng trên 321 hàng, khóa NULL, Unicode, khoảng mâu thuẫn, tiền tố, OR/NOT, JOIN, DML/ALTER/rollback, catalog cũ. make test-studio-state PASS; Studio server và macOS app đã có bản build.
- [ ] Cập nhật cây theo từng trang, thống kê phân bố nâng cao, ước lượng cardinality trung gian và tối ưu thứ tự JOIN.

Checklist chính vẫn **67/82 (81.7%)** vì mục P2 tổng hợp còn mở. Mô hình chi phí vẫn là heuristic; HTTP Studio và nghiệm thu WKWebView còn chờ kiểm thử.


### Giai đoạn 6 — Phần 6.7 (unique index, ALTER, EXPLAIN, foreign keys)

- Checklist chính hiện tại: **72/87 (82.8%)**.
- CREATE UNIQUE INDEX, metadata UNIQUE, trình quản lý index/ALTER với preview, EXPLAIN trong editor và bundle độc lập đã triển khai.
- Foreign keys cùng database, khóa đơn/nhiều cột, MATCH SIMPLE và RESTRICT tức thời; kiểm tra DML/DDL, rollback, catalog cũ. Navigator, Inspector, preview CREATE/DROP FK, Context Help và autocomplete dùng metadata thực.
- `make test`, `make test-studio-state`, `make test-constants` (281 hàm), `make studio-macos`, launcher `--check`, `plutil -lint`, kiểm tra cú pháp Python/shell: PASS. Catalog chính giữ nguyên SHA-256 d97df2bca7c55410a3a9a3ade19a60b05628a1d5808f24d899d0376fd0fba40e. HTTP và WKWebView chưa được nghiệm thu do giới hạn bind loopback đã ghi nhận.


### Giai đoạn 6 — Phần 6.8 (views)

- Checklist chính hiện tại: **74/89 (83.1%)**.
- CREATE VIEW, DROP VIEW, SHOW VIEWS, DESCRIBE, SELECT trên view và JOIN với bảng/view. Lưu định nghĩa SELECT trong catalog, tính lại kết quả theo dữ liệu nguồn; bảo vệ schema phụ thuộc, dùng chung namespace với bảng và rollback DDL. View chỉ đọc, tối đa 64 tầng khi thực thi.
- Navigator hiển thị Views theo database, thông tin cột, tìm kiếm, context menu, bản nháp CREATE/DROP, autocomplete và Context Help; grid không cho chỉnh sửa view.
- `make test` (292 hàm hằng, SQL integration) và `make test-studio-state` PASS. Kiểm thử CLI gồm bảng rỗng, aggregate, JOIN, view lồng, cập nhật nguồn, metadata, lỗi phụ thuộc và rollback; HTTP test đã bổ sung nhưng chưa nghiệm thu do giới hạn bind loopback.

### Giai đoạn 6 — Phần 6.9 (đo thời gian)

- Checklist chính: **75/89 (84.3%)**. CLI `--timing` và API query/guarded-query trả số đo đồng hồ đơn điệu. Action Output, History và CSV giữ thời gian thực thi (gồm USE và ghi snapshot tạm, sau parse/load), xuất JSON/stdout, đọc và phân tích HTTP body và tổng round-trip. Không suy diễn thời gian mạng từ hiệu các số đo.
- Build engine/server, `make test`, `make test-studio-state` PASS; kiểm thử CLI xác nhận JSON-lines mặc định không đổi và số đo hữu hạn không âm. HTTP thực tế còn chờ quyền bind loopback.

### Giai đoạn 6 — Phần 6.10 (phân trang)

- Navigator duyệt 100 hàng/trang qua LIMIT/OFFSET; ORDER BY khóa chính đơn khi có. Bộ lọc, sắp xếp grid và CSV chỉ áp dụng trang hiện tại. Nguồn chỉnh sửa có khóa chính được xác nhận lại theo SQL, database và metadata; đổi schema/SQL làm mất hiệu lực nguồn. Các trang độc lập, thay đổi đồng thời có thể dịch chuyển OFFSET.
- Engine chỉ tạo hàng projection trong khoảng LIMIT/OFFSET cho truy vấn không GROUP BY/DISTINCT/ORDER BY; vẫn kiểm tra các hàng WHERE còn lại để bảo toàn lỗi runtime. Catalog, JOIN, view, index candidates và ORDER BY vẫn có thể materialize toàn bộ.

### Giai đoạn 6 — Phần 6.11 (thống kê bảng)

- SHOW STATISTICS FROM bảng vật lý trả COLUMN, ROWS, JSON_BYTES, NULL_COUNT, NON_NULL_COUNT, DISTINCT_COUNT, MIN, MAX. Thống kê chính xác tại thời điểm đọc, distinct bỏ NULL, JSON_BYTES đo UTF-8 bản ghi bảng gồm hàng/schema/index. Bộ nhớ tăng theo số giá trị khác nhau và kích thước JSON; chưa có storage theo trang hoặc histogram cho optimizer. Inspector tải trực tiếp từ engine.
- Build engine, make test (302 hằng), make test-studio-state, make studio-macos, launcher --check, plutil -lint và kiểm tra cú pháp shell/Python PASS. Catalog chính giữ nguyên SHA-256 d97df2bca7c55410a3a9a3ade19a60b05628a1d5808f24d899d0376fd0fba40e. HTTP/WKWebView chưa nghiệm thu do giới hạn bind loopback đã ghi nhận.
- Checklist chính: **77/89 (86.5%)**.


### Giai đoạn 6 — Phần 6.12 (backup/restore và mô hình quan hệ)

- CLI `--backup` và `--restore`: lưu toàn bộ catalog, kiểm tra tính hợp lệ của snapshot, dựng lại index khi phục hồi, từ chối ghi đè; công bố tệp mới bằng liên kết cứng nguyên tử. Administration gọi API `/api/backup` và `/api/restore`, dùng đường dẫn tuyệt đối và mở catalog phục hồi từ Home. Kiểm thử CLI kiểm tra toàn vẹn, Unicode, view, khóa ngoại, index, tệp lỗi và đích đã tồn tại.
- Mô hình quan hệ dùng metadata Navigator theo từng database và catalog; hiển thị cột, kiểu, ràng buộc, đường liên kết và ánh xạ khóa ngoại nhiều cột, gồm tự tham chiếu. State tests kiểm tra cách ly metadata, view bị loại khỏi sơ đồ, database rỗng và escape HTML/SVG. Sơ đồ hiện là chỉ đọc; chỉnh sửa sơ đồ chưa triển khai.
- API HTTP thực tế và nghiệm thu hộp thoại WKWebView/Finder vẫn mở do giới hạn bind loopback đã ghi nhận. Administration chưa có tài khoản, phân quyền, phiên và nhật ký máy chủ từ xa.

### Giai đoạn 6 — Phần 6.13 (kế hoạch nhiều JOIN)

- Planner truyền ước lượng số hàng đầu ra giữa các JOIN từ số hàng bảng phải, UNIQUE và thống kê index dẫn đầu; LEFT JOIN bảo đảm ước lượng không thấp hơn đầu vào trái. View chưa biết cardinality trong EXPLAIN trả NULL. Thứ tự JOIN theo SQL được giữ nguyên; các JOIN sau chọn lại HASH_JOIN, NESTED_LOOP_JOIN hoặc INDEX_NESTED_LOOP_JOIN khi đã có số hàng trung gian thật.
- EXPLAIN hiển thị số hàng ước lượng cho JOIN, số khóa trung bình cho INDEX_LOOKUP và kế hoạch dựa trên metadata. Ước lượng có giới hạn 10^12 và chưa có histogram, tỷ lệ khớp hoặc phân tích phân bố lệch. Chưa tối ưu thứ tự JOIN.
- Build engine, make test (307 hàm hằng), make test-studio-state và make studio-macos PASS. Kiểm thử mới gồm JOIN thứ hai chọn nested loop/index, LEFT JOIN giữ NULL, kết quả thực tế khác ước lượng, view chưa biết cardinality và EXPLAIN không đổi catalog.
- Checklist chính: **80/92 (87.0%)**. Tách ba chức năng đã triển khai từ hai mục tổng hợp trước đây; các phần routine/quản trị máy chủ còn mở.


### Giai đoạn 6 — Phần 6.14 (INSERT B+ tree theo nút logic)

- [x] INSERT vào cây rỗng hoặc cây có dữ liệu cập nhật đường dẫn từ gốc đến lá, giữ tối đa 16 khóa/con mỗi nút, tách nút lá/nút trong và tạo gốc mới khi cần. Khóa trùng được chèn theo thứ tự vị trí hàng; liên kết lá và khóa cực đại của nhánh được duy trì.
- [x] Số khóa cây con cho phép tìm rank trên các lá kích thước khác nhau; range scan giữ thứ tự vật lý. Thống kê cardinality từng tiền tố và ràng buộc UNIQUE được cập nhật khi INSERT; catalog cũ được đọc bằng rank dạng bulk load và tự chuyển đổi khi INSERT.
- [x] Kiểm thử 18/11/2026: `make all`, `make test` (307 hàm hằng), kiểm thử riêng 400 hàng với hai index đơn/nhiều cột, nút trong và lá, NULL, Unicode, khóa trùng, kiểm tra bất biến JSON, so sánh full scan, UNIQUE và rollback. `make test-studio-state`, `make studio-macos`, launcher `--check`, `plutil -lint`: PASS. Catalog chính giữ nguyên SHA-256 d97df2bca7c55410a3a9a3ade19a60b05628a1d5808f24d899d0376fd0fba40e.
- [ ] UPDATE/DELETE vẫn bulk rebuild, do vị trí vật lý của hàng có thể đổi; ALTER và restore cũng dựng lại cây. Lưu trữ vẫn là catalog JSON ghi toàn bộ; trang vật lý, buffer pool, WAL/MVCC, thống kê phân bố nâng cao và tối ưu thứ tự JOIN còn mở.

Checklist chính giữ **80/92 (87.0%)**; mục engine bổ sung không thuộc bộ đếm UI. HTTP Studio/WKWebView chưa được nghiệm thu do giới hạn bind loopback đã ghi nhận.


## Distribution — CI/CD, cài đặt và nâng cấp

Các mục distribution độc lập với bộ đếm chức năng UI 80/92 (87.0%).

- [x] Tập trung VERSION và ghim revision V++ native dùng để build.
- [x] Đóng gói engine, CLI, Studio và SHA-256 theo nền tảng, loại trừ catalog và cấu hình cá nhân.
- [x] Installer CLI theo tài khoản, kiểm tra SQL trước khi công bố phiên bản, hỗ trợ sửa shortcut cùng phiên bản.
- [x] VDB Setup và VDB Update app macOS Cocoa native: xác nhận, trạng thái xử lý, kết quả và kiểm tra bundle.
- [x] Luồng cập nhật stable release, xác minh checksum, bảo toàn catalog, từ chối downgrade và giữ bản cũ; đã chạy kiểm thử mô phỏng trên macOS ARM64.
- [x] Workflow CI/CD hai nền tảng, gate kiểm thử và publish bằng tag khớp VERSION.
- [ ] Nghiệm thu workflow CI/CD và release thực tế trên GitHub.
- [ ] Kiểm thử Linux x86-64 đầy đủ trên runner thật.
- [ ] Nghiệm thu GUI Setup/Update và mở từ Finder với gói tải về.
- [ ] Developer ID signing và notarization macOS.
- [ ] Windows native và các kiến trúc khác.
