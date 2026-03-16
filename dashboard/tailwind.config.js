/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      fontFamily: { sans: ['Poppins', 'sans-serif'] },
      colors: {
        primary: {
          DEFAULT: '#2F80ED',
          light: '#6AAFF5',
          dark: '#1A5BB8',
        },
        dark: {
          bg: '#0F1828',
          card: '#1E2A3A',
          border: '#2D3D50',
        },
        success: '#27AE60',
        warning: '#E2B93B',
        danger: '#EB5757',
        orange: '#F2994A',
      },
    },
  },
  plugins: [],
};
