import json
import math
import pathlib
import subprocess
import sys
import tempfile

exe = sys.argv[1]
with tempfile.TemporaryDirectory() as temp:
    db = pathlib.Path(temp) / 'catalog.json'

    def run(sql):
        return [json.loads(line) for line in subprocess.check_output(
            [exe, '--db', str(db), '-e', sql], text=True).splitlines()]

    run('CREATE TABLE a(k INT, v INT, extra INT); CREATE TABLE b(k INT, v INT); '
        'CREATE TABLE c(k INT); CREATE TABLE empty(k INT); '
        'INSERT INTO a VALUES (1,0,8),(1,0,9),(1,1,8),(2,2,9),(2,NULL,8),(NULL,0,9); '
        'INSERT INTO b VALUES (1,0),(1,1),(1,1),(2,2),(2,NULL),(NULL,0); '
        'INSERT INTO c VALUES (1),(2),(2);')
    source = 'a AS x JOIN b AS y ON x.k=y.k'

    def check(where, actual, estimate, sources=source, join_estimate=None):
        before = db.read_bytes()
        sql = f'FROM {sources} WHERE {where}'
        plan, result = run(f'EXPLAIN SELECT * {sql}; SELECT COUNT(*) {sql};')
        joins = [r[3] for r in plan['rows'] if r[1].endswith('_JOIN')]
        filtered = next(r[3] for r in plan['rows'] if r[1] == 'FILTER')
        assert result['rows'] == [[actual]], (where, result, actual)
        if estimate is None:
            assert filtered is None, (where, plan)
        elif estimate == "join":
            assert filtered == joins[-1], plan
        else:
            assert math.isclose(filtered, estimate), (where, plan, estimate)
            assert 0 <= filtered <= joins[-1], plan
        if join_estimate is not None:
            assert math.isclose(joins[-1], join_estimate), plan
        assert db.read_bytes() == before, where
        return plan

    check('x.v=y.v', 5, None)
    run('ANALYZE TABLE a; ANALYZE TABLE b; ANALYZE TABLE c; ANALYZE TABLE empty;')
    cases = [
        ('x.v=y.v', 5, 13),
        ('x.v<>y.v', 5, 13),
        ('NOT (x.v=y.v)', 5, 13),
        ('x.v IS NULL OR y.v IS NULL', 3, 13),
        ('x.v=0 AND x.v<y.v', 4, 6),
        ('x.v=0 AND y.v=1', 4, 4),
        ('x.k=2 AND x.v=y.v', 1, 4),
        ('x.k=y.k', 13, 13),
        ('x.v IN (y.v,NULL)', 5, 13),
        ('x.v BETWEEN y.v AND y.k', 6, 13),
        ('x.v=0 OR y.v=2', 8, 13),
        ('x.v=y.v AND x.v=999', 0, 0),
    ]
    for where, count, joined in cases:
        check(where, count, count, join_estimate=joined)
    check('x.v=y.v', 6, 6, sources='a AS x JOIN a AS y ON x.k=y.k', join_estimate=13)
    check('x.v=0 AND x.v<y.v', 4, 4, sources='b AS y JOIN a AS x ON y.k=x.k', join_estimate=6)
    check('x.k=1', 0, 0, sources='a AS x JOIN empty AS y ON x.k=y.k', join_estimate=0)
    check('x.v=y.v AND x.extra=8', 3, None)
    check('x.v=y.v', 5, None, sources='a AS x LEFT JOIN b AS y ON x.k=y.k')
    # A fully pushed WHERE adds no further selectivity, even on a chain.
    plan = check('x.v=0 AND y.v=1', 4, 'join', sources=source + ' JOIN c AS z ON x.k=z.k')
    # Three-way cardinality is heuristic; compare FILTER with the last join.
    assert next(r[3] for r in plan['rows'] if r[1]=='FILTER') == [r[3] for r in plan['rows'] if r[1].endswith('_JOIN')][-1]
    # Missing joint metadata leaves a residual predicate unknown.
    original = db.read_bytes()
    catalog = json.loads(original)
    catalog['databases'][0]['tables'][0].pop('optimizer_joint_statistics')
    db.write_text(json.dumps(catalog))
    check('x.v=y.v', 5, None)
    db.write_bytes(original)
    run('UPDATE a SET v=1 WHERE k=1;')
    check('x.v=y.v', 7, None)
    print('VDB residual statistics: PASS')
