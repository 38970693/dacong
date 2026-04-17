# ── Stage 1: Base ──────────────────────────────────
FROM python:3.11-slim-bookworm AS base

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /app

# ── Stage 2: Dependencies ──────────────────────────
FROM base AS deps

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --user --no-warn-script-location -r requirements.txt

# ── Stage 3: Production ────────────────────────────
FROM base AS production

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libxml2 \
    libxslt1.1 \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from deps stage
COPY --from=deps /root/.local /root/.local

# Make sure scripts in .local are usable
ENV PATH=/root/.local/bin:$PATH

# Copy application code
COPY . .

# Create non-root user for security
RUN useradd -m -u 1000 spider && \
    chown -R spider:spider /app

USER spider

# Health check
HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=3 \
  CMD python -c "import sys; sys.exit(0)" || exit 1

# Run the spider
CMD ["python", "main.py"]
