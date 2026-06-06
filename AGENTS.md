We use Cloudflare Tunnel to serve this application. This is a homedeploy.
We do use Google Cloud for OAUTH and Gemini API.
We use Fastapi, sqlalchemy, alembic, gemini sdk in the backend.
The DB is in postgres with pg vector for vector embeddings.
We use Riverpod for state management in Flutter.

We have a backend/tests/backend_linter.py file, which keeps endpoints and .py files under a reasonable line count. If you're gonna run backend tests, run this file first. If it fails, you have things to fix. If it passes, you may go and run the tests.

We have a 400 line limit for .dart files that are created non-programatically.
We have a 350 line limit for .py files.
If lines grow bigger than this, either we dont have a clear vision for what we are trying to achieve, in which case clap back at the user (asking questions or pointing out what is wrong, clear or not well defined), or the feature is growing big enough that needs to be split across files, in which case we split by responsability and organization.

We follow TDD for the endpoints:
- We define what we need to do, define the schemas for requests and response, then the appropriate tests
- Implement/edit fixtures if needed, implement the tests, we implement the endpoint to pass the test
- The tests are made to be reliable. If the endpoint doesn't pass the test than it's not ready for production
When all that is done, we may get the openapi.json from the /api/v1/openapi.json endpoint, then save the openapi.json to generate the client_sdk with `openapi-generator-cli generate -i ./openapi.json -g dart -o ./client_sdk` (be mindful of relative paths). If we need to edit an endpoint, we follow the same process.

We have a 50 line limit for endpoints and tests in pytest.
If the endpoint is too big, either the feature is too big and we need a better structure/architecture, in which case inform the user and plan/organize this together.
If the pytest is too big, we have to assess the situation and see what is it that needs optimization. If the test does need to be complex, than the feature is designed wrong (tests must never be complex).
We focus mainly on unit tests.
We use fixtures so we dont have to call real APIs.

We NEVER push into main, we push into a another remote branch.
We NEVER switch from the main branch locally. We run 'git pull' and then create a worktree and work there.

We must always run the tests for the backend if there have been changes in the backend before committing the code.

Any documentation you write must be for AI agents to help navigate and understand the decisions taken in case it is not self-explained by the code. Business logic must be written by the user or by the user's request.

## Token Optimization Rules (RTK)
This system has Rust Token Killer (RTK) installed globally. To save context window and avoid token bloat during terminal tool executions, adhere to these rules:

1. **Prepend Token-Heavy Commands:** Always prepend `rtk` to commands that generate massive terminal outputs.
   - Use `rtk git diff` instead of `git diff`
   - Use `rtk status` or `rtk git status` for large repository states
   - Use `rtk test` or `rtk cargo test` / `rtk npm test` for running test suites
   - Use `rtk run <command>` for verbose compiler outputs or logs

2. **Expected Behavior:** RTK will automatically strip ANSI escape codes, truncate repetitive linter/test walls of text, and compress the output by up to 90% before it hits your context window. Trust the compressed output.

All rules can be overridden by the user if it was an expressed order in the current or previous prompt.

Never commit nor build and run the containers unless the user asked for it in the current or previous prompt

The system was made with Linux as the OS for development and deployment.
