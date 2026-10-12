# Use a smaller Python 3.12 image.
# The digest pins the exact base image used for the build.
FROM python:3.12-slim-bookworm@sha256:34386ef0cb081344d7ec1c103ba398e6e9f64e9ab3a1509accc92a4e24a07258

# Prevent Python from creating .pyc files.
# Send Python output directly to container logs without buffering.
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Set the working directory for the remaining instructions.
WORKDIR /app

# Create a dedicated non-root user with no home directory or login shell.
RUN useradd --uid 10001 --user-group --no-create-home --shell /usr/sbin/nologin appuser

# Copy dependencies first so Docker can reuse the installation layer
# when application code changes but requirements stay the same.
COPY app/requirements.txt ./app/requirements.txt

# Install dependencies without keeping pip's download cache in the image.
RUN pip install --no-cache-dir -r app/requirements.txt

# Copy the application without modifying its source files.
COPY app/ ./app/

# Run the application as the non-root user created above.
USER 10001

# Document the application port.
EXPOSE 8080

# Run Flask through Gunicorn with two worker processes.
# Listen on all container interfaces and send access/error logs to stdout/stderr.
CMD ["gunicorn", "--chdir", "app", "--bind", "0.0.0.0:8080", "--workers", "2", "--access-logfile", "-", "--error-logfile", "-", "app:app"]