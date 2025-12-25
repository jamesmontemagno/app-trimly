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
      <header className="header" role="banner">
        <div className="container header-content">
          <div className="logo">
            <img src={`${import.meta.env.BASE_URL}app-icon.svg`} className="logo-icon" alt="TrimTally Logo" width="32" height="32" />
            <span className="logo-text">TrimTally</span>
          </div>
          <nav className="nav" role="navigation" aria-label="Main navigation">
            <button type="button" onClick={scrollToFeatures} aria-label="Navigate to features section">Features</button>
            <a 
              href="https://apps.apple.com/us/app/trimtally/id6755896878" 
              className="btn btn-primary btn-sm" 
              target="_blank" 
              rel="noopener noreferrer"
              aria-label="Download TrimTally from the App Store"
            >
              <Download size={16} aria-hidden="true" />
              Download
            </a>
            <div className="theme-toggle" role="group" aria-label="Theme selection">
              <button 
                className={`theme-btn ${theme === 'light' ? 'active' : ''}`} 
                onClick={() => setTheme('light')}
                title="Light Mode"
                aria-label="Switch to light theme"
                aria-pressed={theme === 'light'}
              >
                <Sun size={18} aria-hidden="true" />
              </button>
              <button 
                className={`theme-btn ${theme === 'dark' ? 'active' : ''}`} 
                onClick={() => setTheme('dark')}
                title="Dark Mode"
                aria-label="Switch to dark theme"
                aria-pressed={theme === 'dark'}
              >
                <Moon size={18} aria-hidden="true" />
              </button>
              <button 
                className={`theme-btn ${theme === 'system' ? 'active' : ''}`} 
                onClick={() => setTheme('system')}
                title="System Default"
                aria-label="Use system theme"
                aria-pressed={theme === 'system'}
              >
                <Monitor size={18} aria-hidden="true" />
              </button>
            </div>
          </nav>
        </div>
      </header>

      <main role="main">
        <Routes>
          <Route path="/" element={<LandingPage resolvedTheme={resolvedTheme} onLearnMore={scrollToFeatures} />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="/terms" element={<TermsPage />} />
        </Routes>
      </main>

      <footer className="footer" role="contentinfo">
        <div className="container">
          <div className="footer-content">
            <div className="footer-brand">
              <div className="logo">
                <img src={`${import.meta.env.BASE_URL}app-icon.svg`} className="logo-icon-sm" alt="TrimTally Logo" width="24" height="24" />
                <span>TrimTally</span>
              </div>
              <p>© {new Date().getFullYear()} Refractored. All rights reserved.</p>
            </div>
            <nav className="footer-links" aria-label="Footer navigation">
              <Link to="/terms">Terms of Service</Link>
              <Link to="/privacy">Privacy Policy</Link>
              <a href="https://github.com/jamesmontemagno/app-trimly" target="_blank" rel="noopener noreferrer">GitHub</a>
            </nav>
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
