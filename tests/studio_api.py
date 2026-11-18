"""Headless Studio regression test. Requires local loopback sockets."""
import http.client
import json
import math
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import time


ROOT = Path(__file__).resolve().parents[1]
TOKEN = 'vdb-studio-test-token'


def main():
    with tempfile.TemporaryDirectory(prefix='vdb-studio-test-') as directory:
        work = Path(directory).resolve()
        first, second, state = (work / name for name in ('a.json', 'b.json', 'state.json'))
        with socket.socket() as probe:
            probe.bind(('127.0.0.1', 0))
            port = probe.getsockname()[1]
        host = f'127.0.0.1:{port}'
        env = dict(os.environ, VDB_STUDIO_CLI=str(ROOT / 'vdb'), VDB_STUDIO_DB=str(first),
                   VDB_STUDIO_HTML=str(ROOT / 'studio/index.html'), VDB_STUDIO_TOKEN=TOKEN,
                   VDB_STUDIO_PORT=str(port), VDB_STUDIO_STATE=str(state), VDB_STUDIO_OPENER='',
                   VDB_STUDIO_READY=str(work / 'ready'))

        def start():
            (work / 'ready').unlink(missing_ok=True)
            process = subprocess.Popen(['sh', ROOT / 'studio/serve'], env=env, cwd=ROOT,
                                       stdout=subprocess.PIPE, stderr=subprocess.STDOUT, umask=0o077)
            for _ in range(200):
                if process.poll() is not None:
                    raise AssertionError(process.communicate()[0].decode())
                if (work / 'ready').exists():
                    return process
                time.sleep(.1)
            stop(process)
            raise AssertionError('Studio startup timeout')

        def stop(process):
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill()
                    process.wait()
            process.stdout.close()

        def request(path, body=None, expected=200, token=TOKEN, header_host=host):
            conn = http.client.HTTPConnection('127.0.0.1', port, timeout=30)
            try:
                conn.request('POST', path, json.dumps(body or {}),
                             {'Host': header_host, 'X-VDB-Token': token, 'Content-Type': 'application/json'})
                response = conn.getresponse()
                data = json.loads(response.read())
                assert response.status == expected, (path, response.status, data)
                return data
            finally:
                conn.close()

        def query(catalog, sql, expected=200):
            return request('/api/query', {'catalog': str(catalog), 'sql': sql, 'database': 'DEFAULT'}, expected)

        saved = {'version': 1, 'profiles': [{'id': 'a', 'name': 'Kho hàng', 'path': str(first)}],
                 'snippets': [{'id': 'snippet-1', 'name': 'Cà phê', 'sql': "  SELECT 'Cà phê';\n-- Mẫu\n"}],
                 'active': 'a', 'sessions': [{'id': 'a', 'selected': 0,
                 'tabs': [{'name': 'Query 1', 'sql': 'SELECT * FROM sp;', 'saved': '', 'db': 'DEFAULT'}]}]}
        process = start()
        try:
            duplicate = subprocess.run(['sh', ROOT / 'studio/serve'], env=env, cwd=ROOT,
                                       capture_output=True, timeout=10)
            assert duplicate.returncode != 0 and 'không thể khóa cấu hình' in duplicate.stderr.decode()
            assert request('/api/workspace')['catalog'] == str(first)
            for path in ('/api/workspace', '/api/workspace/save', '/api/catalog', '/api/query', '/api/validate', '/api/guarded-query', '/api/backup', '/api/restore'):
                request(path, expected=403, token='wrong')
                request(path, expected=403, header_host='wrong.example')
            request('/api/catalog', {'catalog': str(second)}, expected=400)
            assert not second.exists()
            assert request('/api/catalog', {'catalog': str(second), 'create': True})['catalog'] == str(second)
            request('/api/catalog', {'catalog': str(second), 'create': True}, expected=400)
            for catalog, value in ((first, 1), (second, 2)):
                query(catalog, f'CREATE TABLE sp (id INT PRIMARY KEY); INSERT INTO sp VALUES ({value});')
            for catalog, value in ((first, 1), (second, 2)):
                assert query(catalog, 'SELECT * FROM sp;')['results'][0]['rows'] == [[value]]
            backup, restored = work / 'snapshot.json', work / 'restored.json'
            assert request('/api/backup', {'catalog': str(first), 'backup': str(backup)})['backup'] == str(backup)
            assert backup.read_bytes() == first.read_bytes()
            assert request('/api/restore', {'catalog': str(restored), 'backup': str(backup)})['catalog'] == str(restored)
            assert query(restored, 'SELECT * FROM sp;')['results'][0]['rows'] == [[1]]
            request('/api/restore', {'catalog': str(second), 'backup': str(backup)}, expected=400)
            request('/api/backup', {'catalog': str(first), 'backup': str(backup)}, expected=400)
            request('/api/backup', {'catalog': str(first), 'backup': str(state)}, expected=400)
            request('/api/restore', {'catalog': str(state), 'backup': str(backup)}, expected=400)
            invalid = work / 'invalid-backup.json'
            invalid.write_text('{}')
            request('/api/restore', {'catalog': str(work / 'rejected.json'), 'backup': str(invalid)}, expected=400)
            assert not (work / 'rejected.json').exists()
            assert query(second, 'SELECT * FROM sp;')['results'][0]['rows'] == [[2]]
            timing = query(first, 'SELECT * FROM sp;')['timing']
            assert set(timing) == {'execution_ms', 'serialization_ms'}
            assert all(math.isfinite(value) and value >= 0 for value in timing.values())
            before = first.read_bytes()
            query(first, 'DELETE FROM sp; SELECT * FROM missing;', expected=400)
            assert first.read_bytes() == before
            def phase4(endpoint, sql, expected=200):
                return request(endpoint, {'catalog': str(first), 'database': 'DEFAULT', 'sql': sql}, expected)

            assert phase4('/api/validate', 'DELETE FROM sp;')['valid'] == 1
            phase4('/api/validate', 'SELECT FROM;', 400)
            assert first.read_bytes() == before
            phase4('/api/guarded-query', 'UPDATE sp SET id = 10 WHERE id = 1;')
            before = first.read_bytes()
            phase4('/api/guarded-query', 'UPDATE sp SET id = 11 WHERE id = 10; DELETE FROM sp WHERE id = 99;', 400)
            assert first.read_bytes() == before
            assert query(first, 'SELECT * FROM sp;')['results'][0]['rows'] == [[10]]
            query(first, 'CREATE VIEW live AS SELECT * FROM sp;')
            assert query(first, 'SHOW VIEWS;')['results'][0]['rows'] == [['LIVE']]
            assert query(second, 'SHOW VIEWS;')['results'][0]['rows'] == []
            assert query(first, 'SELECT id FROM live;')['results'][0]['rows'] == [[10]]
            assert query(first, 'DESCRIBE live;')['results'][0]['rows'][0] == ['ID','INT',0,0,0,0]
            before = first.read_bytes()
            query(first, 'DROP TABLE sp;', expected=400)
            query(first, 'INSERT INTO live VALUES (20);', expected=400)
            assert first.read_bytes() == before
            query(first, 'INSERT INTO sp VALUES (20);')
            assert query(first, 'SELECT id FROM live ORDER BY id;')['results'][0]['rows'] == [[10],[20]]
            query(first, 'DELETE FROM sp WHERE id = 20; DROP VIEW live;')
            assert query(second, 'SELECT * FROM sp;')['results'][0]['rows'] == [[2]]
            query(first, 'ALTER TABLE sp ADD COLUMN label TEXT; CREATE UNIQUE INDEX ux_label ON sp (label);')
            index = query(first, 'SHOW INDEX FROM sp;')['results'][0]
            assert index['columns'] == ['INDEX', 'COLUMN', 'ENTRIES', 'CARDINALITY', 'HEIGHT', 'UNIQUE']
            assert index['rows'] == [['UX_LABEL', 'LABEL', 0, 0, 1, 1]]
            query(first, "UPDATE sp SET label = 'Cà phê' WHERE id = 10;")
            before = first.read_bytes()
            query(first, "INSERT INTO sp VALUES (11, 'Cà phê');", expected=400)
            assert first.read_bytes() == before
            stats = query(first, 'SHOW STATISTICS FROM sp;')['results'][0]
            assert stats['columns'] == ['COLUMN','ROWS','JSON_BYTES','NULL_COUNT','NON_NULL_COUNT','DISTINCT_COUNT','MIN','MAX']
            assert stats['rows'][0][:2] == ['ID', 1] and stats['rows'][0][3:] == [0,1,1,10,10]
            assert stats['rows'][1][:2] == ['LABEL', 1] and stats['rows'][1][3:] == [0,1,1,'Cà phê','Cà phê']
            assert query(first, 'SELECT * FROM sp ORDER BY id LIMIT 1 OFFSET 1;')['results'][0]['rows'] == []
            assert first.read_bytes() == before
            plan = query(first, 'EXPLAIN SELECT * FROM sp WHERE id = 10;')['results'][0]
            assert plan['columns'] == ['STEP', 'OPERATOR', 'OBJECT', 'ROWS']
            assert any(row[1] == 'TABLE_SCAN' for row in plan['rows'])
            assert first.read_bytes() == before
            query(first, 'ALTER TABLE sp RENAME COLUMN label TO name;')
            assert query(first, 'SHOW INDEX FROM sp;')['results'][0]['rows'][0][1] == 'NAME'
            query(first, 'ALTER TABLE sp DROP COLUMN name;', expected=400)
            query(first, 'CREATE TABLE child (id INT PRIMARY KEY, pid INT REFERENCES sp(id)); INSERT INTO child VALUES (1,10),(2,NULL);')
            foreign = query(first, 'SHOW FOREIGN KEYS FROM child;')['results'][0]
            assert foreign['columns'] == ['FOREIGN_KEY', 'COLUMN', 'REFERENCED_TABLE', 'REFERENCED_COLUMN']
            assert foreign['rows'] == [['FK_CHILD_PID', 'PID', 'SP', 'ID']]
            before = first.read_bytes()
            query(first, 'INSERT INTO child VALUES (3,99);', expected=400)
            query(first, 'DELETE FROM sp WHERE id = 10;', expected=400)
            assert first.read_bytes() == before
            query(first, 'ALTER TABLE child DROP FOREIGN KEY fk_child_pid;')
            assert query(first, 'SHOW FOREIGN KEYS FROM child;')['results'][0]['rows'] == []
            query(first, 'CREATE VIEW live AS SELECT * FROM sp;')
            bad = work / 'bad.json'
            bad.write_text('invalid JSON')
            request('/api/catalog', {'catalog': str(bad)}, expected=400)
            request('/api/catalog', {'catalog': str(state), 'create': True}, expected=400)
            request('/api/workspace/save', {'workspace': {'version': 2}}, expected=400)
            request('/api/workspace/save', {'workspace': saved})
            assert request('/api/workspace')['workspace'] == saved
            assert state.stat().st_mode & 0o077 == 0
            request('/api/catalog', {'catalog': str(state)}, expected=400)
        finally:
            stop(process)
        process = start()
        try:
            assert request('/api/workspace')['workspace'] == saved
            assert query(first, 'SHOW VIEWS;')['results'][0]['rows'] == [['LIVE']]
            assert query(first, 'SELECT * FROM live;')['results'][0]['rows'] == [[10, 'Cà phê']]
            assert query(second, 'SHOW VIEWS;')['results'][0]['rows'] == []
            query(first, 'DROP VIEW live;')
            assert query(second, 'SELECT * FROM sp;')['results'][0]['rows'] == [[2]]
        finally:
            stop(process)
        # Startup failures must exit without publishing a ready marker or changing data.
        def rejected_start(overrides):
            marker = work / 'rejected-ready'
            marker.unlink(missing_ok=True)
            trial_env = dict(env, VDB_STUDIO_READY=str(marker), **overrides)
            result = subprocess.run(['sh', ROOT / 'studio/serve'], env=trial_env, cwd=ROOT,
                                    capture_output=True, timeout=30)
            assert result.returncode != 0, result.stdout.decode()
            assert not marker.exists()

        bad_before = bad.read_bytes()
        rejected_start({'VDB_STUDIO_DB': str(bad)})
        assert bad.read_bytes() == bad_before
        with socket.socket() as occupied:
            occupied.bind(('127.0.0.1', 0))
            occupied.listen(1)
            rejected_start({'VDB_STUDIO_PORT': str(occupied.getsockname()[1])})
        process = start()
        try:
            assert request('/api/workspace')['workspace'] == saved
            process.kill()
            process.wait(timeout=10)
        finally:
            stop(process)
        process = start()
        try:
            assert request('/api/workspace')['workspace'] == saved
            assert query(first, 'SELECT * FROM sp;')['results'][0]['rows'] == [[10, 'Cà phê']]
        finally:
            stop(process)
        state.write_text('invalid JSON')
        process = start()
        try:
            recovered = request('/api/workspace')
            assert recovered['workspace'] is None and recovered['workspaceError']
            assert list(work.glob('state.json.corrupt.*'))
        finally:
            stop(process)
    print('VDB Studio API tests: PASS')


if __name__ == '__main__':
    main()
