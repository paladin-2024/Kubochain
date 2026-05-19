const WS_BASE = (import.meta.env.VITE_SOCKET_URL || 'ws://localhost:8000')
  .replace(/^http/, 'ws');

let ws = null;
const listeners = {};

const dispatch = (event, data) => {
  (listeners[event] || []).forEach((cb) => cb(data));
};

export const connectSocket = () => {
  const token = localStorage.getItem('admin_token');
  if (!token) return null;

  ws = new WebSocket(`${WS_BASE}/ws?token=${token}`);

  ws.onmessage = (e) => {
    try {
      const { event, data } = JSON.parse(e.data);
      if (event) dispatch(event, data ?? {});
    } catch (_) {}
  };

  ws.onclose = () => {
    ws = null;
  };

  ws.onerror = () => {
    ws?.close();
  };

  return ws;
};

export const getSocket = () => ws;

export const disconnectSocket = () => {
  ws?.close();
  ws = null;
};

export const emit = (event, data = {}) => {
  if (ws?.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ event, data }));
  }
};

export const on = (event, callback) => {
  if (!listeners[event]) listeners[event] = [];
  listeners[event].push(callback);
};

export const off = (event) => {
  delete listeners[event];
};
