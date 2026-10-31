const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? ''
export const MOCK_MODE = import.meta.env.VITE_USE_MOCK_API !== 'false'

async function request(path, options = {}) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options.headers,
    },
  })

  if (!response.ok) {
    const message = await response.text()
    throw new Error(message || `Request failed (${response.status})`)
  }

  return response.status === 204 ? null : response.json()
}

const demoDelay = () => new Promise((resolve) => setTimeout(resolve, 450))

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
