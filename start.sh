#!/bin/bash
# HeartMuLa Studio Startup Script

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Starting HeartMuLa Studio..."

# Kill any existing instances
pkill -f "uvicorn backend.app.main:app" 2>/dev/null
pkill -f "vite.*5173" 2>/dev/null
sleep 2

# Start backend with multi-GPU support and 4-bit quantization
echo "Starting backend..."
source venv/bin/activate
HEARTMULA_4BIT=true \
CUDA_VISIBLE_DEVICES=0,1 \
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True \
    python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 > /tmp/heartmula_backend.log 2>&1 &

# Start frontend with LAN access
echo "Starting frontend..."
cd frontend
npm run dev -- --host 0.0.0.0 > /tmp/heartmula_frontend.log 2>&1 &
cd "$SCRIPT_DIR"

echo ""
echo "HeartMuLa Studio starting up..."
echo "Backend: http://localhost:8000 (loading models...)"
echo "Frontend: http://localhost:5173"
echo ""
echo "Logs:"
echo "  Backend:  tail -f /tmp/heartmula_backend.log"
echo "  Frontend: tail -f /tmp/heartmula_frontend.log"
echo ""
echo "Waiting for backend to load models (auto-downloads on first run)..."

# Wait for backend to be ready (up to 5 minutes for first-time download)
for i in {1..300}; do
    if curl -s http://localhost:8000/health > /dev/null 2>&1; then
        echo ""
        echo "Backend ready!"
        break
    fi
    sleep 1
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "."
    fi
done

echo ""
echo "HeartMuLa Studio is ready!"
echo "Open: http://localhost:5173"
