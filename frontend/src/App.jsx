import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import Login from './components/Login';
import Dashboard from './components/Dashboard';

function App() {
  return (
    <BrowserRouter>
      {/* Routes es la caja donde definimos todos los caminos posibles */}
      <Routes>
          
        {/* Ruta 1: Si el usuario entra a la raíz ("/") lo expulsamos al login */}
        <Route path="/" element={<Navigate to="/login" replace />} />
        
        {/* Ruta 2: La pantalla de Login */}
        <Route path="/login" element={<Login />} />
        
        {/* Ruta 3: La pantalla del panel de control */}
        <Route path="/dashboard" element={<Dashboard />} />
          
      </Routes>
    </BrowserRouter>
  )
}

export default App