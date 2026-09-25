"""Vector arithmetic the app does for itself, over the embeddings Gemini wrote.

Gemini writes the vectors; comparing them is arithmetic, and arithmetic lives
here - free to run, testable without a network, the same answer every time.

One definition of cosine similarity for the whole backend. Two would eventually
disagree on the edge cases that matter: a null column (the nightly backfill has
not reached that row yet, #96) and a zero vector (an empty text that was never
sent). Both are "nothing to compare", not "similarity zero", and a reader that
confused the two would quietly treat an un-embedded row as an unrelated one.
"""

import numpy as np


def cosine(left, right) -> float | None:
    """How alike two embeddings are, in [-1, 1], or None when there is nothing
    to compare: either side missing, or either side a zero vector.

    **None is a normal answer, never a failure.** Embeddings are filled by a
    nightly job and every reader must work without them, so a caller decides
    for itself what an absent comparison means to it.
    """
    if left is None or right is None:
        return None
    first = np.asarray(left, dtype=np.float32)
    second = np.asarray(right, dtype=np.float32)
    norms = float(np.linalg.norm(first) * np.linalg.norm(second))
    if norms == 0.0:
        return None
    return float(np.dot(first, second) / norms)
