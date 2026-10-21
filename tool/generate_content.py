"""Генератор учебного контента Fchess: 160 уроков A1–B1.

App читает только готовые assets/data/*.json. Первые 10 уроков заданы
вручную, остальные 150 собираются из тематических спецификаций.
"""
from __future__ import annotations

import json
from pathlib import Path

from expand_curriculum import extend

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "assets" / "data"

WORDS: list[dict] = []


def word(
    wid: str,
    en: str,
    ru: str,
    transcription: str,
    pos: str,
    example_en: str,
    example_ru: str,
    lesson_id: str,
    level: str,
) -> str:
    WORDS.append(
        {
            "id": wid,
            "en": en,
            "ru": ru,
            "transcription": transcription,
            "part_of_speech": pos,
            "example_en": example_en,
            "example_ru": example_ru,
            "lesson_id": lesson_id,
            "level": level,
        }
    )
    return wid


# --- lesson_01: greetings -------------------------------------------------
w1 = [
    word("w_001", "hello", "привет", "/həˈləʊ/", "interjection", "Hello! How are you?", "Привет! Как дела?", "lesson_01", "A1"),
    word("w_002", "name", "имя", "/neɪm/", "noun", "My name is Anna.", "Меня зовут Анна.", "lesson_01", "A1"),
    word("w_003", "nice", "приятный", "/naɪs/", "adjective", "Nice to meet you.", "Приятно познакомиться.", "lesson_01", "A1"),
    word("w_004", "meet", "знакомиться; встречать", "/miːt/", "verb", "We meet at school.", "Мы знакомимся в школе.", "lesson_01", "A1"),
    word("w_005", "how", "как", "/haʊ/", "adverb", "How are you?", "Как ты?", "lesson_01", "A1"),
    word("w_006", "fine", "хорошо; прекрасный", "/faɪn/", "adjective", "I am fine, thank you.", "Я в порядке, спасибо.", "lesson_01", "A1"),
    word("w_007", "thanks", "спасибо", "/θæŋks/", "interjection", "Thanks for your help.", "Спасибо за помощь.", "lesson_01", "A1"),
    word("w_008", "goodbye", "до свидания", "/ˌɡʊdˈbaɪ/", "interjection", "Goodbye! See you tomorrow.", "До свидания! Увидимся завтра.", "lesson_01", "A1"),
]

# --- lesson_02: numbers & age --------------------------------------------
w2 = [
    word("w_009", "one", "один", "/wʌn/", "numeral", "I have one brother.", "У меня один брат.", "lesson_02", "A1"),
    word("w_010", "two", "два", "/tuː/", "numeral", "She has two cats.", "У неё две кошки.", "lesson_02", "A1"),
    word("w_011", "three", "три", "/θriː/", "numeral", "We have three apples.", "У нас три яблока.", "lesson_02", "A1"),
    word("w_012", "five", "пять", "/faɪv/", "numeral", "My sister is five.", "Моей сестре пять лет.", "lesson_02", "A1"),
    word("w_013", "ten", "десять", "/ten/", "numeral", "I am ten years old.", "Мне десять лет.", "lesson_02", "A1"),
    word("w_014", "age", "возраст", "/eɪdʒ/", "noun", "What is your age?", "Какой у тебя возраст?", "lesson_02", "A1"),
    word("w_015", "old", "старый; … лет", "/əʊld/", "adjective", "How old are you?", "Сколько тебе лет?", "lesson_02", "A1"),
    word("w_016", "year", "год", "/jɪə/", "noun", "It is a new year.", "Это новый год.", "lesson_02", "A1"),
]

# --- lesson_03: family ----------------------------------------------------
w3 = [
    word("w_017", "mother", "мать, мама", "/ˈmʌðə/", "noun", "My mother is a teacher.", "Моя мама — учитель.", "lesson_03", "A1"),
    word("w_018", "father", "отец, папа", "/ˈfɑːðə/", "noun", "My father is a doctor.", "Мой папа — врач.", "lesson_03", "A1"),
    word("w_019", "sister", "сестра", "/ˈsɪstə/", "noun", "My sister is ten.", "Моей сестре десять.", "lesson_03", "A1"),
    word("w_020", "brother", "брат", "/ˈbrʌðə/", "noun", "I have one brother.", "У меня один брат.", "lesson_03", "A1"),
    word("w_021", "family", "семья", "/ˈfæməli/", "noun", "My family is big.", "Моя семья большая.", "lesson_03", "A1"),
    word("w_022", "friend", "друг", "/frend/", "noun", "Anna is my friend.", "Анна — мой друг.", "lesson_03", "A1"),
    word("w_023", "son", "сын", "/sʌn/", "noun", "Their son is at school.", "Их сын в школе.", "lesson_03", "A1"),
    word("w_024", "daughter", "дочь", "/ˈdɔːtə/", "noun", "Her daughter is five.", "Её дочери пять лет.", "lesson_03", "A1"),
]

# --- lesson_04: food & drinks --------------------------------------------
w4 = [
    word("w_025", "water", "вода", "/ˈwɔːtə/", "noun", "I drink water every day.", "Я пью воду каждый день.", "lesson_04", "A1"),
    word("w_026", "bread", "хлеб", "/bred/", "noun", "We eat bread for breakfast.", "Мы едим хлеб на завтрак.", "lesson_04", "A1"),
    word("w_027", "apple", "яблоко", "/ˈæpl/", "noun", "This apple is green.", "Это яблоко зелёное.", "lesson_04", "A1"),
    word("w_028", "milk", "молоко", "/mɪlk/", "noun", "The milk is cold.", "Молоко холодное.", "lesson_04", "A1"),
    word("w_029", "coffee", "кофе", "/ˈkɒfi/", "noun", "I drink coffee in the morning.", "Я пью кофе утром.", "lesson_04", "A1"),
    word("w_030", "tea", "чай", "/tiː/", "noun", "Would you like some tea?", "Хочешь чаю?", "lesson_04", "A1"),
    word("w_031", "eat", "есть, кушать", "/iːt/", "verb", "I eat an apple every day.", "Я ем яблоко каждый день.", "lesson_04", "A1"),
    word("w_032", "drink", "пить", "/drɪŋk/", "verb", "We drink tea at home.", "Мы пьём чай дома.", "lesson_04", "A1"),
]

# --- lesson_05: daily routine --------------------------------------------
w5 = [
    word("w_033", "wake up", "просыпаться", "/weɪk ʌp/", "verb", "I wake up at seven.", "Я просыпаюсь в семь.", "lesson_05", "A1"),
    word("w_034", "morning", "утро", "/ˈmɔːnɪŋ/", "noun", "Good morning!", "Доброе утро!", "lesson_05", "A1"),
    word("w_035", "work", "работа; работать", "/wɜːk/", "noun / verb", "I go to work at nine.", "Я иду на работу в девять.", "lesson_05", "A1"),
    word("w_036", "home", "дом", "/həʊm/", "noun", "I come home at six.", "Я прихожу домой в шесть.", "lesson_05", "A1"),
    word("w_037", "evening", "вечер", "/ˈiːvnɪŋ/", "noun", "In the evening I read.", "Вечером я читаю.", "lesson_05", "A1"),
    word("w_038", "sleep", "спать", "/sliːp/", "verb", "I sleep at ten.", "Я сплю в десять.", "lesson_05", "A1"),
    word("w_039", "usually", "обычно", "/ˈjuːʒuəli/", "adverb", "I usually walk to work.", "Я обычно хожу на работу пешком.", "lesson_05", "A1"),
    word("w_040", "early", "рано; ранний", "/ˈɜːli/", "adverb / adjective", "I get up early.", "Я встаю рано.", "lesson_05", "A1"),
]

# --- lesson_06: in the city ----------------------------------------------
w6 = [
    word("w_041", "street", "улица", "/striːt/", "noun", "The street is quiet.", "Улица тихая.", "lesson_06", "A2"),
    word("w_042", "shop", "магазин", "/ʃɒp/", "noun", "The shop is near my home.", "Магазин рядом с моим домом.", "lesson_06", "A2"),
    word("w_043", "station", "станция", "/ˈsteɪʃn/", "noun", "The bus station is on the left.", "Автобусная станция слева.", "lesson_06", "A2"),
    word("w_044", "bus", "автобус", "/bʌs/", "noun", "I take the bus to work.", "Я езжу на работу на автобусе.", "lesson_06", "A2"),
    word("w_045", "ticket", "билет", "/ˈtɪkɪt/", "noun", "I need a bus ticket.", "Мне нужен автобусный билет.", "lesson_06", "A2"),
    word("w_046", "left", "левый; налево", "/left/", "adjective / adverb", "Turn left at the shop.", "Поверни налево у магазина.", "lesson_06", "A2"),
    word("w_047", "right", "правый; направо", "/raɪt/", "adjective / adverb", "The station is on the right.", "Станция справа.", "lesson_06", "A2"),
    word("w_048", "near", "рядом, около", "/nɪə/", "preposition", "The hotel is near the station.", "Отель рядом со станцией.", "lesson_06", "A2"),
]

# --- lesson_07: shopping --------------------------------------------------
w7 = [
    word("w_049", "buy", "покупать", "/baɪ/", "verb", "I want to buy this shirt.", "Я хочу купить эту рубашку.", "lesson_07", "A2"),
    word("w_050", "price", "цена", "/praɪs/", "noun", "What is the price?", "Какая цена?", "lesson_07", "A2"),
    word("w_051", "money", "деньги", "/ˈmʌni/", "noun", "I have some money.", "У меня есть немного денег.", "lesson_07", "A2"),
    word("w_052", "cheap", "дешёвый", "/tʃiːp/", "adjective", "This bag is cheap.", "Эта сумка дешёвая.", "lesson_07", "A2"),
    word("w_053", "expensive", "дорогой", "/ɪkˈspensɪv/", "adjective", "That watch is expensive.", "Те часы дорогие.", "lesson_07", "A2"),
    word("w_054", "size", "размер", "/saɪz/", "noun", "What size are you?", "Какой у тебя размер?", "lesson_07", "A2"),
    word("w_055", "try", "примерять; пытаться", "/traɪ/", "verb", "Can I try this jacket?", "Можно примерить эту куртку?", "lesson_07", "A2"),
    word("w_056", "pay", "платить", "/peɪ/", "verb", "I can pay by card.", "Я могу заплатить картой.", "lesson_07", "A2"),
]

# --- lesson_08: weather & plans ------------------------------------------
w8 = [
    word("w_057", "weather", "погода", "/ˈweðə/", "noun", "The weather is nice today.", "Сегодня хорошая погода.", "lesson_08", "A2"),
    word("w_058", "rain", "дождь", "/reɪn/", "noun", "There is a lot of rain.", "Идёт сильный дождь.", "lesson_08", "A2"),
    word("w_059", "sunny", "солнечный", "/ˈsʌni/", "adjective", "It is sunny tomorrow.", "Завтра солнечно.", "lesson_08", "A2"),
    word("w_060", "cold", "холодный", "/kəʊld/", "adjective", "It is cold outside.", "На улице холодно.", "lesson_08", "A2"),
    word("w_061", "warm", "тёплый", "/wɔːm/", "adjective", "The evening is warm.", "Вечер тёплый.", "lesson_08", "A2"),
    word("w_062", "tomorrow", "завтра", "/təˈmɒrəʊ/", "adverb", "See you tomorrow.", "Увидимся завтра.", "lesson_08", "A2"),
    word("w_063", "plan", "план; планировать", "/plæn/", "noun / verb", "What is your plan?", "Какой у тебя план?", "lesson_08", "A2"),
    word("w_064", "weekend", "выходные", "/ˌwiːkˈend/", "noun", "I rest at the weekend.", "Я отдыхаю на выходных.", "lesson_08", "A2"),
]

# --- lesson_09: travel ----------------------------------------------------
w9 = [
    word("w_065", "travel", "путешествовать", "/ˈtrævl/", "verb", "I want to travel by train.", "Я хочу путешествовать поездом.", "lesson_09", "A2"),
    word("w_066", "train", "поезд", "/treɪn/", "noun", "The train leaves at nine.", "Поезд отправляется в девять.", "lesson_09", "A2"),
    word("w_067", "airport", "аэропорт", "/ˈeəpɔːt/", "noun", "We go to the airport.", "Мы едем в аэропорт.", "lesson_09", "A2"),
    word("w_068", "hotel", "отель", "/həʊˈtel/", "noun", "The hotel is near the station.", "Отель рядом со станцией.", "lesson_09", "A2"),
    word("w_069", "luggage", "багаж", "/ˈlʌɡɪdʒ/", "noun", "My luggage is heavy.", "Мой багаж тяжёлый.", "lesson_09", "A2"),
    word("w_070", "journey", "поездка, путь", "/ˈdʒɜːni/", "noun", "The journey is long.", "Поездка долгая.", "lesson_09", "A2"),
    word("w_071", "flight", "рейс, полёт", "/flaɪt/", "noun", "My flight is at noon.", "Мой рейс в полдень.", "lesson_09", "A2"),
    word("w_072", "passport", "паспорт", "/ˈpɑːspɔːt/", "noun", "Do not forget your passport.", "Не забудь паспорт.", "lesson_09", "A2"),
]

# --- lesson_10: health ----------------------------------------------------
w10 = [
    word("w_073", "doctor", "врач", "/ˈdɒktə/", "noun", "I need to see a doctor.", "Мне нужно к врачу.", "lesson_10", "A2"),
    word("w_074", "headache", "головная боль", "/ˈhedeɪk/", "noun", "I have a headache.", "У меня болит голова.", "lesson_10", "A2"),
    word("w_075", "medicine", "лекарство", "/ˈmedsn/", "noun", "Take the medicine after food.", "Прими лекарство после еды.", "lesson_10", "A2"),
    word("w_076", "rest", "отдых; отдыхать", "/rest/", "noun / verb", "You should rest more.", "Тебе следует больше отдыхать.", "lesson_10", "A2"),
    word("w_077", "healthy", "здоровый", "/ˈhelθi/", "adjective", "Fruit is healthy.", "Фрукты полезны.", "lesson_10", "A2"),
    word("w_078", "feel", "чувствовать", "/fiːl/", "verb", "I feel ill today.", "Сегодня я чувствую себя больным.", "lesson_10", "A2"),
    word("w_079", "hurt", "болеть; причинять боль", "/hɜːt/", "verb", "My head hurts.", "У меня болит голова.", "lesson_10", "A2"),
    word("w_080", "ill", "больной", "/ɪl/", "adjective", "She is ill today.", "Она сегодня больна.", "lesson_10", "A2"),
]


def mc(eid: str, prompt: str, options: list[str], correct: int, hint: str) -> dict:
    return {
        "id": eid,
        "type": "multiple_choice",
        "prompt": prompt,
        "options": options,
        "correct": correct,
        "hint": hint,
    }


def fill(eid: str, prompt: str, answer: str, accepted: list[str], hint: str) -> dict:
    return {
        "id": eid,
        "type": "fill_blank",
        "prompt": prompt,
        "answer": answer,
        "accepted": accepted,
        "hint": hint,
    }


def build(eid: str, prompt: str, words: list[str], answer: str, hint: str) -> dict:
    return {
        "id": eid,
        "type": "build_sentence",
        "prompt": prompt,
        "words": words,
        "answer": answer,
        "hint": hint,
    }


LESSONS = [
    {
        "id": "lesson_01",
        "order": 1,
        "level": "A1",
        "title": "Приветствия и знакомство",
        "summary": "Учимся здороваться и представляться",
        "theory": {
            "blocks": [
                {"type": "text", "content": "В английском приветствие зависит от ситуации. С друзьями говорят коротко: Hi! В школе, в магазине или с новым человеком лучше сказать Hello! Утром можно добавить Good morning!"},
                {"type": "example", "content": "Hello! My name is Anna. — Привет! Меня зовут Анна."},
                {"type": "note", "content": "«Hi» — неформально, «Hello» — нейтрально, «Good morning» — до полудня."},
                {"type": "example", "content": "Nice to meet you! — Приятно познакомиться!"},
                {"type": "text", "content": "Чтобы спросить «Как дела?», скажи How are you? Короткий ответ — I am fine, thanks. В конце разговора говорят Goodbye! или See you!"},
            ]
        },
        "vocabulary_ids": w1,
        "exercises": [
            mc("ex_01_01", "Как сказать «Привет»?", ["Hello", "Goodbye", "Thanks"], 0, "Самое частое приветствие, начинается с H"),
            mc("ex_01_02", "Что ответить на «How are you?»?", ["I am fine, thanks.", "My name is Anna.", "Goodbye!"], 0, "Скажи, что у тебя всё хорошо, и поблагодари"),
            fill("ex_01_03", "My ___ is Anna.", "name", ["name", "Name"], "После My говорят слово «имя»"),
            fill("ex_01_04", "Nice to ___ you.", "meet", ["meet", "Meet"], "Глагол «знакомиться» из фразы Nice to meet you"),
            build("ex_01_05", "Собери предложение", ["is", "My", "Anna", "name"], "My name is Anna", "Начни с притяжательного местоимения «мой»"),
        ],
    },
    {
        "id": "lesson_02",
        "order": 2,
        "level": "A1",
        "title": "Числа и возраст",
        "summary": "Считаем до десяти и говорим, сколько кому лет",
        "theory": {
            "blocks": [
                {"type": "text", "content": "Числа от одного до десяти: one, two, three, four, five, six, seven, eight, nine, ten. Они пригодятся в магазине, в отеле и при знакомстве."},
                {"type": "example", "content": "I am ten years old. — Мне десять лет."},
                {"type": "note", "content": "По-английски возраст говорят через I am … years old, без слова «мне»."},
                {"type": "example", "content": "How old are you? — Сколько тебе лет?"},
                {"type": "text", "content": "Слово year значит «год», а old в этой фразе — «лет». Не путай с прилагательным old «старый»."},
            ]
        },
        "vocabulary_ids": w2,
        "exercises": [
            mc("ex_02_01", "Какое слово значит «пять»?", ["five", "three", "ten"], 0, "Число между four и six"),
            mc("ex_02_02", "Как спросить «Сколько тебе лет?»?", ["How old are you?", "How are you?", "What is your name?"], 0, "В вопросе есть слово old"),
            fill("ex_02_03", "I am ten years ___.", "old", ["old", "Old"], "Слово после years в фразе о возрасте"),
            fill("ex_02_04", "My brother is ___.", "five", ["five", "5"], "Число между четырьмя и шестью"),
            build("ex_02_05", "Собери вопрос", ["old", "are", "How", "you"], "How old are you?", "Начни с вопросительного слова How"),
        ],
    },
    {
        "id": "lesson_03",
        "order": 3,
        "level": "A1",
        "title": "Семья и друзья",
        "summary": "Рассказываем о близких",
        "theory": {
            "blocks": [
                {"type": "text", "content": "Близкие люди: mother — мама, father — папа, sister — сестра, brother — брат. Вместе они — family."},
                {"type": "example", "content": "This is my family. — Это моя семья."},
                {"type": "note", "content": "Перед существительным в единственном числе ставим my: my mother, my friend."},
                {"type": "example", "content": "Anna is my friend. — Анна — мой друг."},
                {"type": "text", "content": "Слово friend подходит и для друга, и для подруги. Для сына и дочери есть отдельные слова: son и daughter."},
            ]
        },
        "vocabulary_ids": w3,
        "exercises": [
            mc("ex_03_01", "«Сестра» — это…", ["sister", "brother", "mother"], 0, "Слово начинается с s"),
            mc("ex_03_02", "Выбери слово «семья»", ["family", "friend", "father"], 0, "В слове есть буква m"),
            fill("ex_03_03", "My ___ is a doctor.", "father", ["father", "Father", "dad", "Dad"], "Мужчина-родитель"),
            fill("ex_03_04", "I have one ___.", "sister", ["sister", "Sister"], "Девочка-сиблинг"),
            build("ex_03_05", "Собери предложение", ["is", "My", "a", "mother", "teacher"], "My mother is a teacher", "Начни с My mother"),
        ],
    },
    {
        "id": "lesson_04",
        "order": 4,
        "level": "A1",
        "title": "Еда и напитки",
        "summary": "Заказываем еду и говорим о любимых продуктах",
        "theory": {
            "blocks": [
                {"type": "text", "content": "Простые продукты и напитки: water — вода, bread — хлеб, apple — яблоко, milk — молоко, coffee — кофе, tea — чай."},
                {"type": "example", "content": "I drink coffee in the morning. — Я пью кофе утром."},
                {"type": "note", "content": "Глагол eat — «есть, кушать», drink — «пить». Съедобное мы eat, напитки drink."},
                {"type": "example", "content": "Would you like some tea? — Хочешь чаю?"},
                {"type": "text", "content": "Вежливая просьба часто начинается с Can I have…? — «Можно мне…?». Это пригодится в кафе."},
            ]
        },
        "vocabulary_ids": w4,
        "exercises": [
            mc("ex_04_01", "Что мы пьём?", ["water", "bread", "apple"], 0, "Жидкость без цвета"),
            mc("ex_04_02", "«Яблоко» — это…", ["apple", "milk", "tea"], 0, "Фрукт, начинается с a"),
            fill("ex_04_03", "I drink ___ in the morning.", "coffee", ["coffee", "Coffee"], "Горячий тёмный напиток"),
            fill("ex_04_04", "I ___ bread for breakfast.", "eat", ["eat", "Eat"], "Глагол «кушать»"),
            build("ex_04_05", "Собери предложение", ["and", "I", "bread", "eat", "cheese"], "I eat bread and cheese", "Начни с I eat"),
        ],
    },
    {
        "id": "lesson_05",
        "order": 5,
        "level": "A1",
        "title": "Мой день",
        "summary": "Говорим о распорядке дня",
        "theory": {
            "blocks": [
                {"type": "text", "content": "Распорядок дня: wake up — просыпаться, go to work — идти на работу, come home — приходить домой, go to sleep — ложиться спать."},
                {"type": "example", "content": "I usually wake up at seven. — Я обычно просыпаюсь в семь."},
                {"type": "note", "content": "Usually ставится перед основным глаголом: I usually work. Но с глаголом be — после него: I am usually at home."},
                {"type": "example", "content": "In the evening I read at home. — Вечером я читаю дома."},
                {"type": "text", "content": "Время суток: morning — утро, evening — вечер. Слово early значит «рано», а не «ранний» в большинстве фраз о времени."},
            ]
        },
        "vocabulary_ids": w5,
        "exercises": [
            mc("ex_05_01", "Что делают утром, когда встают?", ["wake up", "sleep", "goodbye"], 0, "Фразовый глагол с up"),
            mc("ex_05_02", "«Вечер» — это…", ["evening", "morning", "home"], 0, "Время после дня"),
            fill("ex_05_03", "I usually ___ up at seven.", "wake", ["wake", "Wake"], "Глагол перед up"),
            fill("ex_05_04", "I go to ___ at nine in the evening.", "sleep", ["sleep", "Sleep", "bed", "Bed"], "Что делают ночью"),
            build("ex_05_05", "Собери предложение", ["usually", "I", "at", "work", "nine"], "I usually work at nine", "Начни с I usually"),
        ],
    },
    {
        "id": "lesson_06",
        "order": 6,
        "level": "A2",
        "title": "В городе",
        "summary": "Спрашиваем дорогу и пользуемся транспортом",
        "theory": {
            "blocks": [
                {"type": "text", "content": "В городе есть street — улица, shop — магазин, station — станция, bus — автобус. Билет — ticket."},
                {"type": "example", "content": "The hotel is near the station. — Отель рядом со станцией."},
                {"type": "note", "content": "Направление: turn left — поверни налево, turn right — поверни направо. Near — «рядом, около»."},
                {"type": "example", "content": "Excuse me, where is the bus station? — Извините, где автобусная станция?"},
                {"type": "text", "content": "Чтобы спросить дорогу, начни с Excuse me. Затем спроси Where is…? — «Где находится…?»."},
            ]
        },
        "vocabulary_ids": w6,
        "exercises": [
            mc("ex_06_01", "Где ждут автобус?", ["at the bus station", "at the airport", "at home"], 0, "Там слово bus"),
            mc("ex_06_02", "«Налево» — это…", ["left", "right", "near"], 0, "Слово начинается с l"),
            fill("ex_06_03", "I buy a ___ for the bus.", "ticket", ["ticket", "Ticket"], "Документ на проезд"),
            fill("ex_06_04", "The shop is ___ the station.", "near", ["near", "Near"], "Предлог «рядом с»"),
            build("ex_06_05", "Собери предложение", ["is", "The", "near", "hotel", "station", "the"], "The hotel is near the station", "Начни с The hotel"),
        ],
    },
    {
        "id": "lesson_07",
        "order": 7,
        "level": "A2",
        "title": "Покупки",
        "summary": "Спрашиваем цену, размер и платим",
        "theory": {
            "blocks": [
                {"type": "text", "content": "В магазине нужны слова buy — покупать, price — цена, money — деньги, size — размер. Cheap — дешёвый, expensive — дорогой."},
                {"type": "example", "content": "How much does it cost? — Сколько это стоит?"},
                {"type": "note", "content": "Размер спрашивают так: What size are you? Примерка: Can I try it on?"},
                {"type": "example", "content": "I can pay by card. — Я могу заплатить картой."},
                {"type": "text", "content": "«Сколько стоит?» — How much is it? или How much does it cost? В ответ можно услышать It is ten dollars."},
            ]
        },
        "vocabulary_ids": w7,
        "exercises": [
            mc("ex_07_01", "«Дорогой» (о цене) — это…", ["expensive", "cheap", "size"], 0, "Противоположно cheap"),
            mc("ex_07_02", "Что спрашивают о размере одежды?", ["What size are you?", "How old are you?", "Where is the station?"], 0, "В вопросе есть size"),
            fill("ex_07_03", "How much does it ___?", "cost", ["cost", "Cost"], "Глагол «стоить»"),
            fill("ex_07_04", "I want to ___ this jacket.", "try", ["try", "Try"], "Глагол «примерять»"),
            build("ex_07_05", "Собери предложение", ["can", "I", "pay", "card", "by"], "I can pay by card", "Начни с I can"),
        ],
    },
    {
        "id": "lesson_08",
        "order": 8,
        "level": "A2",
        "title": "Погода и планы",
        "summary": "Обсуждаем погоду и строим планы на завтра",
        "theory": {
            "blocks": [
                {"type": "text", "content": "Погода: weather — погода, rain — дождь, sunny — солнечно, cold — холодно, warm — тепло."},
                {"type": "example", "content": "It is sunny and warm today. — Сегодня солнечно и тепло."},
                {"type": "note", "content": "О погоде обычно говорят It is…: It is cold. Не говори просто The weather is cold без контекста, хотя это тоже правильно."},
                {"type": "example", "content": "What are you doing this weekend? — Что ты делаешь на этих выходных?"},
                {"type": "text", "content": "Планы на будущее можно выражать через going to: I am going to travel tomorrow. Слово tomorrow значит «завтра»."},
            ]
        },
        "vocabulary_ids": w8,
        "exercises": [
            mc("ex_08_01", "«Солнечно» — это…", ["sunny", "rain", "cold"], 0, "Слово связано с sun"),
            mc("ex_08_02", "Что наденем в холод?", ["a warm coat", "a ticket", "a passport"], 0, "Тёплая вещь"),
            fill("ex_08_03", "There is a lot of ___ today.", "rain", ["rain", "Rain"], "Осадки"),
            fill("ex_08_04", "Tomorrow the weather will be ___.", "sunny", ["sunny", "Sunny", "warm", "Warm"], "Будет много солнца"),
            build("ex_08_05", "Собери вопрос", ["weekend", "What", "are", "you", "this", "doing"], "What are you doing this weekend?", "Начни с What are you"),
        ],
    },
    {
        "id": "lesson_09",
        "order": 9,
        "level": "A2",
        "title": "Путешествия",
        "summary": "Бронируем отель и собираемся в дорогу",
        "theory": {
            "blocks": [
                {"type": "text", "content": "В путешествии: travel — путешествовать, train — поезд, airport — аэропорт, hotel — отель, luggage — багаж."},
                {"type": "example", "content": "I want to travel by train. — Я хочу путешествовать поездом."},
                {"type": "note", "content": "Поездом, самолётом, автобусом — by train, by plane, by bus. Пешком — on foot."},
                {"type": "example", "content": "Do not forget your passport. — Не забудь паспорт."},
                {"type": "text", "content": "Flight — это рейс или полёт, journey — поездка/путь. Не путай: passport нужен для границы, luggage — для вещей."},
            ]
        },
        "vocabulary_ids": w9,
        "exercises": [
            mc("ex_09_01", "Где садятся на самолёт?", ["airport", "hotel", "station"], 0, "Место с самолётами"),
            mc("ex_09_02", "«Багаж» — это…", ["luggage", "flight", "journey"], 0, "Слово начинается с l"),
            fill("ex_09_03", "I need my ___ to travel abroad.", "passport", ["passport", "Passport"], "Документ для границы"),
            fill("ex_09_04", "We booked a room at the ___.", "hotel", ["hotel", "Hotel"], "Место, где ночуют путешественники"),
            build("ex_09_05", "Собери предложение", ["to", "I", "travel", "want", "by", "train"], "I want to travel by train", "Начни с I want"),
        ],
    },
    {
        "id": "lesson_10",
        "order": 10,
        "level": "A2",
        "title": "Здоровье",
        "summary": "Говорим о самочувствии и визите к врачу",
        "theory": {
            "blocks": [
                {"type": "text", "content": "Когда плохо себя чувствуешь: doctor — врач, headache — головная боль, medicine — лекарство, rest — отдых."},
                {"type": "example", "content": "I have a headache. — У меня болит голова."},
                {"type": "note", "content": "Feel — «чувствовать себя»: I feel ill. Hurt — «болит»: My head hurts."},
                {"type": "example", "content": "You should rest more. — Тебе следует больше отдыхать."},
                {"type": "text", "content": "Should — мягкий совет: You should see a doctor. Healthy — здоровый, ill — больной. Не путай healthy и health."},
            ]
        },
        "vocabulary_ids": w10,
        "exercises": [
            mc("ex_10_01", "Кто помогает, когда ты болен?", ["a doctor", "a waiter", "a driver"], 0, "Человек в белом халате"),
            mc("ex_10_02", "«Головная боль» — это…", ["headache", "healthy", "rest"], 0, "Слово содержит head"),
            fill("ex_10_03", "I feel ___ today. I need a doctor.", "ill", ["ill", "sick", "Ill", "Sick"], "Противоположно healthy"),
            fill("ex_10_04", "Take this ___ after food.", "medicine", ["medicine", "Medicine"], "То, что принимают при болезни"),
            build("ex_10_05", "Собери предложение", ["should", "You", "rest", "more"], "You should rest more", "Начни с You should"),
        ],
    },
]


def validate() -> None:
    ids = [w["id"] for w in WORDS]
    assert len(ids) == len(set(ids)) == 642, len(ids)
    en_words = [w["en"].lower() for w in WORDS]
    assert len(en_words) == len(set(en_words)), (
        "Дубли английских слов: "
        + ", ".join(sorted({en for en in en_words if en_words.count(en) > 1}))
    )
    lesson_ids = {lesson["id"] for lesson in LESSONS}
    assert len(LESSONS) == 160
    assert [lesson["order"] for lesson in LESSONS] == list(range(1, 161))
    by_level = {"A1": 0, "A2": 0, "B1": 0}
    for lesson in LESSONS:
        by_level[lesson["level"]] += 1
        assert 3 <= len(lesson["vocabulary_ids"]) <= 20
        for vid in lesson["vocabulary_ids"]:
            assert any(w["id"] == vid for w in WORDS)
        assert 3 <= len(lesson["exercises"]) <= 5
        ex_ids = [e["id"] for e in lesson["exercises"]]
        assert len(ex_ids) == len(set(ex_ids))
        for e in lesson["exercises"]:
            assert e["type"] in {"multiple_choice", "fill_blank", "build_sentence"}
            assert e["hint"]
            if e["type"] == "multiple_choice":
                assert len(e["options"]) == 3 and 0 <= e["correct"] < 3
            elif e["type"] == "fill_blank":
                assert e["answer"] and e["accepted"]
            else:
                assert e["words"] and e["answer"]
                assert sorted(w.lower() for w in e["words"]) == sorted(
                    e["answer"].lower().replace("?", "").replace(".", "").replace(",", "").split()
                ), e["id"]
    assert by_level == {"A1": 40, "A2": 40, "B1": 80}, by_level
    assert sum(len(lesson["exercises"]) for lesson in LESSONS) == 800
    for w in WORDS:
        assert w["lesson_id"] in lesson_ids
        assert w["level"] in {"A1", "A2", "B1"}
        assert w["transcription"].startswith("/") and w["transcription"].endswith("/")
    assert set(w["id"] for w in WORDS) == {vid for lesson in LESSONS for vid in lesson["vocabulary_ids"]}


def main() -> None:
    extend(WORDS, LESSONS)
    LESSONS.sort(key=lambda lesson: lesson["order"])
    validate()
    DATA.mkdir(parents=True, exist_ok=True)
    lessons_payload = {"version": 2, "planned_total": 160, "lessons": LESSONS}
    vocabulary_payload = {"version": 2, "words": WORDS}
    (DATA / "lessons.json").write_text(
        json.dumps(lessons_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (DATA / "vocabulary.json").write_text(
        json.dumps(vocabulary_payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print(f"lessons={len(LESSONS)} words={len(WORDS)} exercises={sum(len(x['exercises']) for x in LESSONS)}")


if __name__ == "__main__":
    main()
