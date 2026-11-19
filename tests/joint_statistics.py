import copy, json, math, pathlib, subprocess, sys, tempfile
exe = sys.argv[1]
with tempfile.TemporaryDirectory() as temp:
    db = pathlib.Path(temp) / 'catalog.json'
    def run(sql, path=db):
        return [json.loads(line) for line in subprocess.check_output([exe, '--db', str(path), '-e', sql], text=True).splitlines()]
    a = ','.join(['(1,0)']*20 + ['(2,1)']*20 + ['(NULL,NULL)'])
    b = ','.join(['(1,0)']*30 + ['(2,1)']*2 + ['(NULL,1)'])
    run(f'CREATE TABLE a(k INT,flag INT); CREATE TABLE b(k INT,flag INT); INSERT INTO a VALUES {a}; INSERT INTO b VALUES {b}; CREATE TABLE c(k INT); INSERT INTO c VALUES (1),(2),(2); ANALYZE TABLE a; ANALYZE TABLE b; ANALYZE TABLE c;')
    original = db.read_bytes()
    def check(where, expected, estimated=None, path=db, sources='a AS x JOIN b AS y ON x.k=y.k'):
        sql=f'FROM {sources} WHERE {where}'
        plan,result=run(f'EXPLAIN SELECT * {sql}; SELECT COUNT(*) {sql};',path)
        joins=[r[3] for r in plan['rows'] if r[1].endswith('_JOIN') or r[1]=='INDEX_LOOKUP']
        assert joins,plan
        assert result['rows']==[[expected]], (where,result,expected)
        if estimated is not None: assert math.isclose(joins[-1],estimated), (where,joins,estimated,plan)
        return joins
    for where, count in [('x.flag=1',40),('x.flag=0',600),('x.flag IS NULL',0),('x.flag=1 AND y.flag=0',0),('x.flag=1 AND y.flag=1',40),('NOT (x.flag=0 OR x.flag IS NULL)',40),('x.flag IN (1,NULL)',40),('y.flag=1',40),('x.flag=9',0)]:
        check(where,count,count)
    check('x.flag=1 AND y.flag=0',0,0,sources='a AS x JOIN a AS y ON x.k=y.k')
    joins = check('x.flag=1', 80, sources='a AS x JOIN b AS y ON x.k=y.k JOIN c AS z ON y.k=z.k')
    assert len(joins) == 2 and math.isclose(joins[0], 40) and math.isclose(joins[1], 40 * 34 / 33), joins
    assert db.read_bytes()==original
    catalog=json.loads(original)
    table=catalog['databases'][0]['tables'][0]
    assert table['optimizer_joint_statistics']==[[0,1,[[1,0,20],[2,1,20],[None,None,1]]]],table
    for mode in ('missing','bad_count','duplicate'):
        data=copy.deepcopy(catalog)
        t=data['databases'][0]['tables'][0]
        if mode=='missing': del t['optimizer_joint_statistics']
        elif mode=='bad_count': t['optimizer_joint_statistics'][0][2][0][2]+=1
        else: t['optimizer_joint_statistics'][0][2].append(t['optimizer_joint_statistics'][0][2][0])
        path=pathlib.Path(temp)/f'{mode}.json';path.write_text(json.dumps(data))
        check('x.flag=1',40,640*20/41,path)
    run('BEGIN; UPDATE a SET flag=0 WHERE k=2; ROLLBACK;')
    assert db.read_bytes()==original
    for sql in ('INSERT INTO a VALUES (2,1);','UPDATE a SET flag=0 WHERE k=2;','DELETE FROM a WHERE k=2;','ALTER TABLE a ADD COLUMN extra INT;'):
        db.write_bytes(original);run(sql)
        t=json.loads(db.read_bytes())['databases'][0]['tables'][0]
        assert not t['optimizer_joint_statistics'], (sql,t)
    db.write_bytes(original)
    dest=pathlib.Path(temp)/'restored.json'
    subprocess.check_output([exe,'--db',str(dest),'--restore',str(db)])
    assert not json.loads(dest.read_bytes())['databases'][0]['tables'][0].get('optimizer_joint_statistics')
    print('VDB joint statistics: PASS')
