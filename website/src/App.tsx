import { motion } from 'framer-motion'
import { 
  Scale, 
  TrendingUp, 
  Target, 
  Cloud, 
  Activity, 
  Bell, 
  Trophy, 
  ArrowRight,
  Download,
  ChevronRight
} from 'lucide-react'
import './App.css'

function App() {
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
            <Scale className="logo-icon" />
            <span className="logo-text">TrimTally</span>
          </div>
          <nav className="nav">
            <a href="#features">Features</a>
            <a href="https://www.refractored.com/about#privacy-policy" target="_blank" rel="noopener noreferrer">Privacy</a>
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

      {/* Coming Soon Section */}
      <section className="coming-soon section">
        <div className="container">
          <div className="coming-soon-card">
            <div className="coming-soon-content">
              <Trophy className="coming-soon-icon" />
              <h2>Coming Soon in v1.2</h2>
              <p>We're working on exciting new features including Celebrations, Plateau Detection, and Home Screen Widgets.</p>
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
                <Scale className="logo-icon-sm" />
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
