# ---- build/runtime stage (multi-stage keeps the final image lean) ----
FROM python:3.12-slim AS base

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000
ENV PORT=5000

HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:5000/api/health || exit 1

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
