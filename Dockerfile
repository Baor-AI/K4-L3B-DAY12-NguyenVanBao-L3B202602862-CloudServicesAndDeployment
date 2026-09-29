# ═══════════════════════════════════════════════════════════════════
# CP2 — Dockerfile production-ready (multi-stage)
# ═══════════════════════════════════════════════════════════════════

# ─────────────────────────────────────────────────────────────
# Stage 1: builder — cài dependency vào /root/.local
# ─────────────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /app

# Copy requirements TRƯỚC source → tận dụng Docker layer cache
COPY requirements.txt .

# Cài vào --user (không cần root ở stage runtime)
RUN pip install --no-cache-dir --user -r requirements.txt


# ─────────────────────────────────────────────────────────────
# Stage 2: runtime — image gọn, non-root, có healthcheck
# ─────────────────────────────────────────────────────────────
FROM python:3.11-slim AS runtime

WORKDIR /app

# Tạo user thường — không chạy root
RUN useradd --create-home --shell /bin/bash appuser

# Copy dependency đã cài từ builder sang
COPY --from=builder /root/.local /home/appuser/.local

# PATH để python tìm thấy uvicorn/pip packages trong ~/.local
ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=8000

# Copy source code với quyền của appuser
COPY --chown=appuser:appuser . .

# Chuyển sang non-root
USER appuser

# Cloud tự gán $PORT; local mặc định 8000
EXPOSE 8000

# Healthcheck gọi /health — dùng python có sẵn, không cần curl
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import os, urllib.request; urllib.request.urlopen(f'http://localhost:{os.environ[\"PORT\"]}/health').read()" || exit 1

# Exec form — signal (SIGTERM) đi thẳng vào uvicorn, không bị sh chặn
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT}"]