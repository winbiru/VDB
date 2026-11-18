# VDB — Vietnam Database

[![CI / Release](https://github.com/winbiru/VDB/actions/workflows/ci.yml/badge.svg)](https://github.com/winbiru/VDB/actions/workflows/ci.yml)
[![GitHub Release](https://img.shields.io/github/v/release/winbiru/VDB)](https://github.com/winbiru/VDB/releases)

VDB là hệ quản trị cơ sở dữ liệu quan hệ thử nghiệm, xây dựng bằng **V++**. VDB triển khai bộ phân tích SQL, catalog, bộ thực thi truy vấn và kiểm tra ràng buộc bằng mã nguồn `.vi`. Dữ liệu được lưu trong tệp JSON có phiên bản định dạng, không phụ thuộc SQLite, MySQL hay PostgreSQL.

## Cài đặt VDB

VDB sử dụng bộ biên dịch native của [V++ (VXX)](https://github.com/winbiru/VXX). Gói phát hành chứa sẵn engine và Studio đã biên dịch. Người dùng gói binary không cần cài V++ hoặc Make; khi tự build mã nguồn, cần cài V++ theo hướng dẫn bên dưới.

### Gói phát hành

Tải gói và tệp checksum tương ứng từ [GitHub Releases](https://github.com/winbiru/VDB/releases) khi bản phát hành đã xuất hiện.

| Nền tảng | Tệp phát hành | Studio | Trạng thái |
| --- | --- | --- | --- |
| macOS Apple Silicon (ARM64) | `vdb-macos-arm64.tar.gz` | Native desktop, Setup và Update | Đã kiểm thử gói cục bộ; chờ nghiệm thu GUI |
| Linux x86-64 | `vdb-linux-x64.tar.gz` | Trình duyệt | Chờ kiểm thử trên CI Linux |
| Windows / macOS Intel / Linux ARM64 | — | — | Chưa phát hành |

**macOS Apple Silicon:** tải `vdb-macos-arm64.tar.gz` và `vdb-macos-arm64.tar.gz.sha256` vào cùng thư mục, kiểm tra checksum rồi giải nén.

```sh
shasum -a 256 -c vdb-macos-arm64.tar.gz.sha256
tar -xzf vdb-macos-arm64.tar.gz
cd vdb-macos-arm64
open "VDB Setup.app"
# Hoặc cài qua Terminal:
# ./install.sh
```

Màn hình VDB Setup cho phép xác nhận hoặc hủy, hiển thị trạng thái đang kiểm tra/cài đặt và kết quả. Sau khi cài, mở **VDB Studio.app** trong `~/Applications` hoặc dùng CLI. Ứng dụng Setup và Update hiện được ký ad-hoc; chưa có Developer ID và notarization. Gatekeeper có thể yêu cầu xác nhận khi mở gói tải về từ Internet. Chỉ mở khi đã xác minh nguồn tải và checksum.

**Linux x86-64:** sau khi release có asset Linux đã qua CI, tải gói và checksum tương ứng. Máy cần các tiện ích shell POSIX, coreutils, curl, OpenSSL và flock (util-linux); cần trình duyệt để sử dụng Studio.

```sh
sha256sum -c vdb-linux-x64.tar.gz.sha256
tar -xzf vdb-linux-x64.tar.gz
cd vdb-linux-x64
./install.sh
```

Cả hai nền tảng cài theo tài khoản người dùng, không cần sudo. Sau khi cài:

```sh
export PATH="$HOME/.local/bin:$PATH"
vdb --version
vdb -e "SHOW DATABASES;"
vdb studio
```

Thêm dòng `export PATH="$HOME/.local/bin:$PATH"` vào tệp cấu hình shell (ví dụ `~/.zshrc` hoặc `~/.bashrc`) nếu muốn sử dụng CLI ở các phiên Terminal sau.

### Cập nhật

Đóng VDB Studio trước khi cập nhật; installer kiểm tra khóa cấu hình để tránh nâng cấp trong khi Studio đang chạy. Chạy lệnh dưới đây hoặc mở **VDB Update.app** trong `~/Applications` trên macOS:

```sh
vdb update
```

CLI kiểm tra bản ổn định mới hơn trên GitHub Releases, hỏi trước khi tải/cài, xác minh SHA-256 và chạy kiểm tra engine trước khi chuyển phiên bản. GUI xác nhận việc kiểm tra và tự cài bản mới nếu có, hiển thị trạng thái và kết quả. Có thể dùng `vdb update --yes` khi chạy không tương tác. Phiên bản cũ được giữ trong thư mục chương trình, nhưng hiện chưa có lệnh rollback hoặc uninstall tự động. SHA-256 phát hành cùng gói giúp kiểm tra tính toàn vẹn, chưa phải chữ ký phát hành độc lập.

| Thành phần | Vị trí mặc định |
| --- | --- |
| Chương trình từng phiên bản | `~/.local/share/vdb-program/versions/<version>/` |
| Phiên bản đang dùng | `~/.local/share/vdb-program/current` |
| CLI | `~/.local/bin/vdb` |
| Ứng dụng macOS | `~/Applications/VDB Studio.app`, `~/Applications/VDB Update.app` |
| Catalog và cấu hình macOS | `~/Library/Application Support/VDB Studio/` |
| Catalog và cấu hình Linux | `${XDG_DATA_HOME:-$HOME/.local/share}/vdb/` |

Installer bảo toàn catalog và cấu hình khi nâng cấp. Dữ liệu tạo khi chạy từ source trong `data/` vẫn ở vị trí cũ; có thể mở bằng `vdb --db /đường/dẫn/catalog.json` hoặc chọn từ Studio. Có thể tùy chỉnh thư mục chương trình, CLI, ứng dụng bằng `VDB_INSTALL_ROOT`, `VDB_BIN_DIR`, `VDB_APPLICATIONS_DIR` trước khi cài; dùng cùng các giá trị khi cập nhật. macOS hỗ trợ `VDB_STUDIO_DATA_DIR` để chọn thư mục dữ liệu khác.

### Build từ mã nguồn (yêu cầu V++)

Cài bộ công cụ V++ native theo [README V++](https://github.com/winbiru/VXX#readme). VDB ghim revision đã dùng để build ở [distribution/VPP_REVISION](distribution/VPP_REVISION). Trên macOS Apple Silicon cần Git, CMake, Make và Xcode Command Line Tools. Ví dụ dựng đúng revision từ nguồn:

```sh
git clone https://github.com/winbiru/VDB.git
git clone https://github.com/winbiru/VXX.git VXX
git -C VXX checkout --detach "$(cat VDB/distribution/VPP_REVISION)"
cmake -S VXX -B VXX/build-pure-vpp
cmake --build VXX/build-pure-vpp --parallel
cd VDB
../VXX/VPP --version
make VPP="$(cd ../VXX && pwd)/VPP"
./vdb --version
./vdb --db data/demo.json -f examples/demo.sql
./vdb --db data/demo.json -e "USE kho; SELECT * FROM san_pham;"
make test
```

Nếu đã cài V++ tương thích vào PATH, dùng `vpp --version` rồi `make`. Makefile tự tìm `vpp` trong PATH, sau đó dùng `$HOME/V++/VPP` nếu không tìm thấy. Có thể chỉ định `make VPP=/đường/dẫn/vpp`. Linux cần bộ compiler native x86-64 đầy đủ; CI xây dựng theo quy trình bootstrap Linux của V++ (xem [workflow](.github/workflows/ci.yml)). Dùng gói V++ native tương thích nếu đã có.

### CI/CD và tạo release

[Workflow VDB CI / Release](.github/workflows/ci.yml) chạy khi push, pull request hoặc kích hoạt thủ công. Hai runner macOS ARM64 và Linux x86-64 dựng V++ tại revision đã ghim, build VDB, chạy kiểm thử SQL, Studio state, Studio HTTP và cài đặt/cập nhật. Các archive và checksum được lưu dưới dạng artifact. Khi push tag `vMAJOR.MINOR.PATCH` khớp `VERSION`, job publish chỉ chạy sau khi cả hai nền tảng vượt qua các gate. Job xác minh lại checksum và version trong gói rồi tạo GitHub Release, không ghi đè release đã tồn tại.

Đóng gói và thử cài/nâng cấp cục bộ:

```sh
make release
make test-release
```

Các tệp nằm trong `dist/`. Kiểm thử distribution dùng thư mục HOME và catalog tạm, mô phỏng tải release để kiểm tra luồng cập nhật, không cài vào tài khoản đang sử dụng. Để phát hành một phiên bản mới, cập nhật `VERSION`, commit mã nguồn, push nhánh và push tag tương ứng (ví dụ `v0.1.0`). Workflow sẽ tạo release sau khi tất cả kiểm thử thành công.

## Sử dụng CLI

Các tùy chọn:
- `--db FILE`: catalog cần mở. Mặc định `data/vdb.json`.
- `--existing` / `--new`: yêu cầu catalog đã tồn tại / tạo catalog mới, tương ứng.
- `--validate`: kiểm tra cú pháp của batch, không thực thi hoặc ghi catalog (JSON thành công có `"valid":1`).
- `--guard-writes`: mỗi UPDATE/DELETE phải tác động đúng một hàng; nếu không, toàn bộ batch bị hủy.
- `--backup DESTINATION`: sao lưu catalog đã tồn tại vào tệp mới, kiểm tra snapshot trước khi công bố.
- `--restore BACKUP`: kiểm tra dữ liệu sao lưu, dựng lại index và phục hồi vào catalog mới chỉ định bằng `--db`. Cả hai lệnh từ chối ghi đè tệp đích.
- `-e SQL`: thực thi một hoặc nhiều câu SQL.
- `-f FILE`: chạy tệp SQL.
- Có thể truyền SQL qua stdin: `./vdb < examples/demo.sql`.

Ví dụ sao lưu và phục hồi toàn bộ catalog (gồm các database logic, schema, dữ liệu, view và index):

```sh
./vdb --db data/demo.json --backup data/demo-backup.json
./vdb --db data/demo-restored.json --restore data/demo-backup.json
./vdb --db data/demo-restored.json --existing -e "SHOW DATABASES;"
```

Một catalog vật lý có thể chứa nhiều database logic. Mỗi lần gọi CLI bắt đầu ở database `DEFAULT`; dùng `USE tên` để chuyển database trong batch.

## VDB Studio

Ứng dụng desktop macOS Apple Silicon có cửa sổ Cocoa/WKWebView riêng, dựa trên cầu nối ASM đồ họa của V++. Cây schemas, trình soạn SQL nhiều tab, bảng kết quả và nhật ký thực thi dùng trực tiếp engine VDB hiện tại. Server HTTP cục bộ được viết bằng V++.

```sh
./vdb studio --db data/demo.json
# Đổi cổng nếu cần:
./vdb studio --db data/demo.json --port 8766
# Mở trong trình duyệt thay cho cửa sổ desktop:
./vdb studio --browser
# Chỉ khởi động server:
./vdb studio --no-open
```

Trên macOS Apple Silicon, lệnh mặc định dựng ứng dụng `build/VDB Studio.app` bằng clang (Xcode Command Line Tools), khởi động server rồi mở cửa sổ có thanh tiêu đề, Dock, menu và hộp thoại tệp của macOS. Đóng cửa sổ hoặc nhấn Cmd+Q sẽ dừng server của phiên đó. Có thể dùng `--desktop` để chọn chế độ này rõ ràng. Trên nền tảng khác, Studio mặc định mở trình duyệt nếu có chương trình mở URL. Trong chế độ trình duyệt/server, hãy giữ URL phiên riêng tư và nhấn Ctrl+C để dừng server. Launcher dùng OpenSSL để tạo mã phiên ngẫu nhiên.

`make studio-macos` tạo bundle độc lập tại `build/VDB Studio.app`, chứa engine, server, CLI, giao diện và icon. Khi chạy bundle, catalog mặc định và `studio-state.json` nằm trong `~/Library/Application Support/VDB Studio/`; đặt `VDB_STUDIO_DATA_DIR` để chọn thư mục khác. Bundle đã dựng không cần compiler V++ hay Make khi chạy. Bản build hiện chưa được ký/notarize; nghiệm thu Finder/Dock còn chờ.

- Chọn database cho từng tab trong danh sách Database hoặc cây Schemas.
- Home quản lý hồ sơ catalog cục bộ: đặt tên, tìm kiếm, sắp xếp theo tên/gần đây, kiểm tra kết nối, mở, sửa và xóa hồ sơ. Xóa hồ sơ không xóa tệp catalog. Trong cửa sổ desktop có hộp thoại chọn catalog hiện có hoặc đường dẫn tạo mới; ở trình duyệt nhập đường dẫn tuyệt đối. Catalog mới chỉ được tạo khi chọn Lưu & mở.
- Mỗi catalog có tab kết nối riêng với cây schema, các tab SQL, kết quả và nhật ký độc lập. Refresh thực hiện kết nối lại; đóng tab SQL hoặc kết nối có bản nháp sẽ yêu cầu xác nhận.
- Hồ sơ, kết nối đang mở và nội dung SQL (kể cả bản nháp) được lưu trong `data/studio-state.json` để khôi phục khi mở lại. Kết quả và Action Output (tối đa 100 bản ghi) chỉ tồn tại trong phiên hiện tại. History lưu tối đa 50 truy vấn mỗi kết nối đang mở, với SQL tối đa 16.000 ký tự và thông báo tối đa 1.000 ký tự; đóng kết nối sẽ bỏ lịch sử của phiên đó. Tệp cấu hình là JSON chứa SQL dạng văn bản, nên cần giữ riêng tư. Studio chỉ cho phép một tiến trình sử dụng cấu hình tại một thời điểm. Catalog mở qua Studio được chuẩn hóa đường dẫn; CLI yêu cầu đường dẫn thật, không hỗ trợ catalog có liên kết cứng.
- Khi đóng ứng dụng hoặc Cmd+Q, cửa sổ chờ lưu cấu hình. Nếu đang chạy truy vấn, đọc CSV hoặc lưu tệp, hãy đợi thao tác hoàn tất rồi đóng. Nếu lưu cấu hình thất bại hoặc không nhận phản hồi, việc thoát bị hủy. Trong chế độ trình duyệt, việc gửi yêu cầu tải SQL không xác nhận được tệp đã lưu nên bản nháp vẫn được đánh dấu chưa lưu.
- Cây Schemas tìm theo database, bảng, cột, index và khóa ngoại. Mở rộng bảng để xem kiểu và ràng buộc PK/UNIQUE/NOT NULL lấy từ DESCRIBE; nhấp một lần để chọn Object Info, nhấp đúp hoặc Enter để duyệt dữ liệu theo trang 100 hàng, dùng Previous/Next. Nếu có khóa chính một cột, truy vấn sắp xếp theo khóa; các bảng khác dùng thứ tự tự nhiên. Lọc, sắp xếp và xuất CSV trên trang hiện tại. Các truy vấn trang độc lập nên thay đổi đồng thời có thể làm dịch chuyển OFFSET. Menu chuột phải có Set Default Schema, Select Rows, Table Inspector, DESCRIBE, Copy Name, Refresh và các thao tác tạo/xóa phù hợp với đối tượng.
- Information có Object Info cho đối tượng đang chọn và Session cho catalog, database của tab, trạng thái kết nối và nhãn phiên bản engine hiện tại. Metadata được cập nhật khi refresh hoặc sau khi chạy SQL; nếu lỗi, Studio hiển thị cảnh báo dữ liệu có thể đã cũ và khóa các thao tác tạo/xóa bảng qua giao diện đến khi refresh thành công.
- Create Table mở trình thiết kế bảng trực quan với tên, kiểu, độ dài VARCHAR và ràng buộc. Có thể xem trước SQL, mở bản nháp trong editor hoặc tạo bảng ngay. Table Inspector hiển thị cột và kiểu từ DESCRIBE cùng thống kê chỉ mục từ SHOW INDEX và tham chiếu từ SHOW FOREIGN KEYS. Nút Tải thống kê chạy SHOW STATISTICS FROM bảng để đo số hàng, byte JSON UTF-8 của toàn bộ bản ghi bảng, số NULL/khác NULL, số giá trị khác nhau không NULL và MIN/MAX mỗi cột. Đây là kích thước JSON logic, gồm schema, chỉ mục và hàng; chưa đo trang lưu trữ vật lý. Menu bảng và Inspector có hộp thoại ALTER TABLE, CREATE [UNIQUE] INDEX, DROP INDEX, ADD CONSTRAINT FOREIGN KEY và DROP FOREIGN KEY; SQL được xem trước và mở trong tab đúng database để người dùng chạy. DROP TABLE yêu cầu nhập chính xác tên bảng và cảnh báo sẽ xóa toàn bộ dữ liệu của bảng trong catalog đã chọn.
- Menu native File, Edit, View, Query, Database, Tools và Help dùng chung các hành động với toolbar. Có thể quản lý kết nối, mở/lưu SQL, tìm đối tượng, refresh schemas, tạo database, thiết kế CREATE TABLE, xem cấu trúc bằng Table Inspector/DESCRIBE và xuất CSV.
- Phím tắt Cmd/Ctrl+N (tab mới), O (mở), S (lưu), Shift+S (lưu thành tệp khác), W (đóng tab), F (tìm/thay thế). Cmd/Ctrl+Enter chạy vùng chọn nếu có, hoặc toàn bộ tab; Cmd/Ctrl+Shift+Enter chạy câu SQL tại con trỏ. Query menu có ba chế độ chạy riêng. Các câu trong một batch tuân theo giao dịch và khóa catalog CLI.
- View và các nút Nav, Info, SQL+, Output cho phép bật/tắt từng panel; kéo splitter để đổi chiều rộng Navigator/SQL Additions, chiều cao Information/SQL Editor/Output. Bố cục được lưu trong workspace; Reset Layout hoặc Tùy chọn khôi phục mặc định. Khi cửa sổ hẹp, panel SQL Additions tự ẩn và khôi phục khi đủ rộng.
- Trong desktop, Open SQL đọc UTF-8 qua hộp thoại macOS. Save ghi vào đường dẫn đã chọn của tab, hoặc mở hộp thoại nếu chưa có đường dẫn; Save As luôn mở hộp thoại và đổi liên kết tệp khi lưu thành công. Đường dẫn tệp chỉ tồn tại trong phiên native hiện tại; bản nháp khôi phục sau khi mở lại Studio cần chọn lại đường dẫn khi Save lần đầu. Trong trình duyệt, Save/Save As gửi yêu cầu tải xuống và giữ dấu bản nháp vì không thể xác nhận ghi đĩa.
- Query Editor có format SQL cơ bản, gợi ý từ khóa và metadata của catalog (Ctrl+Space), Find/Replace và kiểm tra cú pháp bằng engine. Giới hạn 100/500/1000 hàng chỉ tự thêm LIMIT cho một câu SELECT * đơn giản chưa có LIMIT. Undo/Redo giữ tối đa 100 bước mỗi tab trong phiên; menu Edit > Undo SQL/Redo SQL luôn tác động vào bản nháp SQL đang chọn, kể cả khi focus ở trường khác. Cmd/Ctrl+Z và Shift+Z trong editor thao tác cùng lịch sử.
- Result Grid hỗ trợ lọc, sắp xếp cục bộ, kéo đổi chiều rộng cột, xem/copy ô và hàng. Sửa/thêm/xóa hàng được bật cho kết quả SELECT * từ một bảng có một PRIMARY KEY, đủ cột và khóa không trùng. Xem trước SQL, Apply hoặc Revert; UPDATE/DELETE dùng điều kiện so khớp toàn bộ giá trị ban đầu và yêu cầu đúng một hàng bị tác động. Engine chưa có định danh bảng bất biến; cần refresh nếu bảng bị thay thế từ bên ngoài. Không hỗ trợ giao dịch kéo dài qua nhiều lần chạy.
- Import CSV cho phép chọn bảng, mở tệp UTF-8 hoặc dán nội dung, ánh xạ cột, xem trước và Apply nguyên tử. Giới hạn 128 KB CSV, 500 hàng dữ liệu và 32 KB SQL xem trước. Ô rỗng không có dấu nháy là NULL; ô `""` là chuỗi rỗng. Export CSV có UTF-8 BOM, giữ Unicode và thêm dấu nháy đơn trước chuỗi có nguy cơ được spreadsheet diễn giải thành công thức; các chuỗi đó có thể thay đổi khi import lại.
- Action Output/History lọc theo trạng thái và ngày trong từng kết nối, xem chi tiết, copy, xuất CSV và mở lại SQL từ History. Thời lượng gồm round-trip HTTP phía client, thời gian thực thi engine (sau parse/load, gồm USE và ghi snapshot tạm), xuất JSON/stdout, đọc và phân tích HTTP body. CLI `--timing` thêm một dòng JSON timing cuối batch thành công; mặc định giữ nguyên JSON-lines.
- Bật SQL+ để xem Context Help theo con trỏ, sáu snippet dựng sẵn và My Snippets (thêm/sửa/xóa/tìm kiếm, lưu theo workspace). Chèn SQL tại con trỏ/vùng chọn hoặc mở tab mới rồi chạy thủ công. Nút EXPLAIN trong Query Editor chạy kế hoạch của một SELECT tại con trỏ hoặc vùng chọn trong tab riêng. Engine hỗ trợ ALTER TABLE, DROP DATABASE, CREATE [UNIQUE] INDEX, DROP INDEX và SHOW INDEX qua SQL Editor. Navigator hỗ trợ view chỉ đọc, tạo/xóa qua bản nháp SQL, SELECT và DESCRIBE. Routines và quản trị máy chủ từ xa thuộc các mốc tiếp theo. Metadata Navigator được nạp qua SHOW TABLES/SHOW VIEWS và batch DESCRIBE, SHOW INDEX, SHOW FOREIGN KEYS, chưa phân trang; refresh nếu catalog được thay đổi bên ngoài Studio.
- Administration trên toolbar kiểm tra khả năng đọc catalog hiện tại, hiển thị số database, kết nối Studio và mục Action Output; cho phép sao lưu và phục hồi vào catalog mới. Sau khi phục hồi, mở catalog mới từ Home.
- Nút Mô hình hiển thị sơ đồ bảng và khóa ngoại theo database đã chọn, gồm kiểu cột, ràng buộc và danh sách ánh xạ khóa ngoại nhiều cột. Sơ đồ chỉ đọc, lấy metadata của lần refresh gần nhất.
- `USE` trong câu SQL có hiệu lực trong batch đó. Danh sách Database quyết định database đầu vào cho lần thực thi tiếp theo.

Studio dành cho phát triển cục bộ. API SQL yêu cầu mã phiên và Host `127.0.0.1` với cổng tương ứng. Không công bố cổng ra Internet. Phạm vi SQL giống với CLI bên dưới. Launcher `studio/serve` giữ khóa cấu hình bằng `lockf` trên macOS/FreeBSD hoặc `flock` trên Linux, tự giải phóng khi tiến trình kết thúc. Tệp `.lock` có thể còn trên đĩa sau khi thoát; không cần xóa nó. Luôn khởi động qua `./vdb studio`.

Kiểm thử hồi quy CLI bằng `make test`. Kiểm thử logic trạng thái giao diện bằng `make test-studio-state` (Node.js, mô phỏng API/render, không mở cửa sổ). Kiểm thử HTTP Studio bằng `make test-studio` (Python 3 và quyền bind loopback); bộ kiểm thử dùng catalog và cấu hình tạm, kiểm tra cô lập dữ liệu, kiểm tra Host/token, rollback và khôi phục phiên. State tests kiểm tra thêm metadata theo kết nối/database, trình tạo SQL và định tuyến thao tác Navigator; CLI tests kiểm tra DESCRIBE, CREATE/DROP, ràng buộc, validate không ghi dữ liệu và guarded writes rollback. State tests kiểm tra thêm Undo/Redo, gợi ý, CSV, nguồn Result Grid, Apply/rollback mô phỏng, Context Help và quản lý/chèn snippet. Xem checklist và hướng dẫn nghiệm thu từng giai đoạn trong `studio/CHECKLIST.md`.

## SQL hiện được hỗ trợ

| Nhóm | Cú pháp |
| --- | --- |
| Database | `CREATE DATABASE tên`, `DROP DATABASE tên` (trừ DEFAULT), `USE tên`, `SHOW DATABASES` |
| Schema | `CREATE TABLE`, `DROP TABLE`, `SHOW TABLES`, `DESCRIBE` |
| View | `CREATE VIEW v AS SELECT ...`, `DROP VIEW v`, `SHOW VIEWS`, `DESCRIBE v` |
| Thay đổi schema | `ALTER TABLE t ADD [COLUMN] định_nghĩa`, `DROP [COLUMN] c`, `RENAME COLUMN c TO c_mới`, `RENAME TO t_mới` |
| Chỉ mục | `CREATE [UNIQUE] INDEX ix ON t (c1, c2, ...)`, `DROP INDEX ix ON t`, `SHOW INDEX FROM t`, `SHOW INDEXES FROM t` |
| Khóa ngoại | `REFERENCES p(c)`, `[CONSTRAINT fk] FOREIGN KEY (c1,...) REFERENCES p (k1,...)`, `ALTER TABLE t ADD CONSTRAINT fk FOREIGN KEY (...) REFERENCES p (...)`, `ALTER TABLE t DROP FOREIGN KEY fk`, `SHOW FOREIGN KEYS FROM t` |
| Thống kê | `SHOW STATISTICS FROM t` (bảng vật lý) |
| Kế hoạch | `EXPLAIN SELECT ...` |
| Dữ liệu | `INSERT INTO ... [(cột,...)] VALUES (...), (...)`, `UPDATE ... SET ...`, `DELETE FROM ...` |
| Truy vấn | `SELECT [DISTINCT] *` hoặc danh sách cột/hàm tổng hợp, bí danh `AS`, `WHERE`, `ORDER BY` nhiều cột `[ASC\|DESC]`, `LIMIT n [OFFSET m]` |
| Kết nối bảng | `[INNER] JOIN`, `LEFT [OUTER] JOIN`, `ON a.cột = b.cột`, nhiều JOIN liên tiếp |
| Tổng hợp | `GROUP BY` nhiều cột, `COUNT(*)`, `COUNT(cột)`, `SUM`, `AVG`, `MIN`, `MAX`, `HAVING` theo nhãn/bí danh kết quả |
| Điều kiện | `=`, `!=`, `<>`, `<`, `<=`, `>`, `>=`, `NOT`, `AND`, `OR`, ngoặc, `IS [NOT] NULL`, `[NOT] IN`, `[NOT] BETWEEN`, `[NOT] LIKE` |
| Kiểu | `INT`/`INTEGER` (32 bit), `REAL`, `TEXT`, `VARCHAR(n)`, `BOOLEAN` |
| Ràng buộc | `PRIMARY KEY` một cột, `NOT NULL`, `UNIQUE` |
| Giao dịch | `BEGIN [TRANSACTION]`, `COMMIT`, `ROLLBACK` trong một batch |

`EXPLAIN SELECT` dùng cùng bước kiểm tra tên bảng, cột, JOIN, GROUP BY, HAVING và ORDER BY với SELECT. Kết quả gồm STEP, OPERATOR, OBJECT và ROWS (số hàng hiện có ở TABLE_SCAN, số ứng viên chính xác theo biên khóa ở INDEX_SCAN và INDEX_RANGE_SCAN, số hàng trung bình mỗi lần dò khóa ở INDEX_LOOKUP, số hàng đầu ra ước lượng ở JOIN; các toán tử khác hoặc cardinality chưa biết để NULL). EXPLAIN đọc metadata và biên khóa để lập kế hoạch, không thực thi các toán tử truy vấn.

Chỉ mục B+ tree hỗ trợ một hoặc nhiều cột INT/INTEGER/TEXT/VARCHAR. Chỉ mục một cột bỏ khóa NULL; chỉ mục nhiều cột giữ khóa có thành phần NULL để bảo toàn truy vấn theo tiền tố. Planner lấy giao các biên của điều kiện AND, dùng tiền tố liên tiếp của chỉ mục: các cột đầu có điều kiện bằng và cột kế tiếp có thể dùng <, <=, >, >= hoặc BETWEEN. Điều kiện OR/NOT không tạo biên; điều kiện trên cột không dẫn đầu hoặc literal khác kiểu vẫn được kiểm tra bằng bộ lọc. Rank của biên khóa cho số ứng viên chính xác, kể cả khi khóa trùng nhiều. Chi phí ước lượng TABLE_SCAN = n, INDEX_SCAN = h + k, INDEX_RANGE_SCAN = 2h + 2k (n là số hàng, h là chiều cao cây, k là số ứng viên). Các mô hình chi phí là heuristic. Range scan giữ thứ tự vật lý bằng sắp xếp O(k log k), sau đó kiểm tra lại WHERE. Cây lưu trong catalog JSON. INSERT cập nhật các nút trên đường từ gốc đến lá, tách nút khi vượt 16 khóa/con, cập nhật số khóa của cây con và cardinality theo tiền tố. UPDATE/DELETE/ALTER vẫn xây lại chỉ mục; rollback khôi phục cả dữ liệu và chỉ mục. Phải DROP INDEX trước khi xóa bất kỳ cột nào thuộc chỉ mục. Chỉ mục cũ vẫn đọc được và tự chuyển sang nút có số khóa cây con ở lần INSERT tiếp theo. CREATE UNIQUE INDEX từ chối khóa đầy đủ trùng nhau khi mọi thành phần khác NULL. SHOW INDEX trả thêm cột UNIQUE (0/1); catalog cũ mặc định 0. Các trang này là nút logic trong JSON; catalog vẫn được ghi lại toàn bộ khi lưu.

Planner so sánh chi phí nested loop, hash join và index nested-loop join nếu bảng phải có index dẫn đầu cùng họ kiểu dữ liệu với khóa trái. Chi phí index join dựa trên chiều cao cây và số khóa trung bình mỗi tiền tố (entries / prefix cardinality); EXPLAIN hiển thị INDEX_LOOKUP và INDEX_NESTED_LOOP_JOIN. Kế hoạch nhiều JOIN truyền số hàng trung gian ước lượng từ metadata: tích số hàng nếu thiếu thống kê, giới hạn số khớp theo UNIQUE hoặc cardinality tiền tố, LEFT JOIN có ít nhất một hàng ước lượng cho mỗi hàng trái. Ước lượng không phản ánh đầy đủ phân bố lệch hoặc tỷ lệ khóa khớp; tối đa 10^12 hàng. EXPLAIN với view có cardinality chưa biết dùng NULL và hash. Khi thực thi, các JOIN sau chọn lại thuật toán theo số hàng trung gian thực tế.

ALTER TABLE thêm cột với giá trị NULL cho dữ liệu hiện có; cột NOT NULL/PRIMARY KEY chỉ có thể thêm vào bảng rỗng. Không hỗ trợ DEFAULT hoặc nhiều thao tác ALTER trong một câu lệnh. Có thể xóa cột kể cả khóa chính, nhưng phải giữ ít nhất một cột. Các thao tác DDL có thể rollback trong batch. DROP DATABASE xóa toàn bộ database, giữ DEFAULT và tự chuyển về DEFAULT nếu database đang chọn bị xóa.


Khóa ngoại cùng database hỗ trợ khóa đơn hoặc nhiều cột theo thứ tự, tham chiếu PRIMARY KEY, UNIQUE hoặc toàn bộ CREATE UNIQUE INDEX. MATCH SIMPLE bỏ qua hàng có bất kỳ thành phần NULL; RESTRICT kiểm tra tức thời khi thay đổi dữ liệu hoặc schema. Inline REFERENCES đặt sau các ràng buộc cột. Chưa hỗ trợ CASCADE, deferred hoặc tham chiếu database khác. SHOW FOREIGN KEYS trả tên khóa, cột con, bảng và cột cha.

View là quan hệ chỉ đọc cùng database, dùng chung namespace với bảng. Định nghĩa SELECT và metadata được lưu trong catalog; mỗi lần truy vấn sẽ tính lại từ nguồn hiện tại. View có thể tham chiếu view khác (tối đa 64 tầng khi thực thi), JOIN, WHERE, GROUP BY, HAVING, DISTINCT, ORDER BY và LIMIT. Nhãn cột phải là tên định danh duy nhất; dùng AS cho cột có định danh đủ và biểu thức tổng hợp. DESCRIBE báo kiểu nguồn (SUM/AVG là REAL, COUNT là INT), độ dài VARCHAR và không kế thừa ràng buộc. SHOW TABLES chỉ liệt kê bảng vật lý, SHOW VIEWS liệt kê view. INSERT/UPDATE/DELETE, ALTER, index và FK chỉ hỗ trợ bảng vật lý. DROP hoặc thay đổi cấu trúc quan hệ nguồn bị chặn khi có view phụ thuộc; DROP DATABASE xóa cả view. EXPLAIN hiển thị VIEW_SCAN với ROWS NULL và kế hoạch ngoài, không thực thi định nghĩa view.

Tên định danh dùng ASCII không dấu, không phân biệt chữ hoa/thường (chuẩn hóa thành chữ hoa). BOOLEAN nhận TRUE/FALSE hoặc 1/0 và được lưu, trả về dưới dạng 1/0 theo runtime V++ native hiện tại. Giá trị chuỗi UTF-8 đặt trong dấu nháy đơn và hỗ trợ nháy đơn kép SQL, ví dụ `'O''Brien'`. Hỗ trợ comment dòng `--`.

Kết quả là mỗi câu lệnh một dòng JSON, gồm `columns` và `rows` cho truy vấn, hoặc `affected_rows` cho thao tác dữ liệu.

Ví dụ với bảng `SP(id, price, active)` và `TAGS(pid, label)`:

```sql
SELECT s.id, COUNT(t.label) AS n
FROM sp AS s LEFT JOIN tags AS t ON s.id = t.pid
WHERE s.active = TRUE
GROUP BY s.id
HAVING n > 0
ORDER BY n DESC, s.id ASC
LIMIT 20 OFFSET 0;
```

JOIN hỗ trợ một điều kiện bằng giữa hai cột mỗi lần nối. Bí danh bảng/cột cần `AS`. HAVING dùng cột kết quả hoặc bí danh như `n` trong ví dụ; chưa hỗ trợ viết trực tiếp `HAVING COUNT(*) > 0`. LIKE phân biệt hoa thường, ký tự `_` khớp một ký tự Unicode, `%` khớp chuỗi bất kỳ. WHERE/HAVING áp dụng logic ba trị SQL; NULL không nối bằng NULL, nhưng các NULL cùng khóa được gom nhóm và loại trùng.

## Kiến trúc

```text
SQL / CLI
    |
src/lexer.vi       Tách token
    |
src/parser.vi      Sinh biểu diễn câu lệnh
    |
src/engine.vi      Điều phối catalog và câu lệnh
    |
src/command/       CRUD, binding và điều phối SELECT
    |
src/optimizer/     Chọn thuật toán vật lý
    |
src/algorithm/dispatch.vi  Điều phối thuật toán vật lý
    |
src/algorithm/     Thực thi JOIN, tổng hợp, DISTINCT, sắp xếp
    |
src/chinh.vi       Điều phối batch và đọc/ghi snapshot
    |
Catalog JSON      Lưu nhiều database và bảng
```

Lệnh shell `vdb` quản lý tệp tạm, khóa catalog và đổi tên snapshot trên cùng filesystem. Toàn bộ batch được lưu khi tất cả câu lệnh chạy thành công. Nếu có lỗi cú pháp, ràng buộc hoặc truy vấn, catalog gốc được giữ nguyên. `BEGIN/ROLLBACK` khôi phục snapshot trong bộ nhớ. Khóa thư mục ngăn các CLI cùng làm việc với một catalog; sau khi tiến trình bị kill cưỡng bức, kiểm tra không còn tiến trình sử dụng catalog trước khi xóa thư mục khóa tồn đọng.

### Quy ước hằng chuỗi và bản ghi

Toàn bộ mã engine trong `src/` dùng hằng chuỗi khai báo tại `src/constants.vi` và các hàm tạo bản ghi trong `src/records.vi`. Hằng được biểu diễn bằng hàm module công khai, không tham số, chỉ trả về một chuỗi cố định. Đây là cách tương thích với V++ hiện tại khi chưa xác minh được cú pháp hằng `static final` native.

```vi
nhập constants.*;

hàm công khai là select(lệnh) {
    trả về lệnh[KEY_OP()] == SQL_SELECT();
};
```

Khi bổ sung từ khóa SQL hoặc thuật toán vật lý, khai báo một hàm `SQL_...()` hoặc `ALGO_...()` trong `constants.vi` rồi dùng hàm đó trong parser, planner và dispatcher. Dùng `KEY_...()` cho khóa bản ghi/JSON, `ERR_...()` cho thông báo lỗi. Các giá trị giao thức đã công bố (SQL, JSON, catalog, biến môi trường CLI) phải được giữ ổn định khi refactor; thay đổi định dạng lưu trữ cần có phương án tương thích hoặc migration.

V++ hiện chỉ chấp nhận chuỗi hoặc tên làm khóa trong cú pháp map literal. Khi tạo bản ghi có khóa dùng chung, dùng constructor trong `records.vi`, hoặc tạo map rỗng và gán `bảnGhi[KEY_NAME()] = tên`. Mỗi constructor tạo một map mới, tránh chia sẻ trạng thái có thể thay đổi giữa các lần gọi.

`make test-constants` (Python 3) kiểm tra mọi tệp `.vi` trong `src/`, bỏ qua comment và báo lỗi nếu có chuỗi literal bên ngoài `constants.vi` hoặc khai báo hằng sai quy ước. Kiểm tra này chạy cùng `make test`. Các bài kiểm thử SQL tiếp tục bảo vệ định dạng kết quả và hành vi engine. Chưa đo chi phí gọi hàm hằng trong vòng lặp nóng. Quy ước này hiện áp dụng cho engine; server và giao diện Studio có mã riêng.

## Phạm vi phiên bản 0.1.0

Đây là MVP dạng embedded/batch. Engine nạp toàn bộ catalog vào bộ nhớ, quét hàng tuần tự, kiểm tra UNIQUE bằng so sánh cặp và lưu lại toàn bộ snapshot khi có thay đổi. Việc đổi tên tệp giúp công bố snapshot nguyên tử trên filesystem thông thường; chưa có fsync/WAL để bảo đảm dữ liệu tồn tại qua mất điện.

Các toán tử SELECT được triển khai bằng V++ trong các module độc lập:

```text
src/
├── command/select.vi
├── optimizer/planner.vi
└── algorithm/
    ├── dispatch.vi
    ├── hash.vi
    ├── row.vi
    ├── index/
    │   └── bplus_tree.vi
    ├── join/
    │   ├── hash_join.vi
    │   └── nested_loop.vi
    ├── aggregate/
    │   └── hash_aggregate.vi
    ├── distinct/
    │   └── hash_distinct.vi
    └── sort/
        └── merge_sort.vi
```

SELECT phân tích cú pháp, liên kết cột với schema, kiểm tra ngữ nghĩa và điều phối các bước thực thi. Planner tạo kế hoạch cho từng JOIN (kiểu nối, vị trí khóa hai phía, số cột bên phải) và chọn thuật toán cho các toán tử còn lại. Hàm `thực thi thuật toán(kếHoạch, dữLiệu)` trong `src/algorithm/dispatch.vi` là điểm điều phối chung cho mọi thuật toán vật lý trong bảng dưới đây. Hàm đọc trường `algorithm` của kế hoạch, gọi module tương ứng và báo lỗi nếu thuật toán chưa được hỗ trợ. Khi thêm thuật toán mới, đăng ký nhánh thực thi tại đây và cập nhật planner nếu cần lựa chọn thuật toán đó.

Dữ liệu đầu vào dùng trường `rows` chung. JOIN nhận thêm `right`, sắp xếp nhận thêm `order`, còn tổng hợp nhận `operation` là `GROUP` (kèm `group`) hoặc `REDUCE` (kèm `item`). Các module thuật toán giữ nguyên giao diện nội bộ của chúng.

| Toán tử | Thuật toán hiện có |
| --- | --- |
| Truy cập chỉ mục | INDEX_SCAN, INDEX_RANGE_SCAN |
| INNER/LEFT JOIN | HASH_JOIN, NESTED_LOOP_JOIN, INDEX_NESTED_LOOP_JOIN |
| GROUP BY / tổng hợp | HASH_AGGREGATE |
| DISTINCT | HASH_DISTINCT |
| ORDER BY | MERGE_SORT |

Planner chọn thuật toán truy cập chỉ mục và JOIN theo chi phí ước lượng. Với L hàng bên trái và R hàng bên phải, chi phí nested loop là L × R, chi phí hash là L + R + 17. Nested loop được chọn khi chi phí của nó nhỏ hơn hoặc bằng hash. Các JOIN tiếp theo dùng ước lượng cardinality trung gian khi EXPLAIN và số hàng thực tế khi thực thi. Đây là mô hình heuristic, chưa hiệu chỉnh bằng benchmark. GROUP BY giữ các hàng trong nhóm rồi tính COUNT/SUM/AVG/MIN/MAX. DISTINCT chạy sau projection/HAVING và trước ORDER BY, giữ hàng kết quả đầu tiên. Chưa có merge join hoặc tối ưu thứ tự JOIN. SHOW STATISTICS tính thống kê chính xác tại thời điểm truy vấn; chưa dùng thống kê đó để tối ưu thứ tự JOIN. SELECT có LIMIT/OFFSET không ORDER BY/GROUP BY/DISTINCT chỉ tạo các hàng kết quả được yêu cầu; vẫn kiểm tra toàn bộ WHERE để giữ ngữ nghĩa lỗi. ORDER BY, ứng viên index, JOIN và view vẫn có thể cần bộ nhớ theo toàn bộ dữ liệu.

HASH_JOIN xây bảng băm tạm từ phía phải; NESTED_LOOP_JOIN duyệt các cặp hàng để so sánh khóa. INDEX_NESTED_LOOP_JOIN dò khóa phía trái qua chỉ mục phía phải. Cả ba hỗ trợ INNER/LEFT JOIN, giữ kết quả trùng, thứ tự hàng và không ghép khóa NULL. GROUP BY và DISTINCT dùng bảng băm khóa nhiều cột, ORDER BY dùng merge sort ổn định. Bảng băm có tối đa 65.521 bucket, luôn kiểm tra bằng nhau sau khi chọn bucket, giữ thứ tự xuất hiện và mọi hàng JOIN trùng khóa. Chi phí kỳ vọng của các toán tử băm gần tuyến tính theo số hàng và số kết quả khi hash phân bố tốt; collision nhiều hoặc JOIN nhiều-nhiều vẫn có thể dẫn đến chi phí bậc hai. Bộ nhớ tạm tăng theo dữ liệu truy vấn, chưa có spill ra đĩa.

Các mốc tiếp theo: cập nhật cây theo trang cho UPDATE/DELETE, thống kê nâng cao và tối ưu thứ tự JOIN, storage theo trang, buffer pool, WAL và khôi phục sự cố, MVCC, giao thức client/server TCP, xác thực và phân quyền. Chưa tương thích MySQL wire protocol hoặc đầy đủ SQL chuẩn; chưa dùng cho dữ liệu sản xuất.
