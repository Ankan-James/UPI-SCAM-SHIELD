const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000'
export const MOCK_MODE = import.meta.env.VITE_USE_MOCK_API === 'true'

const TOKEN_KEY = 'numpe_auth_token'
const USER_KEY = 'numpe_auth_user'

export function getStoredToken() {
  return localStorage.getItem(TOKEN_KEY) || sessionStorage.getItem(TOKEN_KEY) || ''
}

export function getStoredUser() {
  try {
    const raw = localStorage.getItem(USER_KEY) || sessionStorage.getItem(USER_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export function saveSession(token, user, remember = true) {
  const storage = remember ? localStorage : sessionStorage
  storage.setItem(TOKEN_KEY, token)
  storage.setItem(USER_KEY, JSON.stringify(user))
}

export function clearSession() {
  localStorage.removeItem(TOKEN_KEY)
  localStorage.removeItem(USER_KEY)
  sessionStorage.removeItem(TOKEN_KEY)
  sessionStorage.removeItem(USER_KEY)
}

async function request(path, options = {}) {
  const token = getStoredToken()
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  }

  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers,
  })

  let data
  const contentType = response.headers.get('content-type') || ''
  if (contentType.includes('application/json')) {
    data = await response.json()
  } else {
    data = await response.text()
  }

  if (!response.ok) {
    const detail =
      (data && typeof data === 'object' && (data.detail || data.message)) ||
      (typeof data === 'string' ? data : null) ||
      `Request failed (${response.status})`
    const errorText = Array.isArray(detail) ? detail.map((d) => d.msg || d).join(', ') : detail
    throw new Error(errorText)
  }

  return response.status === 204 ? null : data
}

const demoDelay = () => new Promise((resolve) => setTimeout(resolve, 450))

export async function registerUser({ name, email, password }) {
  const result = await request('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify({ name, email, password }),
  })
  return result.user
}

export async function loginUser({ email, password, remember = true }) {
  const result = await request('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  })
  if (result.token && result.user) {
    saveSession(result.token, result.user, remember)
  }
  return result
}

export async function getCurrentUser() {
  const token = getStoredToken()
  if (!token) return null
  try {
    const result = await request('/api/auth/me')
    if (result.user) {
      saveSession(token, result.user)
      return result.user
    }
  } catch {
    clearSession()
  }
  return null
}

export async function logoutUser() {
  try {
    await request('/api/auth/logout', { method: 'POST' })
  } catch {
    // Ignore network error during logout
  } finally {
    clearSession()
  }
}

export async function analyzeRecipient(recipient) {
  if (!MOCK_MODE) {
    return request('/api/analyze', {
      method: 'POST',
      body: JSON.stringify({ type: 'upi_id', input: recipient }),
    })
  }

  await demoDelay()
  const suspicious = /claim|prize|refund|verify|unknown|urgent/i.test(recipient)
  return {
    score: suspicious ? 87 : 12,
    level: suspicious ? 'High' : 'Low',
    indicators: suspicious
      ? ['Unverified recipient', 'Urgency or reward language', 'Recipient is not in your saved contacts']
      : ['No common warning signs detected', 'Recipient format looks valid'],
    recommendation: suspicious
      ? 'Pause and verify this recipient independently before proceeding.'
      : 'Check the recipient name and amount before confirming.',
    illustrative: true,
  }
}

export async function sendPayment(payload) {
  if (!MOCK_MODE) {
    return request('/api/payments/send', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  }

  await demoDelay()
  return { id: `NP${Date.now().toString().slice(-9)}`, status: 'success' }
}

export async function analyzeItem(type, input) {
  if (!MOCK_MODE) {
    return request('/api/analyze', { method: 'POST', body: JSON.stringify({ type, input }) })
  }

  await demoDelay()
  const suspicious = /urgent|otp|password|claim|prize|click here|verify|refund/i.test(input)
  return {
    score: suspicious ? 87 : 18,
    level: suspicious ? 'High' : 'Low',
    indicators: suspicious
      ? ['Urgency or pressure language', 'Requests sensitive information or action', 'Source could not be verified']
      : ['No obvious pressure language detected', 'Always verify the sender independently'],
    recommendation: suspicious
      ? 'Pause. Do not share an OTP or open unexpected links. Verify through an official channel.'
      : 'No obvious warning signs were detected. Stay cautious and verify independently.',
    illustrative: true,
  }
}

export async function submitReport(payload) {
  if (!MOCK_MODE) {
    return request('/api/reports', { method: 'POST', body: JSON.stringify(payload) })
  }

  await demoDelay()
  return { id: `RPT-${Date.now().toString().slice(-6)}`, status: 'Pending Review' }
}

export async function updatePaymentLock(locked) {
  if (!MOCK_MODE) {
    return request(`/api/security/${locked ? 'lock' : 'unlock'}`, { method: 'POST' })
  }

  await demoDelay()
  return { locked }
}
