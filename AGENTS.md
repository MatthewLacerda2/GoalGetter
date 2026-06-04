We have a 400 line limit for .dart files that are created non-programatically.
We have a 350 line limit for .py files.
If lines grow bigger than this, either we dont have a clear vision for what we are trying to achieve, in which case clap back at the user (asking questions or pointing out what is wrong, clear or not well defined), or the feature is growing big enough that needs to be split across files, in which case we split by responsability and organization.

we have a 50 line limit for endpoints and tests in pytest.
If the endpoint is too big, either the feature is too big and we need a better structure/architecture, in which case inform the user and plan/organize this together.
If the pytest is too big, we have to assess the situation and see what is it that needs optimization. If the test does need to be complex, than the feature is designed wrong (tests must never be complex).
We focus mainly on unit tests.
We use fixtures so we dont have to call real APIs.

We use Riverpod for state management in Flutter.
We use fastapi, sqlalchemy, alembic, gemini sdk in the backend.
The DB is in postgres with pg vector for vector embeddings.
We use Cloudflare Tunnel to serve this application. This is a homedeploy. We do use Google Cloud for OAUTH and Gemini API.
