import { useState, useEffect, useCallback } from 'react'
import { HashRouter as Router, Routes, Route, Link, useLocation, useNavigate } from 'react-router-dom'
import { Sun, Moon, Monitor, Download } from 'lucide-react'
import './App.css'
import LandingPage from './pages/LandingPage'
import PrivacyPage from './pages/Privacy'
import TermsPage from './pages/Terms'

type Theme = 'light' | 'dark' | 'system'

interface AppShellProps {
  theme: Theme
  setTheme: (value: Theme) => void
  resolvedTheme: 'light' | 'dark'
}

const AppShell = ({ theme, setTheme, resolvedTheme }: AppShellProps) => {
  const location = useLocation()
  const navigate = useNavigate()

  const scrollToFeatures = useCallback(() => {
    const scroll = () => {
      const section = document.getElementById('features')
      if (section) {
        section.scrollIntoView({ behavior: 'smooth', block: 'start' })
      }
    }

    if (location.pathname !== '/') {
      navigate('/', { replace: false })
      setTimeout(() => {
        requestAnimationFrame(scroll)
      }, 100)
    } else {
      scroll()
    }
  }, [location.pathname, navigate])

  return (
    <div className="app">
      <header className="header">
        <div className="container header-content">
          <div className="logo">
            <img src={`${import.meta.env.BASE_URL}app-icon.svg`} className="logo-icon" alt="TrimTally Logo" />
            <span className="logo-text">TrimTally</span>
          </div>
          <nav className="nav">
            <button type="button" onClick={scrollToFeatures}>Features</button>
            <a href="https://apps.apple.com/us/app/trimtally/id6755896878" className="btn btn-primary btn-sm" target="_blank" rel="noopener noreferrer">
              <Download size={16} />
              Download
            </a>
            <div className="theme-toggle">
              <button 
                className={`theme-btn ${theme === 'light' ? 'active' : ''}`} 
                onClick={() => setTheme('light')}
                title="Light Mode"
              >
                <Sun size={18} />
              </button>
              <button 
                className={`theme-btn ${theme === 'dark' ? 'active' : ''}`} 
                onClick={() => setTheme('dark')}
                title="Dark Mode"
              >
                <Moon size={18} />
              </button>
              <button 
                className={`theme-btn ${theme === 'system' ? 'active' : ''}`} 
                onClick={() => setTheme('system')}
                title="System Default"
              >
                <Monitor size={18} />
              </button>
            </div>
          </nav>
        </div>
      </header>

      <main>
        <Routes>
          <Route path="/" element={<LandingPage resolvedTheme={resolvedTheme} onLearnMore={scrollToFeatures} />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="/terms" element={<TermsPage />} />
        </Routes>
      </main>

      <footer className="footer">
        <div className="container">
          <div className="footer-content">
            <div className="footer-brand">
              <div className="logo">
                <img src={`${import.meta.env.BASE_URL}app-icon.svg`} className="logo-icon-sm" alt="TrimTally Logo" />
                <span>TrimTally</span>
              </div>
              <p>© {new Date().getFullYear()} Refractored. All rights reserved.</p>
            </div>
            <div className="footer-links">
              <Link to="/terms">Terms of Service</Link>
              <Link to="/privacy">Privacy Policy</Link>
              <a href="https://github.com/jamesmontemagno/app-trimly" target="_blank" rel="noopener noreferrer">GitHub</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}

function App() {
  const [theme, setTheme] = useState<Theme>(() => {
    const saved = localStorage.getItem('theme')
    return (saved as Theme) || 'system'
  })
  
  const [resolvedTheme, setResolvedTheme] = useState<'light' | 'dark'>('light')

  useEffect(() => {
    const root = window.document.documentElement
    const systemDark = window.matchMedia('(prefers-color-scheme: dark)')

    const applyTheme = () => {
      const isDark = theme === 'dark' || (theme === 'system' && systemDark.matches)
      setResolvedTheme(isDark ? 'dark' : 'light')
      if (isDark) {
        root.classList.add('dark')
      } else {
        root.classList.remove('dark')
      }
    }

    applyTheme()
    localStorage.setItem('theme', theme)

    if (theme === 'system') {
      systemDark.addEventListener('change', applyTheme)
      return () => systemDark.removeEventListener('change', applyTheme)
    }
  }, [theme])

  return (
    <Router>
      <AppShell theme={theme} setTheme={setTheme} resolvedTheme={resolvedTheme} />
    </Router>
  )
}

export default App
