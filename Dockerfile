FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    sqlite3 \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install openclaw globally
RUN npm install -g openclaw@2026.4.26

# Set up working directory
WORKDIR /app

# Create a non-root user for Hugging Face Spaces (UID 1000)
RUN useradd -m -u 1000 user && \
    mkdir -p /app/.openclaw && \
    chown -R user:user /app

# Copy requirements and install python packages
RUN pip install --no-cache-dir \
    fastapi \
    uvicorn \
    pydantic \
    psutil \
    python-multipart

# Copy application files
COPY --chown=user:user . .

# Set environment variables
ENV HOME=/home/user
ENV OPENCLAW_HOME=/app/.openclaw
ENV DB_PATH=/app/dermaart.db
ENV GATEWAY_URL=http://127.0.0.1:18789/v1/chat/completions
ENV PORTAL_REPORTS_URL=http://127.0.0.1:7860/api/reports/submit

# Make start.sh executable
RUN chmod +x start.sh && chown user:user start.sh

# Switch to the non-root user
USER user

# Run startup script
CMD ["/bin/bash", "./start.sh"]
