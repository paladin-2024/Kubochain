/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['DM Sans', 'sans-serif'],
        heading: ['Sora', 'sans-serif'],
      },
      colors: {
        primary: {
          DEFAULT: '#2563EB',
          light:   '#60A5FA',
          dark:    '#1D4ED8',
        },
        dark: {
          bg:     '#F1F5F9',   // page background — slate-100
          card:   '#FFFFFF',   // card surface — white
          border: '#E2E8F0',   // border — slate-200
        },
        success: '#16A34A',
        warning: '#D97706',
        danger:  '#DC2626',
        orange:  '#EA580C',
      },
      animation: {
        'slide-in': 'slideIn 0.2s ease-out',
      },
      keyframes: {
        slideIn: {
          from: { opacity: '0', transform: 'translateY(-6px)' },
          to:   { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
  plugins: [],
};
