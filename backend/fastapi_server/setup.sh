#!/usr/bin/env bash
set -e

echo "==> Creating virtual environment"
python3 -m venv .venv
source .venv/bin/activate

echo "==> Installing dependencies"
pip install -r requirements.txt

echo "==> Copying .env"
if [ ! -f .env ]; then
  cp .env.example .env
  echo "     Edit .env with your DATABASE_URL and secrets before continuing."
fi

echo "==> Creating PostgreSQL database (if it doesn't exist)"
createdb kubochain 2>/dev/null || echo "     Database already exists or createdb not available — skipping."

echo "==> Running Alembic migrations"
alembic upgrade head

echo ""
echo "Done! Start the server with:"
echo "  source .venv/bin/activate && uvicorn app.main:app --reload --port 8000"
