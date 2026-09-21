# lint: data-file
"""The hardcoded history `make claude` gives Fictitious Claude (#60).

Nothing here comes from Gemini or YouTube: it is written by hand to make Home,
Profile, the goals list, the tutor chat and the resources screen look
lived-in. Times are relative to the moment of seeding (`days_ago`, local
`hour`), so the streak is real whenever the seeder runs.

Lesson plan: each entry is (days_ago, hour, correct answers out of
LESSON_SIZE). The active goal has lessons on 14 of the last 15 days, two on a
couple of days, and a gap 6 days ago, so the streak is 6 and not 15.
"""

LESSON_SIZE = 5
START_RATING = 1200  # the Goal.rating column default

# (question, [a, b, c, d], correct index)
ITALIAN_QUESTIONS = [
    ("How do you say 'Good morning' in Italian?", ["Buongiorno", "Buonanotte", "Arrivederci", "Prego"], 0),
    ("Which one means 'Thank you very much'?", ["Per favore", "Grazie mille", "Scusi", "Salve"], 1),
    ("'Dov'è la stazione?' asks for...", ["the time", "the price", "the station", "the menu"], 2),
    ("The polite way to say 'you' to a stranger is...", ["tu", "voi", "loro", "Lei"], 3),
    ("'Il conto, per favore' is said at...", ["a restaurant", "a museum", "a hotel check-in", "a bus stop"], 0),
    ("Which article goes with 'studente'?", ["il", "lo", "la", "l'"], 1),
    ("'Vorrei un caffè' means...", ["I made a coffee", "I drink coffee", "I would like a coffee", "I hate coffee"], 2),
    ("The plural of 'la pizza' is...", ["le pizzi", "i pizze", "gli pizza", "le pizze"], 3),
    ("'Quanto costa?' asks...", ["how much it costs", "how far it is", "what time it is", "who it is"], 0),
    ("Which verb means 'to go'?", ["venire", "andare", "stare", "fare"], 1),
    ("'Ho fame' means...", ["I am cold", "I am tired", "I am hungry", "I am late"], 2),
    ("'A destra' means...", ["straight ahead", "to the left", "behind", "to the right"], 3),
    ("Which is the passato prossimo of 'mangiare' (io)?", ["ho mangiato", "sono mangiato", "mangiavo", "mangerò"], 0),
    ("'Un biglietto di andata e ritorno' is a...", ["one-way ticket", "return ticket", "day pass", "seat reservation"], 1),
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
    ("`df.groupby('city').size()` returns...", ["a list", "a count per city", "the first row per city", "a dict"], 1),
    ("Which selects rows where `age > 30`?", ["df.age > 30", "df.where(30)", "df[df.age > 30]", "df.filter(age=30)"], 2),
    ("A NumPy array's shape is read with...", ["len(a)", "a.size()", "a.dims", "a.shape"], 3),
]

ITALIAN_LESSONS = [
    (14, 20, 2), (13, 19, 3), (12, 21, 2), (11, 8, 3), (10, 19, 3), (10, 22, 4),
    (9, 20, 3), (8, 12, 4), (7, 21, 3),
    # the gap: nothing 6 days ago
    (5, 19, 4), (4, 20, 3), (3, 9, 4), (3, 18, 5), (2, 21, 4), (1, 20, 5), (0, None, 4),
]
GUITAR_LESSONS = [(24, 18, 2), (23, 19, 3), (21, 20, 3)]
PYTHON_LESSONS = [(33, 10, 3), (31, 11, 4)]

# (prompt, reply bubbles, liked, days_ago, hour)
ITALIAN_CHAT = [
    ("Ciao! I land in Rome in three weeks. Where should I start?",
     ["Ciao! Three weeks is plenty for the survival basics.",
      "Let's focus on greetings, ordering food, and asking for directions: that covers most of a trip.",
      "Your first lesson is ready whenever you are."], False, 14, 19),
    ("What's the difference between buongiorno and buonasera?",
     ["Buongiorno is for the morning and early afternoon.",
      "Switch to buonasera from around 4-5 pm. Italians are not strict, but that is the usual line."], False, 12, 21),
    ("Why is it 'lo studente' and not 'il studente'?",
     ["Good catch! Masculine words starting with s + consonant, z, gn, ps or x take 'lo'.",
      "So: lo studente, lo zaino, lo psicologo. But il libro, il treno."], True, 10, 22),
    ("How do I order coffee like a local?",
     ["Just say 'Un caffè, per favore' at the bar: you'll get an espresso.",
      "Want milk? Ask for 'un macchiato'. Cappuccino is a morning thing for most Italians."], False, 8, 12),
    ("I keep mixing up 'a destra' and 'a sinistra'.",
     ["A trick: 'destra' and 'dexterity' share a root, and most people are right-handed.",
      "So destra = right, sinistra = left."], False, 5, 19),
    ("Can you explain the passato prossimo quickly?",
     ["It's avere or essere in the present, plus the past participle.",
      "Ho mangiato (I ate), sono andato (I went).",
      "Movement and change-of-state verbs usually take essere; most others take avere."], False, 3, 18),
    ("How do I ask for a return ticket to Florence?",
     ["'Un biglietto di andata e ritorno per Firenze, per favore.'"], False, 2, 21),
    ("I got 5 out of 5 yesterday!",
     ["Bravissimo! That was a tough set, with the passato prossimo in it.",
      "Tomorrow we mix in more restaurant phrases, so you're ready for your first dinner in Trastevere."], False, 0, None),
]
GUITAR_CHAT = [
    ("Why does the minor pentatonic sound good over blues?",
     ["It leaves out the notes that clash with the dominant chords of a blues.",
      "Add the flat fifth and you get the blues scale."], False, 23, 19),
]
PYTHON_CHAT = [
    ("When should I use loc instead of iloc?",
     ["loc selects by label, iloc by position.", "df.loc['2024-01'] vs df.iloc[0:10]."], False, 31, 11),
]

# (kind, name, description, language, link)
ITALIAN_RESOURCES = [
    ("youtube", "Easy Italian", "Street interviews in Italian, subtitled in Italian and English.", "it",
     "https://www.youtube.com/@EasyItalian"),
    ("youtube", "Italy Made Easy", "Grammar and pronunciation explained slowly, for beginners.", "en",
     "https://www.youtube.com/@ItalyMadeEasy"),
    ("youtube", "Learn Italian with Lucrezia", "Everyday Italian and travel vocabulary from a native teacher.", "en",
     "https://www.youtube.com/@LearnItalianwithLucrezia"),
    ("pdf", "FSI Italian FAST Course", "The US Foreign Service Institute's intensive survival course.", "en",
     "https://www.fsi-language-courses.org/Content.php?page=Italian"),
    ("pdf", "Italian Grammar Wikibook", "A free, complete reference grammar with exercises.", "en",
     "https://en.wikibooks.org/wiki/Italian"),
    ("pdf", "Travel Phrasebook: Italy", "Phrases for hotels, trains, restaurants and emergencies.", "en",
     "https://en.wikivoyage.org/wiki/Italian_phrasebook"),
    ("webpage", "WordReference Italian-English", "Dictionary with forums on idioms and usage.", "en",
     "https://www.wordreference.com/iten/"),
    ("webpage", "Treccani Vocabolario", "The reference monolingual Italian dictionary.", "it",
     "https://www.treccani.it/vocabolario/"),
    ("webpage", "One World Italiano", "Free graded lessons with audio, A1 to C1.", "en",
     "https://www.oneworlditaliano.com/english/"),
]
GUITAR_RESOURCES = [
    ("webpage", "musictheory.net", "Interactive lessons on intervals, scales and chords.", "en",
     "https://www.musictheory.net/lessons"),
]
PYTHON_RESOURCES = [
    ("webpage", "pandas: 10 minutes to pandas", "The official quick tour of pandas.", "en",
     "https://pandas.pydata.org/docs/user_guide/10min.html"),
]

ITALIAN_CONTEXT = (
    "A beginner preparing for a one-week trip to Rome in three weeks. Solid on greetings and "
    "ordering food; still slips on articles (lo/il) and on essere vs avere in the passato prossimo.",
    "Studies in the evening, one short lesson a day, sometimes two. Asks 'why' questions and "
    "remembers rules better with a mnemonic.",
)

# The goals, newest (and active) first. `created_days_ago` must predate the
# goal's first lesson.
GOALS = [
    {"name": "Conversational Italian for a trip to Rome",
     "description": "Get by in Italian on a week in Rome: greetings, ordering food, asking the way, "
                    "buying train tickets, and small talk with locals.",
     "created_days_ago": 15, "active": True, "questions": ITALIAN_QUESTIONS, "lessons": ITALIAN_LESSONS,
     "chat": ITALIAN_CHAT, "resources": ITALIAN_RESOURCES, "context": ITALIAN_CONTEXT},
    {"name": "Music theory for guitar",
     "description": "Understand the chords and scales I already play: intervals, keys, and why the "
                    "pentatonic works for solos.",
     "created_days_ago": 26, "active": False, "questions": GUITAR_QUESTIONS, "lessons": GUITAR_LESSONS,
     "chat": GUITAR_CHAT, "resources": GUITAR_RESOURCES, "context": None},
    {"name": "Python for data analysis",
     "description": "Clean and explore spreadsheets with pandas instead of doing it by hand in Excel.",
     "created_days_ago": 35, "active": False, "questions": PYTHON_QUESTIONS, "lessons": PYTHON_LESSONS,
     "chat": PYTHON_CHAT, "resources": PYTHON_RESOURCES, "context": None},
]

# The student's member-since date.
STUDENT_CREATED_DAYS_AGO = 36
