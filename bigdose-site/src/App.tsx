import { useEffect } from 'react'
import gsap from 'gsap'
import { ScrollTrigger } from 'gsap/ScrollTrigger'
import { DeviceShot, WideShot } from './DeviceShot'
import './landing.css'

gsap.registerPlugin(ScrollTrigger)

/** Set when the App Store listing is live, e.g. `https://apps.apple.com/app/id…` */
const appStoreUrl: string | null = null

function AppStoreButton({
  size = 'default',
  className = '',
}: {
  size?: 'header' | 'hero' | 'cta' | 'default'
  className?: string
}) {
  const badge = (
    <img src="/app-store-badge.png" width={156} height={46} alt="Download on the App Store" />
  )

  const classes = ['app-store-link', `app-store-link--${size}`, className].filter(Boolean).join(' ')

  if (appStoreUrl) {
    return (
      <a
        className={classes}
        href={appStoreUrl}
        rel="noopener noreferrer"
        target="_blank"
        aria-label="Download BigDose on the App Store"
      >
        {badge}
      </a>
    )
  }

  return (
    <span className={`${classes} app-store-link--pending`} aria-label="Download on the App Store — coming soon">
      {badge}
    </span>
  )
}

const painPoints = [
  {
    title: 'Vitamin D and burn risk get tracked separately',
    body: 'Most vitamin D advice tells you how much sun to get. Most skin advice tells you how much to avoid. Very few tools watch both on the same UV, in real time.',
  },
  {
    title: 'Generic timers cannot match your body or your sky',
    body: 'Rules like "15 minutes at noon" ignore skin type, cloud cover, sunscreen, how much skin is exposed and where you live. What works on a chart rarely works on your skin.',
  },
  {
    title: 'Extra sun is never free vitamin D',
    body: 'Every minute outside raises IU and skin stress together. Hitting your daily D goal does not mean you stayed inside your safe burn limit.',
  },
]

const benefits = [
  {
    kicker: '01 · Home dashboard',
    title: 'Your day. Your sky. Your dose.',
    body: 'BigDose reads local UV, cloud cover and sun angle to show when your vitamin D window is open, daily IU progress, weather at a glance and when to head outside.',
    image: '/screenshots/home-dashboard.png',
    alt: 'BigDose home dashboard with vitamin D window, weather card and IU goal ring',
    stat: '28%',
    statLabel: 'IU goal today',
  },
  {
    kicker: '02 · Session planner',
    title: 'Know your limits before you step out.',
    body: 'Set exposed skin, cloud cover and planned time. BigDose shows turn-over at halfway through your session or at 50% MED — whichever comes first — plus wrap-up and safe-max milestones and estimated IU, tuned to your skin type and today\'s UV.',
    image: '/screenshots/session-planner.png',
    alt: 'BigDose session planner with time slider and safe-max limits',
    stat: '~23m',
    statLabel: 'safe max today',
  },
  {
    kicker: '03 · Live session',
    title: 'One ring. Both stories.',
    body: 'A glowing goal ring tracks estimated vitamin D in real time. Below it, live cards show MED (burn risk) Used, minutes to MED and when to turn over — vitamin D progress and skin safety on one screen.',
    image: '/screenshots/active-session.png',
    alt: 'BigDose live sun session with goal ring, IU rate and MED burn-risk cards',
    stat: '34%',
    statLabel: 'of goal ring',
  },
  {
    kicker: '04 · Session complete',
    title: 'See what the session actually did.',
    body: 'Every completed session summarizes estimated IU, MED Used, average rate, peak UV and how much of your daily target you banked — with plain-language burn-risk context.',
    image: '/screenshots/session-complete.png',
    alt: 'BigDose session complete summary with comfortable headroom and MED used',
    stat: '25%',
    statLabel: 'MED used',
  },
  {
    kicker: '05 · Progress',
    title: 'Momentum, not just today.',
    body: 'Track blood-level estimates against your ng/mL goal, weekly intake totals and how sun, supplements and food combine over time.',
    image: '/screenshots/progress.png',
    alt: 'BigDose progress screen with estimated blood level and weekly IU totals',
    stat: '48%',
    statLabel: 'of ng/mL goal',
  },
  {
    kicker: '06 · Sun ledger',
    title: 'Sun, supplements and food in one place.',
    body: 'Today\'s IU breakdown, incidental exposure, Apple Health imports and a rolling 90-day ledger — every source of vitamin D in one view.',
    image: '/screenshots/history.png',
    alt: 'BigDose history sun ledger with daily and 90-day IU totals',
    stat: '193K',
    statLabel: 'IU last 90 days',
  },
]

const onboardingShots = [
  {
    image: '/screenshots/why-bigdose.png',
    alt: 'Why BigDose onboarding — dose your D, defend your skin',
    label: 'Why BigDose',
  },
  {
    image: '/screenshots/skin-type.png',
    alt: 'Fitzpatrick skin type selection during onboarding',
    label: 'Skin type',
  },
  {
    image: '/screenshots/sun-habit.png',
    alt: 'Typical skin exposure and sunscreen habits setup',
    label: 'Sun habit',
  },
  {
    image: '/screenshots/starting-level.png',
    alt: 'Starting level with 25(OH)D lab result options',
    label: 'Starting level',
  },
  {
    image: '/screenshots/daily-intake.png',
    alt: 'Daily supplement intake baseline calculation',
    label: 'Daily intake',
  },
]

const workflow = [
  'Set your Dose DNA',
  'Check today\'s window',
  'Run a live sun session',
  'Log supplements and food',
]

const features = [
  {
    icon: '☀',
    title: 'Vitamin D window',
    body: 'Solar geometry and live weather find when UVB is actually useful — not just when the sun is up.',
  },
  {
    icon: '🛡',
    title: 'Personal MED tracking',
    body: 'Fitzpatrick skin type, age, coverage and sunscreen shape your burn-risk budget.',
  },
  {
    icon: '⌚',
    title: 'Live Activity',
    body: 'Lock-screen and Dynamic Island updates while a session runs — elapsed time, IU progress and goal at a glance.',
  },
  {
    icon: '❤',
    title: 'Apple Health',
    body: 'Import vitamin D supplements and keep your ledger aligned with what you already log.',
  },
  {
    icon: '🔔',
    title: 'Smart alerts',
    body: 'Session safety notifications at the milestones that matter — without ending your session for you.',
  },
  {
    icon: '📚',
    title: 'Science tab',
    body: 'Freshman-level biology on UV, MED and honest limits — no medical cosplay.',
  },
]

const makerApps = [
  { name: 'BigScore', href: 'https://bigscore.web.app', icon: '/makers/bigscore.png' },
  { name: 'BigWrd', href: 'https://bigwrd.web.app', icon: '/makers/bigwrd.png' },
  { name: 'BigRoll', href: 'https://bigroll.web.app', icon: '/makers/bigroll.png' },
  { name: 'BigFli', href: 'https://bigfli.web.app', icon: '/makers/bigfli.png' },
] as const

function MakersAttribution() {
  return (
    <div className="makers-attribution">
      <p className="makers-attribution__kicker type-caption">From the makers of</p>
      <div className="makers-attribution__row">
        {makerApps.map((app, index) => (
          <span className="makers-attribution__item" key={app.name}>
            {index > 0 ? <span className="makers-attribution__sep" aria-hidden="true">·</span> : null}
            <a href={app.href} rel="noopener noreferrer" target="_blank">
              <img src={app.icon} alt="" width={28} height={28} />
              <span>{app.name}</span>
            </a>
          </span>
        ))}
      </div>
    </div>
  )
}

function Header() {
  return (
    <header className="topbar">
      <a className="topbar__brand" href="#" aria-label="BigDose home">
        <img src="/app-icon.png?v=2" alt="" width={42} height={42} />
        <span>BigDose</span>
      </a>
      <nav className="topbar__nav" aria-label="Primary">
        <a href="#why">Why</a>
        <a href="#benefits">Benefits</a>
        <a href="#features">Features</a>
        <a href="#workflow">How</a>
      </nav>
      <AppStoreButton size="header" className="topbar__cta" />
    </header>
  )
}

function SectionPeekLink({
  href,
  eyebrow,
  title,
}: {
  href: string
  eyebrow: string
  title: string
}) {
  return (
    <a className="section-peek-link" href={href}>
      <span className="eyebrow">{eyebrow}</span>
      <span className="display section-peek-link__title">{title}</span>
    </a>
  )
}

function Hero() {
  const tickerItems = ['Goal ring', 'Live UV', 'MED alerts', 'Apple Health', 'Live Activity', 'Dose DNA']

  return (
    <section className="hero peek-host" aria-label="BigDose hero">
      <div className="hero__backdrop" aria-hidden="true">
        <div className="hero__sun" data-hero-sun />
        <span className="hero__watermark display">D</span>
        <div className="hero__ambient">
          <svg viewBox="0 0 1200 640">
            <path d="M-80 430 C 170 120, 430 105, 650 295 S 1020 625, 1280 260" />
            <path d="M20 590 C 270 360, 520 335, 745 455 S 1020 635, 1220 520" />
          </svg>
        </div>
      </div>

      <div className="hero__grid">
        <div className="hero__copy">
          <p className="eyebrow hero__eyebrow" data-hero-eyebrow>
            Vitamin D + Skin Safety
            <br />
            for iPhone
          </p>

          <h1 className="display hero__title" data-hero-title>
            <span className="hero__title-line hero__title-line--primary">Dose your D...</span>
            <span className="hero__title-line hero__title-line--accent">Defend your Skin!</span>
          </h1>

          <p className="hero__lead type-lede" data-hero-lede>
            Most sun advice picks one lane. BigDose tracks vitamin D progress and burn risk at
            the same time — so you can get outside without guessing.
          </p>

          <div className="hero__actions store-badge-row" data-hero-actions>
            <AppStoreButton size="hero" />
            <img
              className="store-badge-row__health"
              src="/works-with-apple-health.svg"
              alt="Works with Apple Health"
              width={123}
              height={34}
              data-hero-health
            />
          </div>

          <div className="hero__proof" aria-label="BigDose highlights" data-hero-proof>
            {tickerItems.slice(0, 4).map((item) => (
              <span key={item}>{item}</span>
            ))}
          </div>
        </div>

        <div className="hero__visual" data-hero-visual>
          <div className="hero__glow" aria-hidden="true" />
          <div className="hero__stack" data-hero-stack>
            <DeviceShot
              className="device--back"
              src="/screenshots/home-dashboard.png"
              alt="BigDose home dashboard"
              eager
            />
            <DeviceShot
              className="device--front"
              src="/screenshots/active-session.png"
              alt="BigDose live sun session with goal ring and MED cards"
              eager
            />
          </div>

          <div className="signal-card signal-card--d" data-float-card>
            <span>Goal ring</span>
            <strong>34%</strong>
            <small>1,138 IU · 5:08 in</small>
          </div>

          <div className="signal-card signal-card--med" data-float-card>
            <span>MED Used</span>
            <strong>21.6%</strong>
            <small>Comfortable headroom</small>
          </div>

          <div className="hero__uv-readout" data-float-card aria-hidden="true">
            <span>UV index now</span>
            <strong>6.2</strong>
            <small>High · window open</small>
          </div>
        </div>
      </div>

      <div className="hero__ticker" aria-hidden="true">
        <div className="hero__ticker-track" data-ticker>
          {[...tickerItems, ...tickerItems].map((item, index) => (
            <span key={`${item}-${index}`}>{item}</span>
          ))}
        </div>
      </div>

      <SectionPeekLink
        href="#why"
        eyebrow="Why BigDose exists"
        title="The sun does two jobs at once."
      />
    </section>
  )
}

function Why() {
  return (
    <section className="why peek-host" id="why">
      <div className="section-heading" data-reveal>
        <span className="eyebrow">Why BigDose exists</span>
        <h2 className="display display-title">The sun does two jobs at once.</h2>
        <p className="type-body">
          UV kick-starts vitamin D and stresses skin cells on the same beam. BigDose was built
          so you do not have to pick one concern and ignore the other.
        </p>
        <p className="type-body pain-grid__intro">
          Most sun advice still misses the mark in three ways:
        </p>
      </div>

      <div className="pain-grid">
        {painPoints.map((point) => (
          <article className="pain-card" data-reveal key={point.title}>
            <h3>{point.title}</h3>
            <p className="type-body">{point.body}</p>
          </article>
        ))}
      </div>

      <SectionPeekLink
        href="#session-planner"
        eyebrow="Plan before you glow"
        title="Turn-over, safe max and IU — before the session starts."
      />
    </section>
  )
}

function SolutionStrip() {
  return (
    <section
      className="solution-strip split-section peek-host"
      id="session-planner"
      aria-label="BigDose session planner"
    >
      <div className="split-section__copy" data-reveal>
        <span className="eyebrow">Plan before you glow</span>
        <h2 className="display display-title">
          Turn-over, safe max and IU — before the session starts.
        </h2>
        <p className="split-section__lede type-lede">
          Set your time, see your limits and estimated IU before you step outside — tuned to
          your skin type and today&apos;s UV.
        </p>
      </div>
      <div className="split-section__media" data-reveal>
        <DeviceShot
          src="/screenshots/session-planner.png"
          alt="BigDose session planner with limits and estimated IU"
        />
      </div>

      <SectionPeekLink
        href="#live-activity"
        eyebrow="Live Activity"
        title="The session follows you to the lock screen."
      />
    </section>
  )
}

function LiveActivityStrip() {
  return (
    <section
      className="live-strip split-section split-section--reverse peek-host"
      id="live-activity"
      aria-label="BigDose Live Activity"
    >
      <div className="split-section__copy" data-reveal>
        <span className="eyebrow">Live Activity</span>
        <h2 className="display display-title">The session follows you to the lock screen.</h2>
        <p className="split-section__lede type-lede">
          Pause or end from Dynamic Island or the lock screen. Elapsed time, IU progress and
          goal fill update while you are outside — no need to unlock the phone.
        </p>
      </div>
      <div className="split-section__media split-section__media--wide" data-reveal>
        <WideShot
          src="/screenshots/live-activity.png"
          alt="BigDose Live Activity on iPhone lock screen during a sun session"
        />
      </div>

      <SectionPeekLink
        href="#benefits"
        eyebrow="Benefits, benefits, benefits"
        title="What changes when BigDose runs the session."
      />
    </section>
  )
}

function Benefits() {
  return (
    <section className="benefits peek-host" id="benefits">
      <div className="section-heading section-heading--compact" data-reveal>
        <span className="eyebrow">Benefits, benefits, benefits</span>
        <h2 className="display display-title">What changes when BigDose runs the session.</h2>
        <p className="type-caption">Actual BigDose screenshots — not a mock.</p>
      </div>

      {benefits.map((benefit, index) => (
        <article className={`benefit ${index % 2 ? 'benefit--reverse' : ''}`} key={benefit.title}>
          <div className="benefit__copy" data-reveal>
            <span className="type-kicker">{benefit.kicker}</span>
            <h3 className="display display-title display-title--benefit">{benefit.title}</h3>
            <p className="type-body">{benefit.body}</p>
            <div className="benefit__stat">
              <strong className="type-stat-value">{benefit.stat}</strong>
              <span className="type-stat-label">{benefit.statLabel}</span>
            </div>
          </div>

          <div className="benefit__screen" data-screen-reveal>
            <DeviceShot src={benefit.image} alt={benefit.alt} />
          </div>
        </article>
      ))}

      <SectionPeekLink
        href="#onboarding"
        eyebrow="Dose DNA"
        title="Personalized from the first minute."
      />
    </section>
  )
}

function OnboardingGallery() {
  return (
    <section className="onboarding peek-host" id="onboarding">
      <div className="section-heading" data-reveal>
        <span className="eyebrow">Dose DNA</span>
        <h2 className="display display-title">Personalized from the first minute.</h2>
        <p className="type-body">
          Skin type, sun habits, lab results and supplement baseline — onboarding builds a
          profile that pre-fills every session.
        </p>
      </div>

      <div className="onboarding__grid">
        {onboardingShots.map((shot) => (
          <figure className="onboarding__item" data-reveal key={shot.label}>
            <DeviceShot src={shot.image} alt={shot.alt} />
            <figcaption className="type-stat-label">{shot.label}</figcaption>
          </figure>
        ))}
      </div>

      <SectionPeekLink
        href="#features"
        eyebrow="Built for real life outside"
        title="Everything around the session."
      />
    </section>
  )
}

function Features() {
  return (
    <section className="features peek-host" id="features">
      <div className="section-heading" data-reveal>
        <span className="eyebrow">Built for real life outside</span>
        <h2 className="display display-title">Everything around the session.</h2>
      </div>

      <div className="features__grid">
        {features.map((feature) => (
          <article className="feature-card" data-reveal key={feature.title}>
            <span className="feature-card__icon" aria-hidden="true">
              {feature.icon}
            </span>
            <h3>{feature.title}</h3>
            <p className="type-body">{feature.body}</p>
          </article>
        ))}
      </div>

      <SectionPeekLink
        href="#workflow"
        eyebrow="How it works"
        title="Four steps. No guesswork."
      />
    </section>
  )
}

function Workflow() {
  return (
    <section className="workflow peek-host" id="workflow">
      <div className="section-heading" data-reveal>
        <span className="eyebrow">How it works</span>
        <h2 className="display display-title">Four steps. No guesswork.</h2>
      </div>

      <div className="workflow__grid">
        {workflow.map((step, index) => (
          <article className="workflow-card" data-reveal key={step}>
            <span>{String(index + 1).padStart(2, '0')}</span>
            <h3>{step}</h3>
          </article>
        ))}
      </div>

      <SectionPeekLink
        href="#closing"
        eyebrow="Get outside"
        title="Get outside with both eyes open."
      />
    </section>
  )
}

function Disclaimer() {
  return (
    <p className="disclaimer type-caption" data-reveal>
      BigDose is informational wellness guidance — not medical advice. Vitamin D and burn-risk
      estimates use published models adjusted for your profile and local conditions. A 25(OH)D
      blood test remains the source of truth for your level.
    </p>
  )
}

function Closing() {
  return (
    <footer className="closing peek-host" id="closing">
      <div className="closing__panel" data-reveal>
        <img className="closing__icon" src="/app-icon.png?v=2" alt="" width={92} height={92} />
        <span className="eyebrow">iPhone · Live Activity · Apple Health</span>
        <h2 className="display display-title">Get outside with both eyes open.</h2>
        <p className="type-lede">
          Track vitamin D progress and burn risk in every live sun session. BigDose watches
          both — in real time — and lets you make the call.
        </p>
        <div className="store-badge-row closing__store-row">
          <AppStoreButton size="hero" />
          <img
            className="store-badge-row__health"
            src="/works-with-apple-health.svg"
            alt="Works with Apple Health"
            width={123}
            height={34}
          />
        </div>
        <MakersAttribution />
      </div>
      <p className="closing__fine type-fine">
        Copyright © 2026 Cre8vPlanet Studios, LLC. Contact:{' '}
        <a href="mailto:info@cre8vplanet.com">info@cre8vplanet.com</a>
        {' · '}
        <a href="/support/">Support</a>
        {' · '}
        <a href="/privacy/">Privacy</a>
        <br />
        Apple, the Apple logo, iPhone and Apple Health are trademarks of Apple Inc., registered
        in the U.S. and other countries.
      </p>
    </footer>
  )
}

export default function App() {
  useEffect(() => {
    const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    if (prefersReducedMotion) return

    let ctx: gsap.Context | undefined

    const onMove = (event: PointerEvent) => {
      const visual = document.querySelector<HTMLElement>('[data-hero-visual]')
      if (!visual || window.innerWidth < 900) return
      const x = (event.clientX / window.innerWidth - 0.5) * 2
      const y = (event.clientY / window.innerHeight - 0.5) * 2
      gsap.to(visual, {
        x: x * 14,
        y: y * 10,
        rotateY: x * 4,
        rotateX: -y * 2,
        duration: 0.8,
        ease: 'power2.out',
      })
      gsap.to('[data-hero-stack]', {
        rotate: -4 + x * 2,
        duration: 0.8,
        ease: 'power2.out',
      })
    }

    try {
      window.addEventListener('pointermove', onMove)

      ctx = gsap.context(() => {
        gsap.from('.topbar', {
          y: -24,
          duration: 0.7,
          ease: 'power3.out',
        })

        gsap.from('[data-hero-sun]', {
          scale: 0.6,
          duration: 1.4,
          ease: 'power2.out',
        })

        gsap.from('.hero__watermark', {
          x: 80,
          duration: 1.6,
          ease: 'power3.out',
          delay: 0.1,
        })

        gsap.from('.hero__title', {
          y: 48,
          duration: 1,
          ease: 'power4.out',
          delay: 0.08,
        })

        gsap.from('[data-hero-eyebrow], [data-hero-lede], [data-hero-actions], [data-hero-health], [data-hero-proof]', {
          y: 34,
          duration: 0.85,
          stagger: 0.09,
          ease: 'power3.out',
          delay: 0.35,
        })

        gsap.from('[data-hero-stack]', {
          x: 90,
          y: 40,
          rotate: -6,
          duration: 1.15,
          delay: 0.2,
          ease: 'power4.out',
        })

        gsap.from('.hero__glow', {
          scale: 0.5,
          duration: 1.2,
          delay: 0.35,
          ease: 'power2.out',
        })

        gsap.from('[data-float-card]', {
          y: 28,
          scale: 0.88,
          duration: 0.7,
          stagger: 0.12,
          delay: 0.55,
          ease: 'back.out(1.45)',
        })

        gsap.to('[data-float-card]', {
          y: (index) => (index % 2 === 0 ? -11 : 11),
          duration: 2.8,
          repeat: -1,
          yoyo: true,
          ease: 'sine.inOut',
          stagger: 0.22,
        })

        gsap.to('[data-hero-sun]', {
          scale: 1.06,
          duration: 5,
          repeat: -1,
          yoyo: true,
          ease: 'sine.inOut',
        })

        gsap.to('[data-ticker]', {
          xPercent: -50,
          duration: 22,
          repeat: -1,
          ease: 'none',
        })

        gsap.utils.toArray<HTMLElement>('[data-reveal]').forEach((element) => {
          const inView = element.getBoundingClientRect().top < window.innerHeight * 0.82

          if (inView) {
            gsap.set(element, { autoAlpha: 1, y: 0 })
            return
          }

          gsap.set(element, { autoAlpha: 0, y: 56 })
          gsap.to(element, {
            y: 0,
            autoAlpha: 1,
            duration: 0.85,
            ease: 'power3.out',
            scrollTrigger: {
              trigger: element,
              start: 'top 82%',
              toggleActions: 'play none none reverse',
            },
          })
        })

        gsap.utils.toArray<HTMLElement>('[data-screen-reveal]').forEach((element) => {
          const inView = element.getBoundingClientRect().top < window.innerHeight * 0.82

          if (inView) {
            gsap.set(element, { autoAlpha: 1, y: 0, scale: 1 })
            return
          }

          gsap.set(element, { autoAlpha: 0, y: 70, scale: 0.94 })
          gsap.to(element, {
            y: 0,
            scale: 1,
            autoAlpha: 1,
            duration: 0.95,
            ease: 'power3.out',
            scrollTrigger: {
              trigger: element,
              start: 'top 82%',
              toggleActions: 'play none none reverse',
            },
          })
        })

        gsap.to('.hero__ambient path', {
          strokeDashoffset: 0,
          duration: 2.2,
          ease: 'power2.inOut',
        })

        gsap.to('.hero__watermark', {
          y: -40,
          ease: 'none',
          scrollTrigger: {
            trigger: '.hero',
            start: 'top top',
            end: 'bottom top',
            scrub: 1.2,
          },
        })
      })
    } catch (error) {
      console.error('BigDose motion setup failed:', error)
    }

    return () => {
      window.removeEventListener('pointermove', onMove)
      ctx?.revert()
    }
  }, [])

  return (
    <>
      <Header />
      <main id="main">
        <Hero />
        <Why />
        <SolutionStrip />
        <LiveActivityStrip />
        <Benefits />
        <OnboardingGallery />
        <Features />
        <Workflow />
        <Disclaimer />
      </main>
      <Closing />
    </>
  )
}
