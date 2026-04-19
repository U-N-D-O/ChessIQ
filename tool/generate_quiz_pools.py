from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import chess


ROOT = Path(__file__).resolve().parents[1]
OPENINGS_DIR = ROOT / 'openings'
OUTPUT_PATH = OPENINGS_DIR / 'quiz_pools.json'
DART_OUTPUT_PATH = ROOT / 'lib' / 'features' / 'quiz' / 'data' / 'opening_quiz_catalog.dart'
ECO_FILES = [OPENINGS_DIR / f'eco{letter}.json' for letter in 'ABCDE']

MOVE_NUMBER_RE = re.compile(r'\d+\.')
MOVE_NUMBER_TOKEN_RE = re.compile(r'^\d+\.(?:\.\.)?$')
MOVE_NUMBER_INLINE_RE = re.compile(r'\d+\.(?:\.\.)?')
WHITESPACE_RE = re.compile(r'\s+')
NAME_ANNOTATION_RE = re.compile(
    r'(\d+\.(?:\.\.)?\s*(?:O-O-O|O-O|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](?:=[QRBN])?[+#]?)(?:\s+(?:O-O-O|O-O|[KQRBN]?[a-h]?[1-8]?x?[a-h][1-8](?:=[QRBN])?[+#]?))*)',
    re.IGNORECASE,
)
NON_FAMILY_CHARS_RE = re.compile(r'[^a-z\-]')
RESULT_TOKENS = {'*', '1-0', '0-1', '1/2-1/2'}

QUIZ_DIFFICULTIES = ('easy', 'medium', 'hard', 'veryHard')
STUDY_CATEGORIES = {
    'easy': 'basic',
    'medium': 'advanced',
    'hard': 'master',
    'veryHard': 'grandmaster',
}

TIER_1_KEYWORDS = (
    'sicilian',
    'ruy lopez',
    'spanish game',
    'berlin defense',
    'berlin defence',
    'french defense',
    'french defence',
    'italian game',
    'giuoco piano',
    "queen's gambit",
    "king's indian",
    'caro-kann',
    'caro kann',
    'english opening',
    'nimzo-indian',
    'nimzo indian',
    'london system',
    'petroff',
    'petrov',
    'vienna game',
    'vienna gambit',
)

TIER_2_KEYWORDS = (
    'slav',
    'dutch',
    "queen's indian",
    'scotch game',
    'scotch gambit',
    "king's gambit",
    'grünfeld',
    'grunfeld',
    'pirc',
    'modern defense',
    'modern defence',
    'four knights',
    'catalan',
    'bogo-indian',
    'bogo indian',
    'semi-slav',
    'ponziani',
    'reti opening',
    'réti',
    'colle',
    'stonewall',
    'alapin',
    'smith-morra',
    'max lange',
    'evans gambit',
    'four knights',
)

TIER_3_KEYWORDS = (
    'alekhine',
    'benoni',
    'budapest',
    'bird',
    'scandinavian',
    'nimzowitsch',
    'nimzovich',
    'torre',
    'trompowsky',
    'benko',
    'polish',
    'hungarian',
    'latvian',
    'danish',
    'from gambit',
    'bowdler',
    'philidor',
    'owen',
    'blackmar',
    'jerome gambit',
    'center game',
)


def normalize_san(raw: str) -> str:
    cleaned = raw.lower().replace('*', '').strip()
    cleaned = MOVE_NUMBER_RE.sub('', cleaned)
    cleaned = cleaned.replace('...', '')
    cleaned = re.sub(r'[^a-z0-9 x#+\-/=]', '', cleaned)
    cleaned = WHITESPACE_RE.sub(' ', cleaned).strip()
    return cleaned


def raw_san_tokens(raw: str) -> list[str]:
    without_numbers = MOVE_NUMBER_INLINE_RE.sub(' ', raw.replace('*', ' '))
    tokens = [token for token in WHITESPACE_RE.split(without_numbers.strip()) if token]
    return [token for token in tokens if token not in RESULT_TOKENS and not MOVE_NUMBER_TOKEN_RE.match(token)]


def opening_popularity_score(name: str) -> float:
    lower = name.lower()
    if any(keyword in lower for keyword in TIER_1_KEYWORDS):
        return 0.92
    if any(keyword in lower for keyword in TIER_2_KEYWORDS):
        return 0.70
    if any(keyword in lower for keyword in TIER_3_KEYWORDS):
        return 0.50
    return 0.25


def opening_passes_difficulty_filter(score: float, difficulty: str) -> bool:
    if difficulty == 'easy':
        return score >= 0.86
    if difficulty == 'medium':
        return 0.65 <= score < 0.86
    if difficulty == 'hard':
        return 0.45 <= score < 0.65
    return score < 0.45


def quiz_total_ply_range(difficulty: str) -> tuple[int, int]:
    if difficulty == 'easy':
        return (2, 8)
    if difficulty == 'medium':
        return (6, 10)
    if difficulty == 'hard':
        return (8, 14)
    return (10, 18)


def line_within_total_ply_range(line: dict[str, object], difficulty: str) -> bool:
    minimum, maximum = quiz_total_ply_range(difficulty)
    total_ply = len(line['move_tokens'])
    return minimum <= total_ply <= maximum


def opening_name_annotation_key(name: str) -> str | None:
    match = NAME_ANNOTATION_RE.search(name)
    if match is None:
        return None
    return WHITESPACE_RE.sub(' ', match.group(1).strip().lower())


def has_opening_name_annotation(name: str) -> bool:
    key = opening_name_annotation_key(name)
    return key is not None and key != ''


def quiz_study_family_candidate(name: str) -> str:
    cleaned = name.strip()
    if cleaned == '':
        return 'Unnamed Opening'

    normalized_name = re.sub(r'[–—]+', '-', cleaned)
    split_index = -1
    for delimiter in (':', ',', ';', '(', ' - '):
        index = normalized_name.find(delimiter)
        if index > 0 and (split_index < 0 or index < split_index):
            split_index = index

    family = normalized_name[:split_index].strip() if split_index > 0 else normalized_name

    tokens = [token for token in family.split() if token]
    if not tokens:
        return cleaned

    family_terms = {
        'gambit',
        'defense',
        'defence',
        'opening',
        'openings',
        'game',
        'attack',
        'system',
        'countergambit',
        'counter-gambit',
    }

    family_end_index = -1
    for index, token in enumerate(tokens):
        normalized = NON_FAMILY_CHARS_RE.sub('', token.lower())
        if normalized in family_terms:
            family_end_index = index

    if family_end_index >= 0:
        return ' '.join(tokens[: family_end_index + 1])

    return family


def canonicalize_quiz_study_family(family: str) -> str:
    display = family.strip()
    if display == '':
        return 'Unnamed Opening'

    display = re.sub(r"[’`´]", "'", display)
    display = re.sub(r'[–—]+', '-', display)
    display = WHITESPACE_RE.sub(' ', display).strip()
    display = re.sub(r'\bDefence\b', 'Defense', display)
    display = re.sub(r'\bdefence\b', 'defense', display)
    display = re.sub(r'\bOpenings\b', 'Opening', display)
    display = re.sub(r'\bopenings\b', 'opening', display)
    display = re.sub(r"\bPetroff's\b", "Petrov's", display)
    display = re.sub(r'\bPetroff\b', 'Petrov', display)
    display = re.sub(r"\bpetroff's\b", "petrov's", display)
    display = re.sub(r'\bpetroff\b', 'petrov', display)

    normalized = WHITESPACE_RE.sub(' ', display.lower()).strip()
    alias_key = WHITESPACE_RE.sub(
        ' ',
        normalized.replace("'", '').replace('-', ' '),
    ).strip()

    if alias_key == 'sicilian defense':
        return 'Sicilian Defense'
    if alias_key == 'sicilian' or alias_key.startswith('sicilian ') or alias_key.endswith(' sicilian'):
        return 'Sicilian'
    if alias_key in {'english', 'english opening'}:
        return 'English Opening'
    if alias_key in {
        'queen pawn',
        'queens pawn',
        'queen pawn game',
        'queens pawn game',
        'queen pawn opening',
        'queens pawn opening',
    }:
        return "Queen's Pawn Game"
    if alias_key in {
        'king pawn',
        'kings pawn',
        'king pawn game',
        'kings pawn game',
        'king pawn opening',
        'kings pawn opening',
    }:
        return "King's Pawn Game"
    if alias_key in {
        'petrov',
        'petrov defense',
        'petrovs defense',
        'russian defense',
        'russian game',
    }:
        return 'Petrov Defense'
    if alias_key in {
        'caro kann',
        'caro kann defense',
        'caro kann defensive system',
    }:
        return 'Caro-Kann Defense'
    if alias_key in {'nimzo indian', 'nimzo indian defense'}:
        return 'Nimzo-Indian Defense'
    if alias_key in {'bogo indian', 'bogo indian defense'}:
        return 'Bogo-Indian Defense'
    if alias_key in {'queens indian', 'queens indian defense'}:
        return "Queen's Indian Defense"
    if alias_key in {'kings indian', 'kings indian defense'}:
        return "King's Indian Defense"

    return display


def quiz_study_family_name(name: str) -> str:
    return canonicalize_quiz_study_family(quiz_study_family_candidate(name))


def dedupe_quiz_study_lines_by_name(lines: list[dict[str, object]]) -> list[dict[str, object]]:
    unique_by_name: dict[str, dict[str, object]] = {}
    for line in lines:
        unique_by_name.setdefault(line['name'], line)
    return sorted(
        unique_by_name.values(),
        key=lambda line: (
            quiz_study_family_name(line['name']).lower(),
            line['name'].lower(),
        ),
    )


def is_replayable(raw_moves: str) -> bool:
    board = chess.Board()
    try:
        for token in raw_san_tokens(raw_moves):
            move = board.parse_san(token)
            board.push(move)
    except Exception:
        return False
    return True


def load_eco_lines() -> list[dict[str, object]]:
    lines: list[dict[str, object]] = []
    for file_path in ECO_FILES:
        with file_path.open('r', encoding='utf-8') as handle:
            data = json.load(handle)
        for entry in data.values():
            if not isinstance(entry, dict):
                continue
            moves_raw = str(entry.get('moves', '') or '')
            base_name = str(entry.get('name', '') or '')
            aliases = entry.get('aliases')
            alias_ct = ''
            alias_scid = ''
            if isinstance(aliases, dict):
                alias_ct = str(aliases.get('ct', '') or '')
                alias_scid = str(aliases.get('scid', '') or '')

            search_text = f'{base_name} {alias_ct} {alias_scid}'.lower()
            display_name = alias_ct if alias_ct else base_name
            if moves_raw == '' or display_name == '':
                continue

            normalized_moves = normalize_san(moves_raw)
            if normalized_moves == '':
                continue

            move_tokens = [token for token in normalized_moves.split(' ') if token]
            if not move_tokens:
                continue

            lines.append(
                {
                    'name': display_name,
                    'normalized_moves': normalized_moves,
                    'move_tokens': move_tokens,
                    'raw_moves': moves_raw,
                    'is_gambit': 'gambit' in search_text,
                }
            )
    return lines


def build_pools(lines: list[dict[str, object]]) -> dict[str, list[dict[str, object]]]:
    all_unique_by_name: dict[str, dict[str, object]] = {}
    for line in lines:
        all_unique_by_name.setdefault(line['name'], line)

    all_unique_sorted_by_rarity = sorted(
        all_unique_by_name.values(),
        key=lambda line: (opening_popularity_score(line['name']), line['name']),
    )

    replayable_by_name: dict[str, bool] = {}

    def line_is_replayable(line: dict[str, object]) -> bool:
        name = line['name']
        if name not in replayable_by_name:
            replayable_by_name[name] = is_replayable(line['raw_moves'])
        return replayable_by_name[name]

    no_annotation_replayable = [
        line
        for line in all_unique_sorted_by_rarity
        if not has_opening_name_annotation(line['name']) and line_is_replayable(line)
    ]

    pools: dict[str, list[dict[str, object]]] = {}
    for difficulty_index, difficulty in enumerate(QUIZ_DIFFICULTIES):
        ranged = [
            line
            for line in no_annotation_replayable
            if line_within_total_ply_range(line, difficulty)
        ]

        base = [
            line
            for line in ranged
            if opening_passes_difficulty_filter(
                opening_popularity_score(line['name']),
                difficulty,
            )
        ]

        if difficulty == 'veryHard' and len(base) < 250:
          existing_names = {line['name'] for line in base}
          for line in ranged:
              if len(base) >= 250:
                  break
              if line['name'] in existing_names:
                  continue
              base.append(line)
              existing_names.add(line['name'])

        guess_name_pool = list(base)
        pools[f'0:{difficulty_index}'] = guess_name_pool

        grouped: dict[str, int] = {}
        for line in base:
            move_tokens = line['move_tokens']
            if len(move_tokens) < 3:
                continue
            prefix = f'{move_tokens[0]} {move_tokens[1]}'
            grouped[prefix] = grouped.get(prefix, 0) + 1

        guess_line_pool = [
            line
            for line in base
            if len(line['move_tokens']) >= 3
            and grouped.get(f"{line['move_tokens'][0]} {line['move_tokens'][1]}", 0) >= 3
        ]
        pools[f'1:{difficulty_index}'] = guess_line_pool

        study_category = STUDY_CATEGORIES[difficulty]
        pools[f'study:{study_category}'] = dedupe_quiz_study_lines_by_name(
            guess_name_pool + guess_line_pool
        )

    pools['study:library'] = dedupe_quiz_study_lines_by_name(no_annotation_replayable)
    return pools


def serialize_pools(pools: dict[str, list[dict[str, object]]]) -> dict[str, object]:
    line_id_by_key: dict[str, int] = {}
    serialized_lines: list[dict[str, object]] = []
    serialized_pools: dict[str, list[int]] = {}

    for pool_key in sorted(pools.keys()):
        pool_ids: list[int] = []
        for line in pools[pool_key]:
            line_key = f"{line['name']}\u0000{line['normalized_moves']}"
            line_id = line_id_by_key.get(line_key)
            if line_id is None:
                line_id = len(serialized_lines)
                line_id_by_key[line_key] = line_id
                serialized_lines.append(
                    {
                        'n': line['name'],
                        'm': line['normalized_moves'],
                        'g': bool(line['is_gambit']),
                    }
                )
            pool_ids.append(line_id)
        serialized_pools[pool_key] = pool_ids

    return {
        'version': 1,
        'lines': serialized_lines,
        'pools': serialized_pools,
        'meta': {
            'lineCount': len(serialized_lines),
            'poolSizes': {key: len(value) for key, value in serialized_pools.items()},
        },
    }


def write_dart_catalog(payload: dict[str, object]) -> None:
    json_payload = json.dumps(payload, ensure_ascii=False, separators=(',', ':'))
    dart_source = (
        "import 'dart:convert';\n\n"
        'Map<String, dynamic> loadOpeningQuizCatalog() {\n'
        '  final decoded = jsonDecode(_openingQuizCatalogJson);\n'
        '  if (decoded is! Map<String, dynamic>) {\n'
        "    throw const FormatException('Invalid opening quiz catalog payload');\n"
        '  }\n'
        '  return decoded;\n'
        '}\n\n'
        "const String _openingQuizCatalogJson = r'''\n"
        f'{json_payload}\n'
        "''';\n"
    )
    DART_OUTPUT_PATH.write_text(dart_source, encoding='utf-8')


def main() -> int:
    lines = load_eco_lines()
    pools = build_pools(lines)
    payload = serialize_pools(pools)
    OUTPUT_PATH.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + '\n',
        encoding='utf-8',
    )
    write_dart_catalog(payload)

    print(f'Loaded {len(lines)} ECO lines')
    print(f'Wrote {payload["meta"]["lineCount"]} unique pooled lines to {OUTPUT_PATH}')
    print(f'Wrote built-in opening quiz catalog to {DART_OUTPUT_PATH}')
    for key, size in payload['meta']['poolSizes'].items():
        print(f'  {key}: {size}')
    return 0


if __name__ == '__main__':
    sys.exit(main())