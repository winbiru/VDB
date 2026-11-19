"""Measure the production V++ JOIN operators on identical temporary fixtures."""

import argparse
import json
import os
import pathlib
import platform
import random
import statistics
import subprocess
import tempfile


def fixture(left_size, right_size, distribution, key_type, seed):
    rng = random.Random(seed)

    def rows(size, right):
        if distribution == 'unique':
            keys = list(range(size))
        elif distribution == 'duplicate':
            keys = [i % 2 for i in range(size)]
        elif distribution == 'null':
            keys = [None if i % 4 else i for i in range(size)]
        elif distribution == 'disjoint':
            keys = [i + (100000 if right else 0) for i in range(size)]
        else:
            keys = [0 if i % 4 else i for i in range(size)]
        if key_type == 'TEXT':
            keys = [None if k is None else f'khóa-{k}' for k in keys]
        rng.shuffle(keys)
        return [[i, k] for i, k in enumerate(keys)]

    return rows(left_size, False), rows(right_size, True)


def expected_rows(left, right, kind):
    result = []
    pairs = 0
    for a in left:
        matches = [a + b for b in right if a[1] is not None and a[1] == b[1]]
        pairs += len(matches)
        result.extend(matches or ([a + [None, None]] if kind == 'LEFT' else []))
    return result, pairs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('executable', type=pathlib.Path)
    parser.add_argument('--samples', type=int, default=5)
    parser.add_argument('--output', type=pathlib.Path)
    parser.add_argument('--suite', choices=('calibration', 'holdout'), default='calibration')
    parser.add_argument('--replay', type=pathlib.Path,
                        help='re-evaluate planner choices using previously validated timings')
    args = parser.parse_args()
    if args.samples < 3:
        parser.error('--samples must be at least 3')
    cases = [(n, n, 'unique', 'INT', 'INNER') for n in (2, 8, 16, 32, 64, 128, 256)]
    cases += [(l, r, 'unique', 'INT', 'INNER') for l, r in ((2, 256), (8, 256), (256, 8), (32, 512))]
    cases += [(n, n, d, 'INT', 'INNER') for n in (32, 64, 128, 256)
              for d in ('duplicate', 'skew', 'null', 'disjoint')]
    cases += [(64, 128, d, 'TEXT', kind) for d in ('unique', 'duplicate', 'null')
              for kind in ('INNER', 'LEFT')]
    seed = 624
    if args.suite == 'holdout':
        seed = 1624
        cases = [(3, 192, 'unique', 'INT', 'INNER'), (12, 12, 'unique', 'INT', 'INNER'),
                 (24, 96, 'unique', 'TEXT', 'LEFT'), (192, 12, 'unique', 'INT', 'INNER'),
                 (48, 48, 'duplicate', 'INT', 'INNER'), (96, 80, 'skew', 'INT', 'LEFT'),
                 (80, 96, 'duplicate', 'TEXT', 'LEFT'), (96, 144, 'null', 'INT', 'LEFT'),
                 (144, 96, 'disjoint', 'TEXT', 'INNER'), (16, 192, 'null', 'TEXT', 'LEFT')]
    replay = None
    if args.replay:
        replay = json.loads(args.replay.read_text())
        cases = [tuple(c[k] for k in ('left', 'right', 'distribution', 'key_type', 'kind'))
                 for c in replay['cases']]
        seed = replay.get('seed', 624)
    reports = []
    with tempfile.TemporaryDirectory() as temp:
        path = pathlib.Path(temp) / 'fixture.json'
        for i, (l, r, distribution, key_type, kind) in enumerate(cases):
            left, right = fixture(l, r, distribution, key_type, seed + i)
            expected, pairs = expected_rows(left, right, kind)
            path.write_text(json.dumps([left, right, kind, key_type, pairs, 0 if replay else args.samples]))
            raw = subprocess.check_output([str(args.executable.resolve())],
                                          env={**os.environ, 'VDB_DATA': str(path)}, text=True)
            samples, selected, indexed, height, result = json.loads(raw)
            if replay:
                previous = replay['cases'][i]
                assert (pairs, len(expected), height) == (previous['pairs'], previous['output_rows'], previous['height'])
                samples = list(previous['samples_ms'].items())
            else:
                assert json.loads(result) == expected, (l, r, distribution, key_type, kind)
            times = {name: statistics.median(values) for name, values in samples}
            report = dict(left=l, right=r, distribution=distribution, key_type=key_type,
                          kind=kind, pairs=pairs, output_rows=len(expected), height=height,
                          selected=selected, selected_indexed=indexed, median_ms=times,
                          samples_ms=dict(samples))
            reports.append(report)
            print(f'{l:3} x {r:<3} {distribution:9} {key_type:4} {kind:5} '
                  + ' '.join(f'{name}={ms:.3f}' for name, ms in times.items())
                  + f' | {selected} / {indexed}', flush=True)
    for indexed in (False, True):
        def quality(cases):
            ratios = []
            for case in cases:
                times = case['median_ms']
                eligible = [v for k, v in times.items() if indexed or k != 'INDEX_NESTED_LOOP_JOIN']
                chosen = times[case['selected_indexed' if indexed else 'selected']]
                ratios.append(chosen / min(eligible))
            return sum(r == 1 for r in ratios), statistics.mean(ratios), max(ratios)
        hits, mean, worst = quality(reports)
        print(f'{"indexed" if indexed else "no index"}: fastest {hits}/{len(reports)}, '
              f'mean slowdown {mean:.4f}x, worst {worst:.4f}x')
        if replay:
            hits, mean, worst = quality(replay['cases'])
            print(f'  original: fastest {hits}/{len(reports)}, mean slowdown {mean:.4f}x, worst {worst:.4f}x')
    if args.output:
        args.output.write_text(json.dumps(dict(platform=replay['platform'] if replay else platform.platform(),
                                               samples=replay['samples'] if replay else args.samples,
                                               seed=seed, cases=reports), indent=2) + '\n')


if __name__ == '__main__':
    main()
