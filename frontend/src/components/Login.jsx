import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

// 1. IMPORTACIÓN: Traemos la imagen al componente. 
// ¡ATENCIÓN! Cambia 'fondo-login.jpg' por el nombre exacto y extensión de tu foto.
import loginImage from '../assets/background.png';

function Login() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const navigate = useNavigate(); 

  const manejarEnvio = (evento) => {
    evento.preventDefault();
    navigate('/dashboard'); 
  };

  return (
    // 2. FONDO: Aplicamos la imagen importada usando la etiqueta style.
    // Usamos Tailwind (bg-cover, bg-center) para que la foto se adapte a cualquier pantalla.
    <div 
      className="min-h-screen flex items-center justify-center bg-gray-900 bg-cover bg-center bg-no-repeat relative"
      style={{ backgroundImage: `url(${loginImage})` }}
    >
      

      {/* TARJETA DE LOGIN: Le añadimos 'relative z-10' para que flote por encima del filtro oscuro */}
      <div className="relative z-10 max-w-md w-full bg-gray-800 rounded-xl shadow-2xl p-8 space-y-6 border border-gray-700">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold text-white tracking-wide">
            Serverless <span className="text-orange-500">Watchdog</span>
          </h2>
          <p className="mt-2 text-sm text-gray-400 font-medium tracking-widest">Login</p>
        </div>

        <form onSubmit={manejarEnvio} className="space-y-5 mt-8">
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Email</label>
            <input 
              type="email" 
              required
              className="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-orange-500 transition-colors"
              placeholder="admin@empresa.com"
              value={email}
              onChange={(e) => setEmail(e.target.value)} 
            />
          </div>
          
          <div>
            <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Password</label>
            <input 
              type="password" 
              required
              className="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-orange-500 transition-colors"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)} 
            />
          </div>

          <button 
            type="submit" 
            className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-bold text-white bg-orange-600 hover:bg-orange-500 transition-colors mt-4"
          >
            Access Dashboard
          </button>
        </form>
      </div>
    </div>
  );
}

export default Login;