import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  Shield,
  Scale, 
  TrendingUp, 
  Target, 
  Cloud, 
  Activity, 
  Bell, 
  Trophy,
  ArrowRight,
  Download,
  Sun,
  Moon,
  Monitor
} from 'lucide-react'
import './App.css'

type Theme = 'light' | 'dark' | 'system'

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

  const features = [
    {
      icon: <Shield className="w-6 h-6" />,
      title: "Private by Design",
      description: "TrimTally keeps every entry on your device with end-to-end privacy. No accounts, no tracking—ever."
    },
    {
      icon: <Cloud className="w-6 h-6" />,
      title: "Optional iCloud Backup",
      description: "Enable secure, encrypted iCloud sync when you want to keep your history backed up across Apple devices."
    },
    {
      icon: <Scale className="w-6 h-6" />,
      title: "Multi-Entry Logging",
      description: "Log as often as you like and let TrimTally handle daily normalization and insights."
    },
    {
      icon: <TrendingUp className="w-6 h-6" />,
      title: "Advanced Analytics",
      description: "Spot trends with SMA, EMA, linear regression, and volatility-aware projections."
    },
    {
      icon: <Target className="w-6 h-6" />,
      title: "Goal Tracking",
      description: "Set smart goals and see how each weigh-in moves you closer with actionable timelines."
    },
    {
      icon: <Activity className="w-6 h-6" />,
      title: "HealthKit Integration",
      description: "Import or export with Apple Health to keep your wellness data perfectly aligned."
    },
    {
      icon: <Bell className="w-6 h-6" />,
      title: "Smart Reminders",
      description: "Build consistent routines with adaptive nudges that respect your schedule."
    },
    {
      icon: <Trophy className="w-6 h-6" />,
      title: "Celebrations & Achievements",
      description: "Stay motivated with milestones, streak celebrations, and plateau detection insights."
    }
  ]

  const containerVariants = {
    hidden: { opacity: 0 },
    visible: {
      opacity: 1,
      transition: {
        staggerChildren: 0.1
      }
    }
  }

  const itemVariants = {
    hidden: { opacity: 0, y: 20 },
    visible: {
      opacity: 1,
      y: 0
    }
  }

  return (
    <div className="app">
      {/* Header */}
      <header className="header">
        <div className="container header-content">
          <div className="logo">
            <img src={`${import.meta.env.BASE_URL}app-icon.svg`} className="logo-icon" alt="TrimTally Logo" />
            <span className="logo-text">TrimTally</span>
          </div>
          <nav className="nav">
            <a href="#features">Features</a>
            <a href="https://www.refractored.com/about#privacy-policy" target="_blank" rel="noopener noreferrer">Privacy</a>
            
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

      {/* Hero Section */}
      <section className="hero section">
        <div className="container">
          <motion.div 
            className="hero-content"
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.6 }}
          >
            <h1 className="hero-title">
              Private, secure weight tracking <span className="gradient-text">with no account required</span>
            </h1>
            <p className="hero-subtitle">
              TrimTally keeps your progress safe on-device by default, with optional encrypted iCloud backup when you want it. 
              Understand trends without the noise thanks to clear analytics, smart goals, and encouraging feedback.
            </p>
            <div className="hero-highlights">
              <span className="hero-highlight-pill">Private &amp; secure</span>
              <span className="hero-highlight-pill">No account required</span>
              <span className="hero-highlight-pill">Optional iCloud backup</span>
            </div>
            <div className="hero-buttons">
              <a href="#" className="btn btn-primary">
                <Download size={20} />
                Download on App Store
              </a>
              <a href="#features" className="btn btn-secondary">
                Learn more <ArrowRight size={18} />
              </a>
            </div>
          </motion.div>
        </div>
      </section>

      {/* Features Section */}
      <section id="features" className="features section">
        <div className="container">
          <div className="section-header">
            <h2>Everything you need to stay on track</h2>
            <p>Powerful tools wrapped in a beautiful, native design.</p>
          </div>
          
          <motion.div 
            className="grid grid-3 features-grid"
            variants={containerVariants}
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-100px" }}
          >
            {features.map((feature, index) => (
              <motion.div key={index} className="feature-card" variants={itemVariants}>
                <div className="feature-icon">{feature.icon}</div>
                <h3>{feature.title}</h3>
                <p>{feature.description}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      {/* App Screenshots Section */}
      <section className="screenshots section">
        <div className="container">
          <div className="section-header">
            <h2>Beautifully Designed</h2>
            <p>Clean, modern interface that feels right at home on your device.</p>
          </div>
          
          <div className="screenshots-grid">
             <div className="screenshot-frame">
               <img 
                 key={`dashboard-${resolvedTheme}`}
                 src={`${import.meta.env.BASE_URL}screenshots/${resolvedTheme}/dashboard.png`} 
                 alt="Dashboard Screen" 
                 onError={(e) => {
                   e.currentTarget.style.display = 'none';
                   e.currentTarget.parentElement!.classList.add('placeholder');
                   e.currentTarget.parentElement!.innerHTML = '<span>Dashboard</span>';
                 }} 
               />
             </div>
             <div className="screenshot-frame">
               <img 
                 key={`analytics-${resolvedTheme}`}
                 src={`${import.meta.env.BASE_URL}screenshots/${resolvedTheme}/analytics.png`} 
                 alt="Analytics Screen" 
                 onError={(e) => {
                   e.currentTarget.style.display = 'none';
                   e.currentTarget.parentElement!.classList.add('placeholder');
                   e.currentTarget.parentElement!.innerHTML = '<span>Analytics</span>';
                 }} 
               />
             </div>
             <div className="screenshot-frame">
               <img 
                 key={`add-entry-${resolvedTheme}`}
                 src={`${import.meta.env.BASE_URL}screenshots/${resolvedTheme}/add-entry.png`} 
                 alt="Add Entry Screen" 
                 onError={(e) => {
                   e.currentTarget.style.display = 'none';
                   e.currentTarget.parentElement!.classList.add('placeholder');
                   e.currentTarget.parentElement!.innerHTML = '<span>Add Entry</span>';
                 }} 
               />
             </div>
          </div>
        </div>
      </section>

      {/* Footer */}
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
              <a href="https://www.refractored.com/terms" target="_blank" rel="noopener noreferrer">Terms of Service</a>
              <a href="https://www.refractored.com/about#privacy-policy" target="_blank" rel="noopener noreferrer">Privacy Policy</a>
              <a href="https://github.com/jamesmontemagno/app-trimly" target="_blank" rel="noopener noreferrer">GitHub</a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  )
}

export default App
