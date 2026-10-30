# NUMPE — Smart Payments. Safer Transactions.

NUMPE is a responsive UPI-style frontend prototype with an integrated Scam Shield experience. All balances, identities, QR payloads, and payment activity are simulated; this project does not connect to a bank or move real money.

## Run locally

```sh
npm install
npm run dev
```

Build the static production bundle with `npm run build`. Run `npm run lint` to check the source.

## Demo journeys

- Choose **Explore the demo** on the welcome screen to open the wallet without signing in.
- Use **Send** and select a recent demo recipient. `claim-reward@unknown` is a prepared high-risk recipient; the simulated transfer is blocked after review.
- Use the **QR inspector** to try a sample UPI payload or paste your own `upi://pay` payload. Inspection never initiates a payment.
- In **Scam Shield**, analyze an example message, link, or UPI ID. Results are illustrative safety signals, not proof of fraud.
- Submit a demo report and try the **Emergency Payment Lock** in the overview or Settings.
- Demo sign-in and registration are UI-only; entered passwords are not stored.

## API adapter

`src/services/api.js` is the centralized integration boundary. The mock adapter is enabled by default. To use a backend, set:

```env
VITE_USE_MOCK_API=false
VITE_API_BASE_URL=http://localhost:8000
```

The adapter currently prepares requests for `/api/analyze`, `/api/payments/send`, `/api/reports`, and `/api/security/{lock,unlock}`. Update the adapter and its response handling to match the backend team's finalized contract. Authentication and other backend endpoints are not connected in this prototype.

## Technology

React, Vite, React Router, Framer Motion, Lucide React, and custom responsive CSS.
