# lint: data-file
"""The question bank of each fictitious goal (#60, split out in #107).

Invented by hand, never by Gemini. Read as data; `history_data.GOALS` wires
each list to its goal.
"""

# (question, [a, b, c, d], correct index)
ITALIAN_QUESTIONS = [
    (
        "How do you say 'Good morning' in Italian?",
        ["Buongiorno", "Buonanotte", "Arrivederci", "Prego"],
        0,
    ),
    ("Which one means 'Thank you very much'?", ["Per favore", "Grazie mille", "Scusi", "Salve"], 1),
    ("'Dov'è la stazione?' asks for...", ["the time", "the price", "the station", "the menu"], 2),
    ("The polite way to say 'you' to a stranger is...", ["tu", "voi", "loro", "Lei"], 3),
    (
        "'Il conto, per favore' is said at...",
        ["a restaurant", "a museum", "a hotel check-in", "a bus stop"],
        0,
    ),
    ("Which article goes with 'studente'?", ["il", "lo", "la", "l'"], 1),
    (
        "'Vorrei un caffè' means...",
        ["I made a coffee", "I drink coffee", "I would like a coffee", "I hate coffee"],
        2,
    ),
    ("The plural of 'la pizza' is...", ["le pizzi", "i pizze", "gli pizza", "le pizze"], 3),
    (
        "'Quanto costa?' asks...",
        ["how much it costs", "how far it is", "what time it is", "who it is"],
        0,
    ),
    ("Which verb means 'to go'?", ["venire", "andare", "stare", "fare"], 1),
    ("'Ho fame' means...", ["I am cold", "I am tired", "I am hungry", "I am late"], 2),
    ("'A destra' means...", ["straight ahead", "to the left", "behind", "to the right"], 3),
    (
        "Which is the passato prossimo of 'mangiare' (io)?",
        ["ho mangiato", "sono mangiato", "mangiavo", "mangerò"],
        0,
    ),
    (
        "'Un biglietto di andata e ritorno' is a...",
        ["one-way ticket", "return ticket", "day pass", "seat reservation"],
        1,
    ),
    ("'Che ore sono?' asks for...", ["the date", "the weather", "the time", "the way"], 2),
]

GUITAR_QUESTIONS = [
    ("How many semitones are in a major third?", ["2", "3", "5", "4"], 3),
    ("The notes of a C major chord are...", ["C E G", "C D G", "C Eb G", "C F A"], 0),
    ("A minor pentatonic scale has how many notes?", ["7", "5", "6", "4"], 1),
    ("The relative minor of G major is...", ["A minor", "B minor", "E minor", "D minor"], 2),
]

PYTHON_QUESTIONS = [
    ("Which pandas call reads a CSV file?", ["pd.read_csv", "pd.load_csv", "pd.open", "pd.csv"], 0),
    (
        "`df.groupby('city').size()` returns...",
        ["a list", "a count per city", "the first row per city", "a dict"],
        1,
    ),
    (
        "Which selects rows where `age > 30`?",
        ["df.age > 30", "df.where(30)", "df[df.age > 30]", "df.filter(age=30)"],
        2,
    ),
    ("A NumPy array's shape is read with...", ["len(a)", "a.size()", "a.dims", "a.shape"], 3),
]
