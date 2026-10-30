export const demoRecipients = [
  { name: 'Ananya Sharma', upi: 'ananya.sharma@numpe', initials: 'AS', color: 'peach' },
  { name: 'Rohan Mehta', upi: 'rohan.mehta@numpe', initials: 'RM', color: 'blue' },
  { name: 'Isha Kapoor', upi: 'isha.k@numpe', initials: 'IK', color: 'violet' },
  { name: 'Prize Desk', upi: 'claim-reward@unknown', initials: 'PD', color: 'rose' },
]

export const initialTransactions = [
  { id: 'NP809241675', name: 'Ananya Sharma', upi: 'ananya.sharma@numpe', amount: 1250, direction: 'sent', status: 'Success', date: 'Today, 10:42 AM', risk: 'Low' },
  { id: 'NP809241312', name: 'Rohan Mehta', upi: 'rohan.mehta@numpe', amount: 3200, direction: 'received', status: 'Success', date: 'Today, 9:18 AM', risk: 'Low' },
  { id: 'NP809240872', name: 'Mira Cafe', upi: 'mira.cafe@numpe', amount: 480, direction: 'sent', status: 'Success', date: 'Yesterday, 7:36 PM', risk: 'Low' },
  { id: 'NP809239013', name: 'Devika Nair', upi: 'devika.nair@numpe', amount: 950, direction: 'received', status: 'Success', date: 'Yesterday, 2:05 PM', risk: 'Low' },
]

export const safetyLessons = [
  { icon: 'ScanLine', title: 'QR payment scams', text: 'Scanning a QR code to pay never means you need to enter your UPI PIN to receive money.' },
  { icon: 'MessageCircleWarning', title: 'Fake payment screenshots', text: 'Check your own transaction history. A screenshot or SMS can be edited or delayed.' },
  { icon: 'Link2', title: 'Phishing links', text: 'Avoid links in unexpected messages. Open your bank or payment app directly instead.' },
  { icon: 'ShieldAlert', title: 'OTP fraud', text: 'Never share your OTP, UPI PIN, or screen with someone claiming to help you.' },
  { icon: 'UserRoundX', title: 'Impersonation scams', text: 'Verify requests for money using a known phone number, not the number in the message.' },
  { icon: 'Clock3', title: 'Urgent payment requests', text: 'Scammers create pressure. Pause and confirm before you act.' },
]
