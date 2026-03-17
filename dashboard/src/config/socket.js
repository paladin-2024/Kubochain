import { io } from 'socket.io-client';

let socket = null;

export const connectSocket = () => {
  const token = localStorage.getItem('admin_token');
  socket = io(import.meta.env.VITE_SOCKET_URL ?? 'http://localhost:5000', {
    transports: ['websocket'],
    auth: { token },
    extraHeaders: { Authorization: `Bearer ${token}` },
  });
  return socket;
};

export const getSocket = () => socket;
export const disconnectSocket = () => socket?.disconnect();
