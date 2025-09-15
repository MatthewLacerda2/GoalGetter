# Onboarding

## Prompt

- Ask the user what he wants to learn
- Offer some curated courses

## Investigate

If what he wants is impossible/forbidden, kick him off right away

- Why does the user wanna learn?
- Assume he doesn't even understand what he/she wants

## Propose

- Show what is your plan and let the user confirm it

If he clicks 'no':
- Say 'oh no, how sad'
- Then send him back to the start

If he clicks 'yes':
- Save the goal, objective, context
- Search for resources
- Generate notes
- Generate lesson
- - - - -

# UX

- User clicks 'lets do lesson'
    - He does lesson/assessment. We store info as he does it, accordingly

    - At the end of it we:
        - Generate more context and info, accordingly
        - Track progress

    - If that was a lesson, is the user showing mastery of the objective?
        - If no, generate more lesson
        - If yes, generate assessment
    - If that was an assessment, did the user show he indeed mastered the objective?
        - If no, generate more lesson
        - If yes, generate new objective
- - - - -

# How to generate an objective:

- Generate name, notes, lesson, info and context
- Update Resources, given context
    - Search for new
    - Disable stale ones