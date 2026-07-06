import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { signIn, signUp, confirmSignUp } from 'aws-amplify/auth';
import loginImage from '../assets/background.png';

function Login() {
  const navigate = useNavigate();

  const [mode, setMode] = useState('login'); // login | signup | confirm

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');

  const [confirmationCode, setConfirmationCode] = useState('');

  const [message, setMessage] = useState('');
  const [errorLogin, setErrorLogin] = useState('');
  const [loading, setLoading] = useState(false);

  const resetMessages = () => {
    setMessage('');
    setErrorLogin('');
  };

  const handleLogin = async (evento) => {
    evento.preventDefault();
    resetMessages();
    setLoading(true);

    try {
      const result = await signIn({
        username: email,
        password,
      });

      if (result.nextStep.signInStep === 'DONE') {
        navigate('/dashboard', { replace: true });
      } else {
        setErrorLogin(`Login requires another step: ${result.nextStep.signInStep}`);
      }
    } catch (error) {
      console.error('Error login Cognito:', error);
      setErrorLogin('Incorrect email or password, or unconfirmed user.');
    } finally {
      setLoading(false);
    }
  };

  const handleSignUp = async (evento) => {
    evento.preventDefault();
    resetMessages();
    setLoading(true);

    try {
      const result = await signUp({
        username: email,
        password,
        options: {
          userAttributes: {
            email,
          },
        },
      });

      if (result.nextStep.signUpStep === 'CONFIRM_SIGN_UP') {
        setMessage('We have sent you a confirmation code to your email.');
        setMode('confirm');
      } else if (result.nextStep.signUpStep === 'DONE') {
        setMessage('Account created successfully. You can now log in.');
        setMode('login');
      } else {
        setMessage(`Registration pending: ${result.nextStep.signUpStep}`);
      }
    } catch (error) {
      console.error('Error sign up Cognito:', error);

      if (error.name === 'UsernameExistsException') {
        setErrorLogin('An account with this email already exists.');
      } else if (error.name === 'InvalidPasswordException') {
        setErrorLogin('The password does not meet the security policy.');
      } else {
        setErrorLogin('Could not create account.');
      }
    } finally {
      setLoading(false);
    }
  };

  const handleConfirmSignUp = async (evento) => {
    evento.preventDefault();
    resetMessages();
    setLoading(true);

    try {
      await confirmSignUp({
        username: email,
        confirmationCode,
      });

      setMessage('Account confirmed successfully. You can now log in.');
      setConfirmationCode('');
      setMode('login');
    } catch (error) {
      console.error('Error confirm sign up Cognito:', error);
      setErrorLogin('Incorrect or expired code.');
    } finally {
      setLoading(false);
    }
  };

  const renderTitle = () => {
    if (mode === 'signup') return 'Create account';
    if (mode === 'confirm') return 'Confirm account';
    return 'Login';
  };

  return (
    <div
      className="min-h-screen flex items-center justify-center bg-gray-900 bg-cover bg-center bg-no-repeat relative"
      style={{ backgroundImage: `url(${loginImage})` }}
    >
      <div className="relative z-10 max-w-md w-full bg-gray-800 rounded-xl shadow-2xl p-8 space-y-6 border border-gray-700">
        <div className="text-center">
          <h2 className="text-3xl font-extrabold text-white tracking-wide">
            Serverless <span className="text-orange-500">Watchdog</span>
          </h2>
          <p className="mt-2 text-sm text-gray-400 font-medium tracking-widest">
            {renderTitle()}
          </p>
        </div>

        {mode !== 'confirm' && (
          <div className="flex bg-gray-900 rounded-lg p-1 border border-gray-700">
            <button
              type="button"
              onClick={() => {
                resetMessages();
                setMode('login');
              }}
              className={`flex-1 py-2 rounded-md text-sm font-bold transition-colors ${
                mode === 'login'
                  ? 'bg-orange-600 text-white'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Login
            </button>

            <button
              type="button"
              onClick={() => {
                resetMessages();
                setMode('signup');
              }}
              className={`flex-1 py-2 rounded-md text-sm font-bold transition-colors ${
                mode === 'signup'
                  ? 'bg-orange-600 text-white'
                  : 'text-gray-400 hover:text-white'
              }`}
            >
              Create account
            </button>
          </div>
        )}

        {mode === 'login' && (
          <form onSubmit={handleLogin} className="space-y-5 mt-8">
            <div>
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                Email
              </label>
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
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                Password
              </label>
              <input
                type="password"
                required
                className="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-orange-500 transition-colors"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>

            {message && (
              <p className="text-sm text-green-400 font-bold">
                {message}
              </p>
            )}

            {errorLogin && (
              <p className="text-sm text-red-400 font-bold">
                {errorLogin}
              </p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-bold text-white bg-orange-600 hover:bg-orange-500 transition-colors mt-4 disabled:opacity-60"
            >
              {loading ? 'Checking credentials...' : 'Access Dashboard'}
            </button>
          </form>
        )}

        {mode === 'signup' && (
          <form onSubmit={handleSignUp} className="space-y-5 mt-8">
            <div>
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                Email
              </label>
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
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                Password
              </label>
              <input
                type="password"
                required
                className="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-orange-500 transition-colors"
                placeholder="Min. 10 chars, upper, lower, number, symbol"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
              <p className="text-xs text-gray-500 mt-2">
                Password must have minimum 10 characters, uppercase, lowercase, number and symbol.
              </p>
            </div>

            {message && (
              <p className="text-sm text-green-400 font-bold">
                {message}
              </p>
            )}

            {errorLogin && (
              <p className="text-sm text-red-400 font-bold">
                {errorLogin}
              </p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-bold text-white bg-orange-600 hover:bg-orange-500 transition-colors mt-4 disabled:opacity-60"
            >
              {loading ? 'Creating account...' : 'Create account'}
            </button>
          </form>
        )}

        {mode === 'confirm' && (
          <form onSubmit={handleConfirmSignUp} className="space-y-5 mt-8">
            <div>
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                Email
              </label>
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
              <label className="block text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">
                Confirmation code
              </label>
              <input
                type="text"
                required
                className="w-full px-4 py-3 bg-gray-900 border border-gray-700 rounded-lg text-white focus:outline-none focus:border-orange-500 transition-colors"
                placeholder="123456"
                value={confirmationCode}
                onChange={(e) => setConfirmationCode(e.target.value)}
              />
            </div>

            {message && (
              <p className="text-sm text-green-400 font-bold">
                {message}
              </p>
            )}

            {errorLogin && (
              <p className="text-sm text-red-400 font-bold">
                {errorLogin}
              </p>
            )}

            <button
              type="submit"
              disabled={loading}
              className="w-full flex justify-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-bold text-white bg-orange-600 hover:bg-orange-500 transition-colors mt-4 disabled:opacity-60"
            >
              {loading ? 'Confirming account...' : 'Confirm account'}
            </button>

            <button
              type="button"
              onClick={() => {
                resetMessages();
                setMode('login');
              }}
              className="w-full text-sm text-gray-400 hover:text-white font-bold"
            >
              Back to login
            </button>
          </form>
        )}
      </div>
    </div>
  );
}

export default Login;