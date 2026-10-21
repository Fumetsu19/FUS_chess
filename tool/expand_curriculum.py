"""Сборка 150 новых уроков и 530 новых слов поверх первых десяти уроков.

Скрипт не входит в приложение: он генерирует assets/data/*.json.
"""
from __future__ import annotations

import random
import re
from typing import Any

try:
    import eng_to_ipa as ipa
except ImportError:  # pragma: no cover - fallback для чистой среды
    ipa = None

from expansion_a1a2 import A1_LESSONS, A2_LESSONS
from expansion_b1 import B1_LESSONS, B1_GRAMMAR_KEYS
from expansion_boost import BOOST_WORDS
from grammar_bank import GRAMMAR

RNG = random.Random(20261020)


def transcription(word: str) -> str:
    if ipa is None:
        return f"/{word}/"
    try:
        value = ipa.convert(word).replace("*", "").strip()
        return f"/{value}/" if value else f"/{word}/"
    except Exception:
        return f"/{word}/"


def blank_context(context: str, word: str) -> str:
    pattern = re.compile(re.escape(word), re.IGNORECASE)
    if not pattern.search(context):
        raise ValueError(f"Слово {word!r} отсутствует в контексте: {context}")
    return pattern.sub("___", context, count=1)


def build_task_options(correct: str, pool: list[str]) -> tuple[list[str], int]:
    distractors: list[str] = []
    for candidate in RNG.sample(pool, min(len(pool), 40)):
        if candidate != correct and candidate not in distractors:
            distractors.append(candidate)
        if len(distractors) == 2:
            break
    if len(distractors) < 2:
        distractors.extend(["другой вариант", "не подходит"][: 2 - len(distractors)])
    options = [correct, *distractors]
    RNG.shuffle(options)
    return options, options.index(correct)


def make_lesson(
    *,
    lesson_id: str,
    order: int,
    level: str,
    title: str,
    summary: str,
    grammar_key: str,
    word_ids: list[str],
    words: list[dict[str, Any]],
    context_en: str,
    context_ru: str,
    all_ru: list[str],
) -> dict[str, Any]:
    grammar = GRAMMAR[grammar_key]
    for word in words:
        if not re.search(re.escape(word["en"]), context_en, re.IGNORECASE):
            raise ValueError(
                f"{lesson_id}: слово {word['en']!r} отсутствует в контексте"
            )

    vocab_mc_word = words[0]
    options, correct = build_task_options(vocab_mc_word["ru"], all_ru)
    fill_word = words[1] if len(words) > 1 else words[0]
    fill_prompt = blank_context(context_en, fill_word["en"])
    fill_accepted = [fill_word["en"], fill_word["en"].capitalize()]
    build_words = grammar["build_answer"].replace(",", "").split()
    RNG.shuffle(build_words)

    exercises = [
        {
            "id": f"ex_{order:03d}_01",
            "type": "multiple_choice",
            "prompt": f"Что означает «{vocab_mc_word['en']}»?",
            "options": options,
            "correct": correct,
            "hint": f"Тема «{title}». Транскрипция: {vocab_mc_word['transcription']}.",
        },
        {
            "id": f"ex_{order:03d}_02",
            "type": "multiple_choice",
            "prompt": grammar["mc_prompt"],
            "options": grammar["mc_options"],
            "correct": grammar["mc_correct"],
            "hint": grammar["mc_hint"],
        },
        {
            "id": f"ex_{order:03d}_03",
            "type": "fill_blank",
            "prompt": fill_prompt,
            "answer": fill_word["en"],
            "accepted": fill_accepted,
            "hint": f"Первая буква: {fill_word['en'][0]}. Транскрипция: {fill_word['transcription']}.",
        },
        {
            "id": f"ex_{order:03d}_04",
            "type": "fill_blank",
            "prompt": grammar["fill_prompt"],
            "answer": grammar["fill_answer"],
            "accepted": grammar["fill_accepted"],
            "hint": grammar["fill_hint"],
        },
        {
            "id": f"ex_{order:03d}_05",
            "type": "build_sentence",
            "prompt": "Собери предложение",
            "words": build_words,
            "answer": grammar["build_answer"],
            "hint": grammar["build_hint"],
        },
    ]
    return {
        "id": lesson_id,
        "order": order,
        "level": level,
        "title": title,
        "summary": summary,
        "theory": {
            "blocks": [
                {"type": "text", "content": f"Тема урока — {title.lower()}. {summary}."},
                {"type": "text", "content": grammar["explanation"]},
                {"type": "example", "content": grammar["example"]},
                {"type": "note", "content": grammar["note"]},
                {"type": "example", "content": f"{context_en} — {context_ru}"},
            ]
        },
        "vocabulary_ids": word_ids,
        "exercises": exercises,
    }


def make_words(
    *,
    start_id: int,
    lesson_id: str,
    level: str,
    raw_words: list[tuple[str, str, str]],
    context_en: str,
    context_ru: str,
) -> tuple[list[dict[str, Any]], int]:
    result = []
    current = start_id
    for en, ru, pos in raw_words:
        result.append(
            {
                "id": f"w_{current:03d}",
                "en": en,
                "ru": ru,
                "transcription": transcription(en),
                "part_of_speech": pos,
                "example_en": context_en,
                "example_ru": context_ru,
                "lesson_id": lesson_id,
                "level": level,
            }
        )
        current += 1
    return result, current


def extend(
    existing_words: list[dict[str, Any]],
    existing_lessons: list[dict[str, Any]],
) -> None:
    # Старые A2-уроки (6–10) переносим после новых A1, чтобы уровни шли по порядку.
    reorder = {
        "lesson_06": 41,
        "lesson_07": 42,
        "lesson_08": 43,
        "lesson_09": 44,
        "lesson_10": 45,
    }
    for lesson in existing_lessons:
        if lesson["id"] in reorder:
            lesson["order"] = reorder[lesson["id"]]

    next_word_id = 81
    all_ru = [word["ru"] for word in existing_words]

    def add_level(
        *,
        specs: list[tuple],
        level: str,
        start_order: int,
        grammar_keys: list[str] | None,
        use_fixed_grammar: bool,
    ) -> None:
        nonlocal next_word_id
        for index, spec in enumerate(specs):
            if use_fixed_grammar:
                title, summary, grammar_key, raw_words, context_en, context_ru = spec
            else:
                title, summary, raw_words, context_en, context_ru = spec
                grammar_key = grammar_keys[index % len(grammar_keys)]  # type: ignore[index]
            order = start_order + index
            lesson_id = f"lesson_{order:03d}"
            words, next_word_id = make_words(
                start_id=next_word_id,
                lesson_id=lesson_id,
                level=level,
                raw_words=raw_words,
                context_en=context_en,
                context_ru=context_ru,
            )
            all_ru.extend(word["ru"] for word in words)
            existing_words.extend(words)
            existing_lessons.append(
                make_lesson(
                    lesson_id=lesson_id,
                    order=order,
                    level=level,
                    title=title,
                    summary=summary,
                    grammar_key=grammar_key,
                    word_ids=[word["id"] for word in words],
                    words=words,
                    context_en=context_en,
                    context_ru=context_ru,
                    all_ru=all_ru,
                )
            )

    add_level(
        specs=A1_LESSONS,
        level="A1",
        start_order=6,
        grammar_keys=None,
        use_fixed_grammar=True,
    )
    add_level(
        specs=A2_LESSONS,
        level="A2",
        start_order=46,
        grammar_keys=None,
        use_fixed_grammar=True,
    )
    add_level(
        specs=B1_LESSONS,
        level="B1",
        start_order=81,
        grammar_keys=B1_GRAMMAR_KEYS,
        use_fixed_grammar=False,
    )

    # Первые пять уроков получают дополнительную лексику: иначе в первой
    # партии слишком быстро заканчиваются новые слова.
    max_id = max(int(word["id"].split("_")[1]) for word in existing_words)
    lessons_by_id = {lesson["id"]: lesson for lesson in existing_lessons}
    for lesson_id, entries in BOOST_WORDS.items():
        lesson = lessons_by_id[lesson_id]
        level = lesson["level"]
        new_words = []
        for en, ru, pos, example_en, example_ru in entries:
            max_id += 1
            new_words.append(
                {
                    "id": f"w_{max_id:03d}",
                    "en": en,
                    "ru": ru,
                    "transcription": transcription(en),
                    "part_of_speech": pos,
                    "example_en": example_en,
                    "example_ru": example_ru,
                    "lesson_id": lesson_id,
                    "level": level,
                }
            )
        existing_words.extend(new_words)
        lesson["vocabulary_ids"].extend(word["id"] for word in new_words)
