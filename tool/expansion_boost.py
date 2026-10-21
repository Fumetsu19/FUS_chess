"""Дополнительная лексика для первых пяти A1-уроков.

Первые игры проходят с небольшим количеством знакомых слов, поэтому без
расширения пула задачи начинают повторяться. Эти слова дают начинающему
больше языковых опор для первых партий.
"""
from __future__ import annotations

BOOST_WORDS: dict[str, list[tuple[str, str, str, str, str]]] = {
    "lesson_01": [
        ("please", "пожалуйста", "adverb", "Please, sit down.", "Пожалуйста, садись."),
        ("sorry", "извините; сожалею", "adjective", "I am sorry, I am late.", "Извините, я опоздал."),
        ("welcome", "добро пожаловать", "interjection", "Welcome to our school!", "Добро пожаловать в нашу школу!"),
        ("afternoon", "день после полудня", "noun", "Good afternoon!", "Добрый день!"),
        ("night", "ночь", "noun", "Good night!", "Доброй ночи!"),
        ("sir", "сэр, господин", "noun", "Good morning, sir.", "Доброе утро, сэр."),
        ("madam", "мадам, госпожа", "noun", "Can I help you, madam?", "Могу я помочь вам, мадам?"),
        ("excuse", "извинять(ся)", "verb", "Excuse me, where is the bank?", "Извините, где находится банк?"),
        ("introduce", "представлять", "verb", "Let me introduce my friend.", "Позволь представить моего друга."),
        ("spell", "произносить по буквам", "verb", "Can you spell your name?", "Можешь произнести своё имя по буквам?"),
        ("repeat", "повторять", "verb", "Could you repeat that, please?", "Не могли бы вы это повторить?"),
        ("understand", "понимать", "verb", "I don't understand.", "Я не понимаю."),
    ],
    "lesson_02": [
        ("four", "четыре", "numeral", "I have four books.", "У меня четыре книги."),
        ("six", "шесть", "numeral", "The lesson starts at six.", "Урок начинается в шесть."),
        ("seven", "семь", "numeral", "There are seven days in a week.", "В неделе семь дней."),
        ("eight", "восемь", "numeral", "She is eight years old.", "Ей восемь лет."),
        ("nine", "девять", "numeral", "The shop opens at nine.", "Магазин открывается в девять."),
        ("zero", "ноль", "numeral", "The temperature is zero.", "Температура — ноль."),
        ("eleven", "одиннадцать", "numeral", "My brother is eleven.", "Моему брату одиннадцать."),
        ("hundred", "сто", "numeral", "There are one hundred pages.", "Там сто страниц."),
    ],
    "lesson_03": [
        ("parents", "родители", "noun", "My parents live in Moscow.", "Мои родители живут в Москве."),
        ("grandmother", "бабушка", "noun", "My grandmother makes good tea.", "Моя бабушка заваривает хороший чай."),
        ("grandfather", "дедушка", "noun", "My grandfather is seventy.", "Моему дедушке семьдесят."),
        ("child", "ребёнок", "noun", "The child is playing outside.", "Ребёнок играет на улице."),
    ],
    "lesson_04": [
        ("cheese", "сыр", "noun", "I like cheese on my bread.", "Я люблю сыр на хлебе."),
        ("egg", "яйцо", "noun", "I eat an egg for breakfast.", "Я ем яйцо на завтрак."),
        ("rice", "рис", "noun", "We cook rice with vegetables.", "Мы готовим рис с овощами."),
        ("juice", "сок", "noun", "She drinks orange juice.", "Она пьёт апельсиновый сок."),
    ],
    "lesson_05": [
        ("lunch", "обед", "noun", "I have lunch at one.", "Я обедаю в час."),
        ("dinner", "ужин", "noun", "We have dinner at seven.", "Мы ужинаем в семь."),
        ("busy", "занятой", "adjective", "I am busy today.", "Сегодня я занят."),
        ("free", "свободный", "adjective", "Are you free tonight?", "Ты свободен сегодня вечером?"),
    ],
}
