import { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import { 
  Scale, 
  TrendingUp, 
  Target, 
  Cloud, 
  Activity, 
  Bell, 
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

  useEffect(() => {
    const root = window.document.documentElement
    const systemDark = window.matchMedia('(prefers-color-scheme: dark)')

    const applyTheme = () => {
      const isDark = theme === 'dark' || (theme === 'system' && systemDark.matches)
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
      icon: <Scale className="w-6 h-6" />,
      title: "Multi-Entry Logging",
      description: "Log your weight multiple times a day. We'll handle the daily aggregation for you."
    },
    {
      icon: <TrendingUp className="w-6 h-6" />,
      title: "Advanced Analytics",
      description: "Visualize your progress with SMA, EMA, and linear regression trend lines."
    },
    {
      icon: <Target className="w-6 h-6" />,
      title: "Goal Tracking",
      description: "Set your target weight and track your journey with smart projections."
    },
    {
      icon: <Cloud className="w-6 h-6" />,
      title: "iCloud Sync",
      description: "Your data stays in sync across all your devices automatically and securely."
    },
    {
      icon: <Activity className="w-6 h-6" />,
      title: "HealthKit Integration",
      description: "Seamlessly syncs with Apple Health to keep all your health data in one place."
    },
    {
      icon: <Bell className="w-6 h-6" />,
      title: "Smart Reminders",
      description: "Get notified at the perfect time to build a consistent weighing habit."
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
            <img src={`${import.meta.env.BASE_URL}app-icon.png`} className="logo-icon" alt="TrimTally Logo" />
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
              Your supportive companion for <span className="gradient-text">mindful weight tracking</span>
            </h1>
            <p className="hero-subtitle">
              TrimTally helps you understand your weight trends without the obsession. 
              Focus on the long-term journey with powerful analytics and gentle guidance.
            </p>
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
             <div className="screenshot-placeholder">
               <span>Dashboard</span>
             </div>
             <div className="screenshot-placeholder">
               <span>Analytics</span>
             </div>
             <div className="screenshot-placeholder">
               <span>Add Entry</span>
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
                <img src={`${import.meta.env.BASE_URL}app-icon.png`} className="logo-icon-sm" alt="TrimTally Logo" />
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
