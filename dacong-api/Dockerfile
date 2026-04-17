# ── Stage 1: Base ──────────────────────────────────
FROM denoland/deno:alpine-2.1.4 AS base

WORKDIR /app

# ── Stage 2: Dependencies ──────────────────────────
FROM base AS deps

# Copy function definitions for dependency caching
COPY supabase/functions ./supabase/functions

# Cache dependencies by running deno cache on all TypeScript files
RUN find supabase/functions -name "*.ts" -exec deno cache --reload {} \;

# ── Stage 3: Production ────────────────────────────
FROM base AS production

# Copy cached dependencies from deps stage
COPY --from=deps /root/.cache/deno /root/.cache/deno

# Copy application code
COPY supabase/functions ./supabase/functions

# Set environment variables
ENV DENO_DIR=/root/.cache/deno
ENV PORT=8000

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD deno eval "fetch('http://localhost:8000/health').then(r => r.ok ? Deno.exit(0) : Deno.exit(1))" || exit 1

# Run the application
CMD ["deno", "run", \
  "--allow-net", \
  "--allow-env", \
  "--allow-read", \
  "--allow-write=/tmp", \
  "supabase/functions/serve.ts"]
