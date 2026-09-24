"""The three steps of the student chain, one file each (#88).

Every step takes the session the chain opened and the student's id, works out
for itself what it needs from the database, and commits what it wrote. None of
them takes a flag saying whether this is the first run: what a step does is
decided by what it finds, so goal creation and the nightly run (#89) call the
same code.
"""
