import { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import axios from 'axios';

// 1. IMPORTACIÓN: Asegúrate de que el nombre coincida con tu archivo en assets
import logsImage from '../assets/fondo.png'; 

const API_URL = 'https://TU_API_ID.execute-api.us-east-1.amazonaws.com/prod';

function Logs() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const healthFilter = searchParams.get('health_status');

  const [logs, setLogs] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchLogs = async () => {
      setLoading(true);
      try {
        let targetUrl = `${API_URL}/logs`;
        if (healthFilter) {
          targetUrl += `?health_status=${healthFilter}`;
        }
        const response = await axios.get(targetUrl);
        setLogs(response.data);
      } catch (error) {
        console.error("API Error fetching logs:", error);
      } finally {
        setLoading(false);
      }
    };
    fetchLogs();
  }, [healthFilter]);

  return (
    // 2. CONTENEDOR CON IMAGEN: Aplicamos el fondo fijo y centrado
    <div 
      className="min-h-screen bg-gray-900 bg-cover bg-center bg-no-repeat bg-fixed relative font-sans text-gray-100"
      style={{ backgroundImage: `url(${logsImage})` }}
    >
      
      {/* 3. CAPA DE CONTRASTE: Filtro oscuro (90%) para máxima legibilidad de la tabla */}
      <div className="absolute inset-0 bg-gray-900/50"></div>

      {/* 4. CONTENIDO: Elevado con z-10 sobre el fondo */}
      <div className="relative z-10 p-8">
        
        <div className="mb-8">
          <button 
            onClick={() => navigate('/dashboard')} 
            className="text-orange-500 text-sm font-bold hover:text-orange-400 transition-colors mb-2 block"
          >
            ← Back to Dashboard
          </button>
          <h1 className="text-3xl font-extrabold text-white uppercase tracking-widest">
            System <span className="text-orange-500">Logs</span>
          </h1>
          <p className="text-gray-300 text-sm italic mt-1 font-medium">
            {healthFilter === 'ERROR' ? 'Incident Report (GSI Filtering)' : 'Full Monitoring History'}
          </p>
        </div>

        {/* TABLA DE LOGS CON FONDO SEMITRANSPARENTE */}
        <div className="bg-gray-800/80 border border-gray-600 rounded-xl shadow-2xl overflow-hidden backdrop-blur-md">
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead>
                <tr className="bg-gray-900/60 text-gray-200 text-xs uppercase tracking-[0.15em] font-black">
                  <th className="px-8 py-5 border-b border-gray-600">Time (UTC)</th>
                  <th className="px-8 py-5 border-b border-gray-600">Name</th>
                  <th className="px-8 py-5 border-b border-gray-600">URL</th>
                  <th className="px-8 py-5 border-b border-gray-600 text-center">Status</th>
                  <th className="px-8 py-5 border-b border-gray-600 text-center">Latency</th>
                  <th className="px-8 py-5 border-b border-gray-600 text-right">Health</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-700 text-sm">
                {loading ? (
                  <tr>
                    <td colSpan="6" className="px-8 py-12 text-center text-gray-100 font-bold animate-pulse text-lg">
                      Requesting data from AWS DynamoDB...
                    </td>
                  </tr>
                ) : logs.length === 0 ? (
                  <tr>
                    <td colSpan="6" className="px-8 py-12 text-center text-gray-300 font-bold text-lg">
                      No records found in the database.
                    </td>
                  </tr>
                ) : (
                  logs.map((log, i) => (
                    <tr key={i} className="hover:bg-gray-700/50 transition-colors">
                      <td className="px-8 py-5 font-mono text-sm text-gray-300">
                        {log.timestamp ? log.timestamp.substring(0, 19).replace('T', ' ') : '-'}
                      </td>
                      <td className="px-8 py-5 font-bold text-white text-base">{log.nombre}</td>
                      <td className="px-8 py-5 text-sm text-gray-300 font-medium">{log.url}</td>
                      <td className="px-8 py-5 text-center font-mono font-bold text-lg">
                        <span className={log.status === 200 ? 'text-green-400' : 'text-red-400'}>
                          {log.status}
                        </span>
                      </td>
                      <td className="px-8 py-5 text-center font-mono text-orange-400 font-bold text-base">
                        {log.latencia}ms
                      </td>
                      <td className="px-8 py-5 text-right">
                        <span className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-black border ${
                          log.health_status === 'OK' 
                            ? 'bg-green-900/40 text-green-400 border-green-500/30' 
                            : 'bg-red-900/40 text-red-400 border-red-500/30'
                        }`}>
                          {log.health_status}
                        </span>
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
}

export default Logs;