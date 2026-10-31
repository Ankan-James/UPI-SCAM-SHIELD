import { useEffect, useMemo, useState } from 'react'
import { BrowserRouter, Navigate, NavLink, Route, Routes, useLocation, useNavigate } from 'react-router-dom'
import { AnimatePresence, motion } from 'framer-motion'
import { QRCodeSVG } from 'qrcode.react'
import {
  ArrowDownLeft, ArrowLeft, ArrowRight, ArrowUpRight, BadgeCheck, Bell, BookOpen,
  Check, CheckCircle2, ChevronDown, CircleHelp, Clock3, Copy,
  FileWarning, Fingerprint, HeartHandshake, KeyRound, LayoutDashboard,
  Link2, LockKeyhole, LogOut, Menu, MessageCircleWarning, Plus, QrCode,
  ScanLine, Search, Send, Settings, Shield, ShieldAlert, ShieldCheck,
  Sparkles, UserRound, UserRoundX, Wallet, X, Eye, EyeOff,
} from 'lucide-react'
import { demoRecipients, initialTransactions, safetyLessons } from './data/demoData'
import {
  analyzeItem, analyzeRecipient, sendPayment, submitReport, updatePaymentLock,
  loginUser, registerUser, logoutUser, getCurrentUser, getStoredUser, getStoredToken,
} from './services/api'

const getInitials = (name) => {
  if (!name) return 'NU'
  const parts = name.trim().split(/\s+/)
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase()
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase()
}
import './App.css'

const money = (value) => `₹${Number(value).toLocaleString('en-IN')}`
const navigation = [
  { to: '/app/dashboard', label: 'Overview', icon: LayoutDashboard },
  { to: '/app/payments', label: 'Payments', icon: Send },
  { to: '/app/receive', label: 'Receive', icon: ArrowDownLeft },
  { to: '/app/scan', label: 'Scan QR', icon: ScanLine },
  { to: '/app/shield', label: 'Scam Shield', icon: ShieldCheck, featured: true },
  { to: '/app/transactions', label: 'Activity', icon: Clock3 },
  { to: '/app/report', label: 'Report a concern', icon: FileWarning },
  { to: '/app/learn', label: 'Safety centre', icon: BookOpen },
  { to: '/app/settings', label: 'Settings', icon: Settings },
]

function Logo({ small = false }) {
  return <div className={`brand ${small ? 'brand-small' : ''}`}><span className="brand-mark"><ShieldCheck size={small ? 18 : 20} strokeWidth={2.2} /></span><span>numpe</span></div>
}

function Toast({ message, onClose }) {
  if (!message) return null
  return <motion.div className="toast" initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} role="status"><CheckCircle2 size={18} />{message}<button aria-label="Dismiss notification" onClick={onClose}><X size={15} /></button></motion.div>
}

function Welcome({ onExplore }) {
  const navigate = useNavigate()
  return <main className="welcome">
    <header className="welcome-nav"><Logo /><div className="demo-pill"><span /> SIMULATED PAYMENTS</div><button className="button button-quiet" onClick={() => navigate('/login')}>Log in <ArrowRight size={16} /></button></header>
    <section className="welcome-hero">
      <div className="welcome-copy">
        <div className="eyebrow"><Sparkles size={14} /> YOUR EVERYDAY MONEY, WITH A SAFER SIDE</div>
        <h1>Pay with confidence.<br /><span>Pause with purpose.</span></h1>
        <p>Meet a smarter way to move money in your demo wallet — with a Scam Shield that helps you spot red flags before you confirm.</p>
        <div className="welcome-actions"><button className="button button-primary button-large" onClick={onExplore}>Explore the demo <ArrowRight size={18} /></button><button className="button button-outline button-large" onClick={() => navigate('/register')}>Create demo account</button></div>
        <div className="welcome-proof"><span><Check size={14} /> No real money</span><span><Check size={14} /> No bank connection</span><span><Check size={14} /> Your data stays yours</span></div>
      </div>
      <div className="welcome-art" aria-label="Illustration of secure digital payments">
        <div className="art-glow" /><div className="art-ring ring-one" /><div className="art-ring ring-two" />
        <div className="art-card"><div className="art-card-top"><span>NUMPE WALLET</span><Shield size={17} /></div><div className="art-card-label">Your demo balance</div><strong>₹24,580<span>.00</span></strong><div className="art-card-bottom"><span>•••• 2048</span><span>DEMO</span></div></div>
        <div className="art-shield"><ShieldCheck size={57} strokeWidth={1.5} /><span><i /></span></div>
        <div className="float-note note-safe"><span><ShieldCheck size={16} /></span><div><b>Scam Shield</b><small>Looking out for you</small></div><BadgeCheck className="note-check" size={17} /></div>
        <div className="float-note note-transfer"><span><ArrowUpRight size={16} /></span><div><b>Payment reviewed</b><small>Recipient verified</small></div></div>
        <div className="art-sparkle sparkle-a">✳</div><div className="art-sparkle sparkle-b">✳</div>
      </div>
    </section>
    <section className="welcome-features"><div className="section-kicker">A little more peace of mind</div><div className="feature-grid">
      {[{ icon: Wallet, title: 'Smart demo payments', text: 'Practice everyday payment flows in a wallet that uses virtual money only.' }, { icon: ShieldCheck, title: 'AI Scam Shield', text: 'Explore helpful risk signals and learn what to check before you pay.' }, { icon: QrCode, title: 'QR safety checks', text: 'Inspect a demo QR payload and see its details before taking action.' }].map(({ icon: Icon, title, text }) => <article className="feature-card" key={title}><span className="feature-icon"><Icon size={20} /></span><h3>{title}</h3><p>{text}</p></article>)}
    </div></section>
    <footer className="welcome-footer"><Logo small /><span>Designed for safer habits. All payments in this prototype are simulated.</span></footer>
  </main>
}

function AuthPage({ register = false, onAuthSuccess }) {
  const navigate = useNavigate()
  const [showPassword, setShowPassword] = useState(false)
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  async function submit(event) {
    event.preventDefault()
    const form = new FormData(event.currentTarget)
    const email = String(form.get('identity') || form.get('email') || '').trim()
    const password = String(form.get('password') || '')
    const name = String(form.get('name') || '').trim()

    if (register && form.get('password') !== form.get('confirm')) return setError('Your passwords do not match.')
    if (password.length < 8) return setError('Use at least 8 characters for your password.')
    setError('')
    setBusy(true)

    try {
      if (register) {
        await registerUser({ name, email, password })
      }
      const session = await loginUser({ email, password })
      if (onAuthSuccess) onAuthSuccess(session.user)
      navigate('/app/dashboard')
    } catch (err) {
      setError(err.message || 'Authentication failed. Please verify credentials.')
    } finally {
      setBusy(false)
    }
  }

  return <main className="auth-page"><button className="auth-back" onClick={() => navigate('/')}><ArrowLeft size={17} /> Back to NUMPE</button><div className="auth-card"><Logo /><div className="auth-heading"><div className="eyebrow">CONNECTED TO NUMPE DATABASE</div><h1>{register ? 'Let’s get you started.' : 'Welcome back.'}</h1><p>{register ? 'Create your account. Stored securely in database.' : 'Sign in to access your NUMPE wallet & Scam Shield.'}</p></div>
    <form onSubmit={submit} className="auth-form">
      {register && <label>Full name<input required name="name" placeholder="e.g. Ankan Mondal" autoComplete="name" /></label>}
      <label>{register ? 'Email address' : 'Email address'}<input required name="identity" type="email" placeholder={register ? 'you@example.com' : 'Enter your email'} autoComplete="username" /></label>
      {register && <label>Phone number (optional)<input name="phone" type="tel" placeholder="+91 98765 43210" autoComplete="tel" /></label>}
      <label>Password<div className="password-wrap"><input required name="password" type={showPassword ? 'text' : 'password'} placeholder="At least 8 characters" autoComplete={register ? 'new-password' : 'current-password'} /><button type="button" aria-label={showPassword ? 'Hide password' : 'Show password'} onClick={() => setShowPassword(!showPassword)}>{showPassword ? <EyeOff size={17} /> : <Eye size={17} />}</button></div></label>
      {register && <label>Confirm password<input required name="confirm" type="password" placeholder="Re-enter password" autoComplete="new-password" /></label>}
      {!register && <button type="button" className="forgot-link" onClick={() => setError('Password reset is not configured for self-service in this build.')}>Forgot password?</button>}
      {error && <div className="form-error" role="alert">{error}</div>}
      <button className="button button-primary button-full" disabled={busy}>{busy ? 'Authenticating with database…' : register ? 'Create account' : 'Log in'} <ArrowRight size={17} /></button>
    </form>
    <p className="auth-switch">{register ? 'Already have an account?' : 'New to NUMPE?'} <button onClick={() => navigate(register ? '/login' : '/register')}>{register ? 'Log in' : 'Create an account'}</button></p><div className="auth-simulated"><LockKeyhole size={14} /> Connected to SQLite backend · Argon2/PBKDF2 security</div>
  </div></main>
}

function Sidebar({ mobileOpen, setMobileOpen, onLogout, user }) {
  const location = useLocation()
  const displayName = user?.name || 'NUMPE User'
  const initials = getInitials(displayName)
  return <><aside className={`sidebar ${mobileOpen ? 'sidebar-open' : ''}`}><div className="sidebar-brand"><Logo /><button className="mobile-close" onClick={() => setMobileOpen(false)} aria-label="Close menu"><X size={19} /></button></div><div className="workspace-label">YOUR SPACE</div><nav className="side-nav">{navigation.map(({ to, label, icon: Icon, featured }) => <NavLink key={to} to={to} onClick={() => setMobileOpen(false)} className={({ isActive }) => `nav-link ${isActive || (to !== '/app/dashboard' && location.pathname.startsWith(to)) ? 'active' : ''} ${featured ? 'nav-featured' : ''}`}><Icon size={18} /><span>{label}</span>{featured && <span className="nav-new">AI</span>}</NavLink>)}</nav><div className="sidebar-bottom"><div className="sidebar-help"><div className="help-icon"><CircleHelp size={17} /></div><div><b>Need a hand?</b><small>Visit our safety centre</small></div><ArrowRight size={15} /></div><button className="profile-mini" onClick={onLogout}><div className="avatar avatar-indigo">{initials}</div><div className="profile-mini-copy"><b>{displayName}</b><small>{user?.email || 'Logged in'}</small></div><LogOut size={16} /></button></div></aside>{mobileOpen && <button className="sidebar-scrim" onClick={() => setMobileOpen(false)} aria-label="Close navigation" />}</>
}

function Shell({ app }) {
  const { locked, toast, setToast, onLogout, user } = app
  const [mobileOpen, setMobileOpen] = useState(false)
  const location = useLocation()
  const active = navigation.find((item) => location.pathname.startsWith(item.to))
  const pageTitles = {
    '/app/dashboard': 'Overview', '/app/payments': 'Send money', '/app/receive': 'Receive money',
    '/app/scan': 'QR inspector', '/app/shield': 'Scam Shield', '/app/transactions': 'Activity',
    '/app/report': 'Report a concern', '/app/learn': 'Safety centre', '/app/settings': 'Settings',
  }
  const pageTitle = pageTitles[location.pathname] ?? active?.label ?? 'Overview'
  function notify(message) { setToast(message); window.setTimeout(() => setToast(''), 3200) }
  const shared = { ...app, notify }
  const initials = getInitials(user?.name)
  return <div className="app-shell"><Sidebar mobileOpen={mobileOpen} setMobileOpen={setMobileOpen} onLogout={onLogout} user={user} /><div className="app-main"><header className="topbar"><button className="menu-toggle" onClick={() => setMobileOpen(true)} aria-label="Open navigation"><Menu size={21} /></button><div className="breadcrumb"><span>NUMPE</span><span className="crumb-slash">/</span><b>{pageTitle}</b></div><div className="topbar-right"><div className={`lock-status ${locked ? 'is-locked' : ''}`}><span />{locked ? 'Payments locked' : 'Shield active'}</div><button className="icon-button notification-button" aria-label="Notifications" onClick={() => notify('You’re all caught up — no new alerts.')}><Bell size={18} /><i /></button><div className="avatar avatar-indigo top-avatar">{initials}</div></div></header>
    <main className="page-content"><AnimatePresence mode="wait"><motion.div key={location.pathname} initial={{ opacity: 0, y: 6 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -4 }} transition={{ duration: 0.18 }} className="page-transition">
      <Routes>
        <Route path="dashboard" element={<Dashboard {...shared} />} />
        <Route path="payments" element={<SendMoney {...shared} />} />
        <Route path="receive" element={<Receive {...shared} />} />
        <Route path="scan" element={<QrInspector {...shared} />} />
        <Route path="shield" element={<ShieldPage {...shared} />} />
        <Route path="transactions" element={<Transactions {...shared} />} />
        <Route path="report" element={<ReportPage {...shared} />} />
        <Route path="learn" element={<LearnPage />} />
        <Route path="settings" element={<SettingsPage {...shared} />} />
        <Route index element={<Navigate to="dashboard" replace />} />
      </Routes>
    </motion.div></AnimatePresence></main><MobileNav /><Toast message={toast} onClose={() => setToast('')} /></div></div>
}

function PageHeading({ eyebrow, title, text, action }) {
  return <div className="page-heading"><div><div className="eyebrow">{eyebrow}</div><h1>{title}</h1>{text && <p>{text}</p>}</div>{action}</div>
}

function Dashboard({ balance, transactions, locked, setLocked, notify }) {
  const navigate = useNavigate()
  const [showBalance, setShowBalance] = useState(true)
  const recent = transactions.slice(0, 4)
  return <div className="dashboard-page"><div className="dashboard-greeting"><div><div className="eyebrow">FRIDAY, OCTOBER 30, 2026</div><h1>Good day, {user?.name ? user.name.split(' ')[0] : 'Member'} <span className="wave">✦</span></h1><p>Here’s your money snapshot for today.</p></div><div className="shield-active-pill"><ShieldCheck size={16} /> Scam Shield is on</div></div>
    <div className="dashboard-grid"><section className="balance-card"><div className="balance-top"><div className="balance-label"><span className="balance-chip"><Wallet size={15} /> DEMO BALANCE</span><span className="balance-caption">Available in your virtual wallet</span></div><button className="balance-eye" aria-label={showBalance ? 'Hide balance' : 'Show balance'} onClick={() => setShowBalance(!showBalance)}>{showBalance ? <Eye size={18} /> : <EyeOff size={18} />}</button></div><div className="balance-amount">{showBalance ? money(balance) : '₹ ••••••'}</div><div className="balance-bottom"><div><small>NUMPE UPI ID</small><span>{user?.upi_id || 'user@numpe'}</span></div><div className="virtual-card-art"><span>••••</span><span>2048</span></div></div><div className="balance-orb orb-one" /><div className="balance-orb orb-two" /></section>
      <section className="quick-card"><div className="card-title-row"><div><h2>Quick actions</h2><p>What would you like to do?</p></div><span className="tiny-demo">DEMO</span></div><div className="quick-actions">
        {[{ label: 'Send', icon: ArrowUpRight, to: '/app/payments', cls: 'quick-blue' }, { label: 'Receive', icon: ArrowDownLeft, to: '/app/receive', cls: 'quick-green' }, { label: 'Scan QR', icon: ScanLine, to: '/app/scan', cls: 'quick-violet' }, { label: 'Shield', icon: ShieldCheck, to: '/app/shield', cls: 'quick-amber' }].map(({ label, icon: Icon, to, cls }) => <button key={label} onClick={() => navigate(to)} className="quick-action"><span className={`quick-icon ${cls}`}><Icon size={20} /></span><span>{label}</span></button>)}</div></section>
    </div>
    <div className="dashboard-lower"><section className="panel recent-panel"><div className="panel-heading"><div><h2>Recent activity</h2><p>Your latest simulated transactions</p></div><button className="text-button" onClick={() => navigate('/app/transactions')}>View all <ArrowRight size={15} /></button></div><TransactionList transactions={recent} compact /></section>
      <div className="dashboard-aside"><section className={`lock-card ${locked ? 'locked' : ''}`}><div className="lock-card-icon">{locked ? <LockKeyhole size={20} /> : <Shield size={20} />}</div><div className="lock-card-content"><b>{locked ? 'Emergency lock is on' : 'Need a pause?'}</b><p>{locked ? 'Outgoing demo payments are paused.' : 'Pause outgoing payments instantly.'}</p></div><button className={`toggle ${locked ? 'toggle-on' : ''}`} aria-label={locked ? 'Unlock payments' : 'Lock payments'} aria-pressed={locked} onClick={async () => { try { const result = await updatePaymentLock(!locked); setLocked(result.locked); notify(result.locked ? 'Emergency payment lock activated.' : 'Outgoing demo payments unlocked.') } catch (error) { notify(error.message) } }}><span /></button></section>
        <button className="shield-promo" onClick={() => navigate('/app/shield')}><div className="promo-icon"><ShieldCheck size={21} /></div><div><b>Think before you pay.</b><p>Check a message, UPI ID, or link with Scam Shield.</p><span>Open Scam Shield <ArrowRight size={14} /></span></div><div className="promo-decoration"><Sparkles size={72} /></div></button></div>
    </div>
    <div className="dashboard-footnote"><ShieldCheck size={15} /> Demo environment — no real money is held or transferred.</div>
  </div>
}

function TransactionList({ transactions, compact = false }) {
  if (!transactions.length) return <div className="empty-state"><div><Wallet size={22} /></div><b>No activity yet</b><p>Your simulated payments will show up here.</p></div>
  return <div className={`transaction-list ${compact ? 'transaction-compact' : ''}`}>{transactions.map((tx) => <div className="transaction-row" key={tx.id}><div className={`transaction-avatar ${tx.direction === 'received' ? 'received-avatar' : ''}`}>{tx.direction === 'received' ? <ArrowDownLeft size={17} /> : tx.name.slice(0, 1)}</div><div className="transaction-person"><b>{tx.name}</b><span>{tx.upi}</span></div><div className="transaction-meta"><b className={tx.direction === 'received' ? 'amount-in' : ''}>{tx.direction === 'received' ? '+' : '−'}{money(tx.amount)}</b><span>{tx.date}</span></div><span className="status-success"><i />{tx.status}</span></div>)}</div>
}

function SendMoney({ balance, locked, setBalance, setTransactions, notify }) {
  const [recipient, setRecipient] = useState('')
  const [amount, setAmount] = useState('')
  const [note, setNote] = useState('')
  const [risk, setRisk] = useState(null)
  const [busy, setBusy] = useState(false)
  const [mpin, setMpin] = useState('')
  const [error, setError] = useState('')
  const [result, setResult] = useState(null)
  const [stage, setStage] = useState(1)
  const person = demoRecipients.find((item) => item.upi === recipient.trim())
  async function reviewPayment(event) {
    event.preventDefault()
    setError('')
    if (!recipient.trim().includes('@')) return setError('Enter a valid demo UPI ID, such as ananya.sharma@numpe.')
    if (!Number.isFinite(Number(amount)) || Number(amount) <= 0) return setError('Enter an amount greater than ₹0.')
    if (Number(amount) > balance) return setError('This amount is higher than your available demo balance.')
    setBusy(true)
    try { setRisk(await analyzeRecipient(recipient.trim())); setStage(2) } catch (e) { setError(e.message) } finally { setBusy(false) }
  }
  async function confirmPayment(event) {
    event.preventDefault()
    if (locked) return setError('Outgoing payments are paused by Emergency Payment Lock.')
    if (mpin.length !== 4) return setError('Enter the 4-digit demo MPIN to continue.')
    if (risk?.level === 'High') return setError('This high-risk demo recipient is blocked. Cancel and verify through another channel.')
    setBusy(true)
    setError('')
    try {
      const payment = await sendPayment({ recipient: recipient.trim(), amount: Number(amount), note })
      if (payment.status !== 'success') { setResult({ status: payment.status, id: payment.id }); setStage(3); return }
      const tx = { id: payment.id, name: person?.name ?? recipient.trim(), upi: recipient.trim(), amount: Number(amount), direction: 'sent', status: 'Success', date: 'Just now', risk: risk?.level ?? 'Low' }
      setBalance((value) => value - Number(amount))
      setTransactions((items) => [tx, ...items])
      setResult({ status: payment.status, id: payment.id })
      setStage(3)
    } catch (e) { setError(e.message) } finally { setBusy(false); setMpin('') }
  }
  function reset() { setStage(1); setRisk(null); setResult(null); setError(''); setRecipient(''); setAmount(''); setNote('') }
  return <div className="send-page"><PageHeading eyebrow="SIMULATED TRANSFER" title="Send money" text="A familiar payment flow, with an extra moment to check." action={<div className="available-balance"><Wallet size={15} /> Available <b>{money(balance)}</b></div>} />
    {locked && <div className="inline-alert alert-red"><LockKeyhole size={18} /><div><b>Emergency Payment Lock is active</b><span>Outgoing transfers are disabled until you unlock payments in Settings.</span></div></div>}
    <div className="send-layout"><section className="panel payment-panel">
      {stage === 3 && result ? <div className={`payment-success payment-outcome-${result.status}`}><div className="success-check"><Check size={31} /></div><div className="eyebrow">{result.status === 'success' ? 'DEMO TRANSFER COMPLETE' : 'DEMO TRANSFER UPDATE'}</div><h2>{result.status === 'success' ? 'Payment sent' : result.status === 'pending' ? 'Payment pending' : result.status === 'blocked' ? 'Payment blocked' : 'Payment failed'}</h2><div className="success-amount">{money(amount)}</div><p>{result.status === 'success' ? `Sent to ${person?.name ?? recipient}` : result.status === 'pending' ? 'The demo service has not confirmed this payment yet.' : result.status === 'blocked' ? 'The demo service blocked this payment. No balance was changed.' : 'The demo service could not complete this payment. No balance was changed.'}</p>{result.id && <div className="reference-box"><span>Reference ID</span><b>{result.id}</b></div>}<button className="button button-primary" onClick={reset}>{result.status === 'success' ? 'Make another payment' : 'Return to payment details'} <ArrowRight size={16} /></button></div> :
      <><div className="step-indicator"><span className={stage >= 1 ? 'step-done' : ''}>1</span><i /><span className={stage >= 2 ? 'step-done' : ''}>2</span><i /><span>3</span><div><b>{stage === 1 ? 'Payment details' : 'Review & confirm'}</b><small>{stage === 1 ? 'Who are you paying today?' : 'Take a moment to check.'}</small></div></div>
      {stage === 1 ? <form onSubmit={reviewPayment} className="payment-form"><label>Recipient’s UPI ID<div className="input-with-icon"><Search size={17} /><input value={recipient} onChange={(e) => setRecipient(e.target.value)} placeholder="name@bank" autoComplete="off" /></div></label>
        <div className="recipient-suggestions"><div className="field-note">RECENT & DEMO RECIPIENTS</div><div className="suggestion-list">{demoRecipients.map((item) => <button type="button" key={item.upi} className={`suggestion ${recipient === item.upi ? 'selected' : ''}`} onClick={() => setRecipient(item.upi)}><span className={`avatar avatar-${item.color}`}>{item.initials}</span><span><b>{item.name}</b><small>{item.upi}</small></span><Plus size={16} /></button>)}</div></div>
        <label>Amount<div className="amount-input"><span>₹</span><input type="number" min="1" step="1" value={amount} onChange={(e) => setAmount(e.target.value)} placeholder="0" /></div></label>
        <label>Payment note <span className="optional-label">OPTIONAL</span><input value={note} onChange={(e) => setNote(e.target.value)} maxLength={60} placeholder="What’s this for?" /></label>
        {error && <div className="form-error" role="alert">{error}</div>}<button disabled={busy || locked} className="button button-primary button-full">{busy ? 'Checking recipient…' : 'Review payment'} <ArrowRight size={17} /></button>
      </form> : <form onSubmit={confirmPayment} className="review-form"><div className={`risk-banner risk-${risk?.level?.toLowerCase()}`}><span className="risk-icon">{risk?.level === 'High' ? <ShieldAlert size={20} /> : <ShieldCheck size={20} />}</span><div><b>{risk?.level} risk · {risk?.score}/100</b><p>{risk?.recommendation}</p></div><span className="illustrative-tag">DEMO</span></div><div className="review-recipient"><span className={`avatar avatar-${person?.color ?? 'blue'}`}>{person?.initials ?? 'UP'}</span><div><b>{person?.name ?? 'UPI recipient'}</b><small>{recipient}</small></div><button type="button" className="text-button" onClick={() => setStage(1)}>Edit</button></div><div className="review-amount"><span>Amount</span><b>{money(amount)}</b></div><div className="risk-indicators"><div className="field-note">WHAT WE CHECKED</div>{risk?.indicators?.map((item) => <span key={item}><CheckCircle2 size={15} />{item}</span>)}</div>
        {risk?.level === 'High' ? <div className="inline-alert alert-red"><ShieldAlert size={18} /><div><b>This demo transfer is blocked</b><span>We won’t send a high-risk payment. Independently verify the recipient.</span></div></div> : <><label className="mpin-label">Confirm with demo MPIN <span className="optional-label">ANY 4 DIGITS · NOT SAVED</span><div className="input-with-icon"><Fingerprint size={18} /><input type="password" inputMode="numeric" maxLength={4} value={mpin} onChange={(e) => setMpin(e.target.value.replace(/\D/g, '').slice(0, 4))} placeholder="••••" /></div></label></>}
        {error && <div className="form-error" role="alert">{error}</div>}<div className="review-actions"><button className="button button-outline" type="button" onClick={reset}>Cancel</button>{risk?.level !== 'High' && <button className="button button-primary" disabled={busy || locked}>{busy ? 'Processing…' : 'Confirm simulated payment'} <ArrowRight size={16} /></button>}</div>
      </form>}
      </>}
    </section><aside className="send-side panel"><div className="side-shield"><ShieldCheck size={23} /></div><h3>A safer second look</h3><p>We check demo recipient signals before you confirm. Our risk score is guidance — not proof of fraud.</p><div className="side-divider" /><div className="side-trust-row"><CheckCircle2 size={16} /><span>Review recipient details</span></div><div className="side-trust-row"><CheckCircle2 size={16} /><span>Pause on unusual requests</span></div><div className="side-trust-row"><CheckCircle2 size={16} /><span>Payments are simulated only</span></div><button className="text-button" onClick={() => notify('This is a demo environment. No real money or bank account is involved.')}>How the demo works <ArrowRight size={14} /></button></aside></div>
  </div>
}

function Receive({ notify, user }) {
  const [copied, setCopied] = useState(false)
  const upiId = user?.upi_id || 'user@numpe'
  const displayName = user?.name || 'NUMPE User'
  const qrUri = `upi://pay?pa=${encodeURIComponent(upiId)}&pn=${encodeURIComponent(displayName)}`
  async function copyId() {
    try { await navigator.clipboard.writeText(upiId); setCopied(true); notify('UPI ID copied to clipboard.'); window.setTimeout(() => setCopied(false), 1800) }
    catch { notify('Clipboard access is unavailable in this browser.') }
  }
  return <div><PageHeading eyebrow="GET PAID, SAFELY" title="Receive money" text="Share your verified UPI ID or show your QR code." /><div className="receive-layout"><section className="panel receive-card"><div className="receive-card-heading"><div className="receive-emblem"><QrCode size={21} /></div><div><b>Your personal QR</b><small>{displayName}</small></div><span className="tiny-demo">CONNECTED</span></div><div className="qr-placeholder" role="img" aria-label={`UPI QR code for ${upiId}`}><QRCodeSVG value={qrUri} size={152} level="H" fgColor="#1b2b50" /></div><div className="qr-demo-note"><ShieldCheck size={14} /> Connected to database account</div><div className="upi-copy"><div><small>YOUR NUMPE UPI ID</small><b>{upiId}</b></div><button className="button button-outline" onClick={copyId}>{copied ? <Check size={16} /> : <Copy size={16} />}{copied ? 'Copied' : 'Copy ID'}</button></div></section><aside className="panel receive-info"><div className="receive-info-icon"><HeartHandshake size={23} /></div><div className="eyebrow">SENDING SHOULD FEEL SIMPLE</div><h2>Only share what’s needed.</h2><p>People can send money to your demo UPI ID. You never need to share an OTP or enter your UPI PIN to receive a payment.</p><div className="receive-tip"><ShieldCheck size={17} /><span>Always check your own app for a payment confirmation — not a screenshot.</span></div></aside></div></div>
}

function QrInspector() {
  const [payload, setPayload] = useState('')
  const [result, setResult] = useState(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  async function inspect(event) {
    event.preventDefault()
    setError('')
    try {
      const parsed = new URL(payload.trim())
      if (parsed.protocol !== 'upi:') throw new Error('Unsupported QR payload. Use a valid upi://pay demo payload.')
      const upi = parsed.searchParams.get('pa')
      if (!upi || !upi.includes('@')) throw new Error('This QR payload is missing a valid payee UPI ID.')
      setBusy(true)
      const risk = await analyzeRecipient(upi)
      setResult({ upi, name: parsed.searchParams.get('pn') || 'Unverified recipient', amount: parsed.searchParams.get('am') || 'Not specified', risk })
    } catch (e) { setError(e.message || 'Enter a valid demo UPI QR payload.') } finally { setBusy(false) }
  }
  const sample = 'upi://pay?pa=aanya.sharma%40numpe&pn=Aanya%20Sharma'
  return <div><PageHeading eyebrow="INSPECT BEFORE YOU ACT" title="QR inspector" text="Inspect a demo UPI payload before considering a payment. Scanning never starts a transfer." /><div className="scanner-layout"><section className="panel scanner-panel"><div className="scanner-preview"><div className="scanner-corners"><i /><i /><i /><i /></div><div className="scanner-icon"><ScanLine size={37} /></div><span className="scan-line" /><div className="scanner-preview-copy"><b>Camera scan is unavailable in this demo</b><span>Use the manual payload inspector below.</span></div></div><form className="scanner-form" onSubmit={inspect}><label>Paste a UPI QR payload<input value={payload} onChange={(e) => setPayload(e.target.value)} placeholder="upi://pay?pa=recipient@bank&pn=Name" /></label><div className="scanner-form-actions"><button className="text-button" type="button" onClick={() => setPayload(sample)}>Try a safe demo payload</button><button className="button button-primary" disabled={busy}>{busy ? 'Inspecting…' : 'Inspect QR'} <ArrowRight size={16} /></button></div>{error && <div className="form-error" role="alert">{error}</div>}</form></section><aside className="panel scanner-safety"><div className="side-shield"><ShieldCheck size={22} /></div><h3>Look before you leap.</h3><p>QR codes can hide a recipient or amount. Review the decoded details before choosing what to do next.</p><div className="scanner-rule"><span>01</span> Check the recipient name</div><div className="scanner-rule"><span>02</span> Confirm the amount independently</div><div className="scanner-rule"><span>03</span> Never enter your PIN to receive money</div></aside></div>
    {result && <section className="panel qr-result"><div className="panel-heading"><div><div className="eyebrow">DECODED DEMO PAYLOAD</div><h2>Review these details</h2></div><span className="tiny-demo">NOT A PAYMENT</span></div><div className="qr-result-grid"><div><small>RECIPIENT</small><b>{result.name}</b></div><div><small>UPI ID</small><b>{result.upi}</b></div><div><small>AMOUNT</small><b>{result.amount === 'Not specified' ? result.amount : money(result.amount)}</b></div><div><small>DEMO RISK CHECK</small><b className={`text-risk-${result.risk.level.toLowerCase()}`}>{result.risk.level} · {result.risk.score}/100</b></div></div><p className="illustrative-copy">Illustrative demo assessment only — not a verified fraud finding.</p></section>}
  </div>
}

function ShieldPage({ notify }) {
  const [type, setType] = useState('message')
  const [input, setInput] = useState('')
  const [result, setResult] = useState(null)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState('')
  const types = [{ id: 'message', label: 'Message', icon: MessageCircleWarning, placeholder: 'Paste a suspicious message here…' }, { id: 'url', label: 'Link or URL', icon: Link2, placeholder: 'Paste an unexpected link or URL…' }, { id: 'upi_id', label: 'UPI ID', icon: Wallet, placeholder: 'Enter the UPI ID you want to check…' }]
  async function analyze(event) {
    event.preventDefault()
    if (!input.trim()) { setError('Add something to check first.'); return }
    setError(''); setBusy(true); setResult(null)
    try { setResult(await analyzeItem(type, input.trim())) } catch (e) { setError(e.message) } finally { setBusy(false) }
  }
  return <div className="shield-page"><section className="shield-hero"><div className="shield-hero-copy"><div className="shield-label"><span /><ShieldCheck size={15} /> NUMPE SCAM SHIELD</div><h1>Think before<br />you <span>pay.</span></h1><p>NUMPE helps you identify suspicious payment activity before you confirm. A second look can make all the difference.</p><div className="shield-hero-foot"><span><CheckCircle2 size={15} /> Private demo analysis</span><span><CheckCircle2 size={15} /> You stay in control</span></div></div><div className="shield-hero-art"><div className="shield-art-ring" /><div className="shield-art-core"><ShieldCheck size={60} strokeWidth={1.4} /></div><span className="shield-art-dot dot-one" /><span className="shield-art-dot dot-two" /><span className="shield-art-dot dot-three" /><div className="shield-art-caption"><span className="pulse-dot" /> ALWAYS ON YOUR SIDE</div></div></section>
    <section className="analysis-layout"><div className="panel analysis-panel"><div className="panel-heading"><div><h2>What would you like to check?</h2><p>Choose a signal type and add the details below.</p></div><span className="analysis-lock"><LockKeyhole size={14} /> PRIVATE</span></div><div className="analysis-tabs">{types.map(({ id, label, icon: Icon }) => <button key={id} onClick={() => { setType(id); setResult(null); setError('') }} className={type === id ? 'selected' : ''}><Icon size={16} />{label}</button>)}</div><form onSubmit={analyze}><label className="sr-only" htmlFor="analysis-input">{types.find((item) => item.id === type)?.label} to analyze</label><textarea id="analysis-input" value={input} onChange={(e) => setInput(e.target.value)} placeholder={types.find((item) => item.id === type)?.placeholder} rows={5} maxLength={1500} /><div className="analysis-form-bottom"><span>{input.length}/1,500 characters · Don’t include passwords or OTPs</span><button className="button button-primary" disabled={busy}>{busy ? <><span className="button-spinner" /> Checking…</> : <><Sparkles size={16} /> Analyze safely</>}</button></div>{error && <div className="form-error" role="alert">{error}</div>}</form>
      {result && <RiskResult result={result} />}
    </div><aside className="analysis-side"><div className="analysis-side-icon"><Fingerprint size={21} /></div><h3>A helpful signal, not a verdict.</h3><p>Risk scores are illustrative guidance, not proof someone is fraudulent. Verify independently before you act.</p><div className="analysis-side-line" /><div className="side-trust-row"><ShieldCheck size={16} /><span>Never share your PIN or OTP</span></div><div className="side-trust-row"><ShieldCheck size={16} /><span>Analysis runs in demo mode</span></div><button className="text-button" onClick={() => notify('Your input is used only for this demo analysis and is not saved.')}>How we handle your data <ArrowRight size={14} /></button></aside></section>
  </div>
}

function RiskResult({ result }) {
  const riskClass = result.level.toLowerCase()
  return <motion.section className={`risk-result risk-result-${riskClass}`} initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }}><div className="risk-result-heading"><div><div className="eyebrow">ILLUSTRATIVE DEMO RESULT</div><h2>Here’s what stood out</h2></div><div className={`risk-score risk-score-${riskClass}`}><div><b>{result.score}</b><small>/100</small></div><span>RISK SCORE</span></div></div><div className={`risk-level risk-level-${riskClass}`}><span className="risk-level-dot" />{result.level} risk indicators</div><div className="risk-explanation"><b>Our suggestion</b><p>{result.recommendation}</p></div><div className="risk-indicators"><div className="field-note">SIGNALS TO CONSIDER</div>{result.indicators.map((item) => <span key={item}><ShieldAlert size={15} />{item}</span>)}</div><div className="risk-disclaimer"><CircleHelp size={15} /> This score is illustrative only and does not prove a person or payment is fraudulent.</div></motion.section>
}

function Transactions({ transactions }) {
  const [query, setQuery] = useState('')
  const [filter, setFilter] = useState('all')
  const filtered = useMemo(() => transactions.filter((tx) => (filter === 'all' || tx.direction === filter) && `${tx.name} ${tx.upi} ${tx.id}`.toLowerCase().includes(query.toLowerCase())), [transactions, filter, query])
  return <div><PageHeading eyebrow="YOUR DEMO WALLET" title="Activity" text="A clear view of your simulated payment history." /><section className="panel transactions-panel"><div className="transaction-tools"><div className="transaction-search"><Search size={16} /><input value={query} onChange={(e) => setQuery(e.target.value)} placeholder="Search name, UPI ID or reference" /></div><div className="filter-pills">{[['all', 'All'], ['sent', 'Sent'], ['received', 'Received']].map(([value, label]) => <button key={value} onClick={() => setFilter(value)} className={filter === value ? 'active' : ''}>{label}</button>)}</div></div><div className="transaction-table-head"><span>RECIPIENT</span><span>DATE</span><span>STATUS</span><span>AMOUNT</span></div><TransactionList transactions={filtered} /></section><div className="transactions-disclaimer"><ShieldCheck size={15} /> All records shown are simulated demo transactions.</div></div>
}

function ReportPage() {
  const [category, setCategory] = useState('Suspicious payment request')
  const [item, setItem] = useState('')
  const [description, setDescription] = useState('')
  const [busy, setBusy] = useState(false)
  const [report, setReport] = useState(null)
  const [error, setError] = useState('')
  async function submit(event) {
    event.preventDefault()
    if (!item.trim() || !description.trim()) { setError('Add the suspicious item and a short description.'); return }
    setBusy(true); setError('')
    try { setReport(await submitReport({ category, item: item.trim(), description: description.trim() })); setItem(''); setDescription('') } catch (e) { setError(e.message) } finally { setBusy(false) }
  }
  return <div><PageHeading eyebrow="HELP KEEP OUR DEMO COMMUNITY SAFER" title="Report a concern" text="Share a suspicious message, link, QR payload, or UPI ID for review." /><div className="report-layout"><form className="panel report-form" onSubmit={submit}><div className="report-info"><ShieldAlert size={18} /><p>A report is a concern for review, not a finding of wrongdoing. Avoid sharing passwords, PINs, or OTPs.</p></div><label>What are you reporting?<select value={category} onChange={(e) => setCategory(e.target.value)}><option>Suspicious payment request</option><option>UPI ID or recipient</option><option>Phishing link</option><option>QR code payload</option><option>Impersonation or other</option></select></label><label>Suspicious item<input value={item} onChange={(e) => setItem(e.target.value)} placeholder="UPI ID, message, URL, or QR details" /></label><label>What happened?<textarea rows={4} maxLength={800} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="Tell us what made you concerned…" /><span className="field-hint">{description.length}/800</span></label>{error && <div className="form-error">{error}</div>}<button className="button button-primary" disabled={busy}>{busy ? 'Submitting…' : 'Submit demo report'} <ArrowRight size={16} /></button><small className="form-disclaimer">Demo only. Do not include personal or financial information.</small></form><aside className="report-aside"><div className="report-aside-icon"><FileWarning size={21} /></div><h3>What happens next?</h3><p>Your demo report is assigned a reference ID and marked for review. Reports do not automatically label a person as a scammer.</p><div className="review-status"><span className="review-dot" /><div><b>Pending review</b><small>New demo reports start here</small></div></div><div className="review-status muted"><span className="review-dot" /><div><b>Under review</b><small>Someone is checking the details</small></div></div><div className="review-status muted"><span className="review-dot" /><div><b>Validated</b><small>Reviewed with additional context</small></div></div></aside></div>{report && <div className="report-confirmation"><CheckCircle2 size={20} /><div><b>Report submitted · {report.status}</b><span>Reference {report.id} · Illustrative status for this demo</span></div><button onClick={() => setReport(null)} aria-label="Dismiss report confirmation"><X size={16} /></button></div>}</div>
}

function LearnPage() {
  const iconMap = { ScanLine, MessageCircleWarning, Link2, ShieldAlert, UserRoundX, Clock3 }
  const [selected, setSelected] = useState(null)
  return <div><PageHeading eyebrow="SMALL PAUSES, SAFER PAYMENTS" title="Safety centre" text="A few simple checks can help you stay one step ahead." /><div className="learn-grid">{safetyLessons.map((lesson, i) => { const Icon = iconMap[lesson.icon]; return <button className={`lesson-card ${selected === i ? 'lesson-open' : ''}`} key={lesson.title} onClick={() => setSelected(selected === i ? null : i)}><span className="lesson-icon"><Icon size={20} /></span><span className="lesson-number">0{i + 1}</span><b>{lesson.title}</b><p>{lesson.text}</p><span className="lesson-expand">{selected === i ? 'Close tip' : 'Read the tip'} <ChevronDown size={14} /></span></button> })}</div><section className="panel learn-bottom"><span className="learn-bottom-icon"><ShieldCheck size={22} /></span><div><b>Remember: you can always take a moment.</b><p>A legitimate request will still make sense after you pause, check, and verify.</p></div></section></div>
}

function SettingsPage({ locked, setLocked, notify, onLogout, user }) {
  const displayName = user?.name || 'NUMPE User'
  const upiId = user?.upi_id || 'user@numpe'
  const email = user?.email || 'Logged in user'
  const initials = getInitials(displayName)
  return <div><PageHeading eyebrow="YOUR NUMPE SPACE" title="Settings" text="Manage your account profile and payment safety preferences." /><div className="settings-layout"><section className="panel settings-card"><div className="settings-section-head"><div className="avatar avatar-indigo avatar-large">{initials}</div><div><h2>{displayName}</h2><p>{email}</p></div><span className="profile-verified"><BadgeCheck size={15} /> Verified</span></div><SettingRow icon={UserRound} title="Profile information" detail={`${displayName} · ${email}`} onClick={() => notify('Profile information is synchronized with SQLite database.')} /><SettingRow icon={Wallet} title="Virtual UPI ID" detail={upiId} onClick={async () => { try { await navigator.clipboard.writeText(upiId); notify('UPI ID copied.') } catch { notify('Clipboard access is unavailable.') } }} /><SettingRow icon={KeyRound} title="MPIN settings" detail="Demo only · Never stored" onClick={() => notify('MPIN setup is simulated and no MPIN is stored.')} /><SettingRow icon={Bell} title="Notifications" detail="Payment and safety alerts enabled" onClick={() => notify('Notification preferences are enabled for this demo.')} /><SettingRow icon={LockKeyhole} title="Privacy & security" detail="Review how NUMPE keeps your demo safe" onClick={() => notify('Demo inputs are not saved to an account.')} /><button className="settings-logout" onClick={onLogout}><LogOut size={17} /> Log out of demo</button></section><aside className="settings-side"><div className={`settings-lock ${locked ? 'locked' : ''}`}><div className="lock-card-icon">{locked ? <LockKeyhole size={20} /> : <ShieldCheck size={20} />}</div><div><b>Emergency Payment Lock</b><p>{locked ? 'Outgoing simulated payments are paused.' : 'Pause all outgoing demo payments.'}</p></div><button className={`toggle ${locked ? 'toggle-on' : ''}`} aria-pressed={locked} aria-label={locked ? 'Unlock payments' : 'Lock payments'} onClick={async () => { try { const result = await updatePaymentLock(!locked); setLocked(result.locked); notify(result.locked ? 'Emergency payment lock activated.' : 'Outgoing demo payments unlocked.') } catch (e) { notify(e.message) } }}><span /></button></div><div className="settings-note"><ShieldCheck size={17} /><span>Lock status is shown in this interface only after the demo service confirms it. Payments are simulated.</span></div></aside></div></div>
}

function SettingRow({ icon: Icon, title, detail, onClick }) {
  return <button className="setting-row" onClick={onClick}><span className="setting-icon"><Icon size={18} /></span><span><b>{title}</b><small>{detail}</small></span><ArrowRight size={16} /></button>
}

function MobileNav() {
  const items = navigation.slice(0, 5)
  return <nav className="mobile-nav">{items.map(({ to, label, icon: Icon }) => <NavLink key={to} to={to} className={({ isActive }) => isActive ? 'active' : ''}><Icon size={19} /><span>{label === 'Overview' ? 'Home' : label === 'Scam Shield' ? 'Shield' : label}</span></NavLink>)}</nav>
}

function AppRoutes() {
  const [user, setUser] = useState(() => getStoredUser())
  const [authenticated, setAuthenticated] = useState(() => Boolean(getStoredToken() && getStoredUser()))
  const [balance, setBalance] = useState(() => {
    const u = getStoredUser()
    return u?.balance_in_paise ? u.balance_in_paise / 100 : 24580
  })
  const [transactions, setTransactions] = useState(initialTransactions)
  const [locked, setLocked] = useState(false)
  const [toast, setToast] = useState('')
  const navigate = useNavigate()

  useEffect(() => {
    async function verifyAuth() {
      if (getStoredToken()) {
        const freshUser = await getCurrentUser()
        if (freshUser) {
          setUser(freshUser)
          setAuthenticated(true)
          if (freshUser.balance_in_paise) {
            setBalance(freshUser.balance_in_paise / 100)
          }
        }
      }
    }
    verifyAuth()
  }, [])

  const handleAuthSuccess = (loggedUser) => {
    setUser(loggedUser)
    setAuthenticated(true)
    if (loggedUser?.balance_in_paise) {
      setBalance(loggedUser.balance_in_paise / 100)
    }
  }

  const logout = async () => {
    await logoutUser()
    setUser(null)
    setAuthenticated(false)
    navigate('/')
  }

  const app = {
    balance,
    transactions,
    locked,
    toast,
    setToast,
    setBalance,
    setTransactions,
    setLocked,
    onLogout: logout,
    user,
  }

  return (
    <Routes>
      <Route
        path="/"
        element={
          <Welcome
            onExplore={() => {
              navigate(authenticated ? '/app/dashboard' : '/login')
            }}
          />
        }
      />
      <Route
        path="/login"
        element={<AuthPage onAuthSuccess={handleAuthSuccess} />}
      />
      <Route
        path="/register"
        element={<AuthPage register onAuthSuccess={handleAuthSuccess} />}
      />
      <Route
        path="/app/*"
        element={authenticated ? <Shell app={app} /> : <Navigate to="/login" replace />}
      />
      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  )
}

export default function App() {
  return <BrowserRouter><AppRoutes /></BrowserRouter>
}
