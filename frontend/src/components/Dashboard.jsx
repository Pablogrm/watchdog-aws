import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';
import axios from 'axios';
import dashboardImage from '../assets/fondo.png'; 

// ---> CAMBIAR ESTO POR LA URL DE TU API GATEWAY <---
const API_URL = 'https://TU_API_ID.execute-api.us-east-1.amazonaws.com/prod';

function Dashboard() {
  const navigate = useNavigate();
  const inventoryRef = useRef(null);

  // Estados
  const [inventory, setInventory] = useState([]);
  const [chartData, setChartData] = useState([]);
  const [activeAlerts, setActiveAlerts] = useState(0);
  
  // Estados del Modal
  const [showAddModal, setShowAddModal] = useState(false);
  const [newWebName, setNewWebName] = useState('');
  const [newWebUrl, setNewWebUrl] = useState('');

  // --- 1. Petición para la tabla de Inventario ---
  const fetchInventory = async () => {
    try {
      const response = await axios.get(`${API_URL}/webs`);
      setInventory(response.data);
    } catch (error) {
      console.error("Error fetching inventory:", error);
    }
  };

  // --- 2. Petición para la Gráfica y Tarjeta de Alertas ---
  const fetchPerformanceData = async () => {
    try {
      const response = await axios.get(`${API_URL}/logs`);
      const logsData = response.data;

      // Ordenar cronológicamente para la gráfica
      const sortedLogs = [...logsData].sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
      
      const formattedChartData = sortedLogs.slice(-20).map(log => ({
        time: log.timestamp.substring(11, 16),
        latency: log.latencia || 0
      }));
      setChartData(formattedChartData);

      // Calcular cuántas webs distintas están fallando extrayendo su health_status
      const healthStatusByUrl = {};
      sortedLogs.forEach(log => {
        healthStatusByUrl[log.url] = log.health_status;
      });
      
      // Función matemática de Javascript para contar los errores
      const arrayDeEstados = Object.values(healthStatusByUrl);
      const errorsCount = arrayDeEstados.filter(estadoSalud => estadoSalud === 'ERROR').length;
      
      setActiveAlerts(errorsCount);

    } catch (error) {
      console.error("Error fetching logs data:", error);
    }
  };

  useEffect(() => {
    fetchInventory();
    fetchPerformanceData();
  }, []);

  // --- 3. FUNCIONES CRUD (Añadir / Borrar) ---
  const handleAddWebsite = async (e) => {
    e.preventDefault();
    try {
      await axios.post(`${API_URL}/webs`, { nombre: newWebName, url: newWebUrl });
      setShowAddModal(false);
      setNewWebName('');
      setNewWebUrl('');
      fetchInventory(); 
    } catch (error) { alert("Failed to add website."); }
  };

  const handleDeleteWebsite = async (urlToDelete) => {
    if (!window.confirm(`Stop monitoring ${urlToDelete}?`)) return;
    try {
      await axios.delete(`${API_URL}/webs?url=${urlToDelete}`);
      fetchInventory(); 
    } catch (error) { alert("Failed to delete website."); }
  };

  return (
    <div 
      className="min-h-screen bg-gray-900 bg-cover bg-center bg-no-repeat bg-fixed relative font-sans text-gray-100"
      style={{ backgroundImage: `url(${dashboardImage})` }}
    >
      <div className="absolute inset-0 bg-gray-900/50"></div>

      <div className="relative z-10 p-8">
        
        {/* HEADER */}
        <div className="flex justify-between items-start mb-12 relative">
          <div className="flex items-start gap-4">
            <h1 className="text-3xl font-extrabold text-orange-500 mb-1 tracking-wide">
              Serverless Watchdog
            </h1>
          </div>
          <p className="absolute left-0 top-10 text-sm text-gray-400 font-medium tracking-widest">
            FINAL DEGREE PROJECT
          </p>
          <button onClick={() => navigate('/login')} className="px-5 py-2 bg-gray-800/80 border border-gray-700 text-gray-100 rounded-lg hover:bg-gray-700 transition-all text-sm font-bold">
            Logout
          </button>
        </div>

        {/* KPI CARDS */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-10">
          <div className="bg-gray-800/90 border border-gray-700 p-6 rounded-xl shadow-xl flex justify-between items-center transition-transform hover:scale-[1.02]">
            <div>
              <h3 className="text-gray-300 text-xs font-bold uppercase tracking-widest mb-1">Monitored URLs</h3>
              <p className="text-4xl font-black text-white">{inventory.length}</p>
            </div>
            <button onClick={() => inventoryRef.current?.scrollIntoView({ behavior: 'smooth' })} className="px-4 py-2 rounded-lg text-xs font-bold bg-blue-500/20 text-blue-300 border border-blue-500/30 hover:bg-blue-500/40">
              View Inventory
            </button>
          </div>

          <div className="bg-gray-800/90 border border-gray-700 p-6 rounded-xl shadow-xl flex justify-between items-center transition-transform hover:scale-[1.02]">
            <div>
              <h3 className="text-gray-300 text-xs font-bold uppercase tracking-widest mb-1">Lambda Interval</h3>
              <p className="text-4xl font-black text-white">5 <span className="text-lg text-gray-500 font-bold uppercase">min</span></p>
            </div>
            <button onClick={() => navigate('/logs')} className="px-4 py-2 rounded-lg text-xs font-bold bg-orange-500/20 text-orange-300 border border-orange-500/30 hover:bg-orange-500/40">
              View Logs
            </button>
          </div>

          <div className="bg-gray-800/90 border border-red-900/40 p-6 rounded-xl shadow-xl flex justify-between items-center relative overflow-hidden transition-transform hover:scale-[1.02]">
            <div className="relative z-10">
              <h3 className="text-gray-300 text-xs font-bold uppercase tracking-widest mb-1">Active Alerts</h3>
              <p className="text-4xl font-black text-red-500">{activeAlerts}</p>
            </div>
            {/* El botón te manda a la página de Logs con el GSI activado */}
            <button onClick={() => navigate('/logs?health_status=ERROR')} className="relative z-10 px-4 py-2 rounded-lg text-xs font-bold bg-red-500/20 text-red-300 border border-red-500/30 hover:bg-red-500/40">
              View Alerts
            </button>
          </div>
        </div>

        {/* PERFORMANCE CHART */}
        <div className="bg-gray-800/90 border border-gray-700 p-8 rounded-xl shadow-xl mb-10">
          <div className="mb-8">
            <h3 className="text-xl font-bold text-white tracking-tight">System Performance</h3>
            <p className="text-sm text-gray-300">Average response latency measured in milliseconds (ms).</p>
          </div>
          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={chartData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#4B5563" />
                <XAxis dataKey="time" axisLine={false} tickLine={false} tick={{fill: '#D1D5DB', fontSize: 12}} dy={10} />
                <YAxis axisLine={false} tickLine={false} tick={{fill: '#D1D5DB', fontSize: 12}} dx={-10} />
                <Tooltip contentStyle={{ backgroundColor: '#1F2937', borderColor: '#374151', borderRadius: '12px' }} itemStyle={{ color: '#F97316', fontWeight: 'bold' }} labelStyle={{ color: '#9CA3AF' }} />
                <Line type="monotone" dataKey="latency" stroke="#F97316" strokeWidth={4} dot={{ r: 4, fill: '#111827', strokeWidth: 2 }} activeDot={{ r: 8, strokeWidth: 0 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* INVENTORY TABLE */}
        <div ref={inventoryRef} className="bg-gray-800/90 border border-gray-600 rounded-xl shadow-2xl overflow-hidden scroll-mt-10 relative mb-10">
          <div className="px-8 py-6 border-b border-gray-600 bg-gray-900/40 flex justify-between items-center">
            <div>
              <h3 className="text-xl font-bold text-white">Website Inventory</h3>
              <p className="text-sm text-gray-200 mt-1">Management of monitored endpoints.</p>
            </div>
            <button onClick={() => setShowAddModal(true)} className="px-4 py-2 bg-orange-600 hover:bg-orange-500 text-white text-sm font-bold rounded-lg transition-colors flex items-center gap-2">
              Add Website
            </button>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-gray-100">
              <thead>
                <tr className="bg-gray-900/60 text-gray-200 text-xs uppercase tracking-widest font-black">
                  <th className="px-8 py-5 border-b border-gray-600 w-1/3">Site Name</th>
                  <th className="px-8 py-5 border-b border-gray-600 w-1/2">Target URL</th>
                  <th className="px-8 py-5 border-b border-gray-600 text-right w-1/6">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-700 text-sm">
                {inventory.map((site) => (
                  <tr key={site.url} className="hover:bg-gray-700/50 transition-colors group">
                    <td className="px-8 py-5 font-bold text-white group-hover:text-orange-400">{site.nombre}</td>
                    <td className="px-8 py-5 text-gray-200 font-mono">{site.url}</td>
                    <td className="px-8 py-5 text-right">
                      <button onClick={() => handleDeleteWebsite(site.url)} className="text-gray-400 hover:text-red-400">
                        <svg className="w-5 h-5 inline-block" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>

      {/* MODAL DE AÑADIR */}
      {showAddModal && (
        <div className="fixed inset-0 bg-black/80 flex items-center justify-center z-50 p-4">
          <div className="bg-gray-800 border border-gray-600 rounded-xl shadow-2xl w-full max-w-md p-6 relative z-[60]">
            <h3 className="text-xl font-bold text-white mb-6">Add New Website</h3>
            <form onSubmit={handleAddWebsite} className="space-y-4">
              <div>
                <label className="block text-xs font-bold text-gray-200 uppercase tracking-wider mb-2">Site Name</label>
                <input type="text" required value={newWebName} onChange={(e) => setNewWebName(e.target.value)} className="w-full bg-gray-900 border border-gray-600 rounded-lg px-4 py-3 text-white focus:border-orange-500 outline-none" />
              </div>
              <div>
                <label className="block text-xs font-bold text-gray-200 uppercase tracking-wider mb-2">Target URL</label>
                <input type="url" required value={newWebUrl} onChange={(e) => setNewWebUrl(e.target.value)} className="w-full bg-gray-900 border border-gray-600 rounded-lg px-4 py-3 text-white font-mono focus:border-orange-500 outline-none" />
              </div>
              <div className="pt-4 flex gap-3">
                <button type="button" onClick={() => setShowAddModal(false)} className="flex-1 px-4 py-3 bg-gray-700 text-white font-bold rounded-lg hover:bg-gray-600">Cancel</button>
                <button type="submit" className="flex-1 px-4 py-3 bg-orange-600 text-white font-bold rounded-lg hover:bg-orange-500">Save Website</button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default Dashboard;