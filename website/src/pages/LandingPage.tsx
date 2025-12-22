import type { ComponentType } from 'react'
import { motion } from 'framer-motion'
import {
  Shield,
  Cloud,
  Scale,
  TrendingUp,
  Target,
  Activity,
  Bell,
  Trophy,
  Download,
  ArrowRight
} from 'lucide-react'

type LandingPageProps = {
  resolvedTheme: 'light' | 'dark'
  onLearnMore: () => void
}

type Feature = {
  Icon: ComponentType<{ className?: string }>
  title: string
  description: string
}

const features: Feature[] = [
  {
    Icon: Shield,
    title: 'Private by Design',
    description: 'TrimTally keeps every entry on your device with end-to-end privacy. No accounts, no tracking—ever.'
  },
  {
    Icon: Cloud,
    title: 'Optional iCloud Backup',
    description: 'Enable secure, encrypted iCloud sync when you want to keep your history backed up across Apple devices.'
  },
  {
    Icon: Scale,
    title: 'Multi-Entry Logging',
    description: 'Log as often as you like and let TrimTally handle daily normalization and insights.'
  },
  {
    Icon: TrendingUp,
    title: 'Advanced Analytics',
    description: 'Spot trends with SMA, EMA, linear regression, and volatility-aware projections.'
  },
  {
    Icon: Target,
    title: 'Goal Tracking',
    description: 'Set smart goals and see how each weigh-in moves you closer with actionable timelines.'
  },
  {
    Icon: Activity,
    title: 'HealthKit Integration',
    description: 'Import or export with Apple Health to keep your wellness data perfectly aligned.'
  },
  {
    Icon: Bell,
    title: 'Smart Reminders',
    description: 'Build consistent routines with adaptive nudges that respect your schedule.'
  },
  {
    Icon: Trophy,
    title: 'Celebrations & Achievements',
    description: 'Stay motivated with milestones, streak celebrations, and plateau detection insights.'
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

const LandingPage = ({ resolvedTheme, onLearnMore }: LandingPageProps) => {
  return (
    <>
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
              <a href="https://apps.apple.com/us/app/trimtally/id6755896878" className="btn btn-primary" target="_blank" rel="noopener noreferrer">
                <Download size={20} />
                Download on App Store
              </a>
              <button type="button" className="btn btn-secondary" onClick={onLearnMore}>
                Learn more <ArrowRight size={18} />
              </button>
            </div>
          </motion.div>
        </div>
      </section>

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
            viewport={{ once: true, margin: '-100px' }}
          >
            {features.map((feature) => (
              <motion.div key={feature.title} className="feature-card" variants={itemVariants}>
                <div className="feature-icon">
                  <feature.Icon className="w-6 h-6" />
                </div>
                <h3>{feature.title}</h3>
                <p>{feature.description}</p>
              </motion.div>
            ))}
          </motion.div>
        </div>
      </section>

      <section className="screenshots section">
        <div className="container">
          <div className="section-header">
            <h2>Beautifully Designed</h2>
            <p>Clean, modern interface that feels right at home on your device.</p>
          </div>

          <div className="screenshots-grid">
            {['dashboard', 'analytics', 'add-entry'].map((name) => (
              <div className="screenshot-frame" key={name}>
                <img
                  key={`${name}-${resolvedTheme}`}
                  src={`${import.meta.env.BASE_URL}screenshots/${resolvedTheme}/${name}.png`}
                  alt={`${name} screen`}
                  onError={(e) => {
                    e.currentTarget.style.display = 'none'
                    e.currentTarget.parentElement?.classList.add('placeholder')
                    if (e.currentTarget.parentElement) {
                      e.currentTarget.parentElement.innerHTML = `<span>${name.replace('-', ' ')}</span>`
                    }
                  }}
                />
              </div>
            ))}
          </div>
        </div>
      </section>
    </>
  )
}

export default LandingPage
