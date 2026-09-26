# SOUL.md

> **The first priority, above every other rule here: the student learns something every
> day, however little.** *"Fazer o aluno aprender alguma coisa todo dia, por menos que
> seja."* When two rules pull apart, this one decides.

What GoalGetter is, and how its decisions are made. `CLAUDE.md` is how to work in this
repository; this is **why the product is the way it is**. When a rule here and a piece of
code disagree, the code is what is wrong — or the rule is out of date, and then the user
says so and this file changes first.

The user adds to this file as the rules come up. Each rule carries the date it was
settled, and the user's own words where they say it better.

## What it is

**Tailor-made teaching: learn whatever you want.** A student names something he wants to
learn and the app teaches it — short daily lessons, a tutor to ask anything, and resources
found for him. Generative AI is what makes that possible: everything is written for one
student, and **nothing is ever reused between students** — not exercises, not resources,
not what the app has read about him.

The metric is that he comes back tomorrow — the first priority above is what makes him.

A goal names *what he wants to learn about*, not a course with a finish line. Progress is
measured against him, not against a syllabus.

## How the app decides

**Gemini writes content; arithmetic decides what appears** (2026-09-24). Writing an
exercise, a tutor reply or a resource's description is Gemini's. Choosing which exercises
a student gets, measuring how he is doing, deciding whether to generate more, where the
right option sits — those are formulas: testable without a network, free to run, and
predictable. A decision made several times a day per student would, as a model call, be
the app's biggest cost and its least predictable behaviour.

**Gemini is the tool of last resort** (2026-09-26). Where a tool exists for the job, the
tool does it: Google Search finds pages, the YouTube Data API finds videos. Gemini never
supplies a link from memory, because he invents them (#175).

**Tokens are the bill.** Every prompt asks for the shortest output that does the job.

## The student

**His answers are the measurement; what he says about himself is his opinion**
(2026-09-26). *"O bot não pode assumir que o usuário sabe o seu próprio nível."* The
rating — his ability, in the Rasch sense — comes from his answers, and an exercise's
difficulty comes from how students answered it, never from a tag Gemini puts on it.

**He does not set where he stops.** *"O app está aqui para ensinar o usuário ao máximo."*
"Only the basics" is not a ceiling. When he has learned what a goal holds, the app moves
him outward — to what that knowledge is useful for and what he seems interested in —
rather than stopping. That moving target is the goal's frontier (#133).

**Don't rely on him describing himself well.** People prefer tapping to typing — an
onboarding by text was tried before, and people only typed because they were asked to.
So the app asks little, by multiple choice, and learns the rest from his answers.

**One goal at a time.** The goal he picked on his profile is the one the app works on:
new exercises, the reading of him, resources. A goal he is not working on is paused, not
unlearned (*"eu não desaprendo, eu só não tô trabalhando nele no momento"*), so nothing
is refreshed for it until he picks it again (2026-09-26).

**He learns in his own language.** He picks it on the first screen, it defaults to his
phone's, and every prompt names it outright.

## Teaching

**Content sits at the threshold of what he knows** (2026-09-24) — always a little
challenge, never more than he can take, because both extremes stop him. As a number: the
chance he answers right, aimed at about 0.75. Classical test theory would aim at 0.5,
which measures him best; we are not optimising measurement, we are optimising that he
comes back tomorrow.

**Exercises teach; they do not test** (2026-09-26). Each one is **the simplest possible,
one step past what he has shown he knows** — so with nothing answered yet, it is the most
basic thing in the subject. When he misses one, seeing the right option is enough.

**"Exercises", not "questions".** An exercise may be an instruction — *"Pick the Middle
Eastern capital"* — not only something ending in a question mark.

**Short and fair:**
- **20 words at most**, for every exercise and every option — onboarding and lessons.
  In practice long text does not fit, and the cap makes length almost deterministic.
- **The shape never gives the answer away:** wrong options are plausible, real confusions
  a learner has, and about as long as the right one; and the right one's position is
  drawn by the code, not chosen by Gemini.

**A lesson is two minutes** — not a number of exercises. *"As questões e lições são
breves para que o aluno não sinta que demora demais fazer uma lição."* That is why the
app records how long he takes on each exercise: his own pace decides how many fit in two
minutes, between **6 and 12**. Short and daily keeps him coming back, and more answers is
more evidence about him.

**The first 18 place him** (2026-09-26). A new goal gets 18 exercises right after
onboarding — three lessons — climbing from the most basic, written by their own prompt.
Until the goal holds 18 answers, nothing more is generated: he has not been measured yet.
One number, `PLACEMENT_SIZE`, used everywhere it applies.

**Onboarding is 6 multiple-choice questions**, about him — what he has done, what for,
what he already knows, how he likes to learn — never asking him to rate himself, and
**never asking him to pick one aspect to focus on**: the subject is covered as he asked
for it, and his answers show where to go. A goal's name and description never narrow
what he asked for ("understand modern China" is not "China's tech giants").

## How we build

- **Issues state the problem and the guidelines; the analysis and the solution are the
  implementer's** (2026-09-26).
- **Prompts are tuned with real output before they merge** (2026-09-26): run them on
  realistic cases, read what comes back, adjust — merging deploys, and judging a prompt
  on the live site is a slow round trip.
- **A defect found along the way is fixed in the task or filed as an issue, and the user
  is told** (2026-09-26).
- **Foundations come first**: architecture, then infrastructure, bugs, foundation work,
  and features last.
- **One developer, one machine.** The app is served from home through a Cloudflare
  tunnel. Simple beats clever: no staging, and a merge is a deploy.
