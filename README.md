# DevOps Interview Task (Part 1): Containerize

**This is a take-home task.** Please submit by the date given when the task was
issued.

## Overview

You are given a small web application (`app/`). A working `Dockerfile` is
provided, but it was written quickly and does **not** follow container best
practices. Your job is to refactor it into a production-quality image and push
it to a container registry.

You do **not** need to modify the application code.

## What we provide

Clone this repository into your local account.

> **Do Not** fork this repository. Clone it and re-push it into your local account.

The following is provided as part of this repository:

Dockerfile            # a working but non-production Dockerfile — improve it
app/
  app.py              # a minimal Python Flask web app (do not modify)
  requirements.txt    # the app's dependencies (do not modify)

The application:

-   Listens on the port given by the `PORT` environment variable (default `8080`).
-   Reads a `GREETING` environment variable used in its response.
-   Exposes `GET /`, `GET /healthz`, and `GET /info`.


## Implementation

The application files in `app/` remain unchanged, and Gunicorn is retained.

### Container changes

- Used Python 3.12 slim, pinned by digest for a consistent base image.
- Removed unnecessary compilers, curl and vim from the runtime image.
- Installed requirements before copying application code so dependency
  layers can be reused when only source code changes.
- Disabled pip's download cache to avoid storing unnecessary files.
- Added `.dockerignore` to exclude Git metadata, virtual environments
  and other files not needed for the build.
- Run the application as a dedicated non-root user, UID 10001.
- Send Gunicorn access and error logs to standard output and standard error.
- Added Dockerfile comments explaining each instruction.

A single-stage build was sufficient because dependency installation
succeeded without additional compilation tools.

### Results

| Check | Result |
| --- | --- |
| Original image size | 1.19 GB |
| Refactored image size | 137 MB |
| Approximate size reduction | 88.5% |
| Application endpoints | `/`, `/healthz` and `/info` returned HTTP 200 |
| Custom greeting | Verified using the `GREETING` environment variable |
| Runtime user | UID 10001, non-root |
| Shutdown | Gunicorn handled SIGTERM and stopped gracefully |
| Build cache | Unchanged rebuild reused cached layers |
| Application source | Compared with the original commit; unchanged |
| Public image access | Pulled successfully after logging out of GHCR |

Sizes are the rounded values reported by Docker locally.

## Published image

Image:
ghcr.io/donchucky21/greeting-container:v1.0.0

Digest:
sha256:c331f262e017bb897fd7ad64ea6439b581ac2989ecd519967b55be5b7095f95e

### Pull and run

docker pull ghcr.io/donchucky21/greeting-container:v1.0.0

docker run -d --name greeting-demo \
  -p 127.0.0.1:8081:8080 \
  -e GREETING="Hello from Chuks" \
  ghcr.io/donchucky21/greeting-container:v1.0.0

Host port 8081 maps to container port 8080, avoiding a conflict with
an existing local container on port 8080.

The Dockerfile's Gunicorn command binds to container port 8080.
Changing `PORT` alone does not change Gunicorn's listening port.

### Test

curl --fail http://localhost:8081/healthz
curl --fail http://localhost:8081/
curl --fail http://localhost:8081/info

docker exec greeting-demo id
docker logs greeting-demo

### Stop and remove the test container

docker stop greeting-demo
docker rm greeting-demo

## Continuous integration

GitHub Actions runs on pull requests targeting `main` and pushes to `main`.

The workflow:

1. Scans repository history for secrets using Gitleaks.
2. Builds and starts the container.
3. Checks all three HTTP endpoints.
4. Verifies that the container runs as a non-root user.
5. Reports image vulnerabilities using Trivy.
6. Fails if fixable HIGH or CRITICAL vulnerabilities are found.
7. Prints container logs and removes the test container.

The initial health check retries errors while the application starts.
It still fails if the retry limit is reached.

Passing the vulnerability gate does not mean the image has no
vulnerabilities. Lower-severity findings and findings without available
fixes remain visible in the report.

## Manual publishing

The image was built and published manually. CI performs checks only.

docker build -t ghcr.io/donchucky21/greeting-container:v1.0.0 .
docker login ghcr.io -u Donchucky21
docker push ghcr.io/donchucky21/greeting-container:v1.0.0

Authentication uses a GitHub personal access token (classic) with
`write:packages`, entered at the password prompt.

The package visibility was changed to Public. Anonymous access was
verified with:

docker logout ghcr.io
docker pull ghcr.io/donchucky21/greeting-container:v1.0.0