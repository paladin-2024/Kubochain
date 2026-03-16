import { io } from 'socket.io-client';

let socket = null;

export const connectSocket = () => {
  const token = localStorage.getItem('admin_token');
  socket = io('http://localhost:5000', {
    transports: ['websocket'],
    auth: { token },
    extraHeaders: { Authorization: `Bearer ${token}` },
  });
  return socket;
};

export const getSocket = () => socket;
export const disconnectSocket = () => socket?.disconnect();
