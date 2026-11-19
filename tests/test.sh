#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
db="$work/test.json"
run() { "$root/vdb" --db "$db" -e "$1"; }
contains() {
    if ! printf '%s\n' "$1" | grep -Fq -- "$2"; then
        printf 'Expected %s in:\n%s\n' "$2" "$1" >&2
        exit 1
    fi
}
fails() {
    cp "$db" "$work/before"
    if run "$1" > "$work/error" 2>&1; then
        echo "Expected failure: $1" >&2
        exit 1
    fi
    contains "$(cat "$work/error")" "$2"
    cmp "$db" "$work/before"
}
out=$(run "CREATE DATABASE kho; USE kho; CREATE TABLE sp (id INT PRIMARY KEY, name VARCHAR(40) NOT NULL, price REAL, active BOOLEAN, note TEXT UNIQUE); INSERT INTO sp VALUES (1, 'Cà phê', 12.5, TRUE, NULL), (2, 'O''Brien; trà', 7, FALSE, 'a'), (3, 'Ca cao', NULL, TRUE, NULL); SELECT id, name FROM sp WHERE active = TRUE ORDER BY id DESC;")
contains "$out" '"rows":[[3,"Ca cao"],[1,"Cà phê"]]'
out=$(run "USE kho; SELECT name, price FROM sp WHERE id = 2;")
contains "$out" "[[\"O'Brien; trà\",7]]"
contains "$(run 'USE kho; SELECT COUNT(*) FROM sp WHERE price IS NULL;')" '"rows":[[1]]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE id >= 1 AND id <> 2 ORDER BY id DESC LIMIT 1;')" '"rows":[[3]]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE price = NULL;')" '"rows":[]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE id = 1 OR id = 2 AND active = TRUE ORDER BY id;')" '"rows":[[1]]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE (id = 1 OR id = 2) AND NOT active = TRUE;')" '"rows":[[2]]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE NOT (price = 7) ORDER BY id;')" '"rows":[[1]]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE id IN (1, 3, NULL) ORDER BY id;')" '"rows":[[1],[3]]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE id NOT IN (1, NULL);')" '"rows":[]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE price BETWEEN 7 AND 12.5 ORDER BY id;')" '"rows":[[1],[2]]'
contains "$(run "USE kho; SELECT id FROM sp WHERE name LIKE 'C_ %' ORDER BY id;")" '"rows":[[1],[3]]'
contains "$(run "USE kho; SELECT id FROM sp WHERE name NOT LIKE '%cao' AND id < price ORDER BY id;")" '"rows":[[1],[2]]'
contains "$(run 'USE kho; SELECT DISTINCT active FROM sp ORDER BY active;')" '"rows":[[0],[1]]'
contains "$(run 'USE kho; SELECT id FROM sp ORDER BY active DESC, id DESC LIMIT 2 OFFSET 1;')" '"rows":[[1],[2]]'
contains "$(run 'USE kho; SELECT COUNT(price), SUM(price), AVG(price), MIN(price), MAX(price) FROM sp;')" '"rows":[[2,19.5,9.75,7,12.5]]'
contains "$(run 'USE kho; SELECT COUNT(*), SUM(price), AVG(price), MIN(price), MAX(price) FROM sp WHERE id = 99;')" '"rows":[[0,null,null,null,null]]'
contains "$(run 'USE kho; SELECT active, COUNT(*) AS n FROM sp GROUP BY active HAVING n > 1 ORDER BY n DESC;')" '"rows":[[1,2]]'
contains "$(run 'USE kho; SELECT active, COUNT(*) AS n FROM sp GROUP BY active ORDER BY active;')" '"rows":[[0,1],[1,2]]'
contains "$(run 'USE kho; SELECT active, note, COUNT(*) AS n FROM sp GROUP BY active, note ORDER BY active, note;')" '"rows":[[0,"a",1],[1,null,2]]'
contains "$(run 'USE kho; SELECT DISTINCT note FROM sp ORDER BY note;')" '"rows":[[null],["a"]]'
contains "$(run 'USE kho; SELECT MIN(name), MAX(name) FROM sp;')" '"rows":[["Ca cao","O'\''Brien; trà"]]'
contains "$(run 'USE kho; SELECT SUM(price), AVG(price) FROM sp WHERE price IS NULL;')" '"rows":[[null,null]]'
contains "$(run 'USE kho; SELECT id FROM sp ORDER BY id LIMIT 0;')" '"rows":[]'
contains "$(run 'USE kho; SELECT id FROM sp ORDER BY id LIMIT 10 OFFSET 99;')" '"rows":[]'
contains "$(run 'USE kho; SELECT id FROM sp WHERE active = TRUE LIMIT 1 OFFSET 1;')" '"rows":[[3]]'
contains "$(run 'USE kho; SELECT id FROM sp LIMIT 0;')" '"rows":[]'
contains "$(run 'USE kho; SELECT id FROM sp LIMIT 1 OFFSET 99;')" '"rows":[]'
contains "$(run 'USE kho; SELECT DISTINCT active FROM sp LIMIT 2;')" '"rows":[[1],[0]]'

fails 'USE kho; SELECT SUM(name) FROM sp;' 'SUM/AVG cần cột số'
fails 'USE kho; SELECT id, COUNT(*) FROM sp;' 'GROUP BY'
fails 'USE kho; SELECT id FROM sp WHERE id = 1 OR unknown = 2;' 'không tìm thấy'
fails 'USE kho; SELECT id FROM sp WHERE id IN ();' 'SQL:'
run "USE kho; CREATE TABLE tags (pid INT, label TEXT); INSERT INTO tags VALUES (1, 'a'), (1, 'b'), (2, 'c'), (NULL, 'd');" >/dev/null
contains "$(run 'USE kho; SELECT s.id, t.label FROM sp AS s LEFT JOIN tags AS t ON t.pid = s.id ORDER BY s.id, t.label;')" '"rows":[[1,"a"],[1,"b"],[2,"c"],[3,null]]'
contains "$(run 'USE kho; SELECT s.id, t.label FROM sp AS s INNER JOIN tags AS t ON s.id = t.pid WHERE s.id IN (1,2) ORDER BY s.id, t.label;')" '"rows":[[1,"a"],[1,"b"],[2,"c"]]'
contains "$(run 'USE kho; SELECT s.id, COUNT(t.label) AS n FROM sp AS s LEFT JOIN tags AS t ON s.id = t.pid GROUP BY s.id ORDER BY s.id;')" '"rows":[[1,2],[2,1],[3,0]]'
contains "$(run 'USE kho; SELECT s.id, t.label, u.label FROM sp AS s JOIN tags AS t ON s.id = t.pid JOIN tags AS u ON t.pid = u.pid ORDER BY s.id, t.label, u.label;')" '"rows":[[1,"a","a"],[1,"a","b"],[1,"b","a"],[1,"b","b"],[2,"c","c"]]'
contains "$(run 'USE kho; SELECT t.pid, u.label FROM tags AS t LEFT JOIN tags AS u ON t.pid = u.pid WHERE t.pid IS NULL;')" '"rows":[[null,null]]'
fails 'USE kho; SELECT pid FROM tags AS t JOIN tags AS u ON t.pid = u.pid;' 'cột mơ hồ'
fails 'USE kho; SELECT * FROM tags AS t JOIN tags AS t ON t.pid = t.pid;' 'trùng bí danh'
run 'USE kho; CREATE TABLE empty_tags (pid INT);' >/dev/null
contains "$(run 'USE kho; SELECT s.id, e.pid FROM sp AS s LEFT JOIN empty_tags AS e ON s.id = e.pid ORDER BY s.id;')" '"rows":[[1,null],[2,null],[3,null]]'
fails 'USE kho; SELECT unknown FROM empty_tags;' 'không tìm thấy'
run 'USE kho; DROP TABLE empty_tags;' >/dev/null
contains "$(run "USE kho; UPDATE tags SET label = 'z' WHERE pid = 2 OR label = 'a'; DELETE FROM tags WHERE pid IS NULL OR (pid = 1 AND label = 'b'); SELECT pid,label FROM tags ORDER BY pid;")" '"rows":[[1,"z"],[2,"z"]]'
run 'USE kho; DROP TABLE tags;' >/dev/null
# Hash operators: integer/real equality, signed zero, collisions, NULL and stable order.
out=$(run "USE kho; CREATE TABLE hash_int (id INT); CREATE TABLE hash_real (id REAL, label TEXT); INSERT INTO hash_int VALUES (7), (0), (-2147483648), (2147483647), (NULL), (99); INSERT INTO hash_real VALUES (7.0, 'first'), (7, 'second'), (-0.0, 'zero'), (-2147483648.0, 'min'), (2147483647.0, 'max'), (NULL, 'null'), (7.5, 'fraction'); SELECT i.id, r.label FROM hash_int AS i LEFT JOIN hash_real AS r ON i.id = r.id;")
contains "$out" '"rows":[[7,"first"],[7,"second"],[0,"zero"],[-2147483648,"min"],[2147483647,"max"],[null,null],[99,null]]'
contains "$(run 'USE kho; SELECT COUNT(*) FROM hash_int AS i JOIN hash_real AS r ON i.id = r.id;')" '"rows":[[5]]'
out=$(run "USE kho; CREATE TABLE hash_text (v TEXT, n REAL); INSERT INTO hash_text VALUES ('a', 7), ('r', 7.0), ('a', 7.0), ('r', 7.5), ('Cà phê', -0.0), ('Cà phê', 0), (NULL, NULL), (NULL, NULL), ('', 0), ('a', 7.5); SELECT v, COUNT(*) AS c FROM hash_text GROUP BY v; SELECT COUNT(*) FROM hash_text AS a JOIN hash_text AS b ON a.v = b.v; SELECT DISTINCT v FROM hash_text; SELECT v, n, COUNT(*) AS c FROM hash_text GROUP BY v, n; SELECT DISTINCT v,n FROM hash_text;")
contains "$out" '"rows":[["a",3],["r",2],["Cà phê",2],[null,2],["",1]]'
contains "$out" '"rows":[[18]]'
contains "$out" '"rows":[["a"],["r"],["Cà phê"],[null],[""]]'
contains "$out" '"rows":[["a",7,2],["r",7.0,1],["r",7.5,1],["Cà phê",-0.0,2],[null,null,2],["",0,1],["a",7.5,1]]'
contains "$out" '"rows":[["a",7],["r",7.0],["r",7.5],["Cà phê",-0.0],[null,null],["",0],["a",7.5]]'
contains "$(run 'USE kho; SELECT COUNT(*) FROM hash_text AS a JOIN hash_text AS b ON a.v = b.v;')" '"rows":[[18]]'
contains "$(run 'USE kho; EXPLAIN SELECT i.id FROM hash_int AS i LEFT JOIN hash_real AS r ON i.id = r.id;')" 'HASH_JOIN'
contains "$(run 'USE kho; EXPLAIN SELECT a.v FROM hash_text AS a JOIN hash_text AS b ON a.v = b.v;')" 'HASH_JOIN'
run 'USE kho; DROP TABLE hash_int; DROP TABLE hash_real; DROP TABLE hash_text;' >/dev/null
contains "$(run 'SHOW DATABASES; USE kho; SHOW TABLES; DESC sp;')" '"rows":[["SP"]]'
# Schema metadata consumed by Navigator and the visual table designer.
out=$(run 'USE kho; DESCRIBE sp;')
contains "$out" '"columns":["NAME","TYPE","LIMIT","NOT_NULL","UNIQUE","PRIMARY_KEY"]'
contains "$out" '["ID","INT",0,1,1,1]'
contains "$out" '["NAME","VARCHAR",40,1,0,0]'
contains "$out" '["NOTE","TEXT",0,0,1,0]'
out=$(run 'USE kho; CREATE TABLE designer_test (id INT PRIMARY KEY, quantity INTEGER, price REAL UNIQUE, note TEXT, name VARCHAR(100) NOT NULL, active BOOLEAN); DESCRIBE designer_test;')
contains "$out" '["QUANTITY","INTEGER",0,0,0,0]'
contains "$out" '["PRICE","REAL",0,0,1,0]'
contains "$out" '["NAME","VARCHAR",100,1,0,0]'
contains "$out" '["ACTIVE","BOOLEAN",0,0,0,0]'
fails 'USE kho; CREATE TABLE invalid (id INT, ID TEXT);' 'trùng tên cột'
fails 'USE kho; CREATE TABLE invalid (id INT PRIMARY KEY, other INT PRIMARY KEY);' 'một cột PRIMARY KEY'
fails 'USE kho; CREATE TABLE invalid (id VARCHAR(0));' 'VARCHAR cần độ dài nguyên dương'
run 'USE kho; DROP TABLE designer_test;' >/dev/null
contains "$(run 'USE kho; SHOW TABLES;')" '"rows":[["SP"]]'

contains "$(run "USE kho; UPDATE sp SET price = 8 WHERE id = 2; DELETE FROM sp WHERE id = 3; SELECT COUNT(*) FROM sp;")" '"rows":[[2]]'
contains "$(run "USE kho; BEGIN; UPDATE sp SET price = 999 WHERE id = 1; ROLLBACK; SELECT price FROM sp WHERE id = 1;")" '"rows":[[12.5]]'
contains "$(run "USE kho; BEGIN; UPDATE sp SET price = 15 WHERE id = 1; COMMIT;")" '"affected_rows":1'
contains "$(run 'USE kho; SELECT price FROM sp WHERE id = 1;')" '"rows":[[15]]'
fails "USE kho; INSERT INTO sp (id, name) VALUES (1, 'dup');" 'trùng UNIQUE'
fails "USE kho; INSERT INTO sp (id, name) VALUES (4, NULL);" 'NOT NULL'
fails "USE kho; INSERT INTO sp (id, name) VALUES ('bad', 'x');" 'sai kiểu'
fails "USE kho; INSERT INTO sp (id, name) VALUES (4, 'ok'), (1, 'bad');" 'trùng UNIQUE'
fails "USE kho; UPDATE sp SET id = 1 WHERE id = 2;" 'trùng UNIQUE'
fails "USE kho; SELECT id FROM sp WHERE unknown = 1;" 'không tìm thấy'
fails "USE kho; DELETE FROM sp; SELECT * FROM unknown;" 'không tìm thấy'
fails "USE kho; DELETE FROM sp; garbage;" 'chưa hỗ trợ'
fails "USE kho; BEGIN; DELETE FROM sp;" 'chưa COMMIT'
fails "USE kho; SELECT * FROM sp WHERE id = 99999999999;" 'INT vượt giới hạn'
contains "$(run 'USE kho; SELECT COUNT(*) FROM sp;')" '"rows":[[2]]'
# Syntax validation and guarded grid writes never publish a failed batch.
validate() { "$root/vdb" --db "$db" --existing --validate -e "$1"; }
guard() { "$root/vdb" --db "$db" --existing --guard-writes -e "$1"; }
cp "$db" "$work/before"
contains "$(validate "USE kho; DELETE FROM sp;")" '"valid":1'
contains "$(validate 'SELECT * FROM unknown;')" '"valid":1'
if validate 'SELECT FROM;' > "$work/error" 2>&1; then
    echo 'Invalid SQL accepted' >&2; exit 1
fi
cmp "$db" "$work/before"
contains "$(guard "USE kho; UPDATE sp SET price = 16 WHERE id = 1 AND name = 'Cà phê' AND price = 15.0 AND active = TRUE AND note IS NULL;")" '"affected_rows":1'
cp "$db" "$work/before"
for sql in 'UPDATE sp SET price = 99 WHERE id = 999' 'DELETE FROM sp' 'BEGIN; UPDATE sp SET price = 17 WHERE id = 1; COMMIT; DELETE FROM sp WHERE id = 999' ; do
    if guard "USE kho; $sql;" > "$work/error" 2>&1; then
        echo "Unexpected guarded success: $sql" >&2; exit 1
    fi
    contains "$(cat "$work/error")" 'batch đã hủy'
    cmp "$db" "$work/before"
done
fails "USE kho; INSERT INTO sp (id,name) VALUES (4,'CSV'); INSERT INTO sp (id,name) VALUES (1,'duplicate');" 'trùng UNIQUE'
contains "$(guard "USE kho; DELETE FROM sp WHERE id = 2 AND name = 'O''Brien; trà' AND price = 8.0 AND active = FALSE AND note = 'a';")" '"affected_rows":1'
contains "$(run 'USE kho; SELECT COUNT(*) FROM sp;')" '"rows":[[1]]'
run 'USE kho; DROP TABLE sp;' >/dev/null
contains "$(run 'USE kho; SHOW TABLES;')" '"rows":[]'
# Explicit open/create modes used by Studio must never silently create or replace data.
second="$work/second.json"
if "$root/vdb" --db "$second" --existing -e 'SHOW DATABASES;' > "$work/error" 2>&1; then
    echo 'Unexpected success opening missing catalog' >&2; exit 1
fi
[ ! -e "$second" ]
"$root/vdb" --db "$second" --new -e "CREATE DATABASE kho; USE kho; CREATE TABLE sp (id INT PRIMARY KEY); INSERT INTO sp VALUES (42);" >/dev/null
cp "$second" "$work/before"
if "$root/vdb" --db "$second" --new -e 'SHOW DATABASES;' > "$work/error" 2>&1; then
    echo 'Unexpected success creating existing catalog' >&2; exit 1
fi
cmp "$second" "$work/before"
contains "$("$root/vdb" --db "$second" --existing -e 'USE kho; SELECT * FROM sp;')" '"rows":[[42]]'
contains "$(run 'USE kho; SHOW TABLES;')" '"rows":[]'
ln "$second" "$work/hardlink.json"
if "$root/vdb" --db "$second" --existing -e 'SHOW DATABASES;' > "$work/error" 2>&1; then
    echo 'Unexpected success opening hard-linked catalog' >&2; exit 1
fi
cmp "$second" "$work/before"
rm "$work/hardlink.json"
ln -s "$second" "$work/symlink.json"
if "$root/vdb" --db "$work/symlink.json" --existing -e 'SHOW DATABASES;' > "$work/error" 2>&1; then
    echo 'Unexpected success opening symbolic link' >&2; exit 1
fi
cmp "$second" "$work/before"
# Physical planning shares SELECT binding and must not read/evaluate data.
run 'CREATE DATABASE phase6; USE phase6; CREATE TABLE a (id INT PRIMARY KEY, label TEXT); CREATE TABLE b (id INT); INSERT INTO a VALUES (1, NULL), (2, NULL); INSERT INTO b VALUES (1);' >/dev/null
cp "$db" "$work/before"
out=$(run 'USE phase6; EXPLAIN SELECT DISTINCT a.id, COUNT(b.id) AS n FROM a LEFT JOIN b ON a.id = b.id WHERE a.id > 0 GROUP BY a.id HAVING n >= 0 ORDER BY n LIMIT 5;')
contains "$out" '"rows":[[1,"TABLE_SCAN","A",2],[2,"TABLE_SCAN","B",1],[3,"NESTED_LOOP_JOIN","LEFT",2.0],[4,"FILTER","",null],[5,"HASH_AGGREGATE","",null],[6,"PROJECT","",null],[7,"HAVING_FILTER","",null],[8,"HASH_DISTINCT","",null],[9,"MERGE_SORT","",null],[10,"LIMIT","",null]]'
contains "$(run 'USE phase6; EXPLAIN SELECT id FROM a WHERE id LIKE 1;')" 'FILTER'
# Multi-JOIN estimates are metadata-only; runtime chooses using actual intermediate rows.
out=$(run 'USE phase6; EXPLAIN SELECT a.id FROM a LEFT JOIN b ON a.id = b.id LEFT JOIN b AS c ON b.id = c.id;')
contains "$out" '[3,"NESTED_LOOP_JOIN","LEFT",2.0]'
contains "$out" '[5,"NESTED_LOOP_JOIN","LEFT",2.0]'
contains "$(run 'USE phase6; SELECT a.id,b.id,c.id FROM a LEFT JOIN b ON a.id = b.id LEFT JOIN b AS c ON b.id = c.id;')" '"rows":[[1,1,1],[2,null,null]]'
out=$(run 'USE phase6; EXPLAIN SELECT a.id FROM a JOIN b ON a.id = b.id JOIN b AS c ON b.id = c.id;')
contains "$out" '[5,"NESTED_LOOP_JOIN","INNER",2.0]'
contains "$(run 'USE phase6; SELECT COUNT(*) FROM a JOIN b ON a.id = b.id JOIN b AS c ON b.id = c.id;')" '"rows":[[1]]'


cmp "$db" "$work/before"
fails 'USE phase6; EXPLAIN SELECT missing FROM a;' 'không tìm thấy'
fails 'USE phase6; EXPLAIN SELECT id, COUNT(*) FROM a;' 'GROUP BY'
fails 'USE phase6; EXPLAIN DELETE FROM a;' 'SQL:'
run 'USE phase6; ALTER TABLE a ADD COLUMN price REAL; ALTER TABLE a RENAME COLUMN label TO name; ALTER TABLE a RENAME TO items;' >/dev/null
contains "$(run 'USE phase6; SELECT * FROM items ORDER BY id;')" '"rows":[[1,null,null],[2,null,null]]'
fails 'USE phase6; ALTER TABLE items ADD COLUMN id INT;' 'trùng'
fails 'USE phase6; ALTER TABLE items ADD COLUMN required TEXT NOT NULL;' 'NOT NULL'
fails 'USE phase6; ALTER TABLE items ADD COLUMN second_id INT PRIMARY KEY;' 'PRIMARY KEY'
fails 'USE phase6; ALTER TABLE items RENAME TO b;' 'tồn tại'
run 'USE phase6; UPDATE items SET price = 3.5 WHERE id = 1; ALTER TABLE items DROP COLUMN name;' >/dev/null
contains "$(run 'USE phase6; SELECT * FROM items ORDER BY id;')" '"rows":[[1,3.5],[2,null]]'
fails 'USE phase6; ALTER TABLE b DROP COLUMN id;' 'cột cuối cùng'
cp "$db" "$work/before"
contains "$(run 'USE phase6; BEGIN; ALTER TABLE items ADD COLUMN extra TEXT; ROLLBACK; SELECT * FROM items ORDER BY id;')" '"rows":[[1,3.5],[2,null]]'
cmp "$db" "$work/before"
contains "$(run 'USE phase6; BEGIN; DROP DATABASE phase6; ROLLBACK; SELECT * FROM items ORDER BY id;')" '"rows":[[1,3.5],[2,null]]'
cmp "$db" "$work/before"
fails 'DROP DATABASE DEFAULT;' 'DEFAULT'
fails 'DROP DATABASE missing;' 'không tìm thấy'
contains "$(run 'USE phase6; DROP DATABASE phase6; SHOW TABLES;')" '"rows":[]'
fails 'USE phase6;' 'không tìm thấy'
# B+ tree: multiple levels, duplicate keys across leaves, NULL and stable row order.
values=$(python3 - <<'SQL'
print(', '.join(f"({i}, {('NULL' if i == 320 else 7 if i <= 35 else i)}, 'k{i:03d}')" for i in range(1,321)))
SQL
)
run "CREATE DATABASE idx; USE idx; CREATE TABLE items (id INT, k INT, label TEXT); INSERT INTO items VALUES $values;" >/dev/null
before=$(run 'USE idx; SELECT id FROM items WHERE k = 7;')
# Compare all supported range shapes with the original full scan.
range_results() {
    for predicate in 'k < 7' 'k <= 7' 'k > 310' 'k >= 310' '310 < k' '310 >= k' 'k BETWEEN 7 AND 36' 'k BETWEEN 36 AND 7' 'k BETWEEN 1000 AND 1001' 'k BETWEEN 310 AND 400' "label BETWEEN 'k010' AND 'k020'" 'k >= NULL' 'k > 310.0'; do
        run "USE idx; SELECT id FROM items WHERE $predicate;"
    done
}
range_results > "$work/ranges-before"
run 'USE idx; CREATE INDEX ix_k ON items (k); CREATE INDEX ix_label ON items (label);' >/dev/null
contains "$(run 'USE idx; SHOW INDEXES FROM items;')" '["IX_K","K",319,285,3,0]'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM items WHERE k = 7;')" 'INDEX_SCAN'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM items WHERE id = 7;')" 'TABLE_SCAN'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM items WHERE k > 7;')" 'TABLE_SCAN'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM items WHERE k BETWEEN 7 AND 36;')" '[1,"INDEX_RANGE_SCAN","IX_K",36]'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM items WHERE 310 < k;')" '[1,"INDEX_RANGE_SCAN","IX_K",9]'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM items WHERE k >= NULL;')" 'TABLE_SCAN'
range_results > "$work/ranges-after"
cmp "$work/ranges-before" "$work/ranges-after"
[ "$before" = "$(run 'USE idx; SELECT id FROM items WHERE k = 7;')" ]
contains "$(run 'USE idx; SELECT id FROM items WHERE 300 = k;')" '"rows":[[300]]'
contains "$(run "USE idx; SELECT id FROM items WHERE label = 'k300';")" '"rows":[[300]]'
contains "$(run 'USE idx; SELECT id FROM items WHERE k = 1000;')" '"rows":[]'
contains "$(run 'USE idx; SELECT id FROM items WHERE k IS NULL;')" '"rows":[[320]]'
fails 'USE idx; CREATE INDEX ix_k ON items (id);' 'index đã tồn tại'
fails 'USE idx; ALTER TABLE items DROP COLUMN k;' 'DROP INDEX'
run "USE idx; INSERT INTO items VALUES (321, 7, 'new'); UPDATE items SET k = 999 WHERE id = 300; DELETE FROM items WHERE id = 1; ALTER TABLE items RENAME COLUMN k TO key_new;" >/dev/null
contains "$(run 'USE idx; SELECT id FROM items WHERE key_new = 999;')" '"rows":[[300]]'
contains "$(run 'USE idx; SELECT COUNT(*) FROM items WHERE key_new = 7;')" '"rows":[[35]]'
# Range candidates must preserve original row order, including with LIMIT.
contains "$(run 'USE idx; SELECT id FROM items WHERE key_new >= 318 LIMIT 3;')" '"rows":[[300],[318],[319]]'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM items WHERE key_new >= 318;')" 'INDEX_RANGE_SCAN'
contains "$(run 'USE idx; SELECT id FROM items WHERE key_new BETWEEN 7 AND 7 ORDER BY id DESC LIMIT 2;')" '"rows":[[321],[35]]' 
contains "$(run 'USE idx; SHOW INDEX FROM items;')" '["IX_K","KEY_NEW"'
cp "$db" "$work/before"
contains "$(run 'USE idx; BEGIN; UPDATE items SET key_new = 1000 WHERE id = 300; ROLLBACK; SELECT id FROM items WHERE key_new = 999;')" '"rows":[[300]]'
cmp "$db" "$work/before"
run 'USE idx; DROP INDEX ix_k ON items; ALTER TABLE items DROP COLUMN key_new;' >/dev/null
contains "$(run 'USE idx; SHOW INDEX FROM items;')" 'IX_LABEL'
contains "$(run "USE idx; SELECT id FROM items WHERE label = 'k300';")" '"rows":[[300]]'
# Join selection: small relations use nested loop, larger ones use hash.
run 'USE idx; CREATE TABLE small_a (id INT); CREATE TABLE small_b (id INT); INSERT INTO small_a VALUES (7),(NULL),(8); INSERT INTO small_b VALUES (7),(7),(NULL);' >/dev/null
contains "$(run 'USE idx; EXPLAIN SELECT small_a.id, small_b.id FROM small_a LEFT JOIN small_b ON small_a.id = small_b.id;')" 'NESTED_LOOP_JOIN'
contains "$(run 'USE idx; SELECT small_a.id, small_b.id FROM small_a LEFT JOIN small_b ON small_a.id = small_b.id;')" '"rows":[[7,7],[7,7],[null,null],[8,null]]'
contains "$(run 'USE idx; SELECT small_a.id, small_b.id FROM small_a INNER JOIN small_b ON small_a.id = small_b.id;')" '"rows":[[7,7],[7,7]]'
contains "$(run 'USE idx; EXPLAIN SELECT a.id FROM items AS a JOIN items AS b ON a.id = b.id;')" 'HASH_JOIN'
contains "$(run 'USE idx; SELECT COUNT(*) FROM items AS a JOIN items AS b ON a.id = b.id;')" '"rows":[[320]]'
run 'USE idx; DELETE FROM small_b;' >/dev/null
contains "$(run 'USE idx; SELECT small_a.id, small_b.id FROM small_a LEFT JOIN small_b ON small_a.id = small_b.id;')" '"rows":[[7,null],[null,null],[8,null]]'
# Empty and all-NULL trees must return safe empty bounds.
run 'USE idx; CREATE TABLE empty_idx (k INT); CREATE INDEX ix_empty ON empty_idx (k);' >/dev/null
contains "$(run 'USE idx; SELECT k FROM empty_idx WHERE k >= 0;')" '"rows":[]'
null_values=$(python3 -c "print(','.join(['(NULL)'] * 20))")
run "USE idx; INSERT INTO empty_idx VALUES $null_values;" >/dev/null
contains "$(run 'USE idx; SHOW INDEX FROM empty_idx;')" '["IX_EMPTY","K",0,0,1,0]'
contains "$(run 'USE idx; EXPLAIN SELECT k FROM empty_idx WHERE k >= 0;')" '[1,"INDEX_RANGE_SCAN","IX_EMPTY",0]'
contains "$(run 'USE idx; SELECT k FROM empty_idx WHERE k >= 0;')" '"rows":[]'
contains "$(run 'USE idx; SELECT COUNT(*) FROM empty_idx WHERE k IS NULL;')" '"rows":[[20]]'
# Unicode range results must match full scan even at leaf boundaries.
unicode_values=$(python3 - <<'SQL'
print(','.join(f"({i}, 'Trà {i:02d}')" for i in range(1,41)))
SQL
)
run "USE idx; CREATE TABLE unicode_idx (id INT, k TEXT); INSERT INTO unicode_idx VALUES $unicode_values;" >/dev/null
unicode_sql="USE idx; SELECT id FROM unicode_idx WHERE k BETWEEN 'Trà 16' AND 'Trà 17';"
before=$(run "$unicode_sql")
run 'USE idx; CREATE INDEX ix_unicode ON unicode_idx (k);' >/dev/null
contains "$(run "USE idx; EXPLAIN SELECT id FROM unicode_idx WHERE k BETWEEN 'Trà 16' AND 'Trà 17';")" '[1,"INDEX_RANGE_SCAN","IX_UNICODE",2]'
[ "$before" = "$(run "$unicode_sql")" ]
contains "$before" '"rows":[[16],[17]]'
# Compound bounds, composite prefixes, NULL suffixes and indexed joins.
compound_values=$(python3 - <<'SQL'
print(','.join(f"({i},{i % 20},{'NULL' if i % 9 == 0 else chr(39) + 'Trà %03d' % i + chr(39)})" for i in range(1,321)))
SQL
)
run "USE idx; CREATE TABLE compound (id INT, a INT, b TEXT); INSERT INTO compound VALUES $compound_values; INSERT INTO compound VALUES (321,NULL,'other'); CREATE TABLE probes (a INT); INSERT INTO probes VALUES (7),(NULL),(99);" >/dev/null
compound_results() {
    for predicate in 'a = 7' "a = 7 AND b >= 'Trà 100' AND b < 'Trà 200'" "a = 7 AND 'Trà 100' <= b" 'a >= 7 AND a <= 7' 'a = 7 AND a = 8' 'a > 7 AND a < 7' 'a = 7 AND (b IS NULL OR id > 300)' 'a = 7 AND NOT (id < 100)' 'a = 7 OR a = 8' "b = 'Trà 107'" "a = 7 AND b BETWEEN 'Trà 100' AND 'Trà 200'" 'a = 7 AND b IS NULL' 'a < 1' 'a = 7.0'; do
        run "USE idx; SELECT id FROM compound WHERE $predicate LIMIT 50;"
    done
}
compound_results > "$work/compound-before"
join_sql='USE idx; SELECT p.a, c.id FROM probes AS p LEFT JOIN compound AS c ON p.a = c.a;'
join_before=$(run "$join_sql")
inner_sql='USE idx; SELECT p.a, c.id FROM probes AS p INNER JOIN compound AS c ON p.a = c.a;'
inner_before=$(run "$inner_sql")
run 'USE idx; CREATE INDEX ix_ab ON compound (a,b);' >/dev/null
contains "$(run 'USE idx; SHOW INDEX FROM compound;')" '["IX_AB","A,B",321,'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM compound WHERE a = 7;')" '[1,"INDEX_RANGE_SCAN","IX_AB",16]'
contains "$(run "USE idx; EXPLAIN SELECT id FROM compound WHERE a = 7 AND b >= 'Trà 100' AND b < 'Trà 200';")" 'INDEX_RANGE_SCAN'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM compound WHERE a = 7 AND a = 8;')" '[1,"INDEX_RANGE_SCAN","IX_AB",0]'
contains "$(run "USE idx; EXPLAIN SELECT id FROM compound WHERE b = 'Trà 107';")" 'TABLE_SCAN'
contains "$(run 'USE idx; EXPLAIN SELECT id FROM compound WHERE a = 7 OR a = 8;')" 'TABLE_SCAN'
compound_results > "$work/compound-after"
cmp "$work/compound-before" "$work/compound-after"
contains "$(run 'USE idx; EXPLAIN SELECT p.a, c.id FROM probes AS p LEFT JOIN compound AS c ON p.a = c.a;')" 'INDEX_NESTED_LOOP_JOIN'
run 'USE idx; CREATE TABLE join_seed (a INT UNIQUE); INSERT INTO join_seed VALUES (7);' >/dev/null
out=$(run 'USE idx; EXPLAIN SELECT p.a,c.id FROM probes AS p JOIN join_seed AS s ON p.a = s.a JOIN compound AS c ON s.a = c.a;')
contains "$out" 'INDEX_NESTED_LOOP_JOIN'
contains "$(run 'USE idx; SELECT COUNT(*) FROM probes AS p JOIN join_seed AS s ON p.a = s.a JOIN compound AS c ON s.a = c.a;')" '"rows":[[16]]'
contains "$(run 'USE idx; SELECT COUNT(*) FROM probes AS p JOIN join_seed AS s ON p.a = s.a JOIN join_seed AS t ON s.a = t.a;')" '"rows":[[1]]'

[ "$join_before" = "$(run "$join_sql")" ]
[ "$inner_before" = "$(run "$inner_sql")" ]
fails 'USE idx; CREATE INDEX ix_dup ON compound (a,a);' 'trùng tên cột'
fails 'USE idx; ALTER TABLE compound DROP COLUMN b;' 'DROP INDEX'
run "USE idx; ALTER TABLE compound RENAME COLUMN b TO label; INSERT INTO compound VALUES (322,7,NULL); UPDATE compound SET a = 7 WHERE id = 321; DELETE FROM compound WHERE id = 7;" >/dev/null
contains "$(run 'USE idx; SHOW INDEX FROM compound;')" '["IX_AB","A,LABEL",321,'
contains "$(run 'USE idx; SELECT COUNT(*) FROM compound WHERE a = 7;')" '"rows":[[17]]'
cp "$db" "$work/before"
run 'USE idx; BEGIN; UPDATE compound SET a = 99 WHERE a = 7; ROLLBACK;' >/dev/null
cmp "$db" "$work/before"
run 'USE idx; DROP INDEX ix_ab ON compound; CREATE INDEX ix_a ON compound (a);' >/dev/null
contains "$(run 'USE idx; EXPLAIN SELECT id FROM compound WHERE a >= 7 AND a <= 7;')" 'INDEX_RANGE_SCAN'
contains "$(run 'USE idx; EXPLAIN SELECT p.a, c.id FROM probes AS p LEFT JOIN compound AS c ON p.a = c.a;')" 'INDEX_NESTED_LOOP_JOIN'
# Older catalogs contain only the scalar column name and cardinality.
python3 - "$db" <<'PYOLD'
import json, sys
p = sys.argv[1]
with open(p) as f: data = json.load(f)
def visit(v):
    if isinstance(v, dict):
        if v.get('name') == 'IX_A':
            v.pop('index_columns', None)
            v.pop('prefix_cardinality', None)
            v.pop('unique', None)
            for node in v['nodes']: node.pop('count', None)
        for child in v.values(): visit(child)
    elif isinstance(v, list):
        for child in v: visit(child)
visit(data)
with open(p, 'w') as f: json.dump(data, f, ensure_ascii=False)
PYOLD
contains "$(run 'USE idx; SELECT COUNT(*) FROM compound WHERE a = 7;')" '"rows":[[17]]'
contains "$(run 'USE idx; EXPLAIN SELECT p.a, c.id FROM probes AS p LEFT JOIN compound AS c ON p.a = c.a;')" 'INDEX_NESTED_LOOP_JOIN'
# Exercise each mutation as the first write to a legacy catalog.
cp "$db" "$work/legacy-index"
run 'USE idx; UPDATE compound SET a = 8 WHERE id = 322;' >/dev/null
contains "$(run 'USE idx; SELECT COUNT(*) FROM compound WHERE a = 7;')" '"rows":[[16]]'
cp "$work/legacy-index" "$db"
run 'USE idx; DELETE FROM compound WHERE id = 322;' >/dev/null
contains "$(run 'USE idx; SELECT COUNT(*) FROM compound WHERE a = 7;')" '"rows":[[16]]'
cp "$work/legacy-index" "$db"
run 'USE idx; INSERT INTO compound VALUES (323,7,NULL);' >/dev/null
contains "$(run 'USE idx; SELECT COUNT(*) FROM compound WHERE a = 7;')" '"rows":[[18]]'
run 'USE idx; UPDATE compound SET a = 8 WHERE id = 322; DELETE FROM compound WHERE id = 323;' >/dev/null
contains "$(run 'USE idx; SELECT COUNT(*) FROM compound WHERE a = 7;')" '"rows":[[16]]'
# Unique composite indexes permit NULL components and reject duplicate full keys.
run "USE idx; CREATE TABLE unique_idx (id INT PRIMARY KEY, a INT, b TEXT); INSERT INTO unique_idx VALUES (1,1,'a'),(2,1,'b'),(3,1,NULL),(4,1,NULL); CREATE UNIQUE INDEX ux_ab ON unique_idx (a,b);" >/dev/null
contains "$(run 'USE idx; SHOW INDEX FROM unique_idx;')" '["UX_AB","A,B",4,3,1,1]'
fails "USE idx; INSERT INTO unique_idx VALUES (5,1,'a');" 'UX_AB'
fails "USE idx; UPDATE unique_idx SET b = 'a' WHERE id = 2;" 'UX_AB'
fails 'USE idx; CREATE UNIQUE INDEX ux_a ON unique_idx (a);' 'UX_A'
run "USE idx; ALTER TABLE unique_idx RENAME COLUMN b TO label; DELETE FROM unique_idx WHERE id = 1; INSERT INTO unique_idx VALUES (5,1,'a');" >/dev/null
fails "USE idx; INSERT INTO unique_idx VALUES (6,1,'a');" 'UX_AB'
cp "$db" "$work/before"
run 'USE idx; BEGIN; DROP INDEX ux_ab ON unique_idx; ROLLBACK;' >/dev/null
cmp "$db" "$work/before"
fails "USE idx; INSERT INTO unique_idx VALUES (6,1,'a');" 'UX_AB'
run 'USE idx; DROP INDEX ux_ab ON unique_idx; CREATE INDEX ix_ab ON unique_idx (a,label);' >/dev/null
run "USE idx; INSERT INTO unique_idx VALUES (6,1,'a');" >/dev/null
fails 'USE idx; CREATE UNIQUE INDEX ux_ab ON unique_idx (a,label);' 'UX_AB'
run 'USE idx; CREATE TABLE single_unique (k INT); CREATE UNIQUE INDEX ux_k ON single_unique (k); INSERT INTO single_unique VALUES (NULL),(NULL),(1);' >/dev/null
fails 'USE idx; INSERT INTO single_unique VALUES (1);' 'UX_K'
# Incremental pages: insert into empty indexes, split leaves and internal nodes,
# verify prefix counts, leaf links, rank queries and statement rollback.
run 'USE idx; CREATE TABLE page_idx (id INT, a INT, b TEXT); CREATE INDEX ix_page_a ON page_idx (a); CREATE UNIQUE INDEX ux_page_ab ON page_idx (a,b); CREATE TABLE page_scan (id INT, a INT, b TEXT);' >/dev/null
for batch in 0 1 2 3; do
    page_values=$(python3 - "$batch" <<'PYPAGE'
import sys
start = int(sys.argv[1]) * 100
print(','.join(f"({i},{'NULL' if i % 17 == 0 else (399-i)*37%23},{'NULL' if i % 7 == 0 else repr('Trà %03d' % i)})" for i in range(start, start+100)))
PYPAGE
)
    run "USE idx; INSERT INTO page_idx VALUES $page_values; INSERT INTO page_scan VALUES $page_values;" >/dev/null
done
for predicate in 'a = 7' 'a BETWEEN 3 AND 5' 'a < 2' 'a > 20' 'a > 99' 'a IS NULL' "a = 7 AND b BETWEEN 'Trà 010' AND 'Trà 300'" 'a = 7 AND b IS NULL' 'a = 0 AND a = 1'; do
    [ "$(run "USE idx; SELECT id FROM page_idx WHERE $predicate LIMIT 50;")" = "$(run "USE idx; SELECT id FROM page_scan WHERE $predicate LIMIT 50;")" ]
done
contains "$(run 'USE idx; EXPLAIN SELECT id FROM page_idx WHERE a BETWEEN 3 AND 5;')" 'INDEX_RANGE_SCAN'
check_page_tree() {
python3 - "$db" "$1" <<'PYTREE'
import json, sys
with open(sys.argv[1]) as f: catalog = json.load(f)
def tables(v):
    if isinstance(v, dict):
        if v.get('name') == 'PAGE_IDX' and 'rows' in v: yield v
        for child in v.values(): yield from tables(child)
    elif isinstance(v, list):
        for child in v: yield from tables(child)
table, = tables(catalog)
for tree in table['indexes']:
    nodes = tree['nodes']
    columns = tree['index_columns']
    single = len(columns) == 1
    visited, leaves = set(), []
    def order(key):
        return tuple((v is not None, v) for v in ([key] if single else key))
    def walk(i, depth):
        assert i not in visited
        visited.add(i)
        n = nodes[i]
        keys, children = n['key'], n['children']
        assert len(keys) == len(children) <= 16
        assert keys or (i == tree['root'] and n['leaf'])
        assert list(map(order, keys)) == sorted(map(order, keys))
        if n['leaf']:
            assert depth == tree['height'] and n['count'] == len(keys)
            leaves.append(i)
            return list(zip(keys, children))
        entries = []
        for key, child in zip(keys, children):
            part = walk(child, depth+1)
            assert key == part[-1][0]
            entries.extend(part)
        assert n['count'] == len(entries)
        return entries
    entries = walk(tree['root'], 1)
    assert len(visited) == len(nodes) and tree['height'] >= int(sys.argv[2])
    assert len(entries) == tree['count']
    assert [nodes[i]['next'] for i in leaves] == leaves[1:] + [-1]
    expected = []
    for i, row in enumerate(table['rows']):
        key = row[1] if single else row[1:3]
        if not single or key is not None: expected.append((key, i))
    expected.sort(key=lambda e: (order(e[0]), e[1]))
    assert entries == expected
    prefixes = [len({tuple(([k] if single else k)[:j]) for k, _ in entries}) for j in range(1,len(columns)+1)]
    assert tree['prefix_cardinality'] == prefixes and tree['cardinality'] == prefixes[-1]
PYTREE
}
check_page_tree 3
fails "USE idx; INSERT INTO page_idx VALUES (900,7,'new'),(901,7,'new');" 'UX_PAGE_AB'
cp "$db" "$work/before"
run "USE idx; BEGIN; INSERT INTO page_idx VALUES (900,7,'new'); ROLLBACK;" >/dev/null
cmp "$db" "$work/before"
# Incremental UPDATE/DELETE: move keys across leaves, keep duplicate row order,
# update NULL prefixes, compact physical row positions and collapse empty roots.
run "USE idx; UPDATE page_idx SET a = 7 WHERE id < 50; UPDATE page_scan SET a = 7 WHERE id < 50; UPDATE page_idx SET b = NULL WHERE id BETWEEN 30 AND 80; UPDATE page_scan SET b = NULL WHERE id BETWEEN 30 AND 80; UPDATE page_idx SET a = NULL WHERE id BETWEEN 100 AND 125; UPDATE page_scan SET a = NULL WHERE id BETWEEN 100 AND 125;" >/dev/null
check_page_tree 1
for predicate in 'a = 7' 'a BETWEEN 3 AND 5' 'a IS NULL' 'a = 7 AND b IS NULL' "a = 7 AND b BETWEEN 'Trà 010' AND 'Trà 300'"; do
    [ "$(run "USE idx; SELECT id FROM page_idx WHERE $predicate LIMIT 100;")" = "$(run "USE idx; SELECT id FROM page_scan WHERE $predicate LIMIT 100;")" ]
done
fails "USE idx; UPDATE page_idx SET a = 99, b = 'duplicate' WHERE id BETWEEN 1 AND 2;" 'UX_PAGE_AB'
cp "$db" "$work/before"
run 'USE idx; BEGIN; DELETE FROM page_idx WHERE id < 300; UPDATE page_idx SET a = 100; ROLLBACK;' >/dev/null
cmp "$db" "$work/before"
run 'USE idx; DELETE FROM page_idx WHERE id < 350; DELETE FROM page_scan WHERE id < 350;' >/dev/null
check_page_tree 1
for predicate in 'a = 7' 'a BETWEEN 3 AND 20' 'a IS NULL' 'a > 20'; do
    [ "$(run "USE idx; SELECT id FROM page_idx WHERE $predicate;")" = "$(run "USE idx; SELECT id FROM page_scan WHERE $predicate;")" ]
done
run 'USE idx; DELETE FROM page_idx; DELETE FROM page_scan;' >/dev/null
check_page_tree 1
run "USE idx; INSERT INTO page_idx VALUES (1,7,'a'),(2,7,NULL),(3,NULL,'b'); INSERT INTO page_scan VALUES (1,7,'a'),(2,7,NULL),(3,NULL,'b'); UPDATE page_idx SET a = 7 WHERE id = 3; UPDATE page_scan SET a = 7 WHERE id = 3;" >/dev/null
check_page_tree 1
[ "$(run 'USE idx; SELECT id FROM page_idx WHERE a = 7;')" = "$(run 'USE idx; SELECT id FROM page_scan WHERE a = 7;')" ]
# Foreign keys: immediate MATCH SIMPLE and RESTRICT, including schema changes.
run 'CREATE DATABASE fk_test; USE fk_test; CREATE TABLE parent (id INT PRIMARY KEY, code TEXT UNIQUE); CREATE TABLE child (id INT PRIMARY KEY, pid INTEGER REFERENCES parent(id)); INSERT INTO parent VALUES (1, NULL), (2, NULL); INSERT INTO child VALUES (1,1),(2,NULL);' >/dev/null
contains "$(run 'USE fk_test; SHOW FOREIGN KEYS FROM child;')" '["FK_CHILD_PID","PID","PARENT","ID"]'
fails 'USE fk_test; INSERT INTO child VALUES (3,99);' 'FK_CHILD_PID'
fails 'USE fk_test; UPDATE child SET pid = 99 WHERE id = 1;' 'FK_CHILD_PID'
fails 'USE fk_test; UPDATE parent SET id = 3 WHERE id = 1;' 'FK_CHILD_PID'
fails 'USE fk_test; DELETE FROM parent WHERE id = 1;' 'FK_CHILD_PID'
fails 'USE fk_test; DROP TABLE parent;' 'không tìm thấy'
fails 'USE fk_test; ALTER TABLE child DROP COLUMN pid;' 'không tìm thấy'
fails 'USE fk_test; ALTER TABLE parent DROP COLUMN id;' 'không tìm thấy'
fails 'USE fk_test; CREATE TABLE bad (x INT REFERENCES missing(id));' 'không tìm thấy'
fails 'USE fk_test; CREATE TABLE bad (x INT REFERENCES parent(missing));' 'không tìm thấy'
fails 'USE fk_test; CREATE TABLE bad (x TEXT REFERENCES parent(id));' 'không tương thích'
fails 'USE fk_test; CREATE TABLE bad (x INT, FOREIGN KEY (x,x) REFERENCES parent(id,id));' 'trùng tên cột'
fails 'USE fk_test; CREATE TABLE bad (x INT, FOREIGN KEY (x) REFERENCES parent(id,code));' 'số cột'
fails 'USE fk_test; CREATE TABLE bad (x INT REFERENCES child(pid));' 'PRIMARY KEY hoặc UNIQUE'
fails 'USE fk_test; ALTER TABLE child ADD CONSTRAINT fk_child_pid FOREIGN KEY (pid) REFERENCES parent(id);' 'đã tồn tại'
run "USE fk_test; CREATE TABLE composite_parent (a INT, b TEXT); CREATE UNIQUE INDEX ux_ab ON composite_parent (a,b); INSERT INTO composite_parent VALUES (1,'a'),(1,'b'); CREATE TABLE composite_child (a INTEGER,b VARCHAR(20),CONSTRAINT fk_ab FOREIGN KEY (a,b) REFERENCES composite_parent(a,b)); INSERT INTO composite_child VALUES (1,'a'),(999,NULL),(NULL,'z');" >/dev/null
contains "$(run 'USE fk_test; SHOW FOREIGN KEYS FROM composite_child;')" '["FK_AB","A,B","COMPOSITE_PARENT","A,B"]'
fails "USE fk_test; INSERT INTO composite_child VALUES (2,'a');" 'FK_AB'
fails 'USE fk_test; DROP INDEX ux_ab ON composite_parent;' 'FK_AB'
fails 'USE fk_test; CREATE TABLE bad (a INT,b TEXT,FOREIGN KEY (b,a) REFERENCES composite_parent(b,a));' 'FK_BAD'
run "USE fk_test; CREATE TABLE node (id INT PRIMARY KEY, next_id INT REFERENCES node(id)); INSERT INTO node VALUES (1,2),(2,1),(3,3); CREATE TABLE extra (id INT, code VARCHAR(20)); INSERT INTO extra VALUES (1,NULL); ALTER TABLE extra ADD CONSTRAINT fk_extra FOREIGN KEY (id) REFERENCES parent(id); ALTER TABLE extra ADD COLUMN pid INT REFERENCES parent(id); ALTER TABLE extra ADD FOREIGN KEY (code) REFERENCES parent(code);" >/dev/null
fails 'USE fk_test; DELETE FROM node WHERE id = 1;' 'FK_NODE_NEXT_ID'
run 'USE fk_test; DELETE FROM node;' >/dev/null
run 'USE fk_test; CREATE TABLE invalid_child (pid INT); INSERT INTO invalid_child VALUES (99);' >/dev/null
fails 'USE fk_test; ALTER TABLE invalid_child ADD CONSTRAINT fk_invalid FOREIGN KEY (pid) REFERENCES parent(id);' 'FK_INVALID'
fails 'USE fk_test; INSERT INTO parent VALUES (99,NULL); INSERT INTO child VALUES (4,100);' 'FK_CHILD_PID'
cp "$db" "$work/before"
run 'USE fk_test; BEGIN; ALTER TABLE child DROP FOREIGN KEY fk_child_pid; DELETE FROM child; ROLLBACK;' >/dev/null
cmp "$db" "$work/before"
run 'USE fk_test; ALTER TABLE parent RENAME COLUMN id TO pk; ALTER TABLE parent RENAME TO renamed_parent; ALTER TABLE child RENAME COLUMN pid TO parent_id; ALTER TABLE child RENAME TO renamed_child;' >/dev/null
contains "$(run 'USE fk_test; SHOW FOREIGN KEYS FROM renamed_child;')" '["FK_CHILD_PID","PARENT_ID","RENAMED_PARENT","PK"]'
fails 'USE fk_test; INSERT INTO renamed_child VALUES (3,99);' 'FK_CHILD_PID'
run 'USE fk_test; ALTER TABLE renamed_child DROP FOREIGN KEY fk_child_pid; ALTER TABLE extra DROP FOREIGN KEY fk_extra; ALTER TABLE extra DROP FOREIGN KEY fk_extra_pid; ALTER TABLE extra DROP FOREIGN KEY fk_extra_code; DELETE FROM renamed_parent; DROP TABLE renamed_parent;' >/dev/null
contains "$(run 'USE fk_test; SHOW FOREIGN KEYS FROM renamed_child;')" '"rows":[]'
contains "$(run 'USE idx; SHOW FOREIGN KEYS FROM compound;')" '"rows":[]'
# Views: live, read-only relations with bound metadata and dependencies.
run 'CREATE DATABASE view_test; USE view_test; CREATE TABLE base (id INT PRIMARY KEY, label VARCHAR(20), qty REAL); CREATE VIEW live AS SELECT * FROM base; CREATE VIEW totals AS SELECT COUNT(*) AS n, SUM(qty) AS total FROM live;' >/dev/null
contains "$(run 'USE view_test; SHOW VIEWS;')" '"rows":[["LIVE"],["TOTALS"]]'
contains "$(run 'USE view_test; SHOW TABLES;')" '"rows":[["BASE"]]'
contains "$(run 'USE view_test; DESCRIBE live;')" '["LABEL","VARCHAR",20,0,0,0]'
contains "$(run 'USE view_test; SELECT * FROM totals;')" '"rows":[[0,null]]'
contains "$(run 'USE view_test; SELECT * FROM live;')" '"rows":[]'
run "USE view_test; INSERT INTO base VALUES (1,'a',2),(2,'b',3); CREATE VIEW nested AS SELECT id,label FROM live WHERE qty > 2; CREATE VIEW joined AS SELECT b.id AS id, v.label AS label FROM base AS b JOIN live AS v ON b.id = v.id;" >/dev/null
contains "$(run 'USE view_test; SELECT * FROM live ORDER BY id;')" '"rows":[[1,"a",2],[2,"b",3]]'
contains "$(run 'USE view_test; SELECT * FROM nested;')" '"rows":[[2,"b"]]'
contains "$(run 'USE view_test; SELECT * FROM joined ORDER BY id;')" '"rows":[[1,"a"],[2,"b"]]'
contains "$(run 'USE view_test; SELECT v.id FROM live AS v JOIN base AS b ON v.id = b.id ORDER BY v.id;')" '"rows":[[1],[2]]'
out=$(run 'USE view_test; EXPLAIN SELECT v.id FROM live AS v JOIN base AS b ON v.id = b.id JOIN base AS c ON b.id = c.id;')
contains "$out" '[3,"HASH_JOIN","INNER",null]'
contains "$out" '[5,"HASH_JOIN","INNER",null]'
contains "$(run 'USE view_test; SELECT COUNT(*) FROM live AS v JOIN base AS b ON v.id = b.id JOIN base AS c ON b.id = c.id;')" '"rows":[[2]]'
out=$(run 'USE view_test; EXPLAIN SELECT b.id FROM base AS b JOIN live AS v ON b.id = v.id JOIN base AS c ON v.id = c.id;')
contains "$out" '[2,"VIEW_SCAN","LIVE",null]'
contains "$out" '[5,"HASH_JOIN","INNER",null]'


contains "$(run 'USE view_test; SELECT * FROM totals;')" '"rows":[[2,5.0]]'
contains "$(run 'USE view_test; EXPLAIN SELECT * FROM live;')" 'VIEW_SCAN'
run 'USE view_test; UPDATE base SET qty = 4 WHERE id = 1; DELETE FROM base WHERE id = 2;' >/dev/null
contains "$(run 'USE view_test; SELECT * FROM nested;')" '"rows":[[1,"a"]]'
contains "$(run 'USE view_test; SELECT * FROM totals;')" '"rows":[[1,4.0]]'
fails 'USE view_test; CREATE VIEW bad AS SELECT missing FROM base;' 'không tìm thấy'
fails 'USE view_test; CREATE VIEW bad AS SELECT * FROM missing;' 'không tìm thấy'
fails 'USE view_test; CREATE VIEW bad AS SELECT COUNT(*) FROM base;' 'bí danh AS'
fails 'USE view_test; CREATE VIEW bad AS SELECT id,id FROM base;' 'trùng tên cột'
fails 'USE view_test; CREATE TABLE live (id INT);' 'đã tồn tại'
fails 'USE view_test; CREATE VIEW base AS SELECT * FROM live;' 'đã tồn tại'
fails 'USE view_test; INSERT INTO live VALUES (3,NULL,NULL);' 'không tìm thấy'
fails 'USE view_test; UPDATE live SET qty = 9;' 'không tìm thấy'
fails 'USE view_test; DELETE FROM live;' 'không tìm thấy'
fails 'USE view_test; CREATE INDEX ix_live ON live (id);' 'không tìm thấy'
fails 'USE view_test; ALTER TABLE live ADD COLUMN x INT;' 'không tìm thấy'
fails 'USE view_test; CREATE TABLE bad (id INT REFERENCES live(id));' 'không tìm thấy'
fails 'USE view_test; DROP TABLE base;' 'view phụ thuộc'
fails 'USE view_test; ALTER TABLE base ADD COLUMN x INT;' 'view phụ thuộc'
fails 'USE view_test; DROP VIEW live;' 'view phụ thuộc'
fails 'USE view_test; DROP TABLE live;' 'không tìm thấy'
cp "$db" "$work/before"
run 'USE view_test; BEGIN; DROP VIEW nested; CREATE VIEW temp_view AS SELECT * FROM live; ROLLBACK;' >/dev/null
cmp "$db" "$work/before"
fails 'USE view_test; CREATE VIEW temp_view AS SELECT * FROM live; DROP VIEW missing;' 'không tìm thấy'
contains "$(run 'USE idx; SHOW VIEWS;')" '"rows":[]'
run 'USE view_test; DROP VIEW nested; DROP VIEW joined; DROP VIEW totals; DROP VIEW live; ALTER TABLE base ADD COLUMN x INT; DROP TABLE base;' >/dev/null
contains "$(run 'USE view_test; SHOW VIEWS;')" '"rows":[]'
# Statistics are computed from the current physical table and do not mutate it.
run "CREATE DATABASE stats_test; USE stats_test; CREATE TABLE sample (id INT PRIMARY KEY, amount REAL, label TEXT, flag BOOLEAN, empty_col TEXT); INSERT INTO sample VALUES (1,1,'Cà phê',TRUE,NULL),(2,1.0,'Cà phê',FALSE,NULL),(3,2.5,'Trà',TRUE,NULL),(4,NULL,NULL,NULL,NULL); CREATE INDEX ix_label ON sample (label); CREATE TABLE empty_table (id INT);" >/dev/null
cp "$db" "$work/before"
run 'USE stats_test; SHOW STATISTICS FROM sample; SHOW STATISTICS FROM empty_table;' > "$work/stats"
cmp "$db" "$work/before"
python3 - "$db" "$work/stats" <<'PYTEST'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    catalog = json.load(f)
with open(sys.argv[2], encoding='utf-8') as f:
    stats, empty = [json.loads(line) for line in f][1:]
tables = next(db['tables'] for db in catalog['databases'] if db['name'] == 'STATS_TEST')
def size(name):
    table = next(t for t in tables if t['name'] == name)
    return len(json.dumps(table, ensure_ascii=False, separators=(',', ':')).encode('utf-8'))
assert stats['columns'] == ['COLUMN','ROWS','JSON_BYTES','NULL_COUNT','NON_NULL_COUNT','DISTINCT_COUNT','MIN','MAX']
assert stats['rows'] == [
    ['ID',4,size('SAMPLE'),0,4,4,1,4],
    ['AMOUNT',4,size('SAMPLE'),1,3,2,1,2.5],
    ['LABEL',4,size('SAMPLE'),1,3,2,'Cà phê','Trà'],
    ['FLAG',4,size('SAMPLE'),1,3,2,0,1],
    ['EMPTY_COL',4,size('SAMPLE'),4,0,0,None,None],
], stats
assert empty['rows'] == [['ID',0,size('EMPTY_TABLE'),0,0,0,None,None]], empty
PYTEST
fails 'SHOW STATISTICS FROM sample;' 'không tìm thấy'
fails 'USE stats_test; SHOW STATISTICS FROM missing;' 'không tìm thấy'
fails "USE stats_test; SELECT * FROM sample WHERE id = 1 OR id LIKE 'a' LIMIT 1;" 'LIKE'
# Persistent optimizer distribution statistics, estimates and invalidation.
run 'USE stats_test; ANALYZE TABLE sample; ANALYZE TABLE empty_table;' > "$work/analyzed"
cp "$db" "$work/before"
run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE amount = 1; EXPLAIN SELECT * FROM sample WHERE label IS NULL; EXPLAIN SELECT * FROM sample WHERE amount BETWEEN 1 AND 2.5; EXPLAIN SELECT * FROM sample WHERE 2 < amount; EXPLAIN SELECT * FROM sample WHERE amount <> 1; EXPLAIN SELECT * FROM sample WHERE empty_col IS NOT NULL; EXPLAIN SELECT * FROM empty_table WHERE id = 1; EXPLAIN SELECT * FROM sample AS a JOIN sample AS b ON a.amount = b.amount; EXPLAIN SELECT * FROM sample AS a LEFT JOIN sample AS b ON a.amount = b.amount; SELECT COUNT(*) FROM sample AS a LEFT JOIN sample AS b ON a.amount = b.amount;' > "$work/analyzed-plans"
cmp "$db" "$work/before"
python3 - "$work/analyzed" "$work/analyzed-plans" <<'PYTEST'
import json,sys
def read(path):
    with open(path) as f:
        return [json.loads(line) for line in f][1:]
stats,empty=read(sys.argv[1])
assert stats['columns']==['COLUMN','NULL_COUNT','DISTINCT_COUNT','MOST_COMMON','HISTOGRAM']
by_col={row[0]:row[1:] for row in stats['rows']}
assert by_col['AMOUNT']==[1,2,[[1,2]],[[2.5,2.5,1,1]]], by_col
assert by_col['LABEL']==[1,2,[['Cà phê',2]],[['Trà','Trà',1,1]]], by_col
assert by_col['FLAG']==[1,2,[[1,2]],[[0,0,1,1]]], by_col
assert by_col['EMPTY_COL']==[4,0,[],[]]
assert empty['rows']==[['ID',0,0,[],[]]]
plans=read(sys.argv[2])
for plan,expected in zip(plans[:7],[2,1,3,1,1,0,0]):
    assert next(row[3] for row in plan['rows'] if row[1]=='FILTER')==expected, plan
for plan,expected in zip(plans[7:9],[5,6]):
    assert next(row[3] for row in plan['rows'] if row[1].endswith('_JOIN'))==expected, plan
assert plans[9]['rows']==[[6]], plans[9]
PYTEST
# Compound estimates retain SQL TRUE/FALSE/UNKNOWN and shared-column constraints.
python3 - "$root/vdb" "$db" <<'PYTEST'
import json, math, subprocess, sys
from pathlib import Path
exe, db = sys.argv[1:]
before = Path(db).read_bytes()
# (table, predicate, estimated TRUE rows, actual TRUE rows)
cases = [
    ('sample', 'NOT amount=1', 1, 1),
    ('sample', 'amount=1 AND amount=2.5', 0, 0),
    ('sample', 'amount=1 OR amount=1.0', 2, 2),
    ('sample', 'amount=1 OR NOT amount=1', 3, 3),
    ('sample', 'amount IS NULL AND amount=1', 0, 0),
    ('sample', 'amount IS NULL OR amount IS NOT NULL', 4, 4),
    ('sample', 'NOT (amount IS NULL OR amount=1)', 1, 1),
    ('sample', 'amount IN (1, 1.0, 2.5, NULL)', 3, 3),
    ('sample', 'amount NOT IN (1, NULL)', 0, 0),
    ('sample', 'amount NOT IN (1, 1.0)', 1, 1),
    ('sample', 'amount NOT BETWEEN NULL AND 1', 1, 1),
    ('sample', 'amount NOT BETWEEN 2 AND NULL', 2, 2),
    ('sample', 'amount NOT BETWEEN 2.5 AND 1', 3, 3),
    ('sample', 'amount=1 AND flag=TRUE', 1, 1),
    ('sample', 'amount=1 OR flag=TRUE', 3, 3),
    ('sample', 'NOT (amount=1 AND flag=TRUE)', 1.75, 2),
    ('sample', 'NOT (amount=1 OR flag=TRUE)', 0.25, 0),
    ('sample', "label LIKE 'C_ ph%'", 2, 2),
    ('sample', "label NOT LIKE 'C_ ph%'", 1, 1),
    ('sample', "label LIKE 'C%' OR label='Trà'", 3, 3),
    ('sample', 'label NOT LIKE NULL', 0, 0),
    ('sample', "empty_col IS NULL AND NOT empty_col='x'", 0, 0),
    ('sample', 'NOT (empty_col IS NULL AND amount=1)', 1, 1),
    ('sample', 'id=1 AND amount=2.5', 0.25, 0),
    ('empty_table', 'NOT (id=1 OR id IN (2,NULL))', 0, 0),
    ('sample', 'amount IN (id, 1)', None, 2),
    ('sample', 'amount=id', None, 1),
]
# Correctness of the actual SELECT is checked separately from estimates.
for table, pred, expected, actual in cases:
    sql=f'USE stats_test; EXPLAIN SELECT * FROM {table} WHERE {pred}; SELECT COUNT(*) FROM {table} WHERE {pred};'
    _, plan, result = map(json.loads, subprocess.check_output([exe,'--db',db,'-e',sql], text=True).splitlines())
    estimate=next(row[3] for row in plan['rows'] if row[1]=='FILTER')
    assert (estimate is None if expected is None else math.isclose(estimate, expected)), (pred, estimate, expected)
    assert result['rows']==[[actual]], (pred,result,actual)
    candidates=plan['rows'][0][3]
    assert estimate is None or 0<=estimate<=candidates, plan
    assert Path(db).read_bytes()==before, pred
# Invalid LIKE operand types are not evaluated by EXPLAIN.
_, plan=map(json.loads,subprocess.check_output([exe,'--db',db,'-e',"USE stats_test; EXPLAIN SELECT * FROM sample WHERE id LIKE 'a';"],text=True).splitlines())
assert next(row[3] for row in plan['rows'] if row[1]=='FILTER') is None, plan
PYTEST
run 'USE stats_test; BEGIN; UPDATE sample SET amount=99 WHERE id=1; ROLLBACK;' >/dev/null
cmp "$db" "$work/before"
run 'USE stats_test; UPDATE sample SET amount=99 WHERE id=-1; DELETE FROM sample WHERE id=-1;' >/dev/null
contains "$(run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE amount=1;')" '[2,"FILTER","",2]'
run 'USE stats_test; INSERT INTO sample VALUES (5,1,NULL,NULL,NULL);' >/dev/null
contains "$(run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE amount=1;')" '[2,"FILTER","",null]'
contains "$(run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE NOT (amount=1 OR amount IS NULL);')" '[2,"FILTER","",null]'
run 'USE stats_test; ANALYZE TABLE sample; UPDATE sample SET amount=99 WHERE id=1;' >/dev/null
contains "$(run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE amount=1;')" '[2,"FILTER","",null]'
run 'USE stats_test; ANALYZE TABLE sample; DELETE FROM sample WHERE id=5;' >/dev/null
contains "$(run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE amount=1;')" '[2,"FILTER","",null]'
run 'USE stats_test; ANALYZE TABLE sample; ALTER TABLE sample ADD COLUMN extra INT;' >/dev/null
contains "$(run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE amount=1;')" '[2,"FILTER","",null]'
run 'USE stats_test; BEGIN; ANALYZE TABLE sample; ROLLBACK;' >/dev/null
contains "$(run 'USE stats_test; EXPLAIN SELECT * FROM sample WHERE amount=1;')" '[2,"FILTER","",null]'
# Histogram buckets exclude MCVs even where their ranges span the same value.
run 'USE stats_test; CREATE TABLE skew (v INT); CREATE TABLE probe (v INT); INSERT INTO probe VALUES (20),(20),(NULL),(1000);' >/dev/null
values=$(python3 -c 'print(",".join(f"({i})" for i in list(range(40))+[20]*30+[None]*0))')
run "USE stats_test; INSERT INTO skew VALUES $values,(NULL); CREATE INDEX ix_skew ON skew(v); ANALYZE TABLE skew; ANALYZE TABLE probe;" > "$work/skew"
run 'USE stats_test; EXPLAIN SELECT * FROM skew WHERE v=20; EXPLAIN SELECT * FROM probe AS p LEFT JOIN skew AS s ON p.v=s.v; SELECT COUNT(*) FROM probe AS p LEFT JOIN skew AS s ON p.v=s.v;' > "$work/skew-plans"
python3 - "$work/skew" "$work/skew-plans" <<'PYTEST'
import json,sys
with open(sys.argv[1]) as f: stats=[json.loads(line) for line in f][-2]
with open(sys.argv[2]) as f: plans=[json.loads(line) for line in f][1:]
_,nulls,ndv,mcv,buckets=stats['rows'][0]
assert (nulls,ndv,mcv)==(1,40,[[20,31]]),stats
assert len(buckets)<=16 and sum(b[2] for b in buckets)==39 and sum(b[3] for b in buckets)==39,stats
assert next(row[3] for row in plans[0]['rows'] if row[1]=='FILTER')==31,plans
assert next(row[3] for row in plans[1]['rows'] if row[1].endswith('_JOIN'))==64,plans
assert plans[2]['rows']==[[64]],plans
PYTEST
# Compound residual-bucket estimates share boundaries and exclude MCV keys.
python3 - "$root/vdb" "$db" <<'PYTEST'
import json, math, subprocess, sys
from pathlib import Path
exe, db = sys.argv[1:]
before=Path(db).read_bytes()
for pred, expected in [
    ('v=20 OR v=21',32), ('v=20 AND v=21',0),
    ('v=20 OR v IS NULL',32), ('v=20 AND v IS NOT NULL',31),
    ('v BETWEEN 19 AND 21',33), ('v>=18 AND v<=21',34),
    ('v NOT IN (20,NULL)',0), ('v<5 OR v>=5',70),
    ('v>5 AND v<5',0), ('v>=5 AND v<=5',1),
    ('v IN (1,1,2,3,4,5,6,7,8,9,20)',40),
    ('v NOT BETWEEN NULL AND 19',50), ('v>20',19),
]:
    sql=f'USE stats_test; EXPLAIN SELECT * FROM skew WHERE {pred}; SELECT COUNT(*) FROM skew WHERE {pred};'
    _, plan, result=map(json.loads,subprocess.check_output([exe,'--db',db,'-e',sql],text=True).splitlines())
    estimate=next(row[3] for row in plan['rows'] if row[1]=='FILTER')
    assert math.isclose(estimate,expected), (pred,plan,expected)
    assert result['rows']==[[expected]], (pred,result)
    assert 0<=estimate<=plan['rows'][0][3], plan
assert Path(db).read_bytes()==before
PYTEST
run 'USE stats_test; CREATE TABLE text_buckets (v TEXT);' >/dev/null
values=$(python3 -c 'print(",".join(f"({chr(39)}t{i:02}{chr(39)})" for i in range(40)))')
run "USE stats_test; INSERT INTO text_buckets VALUES $values,(NULL); ANALYZE TABLE text_buckets;" >/dev/null
contains "$(run "USE stats_test; EXPLAIN SELECT * FROM text_buckets WHERE v LIKE 't%';")" '[2,"FILTER","",null]'
contains "$(run "USE stats_test; SELECT COUNT(*) FROM text_buckets WHERE v LIKE 't%';")" '"rows":[[40]]'
# More repeated keys than MCV capacity, with exact total population.
run 'USE stats_test; CREATE TABLE repeated (v INT);' >/dev/null
values=$(python3 -c 'print(",".join(f"({i})" for i in range(20) for _ in range(i+2)))')
run "USE stats_test; INSERT INTO repeated VALUES $values; ANALYZE TABLE repeated;" > "$work/repeated"
python3 - "$work/repeated" <<'PYTEST'
import json,sys
with open(sys.argv[1]) as f: stats=[json.loads(line) for line in f][-1]
_,nulls,ndv,mcv,buckets=stats['rows'][0]
assert (nulls,ndv)==(0,20),stats
assert mcv==[[i,i+2] for i in range(19,11,-1)],stats
assert sum(b[3] for b in buckets)==12 and sum(b[2] for b in buckets)==90,stats
PYTEST
# Invalid cached metadata must fall back to the previous estimator.
python3 - "$db" "$work/invalid-stats.json" <<'PYTEST'
import json,sys
with open(sys.argv[1]) as f: catalog=json.load(f)
tables=next(d['tables'] for d in catalog['databases'] if d['name']=='STATS_TEST')
table=next(t for t in tables if t['name']=='SKEW')
table['optimizer_statistics']=[[1,40,[[20,31]],[[0,39,39,0]]]]
with open(sys.argv[2],'w') as f: json.dump(catalog,f)
PYTEST
contains "$("$root/vdb" --db "$work/invalid-stats.json" -e 'USE stats_test; EXPLAIN SELECT * FROM skew WHERE v=20;')" '[2,"FILTER","",null]'
contains "$("$root/vdb" --db "$work/invalid-stats.json" -e 'USE stats_test; EXPLAIN SELECT * FROM skew WHERE NOT (v=20 OR v IS NULL);')" '[2,"FILTER","",null]'
contains "$("$root/vdb" --db "$work/invalid-stats.json" -e 'USE stats_test; SELECT COUNT(*) FROM probe AS p LEFT JOIN skew AS s ON p.v=s.v;')" '"rows":[[64]]'
cp "$db" "$work/before"
"$root/vdb" --db "$db" --backup "$work/analyzed-backup.json" >/dev/null
cmp "$db" "$work/before"
"$root/vdb" --db "$work/analyzed-restored.json" --restore "$work/analyzed-backup.json" >/dev/null
contains "$("$root/vdb" --db "$work/analyzed-restored.json" -e 'USE stats_test; EXPLAIN SELECT * FROM skew WHERE v=20;')" '[2,"FILTER","",null]'
# Cost-based reorder preserves SQL column layout and original physical row order.
run 'CREATE DATABASE reorder_test; USE reorder_test; CREATE TABLE a (id INT, k INT, label TEXT); CREATE TABLE b (id INT, k REAL); CREATE TABLE c (id INT, label TEXT); CREATE TABLE d (id INT);' >/dev/null
av=$(python3 -c 'print(",".join(f"({i},1,{chr(39)}Cà phê{chr(39)})" for i in range(40,0,-1)))')
bv=$(python3 -c 'print(",".join(f"({i},1.0)" for i in range(1,41)))')
run "USE reorder_test; INSERT INTO a VALUES $av,(NULL,NULL,'Trà'); INSERT INTO b VALUES $bv,(NULL,NULL); INSERT INTO c VALUES (3,'Trà'),(1,'Cà phê'),(3,'Cà phê'),(NULL,'Trà'); INSERT INTO d VALUES (999); CREATE INDEX ix_a_id ON a(id);" >/dev/null
star='FROM a AS x JOIN b AS y ON x.k=y.k JOIN c AS z ON x.id=z.id'
chain='FROM a AS x JOIN b AS y ON x.k=y.k JOIN c AS z ON y.id=z.id'
self='FROM a AS x JOIN a AS y ON x.k=y.k JOIN c AS z ON x.id=z.id'
empty='FROM a AS x JOIN b AS y ON x.k=y.k JOIN d AS z ON x.id=z.id'
queries="USE reorder_test; SELECT * $star; SELECT * $chain; SELECT * $self; SELECT * $empty; SELECT * $star LIMIT 11 OFFSET 37; SELECT x.id AS xid,y.id AS yid,z.label AS label $star ORDER BY z.id LIMIT 13 OFFSET 30; SELECT DISTINCT x.id,z.label $star; SELECT z.label,COUNT(*) AS n,SUM(y.id) AS total $star GROUP BY z.label; SELECT * $star WHERE y.id > 38;"
# Compare combined plans against execution before statistics exist.
combined="USE reorder_test; SELECT * $star WHERE z.id=1; SELECT * $star WHERE z.id=1 AND y.id>38; SELECT * $star WHERE z.id=1 AND x.id>0; SELECT * $star WHERE z.id=3 LIMIT 7 OFFSET 39; SELECT DISTINCT x.id,z.label $star WHERE z.id=3 ORDER BY z.label; SELECT z.label,COUNT(*),SUM(y.id) $star WHERE z.id=3 GROUP BY z.label; SELECT * $chain WHERE z.id=3 AND x.id>38; SELECT * $self WHERE z.id=1 AND y.id>38; SELECT * $star WHERE z.id=999; SELECT * $star WHERE z.id=1 AND x.id=x.k;"
run "$combined" > "$work/combined-original"
run "$queries" > "$work/join-original"
run 'USE reorder_test; ANALYZE TABLE a; ANALYZE TABLE b;' >/dev/null
contains "$(run "USE reorder_test; EXPLAIN SELECT * $star;")" '[1,"TABLE_SCAN","A",41]'
run 'USE reorder_test; ANALYZE TABLE c; ANALYZE TABLE d;' >/dev/null
cp "$db" "$work/before"
run "$queries" > "$work/join-reordered"
cmp "$work/join-original" "$work/join-reordered"
run "USE reorder_test; EXPLAIN SELECT * $star; EXPLAIN SELECT * $chain; EXPLAIN SELECT * $self; EXPLAIN SELECT * $empty; EXPLAIN SELECT * FROM a AS x LEFT JOIN b AS y ON x.k=y.k JOIN c AS z ON x.id=z.id; EXPLAIN SELECT * FROM c AS x JOIN c AS y ON x.id=y.id JOIN c AS z ON x.id=z.id;" > "$work/join-plans"
cmp "$db" "$work/before"
python3 - "$work/join-plans" "$work/join-reordered" <<'PYTEST'
import json,sys
with open(sys.argv[1]) as f: plans=[json.loads(line) for line in f][1:]
with open(sys.argv[2]) as f: results=[json.loads(line) for line in f][1:]
for plan in plans[:4]:
    ops=[r[1] for r in plan['rows']]
    assert 'RESTORE_JOIN_ORDER' in ops, plan
    assert ops.index('RESTORE_JOIN_ORDER') < ops.index('PROJECT'), plan
assert any(r[1]=='INDEX_LOOKUP' and r[2]=='IX_A_ID' for r in plans[0]['rows']),plans[0]
for plan in plans[4:]:
    assert all(r[1]!='RESTORE_JOIN_ORDER' for r in plan['rows']),plan
assert len(results[0]['rows'])==120 and len(results[1]['rows'])==120 and len(results[2]['rows'])==120,results[:3]
assert results[3]['rows']==[],results[3]
PYTEST
run "$combined" > "$work/combined-reordered"
cmp "$work/combined-original" "$work/combined-reordered"
run "USE reorder_test; EXPLAIN SELECT * $star WHERE z.id=1; EXPLAIN SELECT * $star WHERE z.id=1 AND y.id>38; EXPLAIN SELECT * $star WHERE z.id=1 AND x.id>0; EXPLAIN SELECT * $star WHERE z.id=1 AND x.id=x.k; EXPLAIN SELECT * $star WHERE z.id=999; EXPLAIN SELECT * $star WHERE z.id=1 AND x.id LIKE 'a';" > "$work/combined-plans"
cmp "$db" "$work/before"
python3 - "$work/combined-plans" "$work/combined-reordered" <<'PYTEST'
import json,sys
def rows(path):
    with open(path) as f:
        return [json.loads(line)['rows'] for line in list(f)[1:]]
plans, results = map(rows,sys.argv[1:])
for plan in plans[:3]:
    ops = [r[1] for r in plan]
    assert 'RESTORE_JOIN_ORDER' in ops and ops.index('RESTORE_JOIN_ORDER') < ops.index('FILTER'),plan
    assert plan[0][2]=='C' and plan[1][1:]==['SOURCE_FILTER','Z',1],plan
assert any(r[1]=='INDEX_LOOKUP' and r[2]=='IX_A_ID' for r in plans[0]),plans[0]
assert any(r[1]=='SOURCE_FILTER' and r[2]=='Y' for r in plans[1]),plans[1]
assert any(r[1]=='SOURCE_FILTER' and r[2]=='X' for r in plans[2]),plans[2]
assert not any(r[1]=='INDEX_LOOKUP' and r[2]=='IX_A_ID' for r in plans[2]),plans[2]
assert any(r[1:] == ['SOURCE_FILTER','X',None] for r in plans[3]),plans[3]
assert not any(r[1]=='RESTORE_JOIN_ORDER' for r in plans[3]),plans[3]
assert any(r[1:] == ['SOURCE_FILTER','Z',0] for r in plans[4]),plans[4]
assert not any(r[1]=='SOURCE_FILTER' for r in plans[5]),plans[5]
assert [len(r) for r in results]==[40,2,40,7,2,2,4,2,0,40],results
PYTEST
run 'USE reorder_test; CREATE VIEW av AS SELECT * FROM a;' >/dev/null
out=$(run 'USE reorder_test; EXPLAIN SELECT * FROM av AS x JOIN b AS y ON x.k=y.k JOIN c AS z ON x.id=z.id;')
contains "$out" 'VIEW_SCAN'
if printf '%s\n' "$out" | grep -Fq RESTORE_JOIN_ORDER; then exit 1; fi
run 'USE reorder_test; INSERT INTO c VALUES (999,NULL);' >/dev/null
out=$(run "USE reorder_test; EXPLAIN SELECT * $star;")
if printf '%s\n' "$out" | grep -Fq RESTORE_JOIN_ORDER; then exit 1; fi
# Pushdown preserves physical order, aliases and the original WHERE semantics.
run 'CREATE DATABASE pushdown_test; USE pushdown_test; CREATE TABLE a (id INT, k INT, label TEXT); CREATE TABLE b (id INT, k INT, label TEXT); CREATE TABLE c (k INT); CREATE TABLE empty (k INT);' >/dev/null
av=$(python3 -c 'print(",".join(f"({i},{i%3},{chr(39)}Trà{chr(39)})" for i in range(40,0,-1)))')
bv=$(python3 -c 'print(",".join(f"({i},{i%3},{chr(39)}Cà phê{chr(39)})" for i in range(1,41)))')
run "USE pushdown_test; INSERT INTO a VALUES $av,(NULL,NULL,NULL); INSERT INTO b VALUES $bv,(42,1,NULL),(NULL,NULL,NULL); INSERT INTO c VALUES (1),(1),(2),(NULL); CREATE INDEX ix_a ON a(id); CREATE INDEX ix_b ON b(id); CREATE INDEX ix_b_k ON b(k); CREATE VIEW av AS SELECT * FROM a;" >/dev/null
push='FROM a AS x JOIN b AS y ON x.k=y.k'
where="x.id BETWEEN 37 AND 40 AND y.id IN (1,4,7,NULL) AND NOT (y.label IS NULL OR y.label LIKE 'Trà%') AND x.id > y.id"
# A mixed-source OR wrapper forces the original execution path.
run "USE pushdown_test; SELECT * $push WHERE $where; SELECT * $push WHERE ($where) OR (x.id=y.id AND 1=0); SELECT * $push WHERE $where LIMIT 2 OFFSET 1; SELECT * $push WHERE ($where) OR (x.id=y.id AND 1=0) LIMIT 2 OFFSET 1; SELECT x.k,COUNT(*) $push WHERE $where GROUP BY x.k ORDER BY x.k; SELECT x.k,COUNT(*) $push WHERE ($where) OR (x.id=y.id AND 1=0) GROUP BY x.k ORDER BY x.k; SELECT DISTINCT x.id,y.label $push WHERE $where ORDER BY x.id; SELECT DISTINCT x.id,y.label $push WHERE ($where) OR (x.id=y.id AND 1=0) ORDER BY x.id;" > "$work/push-results"
run "USE pushdown_test; EXPLAIN SELECT * $push WHERE x.id=40 AND y.id=1; EXPLAIN SELECT * $push WHERE x.id=y.id OR y.id=1;" > "$work/push-before"
run 'USE pushdown_test; ANALYZE TABLE a; ANALYZE TABLE b; ANALYZE TABLE c;' >/dev/null
cp "$db" "$work/before"
run "USE pushdown_test; EXPLAIN SELECT * $push WHERE x.id=40 AND y.id=1; EXPLAIN SELECT * $push WHERE x.id=40; EXPLAIN SELECT * $push WHERE x.id=40 AND y.id LIKE 'a'; EXPLAIN SELECT * $push WHERE x.id=40 AND y.id>'a'; EXPLAIN SELECT * FROM a AS x LEFT JOIN b AS y ON x.k=y.k WHERE y.label IS NULL; EXPLAIN SELECT * FROM av AS x JOIN b AS y ON x.k=y.k WHERE y.id=1; EXPLAIN SELECT * $push JOIN c AS z ON x.k=z.k WHERE y.id=1 AND z.k=1;" > "$work/push-after"
cmp "$db" "$work/before"
python3 - "$work/push-results" "$work/push-before" "$work/push-after" <<'PYTEST'
import json,sys
def rows(path):
    with open(path) as f:
        return [json.loads(line)['rows'] for line in list(f)[1:]]
results, before, after = map(rows,sys.argv[1:])
assert len(results)==8 and len(results[0])==6,results
for i in range(0,8,2):
    assert results[i]==results[i+1],results[i:i+2]
assert [(r[2],r[3]) for r in before[0] if r[1]=='SOURCE_FILTER']==[('X',None),('Y',None)],before
assert not any(r[1]=='SOURCE_FILTER' for r in before[1]),before
assert [(r[2],r[3]) for r in after[0] if r[1]=='SOURCE_FILTER']==[('X',1),('Y',1)],after
assert {r[2] for r in after[0] if r[1]=='INDEX_SCAN'}=={'IX_A','IX_B'},after
assert not any(r[1]=='INDEX_LOOKUP' for r in after[0]),after
assert any(r[1]=='SOURCE_FILTER' and r[2]=='X' for r in after[1]),after
for plan in after[2:6]:
    assert not any(r[1]=='SOURCE_FILTER' for r in plan),plan
assert sorted(r[2] for r in after[6] if r[1]=='SOURCE_FILTER')==['Y','Z'],after
PYTEST
contains "$(run "USE pushdown_test; SELECT x.id,y.id $push WHERE x.id=40 AND y.id=1;")" '"rows":[[40,1]]'
contains "$(run "USE pushdown_test; SELECT x.id,y.id $push WHERE x.id=40 AND y.label IS NULL;")" '"rows":[[40,42]]'
contains "$(run "USE pushdown_test; SELECT x.id,y.id $push WHERE x.id=y.id AND x.id=40;")" '"rows":[[40,40]]'
contains "$(run 'USE pushdown_test; SELECT x.id,y.id FROM a AS x JOIN a AS y ON x.k=y.k WHERE x.id=40 AND y.id=37;')" '"rows":[[40,37]]'
contains "$(run "USE pushdown_test; SELECT COUNT(*) $push JOIN c AS z ON x.k=z.k WHERE y.id=1 AND z.k=1;")" '"rows":[[28]]'
contains "$(run "USE pushdown_test; SELECT * $push WHERE x.id=999 AND y.id LIKE 'a';")" '"rows":[]'
contains "$(run "USE pushdown_test; SELECT * FROM a AS x JOIN empty AS y ON x.k=y.k WHERE x.id LIKE 'a';")" '"rows":[]'
fails "USE pushdown_test; SELECT * $push WHERE x.id=40 AND y.id LIKE 'a';" 'LIKE'
fails "USE pushdown_test; SELECT * $push WHERE y.id LIKE 'a' AND x.id=999;" 'LIKE'
python3 "$root/tests/joint_statistics.py" "$root/vdb"
python3 "$root/tests/residual_statistics.py" "$root/vdb"
python3 "$root/tests/merge_join.py" "$root/vdb"
# Timing is opt-in and does not alter the normal JSON-lines results.
"$root/vdb" --db "$db" --existing --timing -e 'USE fk_test; SELECT * FROM renamed_child;' > "$work/timed"
run 'USE fk_test; SELECT * FROM renamed_child;' > "$work/untimed"
python3 - "$work/timed" "$work/untimed" <<'PYTEST'
import json, math, sys
with open(sys.argv[1]) as f:
    timed = [json.loads(line) for line in f]
with open(sys.argv[2]) as f:
    untimed = [json.loads(line) for line in f]
assert timed[:-1] == untimed
assert set(timed[-1]) == {'timing'}
assert set(timed[-1]['timing']) == {'execution_ms', 'serialization_ms'}
assert all(math.isfinite(value) and value >= 0 for value in timed[-1]['timing'].values())
PYTEST
# Backup/restore preserves source bytes, validates logical data and rebuilds indexes.
backup_source="$work/backup-source.json"
backup_file="$work/snapshot.json"
restored_file="$work/restored.json"
"$root/vdb" --db "$backup_source" -e "CREATE TABLE P(ID INT PRIMARY KEY, V TEXT); INSERT INTO P VALUES (1, 'Cà phê'); CREATE TABLE C(ID INT PRIMARY KEY, PID INT, FOREIGN KEY(PID) REFERENCES P(ID)); INSERT INTO C VALUES (2,1); CREATE INDEX IX ON P(V); CREATE VIEW VV AS SELECT ID,V FROM P;" > /dev/null
"$root/vdb" --db "$backup_source" --backup "$backup_file" > /dev/null
cmp "$backup_source" "$backup_file"
"$root/vdb" --db "$restored_file" --restore "$backup_file" > /dev/null
"$root/vdb" --db "$restored_file" --existing -e 'SELECT * FROM VV; SELECT * FROM C; SHOW INDEX FROM P; SHOW FOREIGN KEYS FROM C;' > "$work/restored-results"
"$root/vdb" --db "$backup_source" --existing -e 'SELECT * FROM VV; SELECT * FROM C; SHOW INDEX FROM P; SHOW FOREIGN KEYS FROM C;' > "$work/source-results"
cmp "$work/restored-results" "$work/source-results"
for operation in backup restore; do
    if "$root/vdb" --db "$backup_source" --"$operation" "$backup_file" > /dev/null 2>&1; then echo "Unexpected overwrite: $operation" >&2; exit 1; fi
done
cmp "$backup_source" "$backup_file"
mkdir "$work/backup-directory"
if "$root/vdb" --db "$backup_source" --backup "$work/backup-directory" > /dev/null 2>&1; then exit 1; fi
python3 - "$backup_file" "$work" <<'PYTEST'
import copy, json, pathlib, sys
source = json.loads(pathlib.Path(sys.argv[1]).read_text())
work = pathlib.Path(sys.argv[2])
for name in ('version','width','duplicate','foreign','view','index'):
    data = copy.deepcopy(source)
    db = data['databases'][0]
    p, c = db['tables']
    if name == 'version': data['version'] = 99
    if name == 'width': p['rows'][0].append(1)
    if name == 'duplicate': p['rows'].append(p['rows'][0])
    if name == 'foreign': c['rows'][0][1] = 99
    if name == 'view': db['views'][0]['query']['name'] = 'MISSING'
    if name == 'index': p['indexes'][0]['index_columns'] = ['MISSING']
    (work / ('bad-' + name + '.json')).write_text(json.dumps(data))
PYTEST
for name in version width duplicate foreign view index; do
    invalid="$work/bad-$name.json"
    target="$work/reject-$name.json"
    if "$root/vdb" --db "$target" --restore "$invalid" > /dev/null 2>&1; then echo "Accepted invalid backup: $name" >&2; exit 1; fi
    test ! -e "$target"
    if "$root/vdb" --db "$invalid" --backup "$target" > /dev/null 2>&1; then echo "Backed up invalid catalog: $name" >&2; exit 1; fi
    test ! -e "$target"
done
echo 'VDB integration tests: PASS'  
