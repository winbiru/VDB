import json
import pathlib
import random
import subprocess
import sys
import tempfile

exe = sys.argv[1]
rng = random.Random(623)
with tempfile.TemporaryDirectory() as temp:
    db = pathlib.Path(temp) / 'catalog.json'

    def run(sql):
        return [json.loads(line) for line in subprocess.check_output(
            [exe, '--db', str(db), '-e', sql], text=True).splitlines()]

    def literal(value):
        if value is None:
            return 'NULL'
        if isinstance(value, str):
            return "'" + value.replace("'", "''") + "'"
        return str(value)

    def load(name, key_type, keys):
        rng.shuffle(keys)
        rows = [(i, key) for i, key in enumerate(keys)]
        values = ','.join('(' + ','.join(map(literal, row)) + ')' for row in rows)
        run(f'CREATE TABLE {name}(id INT,k {key_type}); INSERT INTO {name} VALUES {values};')
        return rows

    a = load('a', 'INT', [1]*40 + [2]*40 + [None]*8 + [-7]*8)
    b = load('b', 'REAL', [1.0]*40 + [2.0]*40 + [None]*8 + [2.5]*8)
    c = load('c', 'TEXT', ['Cà phê']*40 + ['']*40 + [None]*8 + ['Trà']*8)
    d = load('d', 'VARCHAR(20)', ['Cà phê']*40 + ['']*40 + [None]*8 + ['đá']*8)
    e = load('e', 'INT', list(range(96)))
    f = load('f', 'INT', list(range(96)))
    run('CREATE TABLE empty(k INT);')

    def expected(left, right, outer=False):
        rows = []
        for i, x in left:
            matches = [[i, j] for j, y in right if x is not None and y is not None and x == y]
            rows.extend(matches or ([[i, None]] if outer else []))
        return rows

    fixtures = [('a', 'b', a, b), ('b', 'a', b, a), ('c', 'd', c, d), ('a', 'a', a, a)]
    queries = []
    for left, right, left_rows, right_rows in fixtures:
        for outer in (False, True):
            source = f'FROM {left} AS x {"LEFT " if outer else ""}JOIN {right} AS y ON x.k=y.k'
            sql = f'SELECT x.id AS xid,y.id AS yid {source}'
            rows = expected(left_rows, right_rows, outer)
            queries.append((sql, rows))
            queries.append((sql + ' LIMIT 17 OFFSET 55', rows[55:72]))
    source = 'FROM a AS x JOIN b AS y ON x.k=y.k'
    pairs = expected(a, b)
    keys = dict(a)
    queries.extend([
        (f'SELECT x.id AS xid,y.id AS yid {source} ORDER BY x.k LIMIT 23 OFFSET 61',
         sorted(pairs, key=lambda row: keys[row[0]])[61:84]),
        (f'SELECT DISTINCT x.id {source}',
         [[i] for i in dict.fromkeys(i for i, _ in pairs)]),
        (f'SELECT x.k,COUNT(*) {source} GROUP BY x.k ORDER BY x.k',
         [[1, 1600], [2, 1600]]),
    ])
    third = {key: i for i, key in e}
    queries.append((f'SELECT x.id AS xid,y.id AS yid,z.id AS zid {source} JOIN e AS z ON y.k=z.k',
                    [[i, j, third[keys[i]]] for i, j in pairs]))
    before = []
    for sql, rows in queries:
        plan, result = run(f'EXPLAIN {sql}; {sql};')
        assert any(r[1] == 'HASH_JOIN' for r in plan['rows']), plan
        assert result['rows'] == rows, sql
        before.append(result)
    run('ANALYZE TABLE a; ANALYZE TABLE b; ANALYZE TABLE c; ANALYZE TABLE d; ANALYZE TABLE e; ANALYZE TABLE f;')
    snapshot = db.read_bytes()
    for (sql, rows), baseline in zip(queries, before):
        plan, result = run(f'EXPLAIN {sql}; {sql};')
        assert any(r[1] == 'MERGE_JOIN' for r in plan['rows']), (sql, plan)
        assert result == baseline and result['rows'] == rows, sql
    # The calibrated cost model can prefer hash after pushdown reduces the
    # estimated match density. Both plans must preserve the original rows.
    for predicate, algorithm, retained in [('x.k IN (1,2)', 'HASH_JOIN', 80),
                                           ('x.k IN (1,2,-7)', 'MERGE_JOIN', 88)]:
        sql = f'SELECT x.id AS xid,y.id AS yid {source} WHERE {predicate}'
        plan, result = run(f'EXPLAIN {sql}; {sql};')
        assert any(r[1] == algorithm for r in plan['rows']), plan
        assert any(r[1:] == ['SOURCE_FILTER', 'X', retained] for r in plan['rows']), plan
        assert result['rows'] == expected(a,b), result
    plan, result = run('EXPLAIN SELECT COUNT(*) FROM e AS x JOIN f AS y ON x.k=y.k; SELECT COUNT(*) FROM e AS x JOIN f AS y ON x.k=y.k;')
    assert any(r[1] == 'HASH_JOIN' for r in plan['rows']), plan
    assert result['rows'] == [[96]], result
    plan, result = run('EXPLAIN SELECT COUNT(*) FROM a AS x JOIN empty AS y ON x.k=y.k; SELECT COUNT(*) FROM a AS x JOIN empty AS y ON x.k=y.k;')
    assert not any(r[1] == 'MERGE_JOIN' for r in plan['rows']), plan
    assert result['rows'] == [[0]], result
    assert db.read_bytes() == snapshot
    run('UPDATE a SET k=99 WHERE id=0;')
    plan, result = run(f'EXPLAIN SELECT COUNT(*) {source}; SELECT COUNT(*) {source};')
    assert any(r[1] == 'HASH_JOIN' for r in plan['rows']), plan
    updated = [(i, 99 if i == 0 else k) for i,k in a]
    assert result['rows'] == [[len(expected(updated,b))]], result
    print('VDB merge join: PASS')
