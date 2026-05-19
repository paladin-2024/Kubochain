import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Motorbike01Icon, Shield01Icon, LockPasswordIcon } from 'hugeicons-react';
import api from '../config/api';

export default function Login() {
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const res = await api.post('/auth/login', { phone, password });
      if (res.data.user.role !== 'admin') {
        setError('Accès réservé aux administrateurs');
        return;
      }
      localStorage.setItem('admin_token', res.data.access_token);
      const u = res.data.user || {};
      localStorage.setItem('admin_user', JSON.stringify({
        name: u.firstName ? `${u.firstName} ${u.lastName || ''}`.trim() : (u.name || u.phone || ''),
        phone: u.phone || '',
      }));
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.detail || err.response?.data?.message || 'Connexion échouée');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-50 flex items-center justify-center p-4">
      <div className="w-full max-w-md">

        {/* Logo */}
        <div className="text-center mb-8">
          <div className="inline-flex w-16 h-16 bg-primary rounded-2xl items-center justify-center mb-4 shadow-lg shadow-primary/25">
            <Motorbike01Icon size={32} color="#ffffff" />
          </div>
          <h1 className="font-heading font-black text-slate-900 text-3xl tracking-tight">KuboChain</h1>
          <p className="text-slate-500 mt-1 text-sm">Command Center — Admin Access</p>
        </div>

        {/* Card */}
        <div className="bg-white border border-slate-200 rounded-2xl p-8 shadow-xl shadow-slate-200/60">
          <div className="flex items-center gap-2 mb-6">
            <Shield01Icon size={16} className="text-primary" />
            <h2 className="text-slate-900 text-xl font-semibold font-heading">Connexion Admin</h2>
          </div>

          {error && (
            <div className="bg-red-50 border border-red-200 text-red-600 text-sm px-4 py-3 rounded-xl mb-4">
              {error}
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="text-slate-600 text-sm mb-1.5 block font-medium">Numéro de téléphone</label>
              <div className="flex">
                <span className="inline-flex items-center px-3 bg-slate-100 border border-r-0 border-slate-200 rounded-l-xl text-slate-500 text-sm font-medium select-none">
                  🇨🇩 +243
                </span>
                <input
                  type="tel"
                  value={phone.replace(/^\+243/, '')}
                  onChange={(e) => setPhone('+243' + e.target.value.replace(/\D/g, ''))}
                  className="flex-1 bg-slate-50 border border-slate-200 rounded-r-xl px-4 py-3 text-slate-900 placeholder-slate-400 focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                  placeholder="999000001"
                  required
                />
              </div>
            </div>
            <div>
              <label className="text-slate-600 text-sm mb-1.5 block font-medium">Mot de passe</label>
              <div className="relative">
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 pr-11 text-slate-900 placeholder-slate-400 focus:outline-none focus:border-primary focus:ring-2 focus:ring-primary/20 transition-all"
                  placeholder="••••••••"
                  required
                />
                <LockPasswordIcon size={16} className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400" />
              </div>
            </div>
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-primary hover:bg-primary-dark text-white font-semibold py-3 rounded-xl transition-colors disabled:opacity-50 mt-2 font-heading tracking-wide shadow-md shadow-primary/20"
            >
              {loading ? 'Connexion…' : 'Accéder au tableau de bord'}
            </button>
          </form>

          <p className="text-slate-400 text-xs text-center mt-5">
            Accès réservé aux administrateurs autorisés
          </p>
        </div>
      </div>
    </div>
  );
}
