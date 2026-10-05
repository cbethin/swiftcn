'use client';
import Link from 'next/link';
import { sitePath } from '@/lib/site-path';
import { useState } from 'react';
import { motion, useReducedMotion } from 'motion/react';
import { ArrowRight, Braces, Command, Layers, MoveUpRight, SlidersHorizontal } from 'lucide-react';

const examples = [
  { title: 'Style', tag: '01 / COMPOSE', code: 'Text("A little more native.")\n    .tw("text-lg font-semibold p-6 bg-surface rounded-xl")', note: 'Familiar utilities become real SwiftUI modifiers.', classes: ['text-lg', 'font-semibold', 'p-6', 'bg-surface', 'rounded-xl'] },
  { title: 'State', tag: '02 / RESPOND', code: 'Button("Continue", action: next)\n    .buttonStyle(.tw("button-primary active:scale-[0.97] animate-spring duration-150"))', note: 'SwiftUI keeps the action, gestures, and keyboard behavior.', classes: ['button-primary', 'active:scale-[0.97]', 'animate-spring'] },
  { title: 'Motion', tag: '03 / CONNECT', code: 'cover.tw("shared-[cover]/hero")\n\ncontainer.tw(\n    "group/hero animate-smooth",\n    value: expanded\n)', note: 'Persistent native namespaces. State you already own.', classes: ['group/hero', 'shared-[cover]', 'animate-smooth'] },
];
const guides = [
  { icon: Braces, title: 'Compose your styles', copy: 'Strings when you want them. Typed utilities when you need them.', href: '/docs/styling', number: '01' },
  { icon: SlidersHorizontal, title: 'Make it yours', copy: 'Adaptive colors, shared recipes, and custom argument factories.', href: '/docs/global-rules', number: '02' },
  { icon: Layers, title: 'Give state some motion', copy: 'Native springs and shared elements, composed in a few classes.', href: '/docs/shared-elements', number: '03' },
];
export function Landing() {
  const [selected, setSelected] = useState(0);
  const [expanded, setExpanded] = useState(false);
  const reduced = useReducedMotion();
  const example = examples[selected];
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
        <div className="example-tabs" role="tablist" aria-label="Swift examples">
          {examples.map((item, i) => <button key={item.title} role="tab" aria-selected={selected === i} aria-controls="example-panel" id={`example-tab-${i}`} tabIndex={selected === i ? 0 : -1} onClick={() => setSelected(i)} onKeyDown={(event) => {
            if (['ArrowRight', 'ArrowLeft', 'Home', 'End'].includes(event.key)) {
              event.preventDefault();
              const next = event.key === 'Home' ? 0 : event.key === 'End' ? 2 : (selected + (event.key === 'ArrowRight' ? 1 : 2)) % 3;
              setSelected(next);
              document.getElementById(`example-tab-${next}`)?.focus();
            }
          }}>{item.title}{selected === i && <motion.span className="tab-indicator" layoutId="active-tab" transition={{ duration: reduced ? 0 : .2 }} />}</button>)}
        </div>
        <div id="example-panel" role="tabpanel" aria-labelledby={`example-tab-${selected}`}>
          <div className="example-code"><span className="example-kicker">{example.tag}</span><pre><code>{example.code}</code></pre></div>
          <div className="visual-example">
            <motion.div className={`illustration-card ${expanded ? 'expanded' : ''}`} layout transition={{ type: 'spring', bounce: .1, duration: reduced ? 0 : .4 }}>
              <motion.div layout className="illustration-icon" transition={{ duration: reduced ? 0 : .3 }}><img className="bird-mark" src={sitePath('/brand/swiftcn-bird-v1.png')} alt="" width={36} height={36} /></motion.div>
              <div><strong>A little more native.</strong><p>Less ceremony. More SwiftUI.</p></div>
              <motion.button type="button" onClick={() => setExpanded(!expanded)} whileTap={reduced ? undefined : { transform: 'scale(0.97)' }} aria-expanded={expanded}>{expanded ? 'Back to simple' : 'Make some room'} <ArrowRight size={14} /></motion.button>
            </motion.div>
            <span className="illustration-caption">Interactive web illustration · native captures below</span>
          </div>
          <div className="class-chips">{example.classes.map(cls => <code key={cls}>{cls}</code>)}</div>
          <p className="example-note">{example.note}</p>
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
