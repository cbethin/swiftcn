'use client';
import Link from 'next/link';
import { sitePath } from '@/lib/site-path';
import { useState } from 'react';
import { motion, useReducedMotion } from 'motion/react';
import { ArrowRight, Braces, Command, Layers, MoveUpRight, SlidersHorizontal } from 'lucide-react';

const demoCode = `@State private var expanded = false

VStack(alignment: .leading) {
    Text("A little more native.").tw("text-sm font-semibold")
    Button(expanded ? "Back to simple" : "Make some room") {
        expanded.toggle()
    }.buttonStyle(.tw("button-primary"))
}
.tw(cn("p-5 bg-surface rounded-xl animate-spring",
       expanded ? "w-[365]" : "w-[290]"), value: expanded)`;
const demoClasses = ['cn', 'p-5', 'rounded-xl', 'w-[365]', 'animate-spring'];
const guides = [
  { icon: Braces, title: 'Compose your styles', copy: 'Strings when you want them. Typed utilities when you need them.', href: '/docs/styling', number: '01' },
  { icon: SlidersHorizontal, title: 'Make it yours', copy: 'Adaptive colors, shared recipes, and custom argument factories.', href: '/docs/global-rules', number: '02' },
  { icon: Layers, title: 'Give state some motion', copy: 'Native springs and shared elements, composed in a few classes.', href: '/docs/shared-elements', number: '03' },
];
export function Landing() {
  const [expanded, setExpanded] = useState(false);
  const reduced = useReducedMotion();
  return <div className="landing">
    <section className="hero" aria-labelledby="hero-title">
      <div className="hero-copy">
        <div className="eyebrow"><span className="status-dot" /> SWIFTUI, WITH A FAMILIAR VOCABULARY</div>
        <h1 id="hero-title">Familiar classes.<br /><span>Native everything.</span></h1>
        <p className="hero-description">The composition you love in shadcn.<br className="desktop-break" /> The controls, gestures, and motion you love in SwiftUI.</p>
        <div className="hero-actions">
          <Link href="/docs/installation" className="action-primary">Start building <ArrowRight size={16} /></Link>
          <Link href="/docs" className="action-secondary">Read the docs <MoveUpRight size={15} /></Link>
        </div>
        <div className="platforms"><Command size={13} /> iOS 17+ <span>·</span> macOS 14+ <span>·</span> Swift 6 <span>·</span> MIT</div>
      </div>
      <div className="workbench">
        <div className="workbench-top"><div className="traffic-lights"><i /><i /><i /></div><span>Something familiar. Something native.</span><span className="file-label">.swift</span></div>
        <div className="example-demo" role="group" aria-label="Compose styles and animate state">
          <div className="example-code"><span className="example-kicker">ONE VIEW. STYLES, STATE, AND MOTION.</span><pre><code>{demoCode}</code></pre></div>
          <div className="visual-example">
            <div className="illustration-stage">
              <motion.div className="illustration-card" initial={false} animate={{ width: expanded ? 365 : 290 }} transition={{ type: 'spring', bounce: 0, duration: reduced ? 0 : .4 }}>
                <div className="illustration-icon"><img className="bird-mark" src={sitePath('/brand/swiftcn-bird-v1.png')} alt="" width={36} height={36} /></div>
                <div className="illustration-copy"><strong>A little more native.</strong><p>Less ceremony. More SwiftUI.</p></div>
                <button type="button" onClick={() => setExpanded(value => !value)} aria-expanded={expanded} aria-label={expanded ? 'Back to simple' : 'Make some room'}>
                  <span className="illustration-button-label" aria-hidden="true">
                    <motion.span initial={false} animate={{ opacity: expanded ? 0 : 1 }} transition={{ duration: reduced ? 0 : .15 }}>Make some room</motion.span>
                    <motion.span initial={false} animate={{ opacity: expanded ? 1 : 0 }} transition={{ duration: reduced ? 0 : .15 }}>Back to simple</motion.span>
                  </span>
                  <motion.span className="illustration-button-arrow" initial={false} animate={{ rotate: expanded ? 180 : 0 }} transition={{ duration: reduced ? 0 : .2 }} aria-hidden="true"><ArrowRight size={14} /></motion.span>
                </button>
              </motion.div>
            </div>
            <span className="illustration-caption">Interactive web illustration · native captures below</span>
          </div>
          <div className="class-chips">{demoClasses.map(cls => <code key={cls}>{cls}</code>)}</div>
          <p className="example-note">Compose the classes with cn. Let SwiftUI animate your state.</p>
        </div>
      </div>
    </section>
    <div className="principle-strip"><span>SwiftUI at the foundation.</span><span>Styles you can own.</span><span>State stays native.</span><span>Zero runtime dependencies.</span></div>
    <section className="guide-section" aria-labelledby="guides-title">
      <div className="section-heading"><div><div className="eyebrow">SMALL API. ROOM TO GROW.</div><h2 id="guides-title">From a class to your design system.</h2></div><Link href="/docs/utilities">Explore the utilities <ArrowRight size={15} /></Link></div>
      <div className="guide-grid">{guides.map(({ icon: Icon, ...guide }) => <Link key={guide.number} href={guide.href} className="guide-card"><div className="guide-card-top"><Icon size={20} /><span>{guide.number}</span></div><h3>{guide.title}</h3><p>{guide.copy}</p><ArrowRight size={17} className="guide-arrow" /></Link>)}</div>
    </section>
    <section className="native-section" aria-labelledby="native-title">
      <div className="section-heading"><div><div className="eyebrow">THE REAL THING</div><h2 id="native-title">Rendered by SwiftUI.</h2><p>Native controls, adaptive themes, and editable recipes.</p></div><Link href="/docs/native-controls">Meet the components <ArrowRight size={15} /></Link></div>
      <figure className="native-gallery"><picture><img src={sitePath('/native/catalog-light.png')} alt="Native SwiftUI catalog showing buttons, text fields, toggles, sliders, and utility styles." loading="lazy" className="capture-light" width="1800" height="1316" /><img className="capture-dark" src={sitePath('/native/catalog-dark.png')} alt="Native SwiftUI catalog in dark appearance." loading="lazy" width="1800" height="1316" /></picture><figcaption>Actual macOS capture from the swiftcn catalog. Run the app to try its native interactions.</figcaption></figure>
    </section>
    <section className="closing"><div><span className="eyebrow">START WITH WHAT YOU KNOW</span><h2>Your next view, with fewer modifiers.</h2><p>Add the package. Compose a style. Keep building in SwiftUI.</p></div><Link href="/docs/installation" className="action-primary">Install swiftcn <ArrowRight size={16} /></Link></section>
    <footer className="site-footer"><span>swiftcn <span className="footer-muted">/ Familiar classes. Native SwiftUI.</span></span><div><Link href="/docs">Documentation</Link><a href="https://github.com/cbethin/swiftcn">GitHub ↗</a></div></footer>
  </div>;
}
