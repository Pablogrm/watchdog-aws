import { useNavigate } from 'react-router-dom';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

function Dashboard() {
  const navigate = useNavigate();

  // DATOS FALSOS (Mock Data) - Luego vendrán de Lambda/DynamoDB
  const datosGrafica = [
    { hora: '10:00', latencia: 120 },
    { hora: '11:00', latencia: 132 },
    { hora: '12:00', latencia: 101 },
    { hora: '13:00', latencia: 143 },
    { hora: '14:00', latencia: 450 }, // Un pico de lentitud
    { hora: '15:00', latencia: 110 },
  ];

  const webs = [
    { id: 1, nombre: 'Portal Principal', url: 'https://miempresa.com', estado: 'ONLINE', ultimaVez: 'hace 1 min' },
    { id: 2, nombre: 'API de Pagos', url: 'https://api.pagos.com', estado: 'ONLINE', ultimaVez: 'hace 5 min' },
    { id: 3, nombre: 'Servidor de Correo', url: 'https://mail.empresa.com', estado: 'OFFLINE', ultimaVez: 'hace 2 min' },
  ];

  return (
    <div className="min-h-screen bg-green-50 p-8 font-sans">
      
      {/* CABECERA */}
      <div className="flex justify-between items-center mb-8">
        <div>
          <h1 className="text-3xl font-extrabold text-gray-900">Serverless Watchdog</h1>
          <p className="text-sm text-gray-500 mt-1">TFG - Pablo García-Rojo Madrid</p>
        </div>
        <button 
          onClick={() => navigate('/login')}
          className="px-4 py-2 bg-white border border-gray-300 text-gray-700 rounded-lg shadow-sm hover:bg-gray-50 transition-colors font-medium text-sm"
        >
          Cerrar Sesión
        </button>
      </div>

      {/* TARJETAS KPI */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex flex-col justify-center">
          <span className="text-gray-500 text-sm font-medium mb-1">Total Endpoints</span>
          <span className="text-3xl font-bold text-gray-800">3</span>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex flex-col justify-center">
          <span className="text-gray-500 text-sm font-medium mb-1">Estado del Sistema</span>
          <span className="text-3xl font-bold text-green-600 flex items-center gap-2">
            <span className="w-3 h-3 rounded-full bg-green-500 animate-pulse"></span> Operativo
          </span>
        </div>
        <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 flex flex-col justify-center">
          <span className="text-gray-500 text-sm font-medium mb-1">Alerts (24h)</span>
          <span className="text-3xl font-bold text-red-500">1</span>
        </div>
      </div>

      {/* GRÁFICA DE RENDIMIENTO */}
      <div className="bg-white p-6 rounded-xl shadow-sm border border-gray-100 mb-8">
        <h3 className="text-lg font-bold text-gray-800 mb-6">Tiempos de Respuesta Promedio (ms)</h3>
        <div className="h-64 w-full">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={datosGrafica}>
              <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E5E7EB" />
              <XAxis dataKey="hora" axisLine={false} tickLine={false} tick={{fill: '#6B7280'}} />
              <YAxis axisLine={false} tickLine={false} tick={{fill: '#6B7280'}} />
              <Tooltip contentStyle={{ borderRadius: '8px', border: 'none', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)' }}/>
              <Line type="monotone" dataKey="latencia" stroke="#3B82F6" strokeWidth={3} dot={{r: 4, strokeWidth: 2}} activeDot={{r: 6}} />
            </LineChart>
          </ResponsiveContainer>
        </div>
      </div>

      {/* TABLA DE INVENTARIO */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center bg-gray-50/50">
          <h3 className="text-lg font-bold text-gray-800">Inventario de Webs</h3>
          <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm font-medium shadow-sm">
            + Añadir Nueva URL
          </button>
        </div>
        
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50 text-gray-500 text-xs uppercase tracking-wider">
                <th className="px-6 py-3 font-medium">Nombre</th>
                <th className="px-6 py-3 font-medium">URL</th>
                <th className="px-6 py-3 font-medium">Estado</th>
                <th className="px-6 py-3 font-medium">Último Chequeo</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {webs.map((web) => (
                <tr key={web.id} className="hover:bg-gray-50 transition-colors">
                  <td className="px-6 py-4 font-medium text-gray-900">{web.nombre}</td>
                  <td className="px-6 py-4 text-gray-500">{web.url}</td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                      web.estado === 'ONLINE' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'
                    }`}>
                      {web.estado}
                    </span>
                  </td>
                  <td className="px-6 py-4 text-gray-500">{web.ultimaVez}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

    </div>
  );
}

export default Dashboard;