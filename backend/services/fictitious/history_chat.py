# lint: data-file
"""The tutor chat of each fictitious goal (#60, split out in #107).

Invented by hand, never by Gemini. The hours are the student's wall clock
(`core.clock.APP_TIMEZONE`, #92), not the server's.
"""

# (prompt, reply bubbles, liked, days_ago, hour)
ITALIAN_CHAT = [
    (
        "Ciao! I land in Rome in three weeks. Where should I start?",
        [
            "Ciao! Three weeks is plenty for the survival basics.",
            "Let's focus on greetings, ordering food, and asking for directions: that covers most of a trip.",
            "Your first lesson is ready whenever you are.",
        ],
        False,
        14,
        19,
    ),
    (
        "What's the difference between buongiorno and buonasera?",
        [
            "Buongiorno is for the morning and early afternoon.",
            "Switch to buonasera from around 4-5 pm. Italians are not strict, but that is the usual line.",
        ],
        False,
        12,
        21,
    ),
    (
        "Why is it 'lo studente' and not 'il studente'?",
        [
            "Good catch! Masculine words starting with s + consonant, z, gn, ps or x take 'lo'.",
            "So: lo studente, lo zaino, lo psicologo. But il libro, il treno.",
        ],
        True,
        10,
        22,
    ),
    (
        "How do I order coffee like a local?",
        [
            "Just say 'Un caffè, per favore' at the bar: you'll get an espresso.",
            "Want milk? Ask for 'un macchiato'. Cappuccino is a morning thing for most Italians.",
        ],
        False,
        8,
        12,
    ),
    (
        "I keep mixing up 'a destra' and 'a sinistra'.",
        [
            "A trick: 'destra' and 'dexterity' share a root, and most people are right-handed.",
            "So destra = right, sinistra = left.",
        ],
        False,
        5,
        19,
    ),
    (
        "Can you explain the passato prossimo quickly?",
        [
            "It's avere or essere in the present, plus the past participle.",
            "Ho mangiato (I ate), sono andato (I went).",
            "Movement and change-of-state verbs usually take essere; most others take avere.",
        ],
        False,
        3,
        18,
    ),
    (
        "How do I ask for a return ticket to Florence?",
        ["'Un biglietto di andata e ritorno per Firenze, per favore.'"],
        False,
        2,
        21,
    ),
    (
        "I got 5 out of 5 yesterday!",
        [
            "Bravissimo! That was a tough set, with the passato prossimo in it.",
            "Tomorrow we mix in more restaurant phrases, so you're ready for your first dinner in Trastevere.",
        ],
        False,
        0,
        None,
    ),
]
GUITAR_CHAT = [
    (
        "Why does the minor pentatonic sound good over blues?",
        [
            "It leaves out the notes that clash with the dominant chords of a blues.",
            "Add the flat fifth and you get the blues scale.",
        ],
        False,
        23,
        19,
    ),
]
PYTHON_CHAT = [
    (
        "When should I use loc instead of iloc?",
        ["loc selects by label, iloc by position.", "df.loc['2024-01'] vs df.iloc[0:10]."],
        False,
        31,
        11,
    ),
]
