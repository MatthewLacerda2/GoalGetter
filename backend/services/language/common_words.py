"""Each language's commonest short words, for `detection.py`.

Function words (articles, pronouns, prepositions, conjunctions, the commonest
verb forms) plus the handful a student writes when he names a goal ("I want to
learn", "quero aprender"). A word two languages share may sit in both lists:
it then scores for both, and cancels out. Lowercase, accents kept.
"""

from backend.core.language import Language

COMMON_WORDS: dict[Language, frozenset[str]] = {
    Language.ENGLISH: frozenset(
        """
        the a an and or but of to in on at for with from by about as into
        is are was were be been being am do does did have has had will would
        can could should i you he she it we they me my your his her our their
        this that these those what which who how why when where there here
        not no yes if so than then all some any more most very just also
        want learn learning how know understand get make like need
        """.split()
    ),
    Language.PORTUGUESE: frozenset(
        """
        o a os as um uma uns umas e ou mas de do da dos das em no na nos nas
        por pelo pela para com sem sobre que se não sim é são foi era ser
        estar está estou tem ter eu você ele ela nós eles elas meu minha seu
        sua isso isto esse essa este esta como quando onde porque também
        muito mais já ao aos à às quero queria aprender saber entender fazer
        gostaria preciso sei
        """.split()
    ),
    Language.SPANISH: frozenset(
        """
        el la los las un una unos unas y o a pero de del en al por para con sin
        sobre que se no sí es son fue era ser estar está estoy tiene tener yo
        tú él ella nosotros ellos ellas mi mis su sus eso esto ese esa este
        esta como cuando donde porque también muy más ya quiero quería
        aprender saber entender hacer me gustaría necesito sé hay
        """.split()
    ),
    Language.FRENCH: frozenset(
        """
        le la les un une des et ou mais de du en au aux par pour avec sans sur
        que qui ne pas oui est sont était être avoir ai as a je tu il elle
        nous vous ils elles mon ma mes ton ta son sa ses ce cette ces comme
        quand où parce aussi très plus déjà veux voudrais apprendre savoir
        comprendre faire j l d qu c n m s
        """.split()
    ),
    Language.GERMAN: frozenset(
        """
        der die das den dem des ein eine einen einem einer und oder aber von
        zu im in am an auf für mit ohne über dass nicht nein ja ist sind war
        waren sein haben habe hat ich du er sie es wir ihr mein meine dein
        sein ihre dieser diese dieses wie wann wo warum weil auch sehr mehr
        schon will möchte lernen wissen verstehen machen kann
        """.split()
    ),
}
