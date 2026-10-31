(() => {
  const form = document.querySelector("#payment-demo-form");
  const recipientInput = document.querySelector("#demo-recipient");
  const amountInput = document.querySelector("#demo-amount");
  const noteInput = document.querySelector("#demo-note");
  const result = document.querySelector("#payment-demo-result");
  const dialog = document.querySelector("#risk-dialog");
  const reasonsList = document.querySelector("#risk-dialog-reasons");

  if (!(form instanceof HTMLFormElement) ||
      !(recipientInput instanceof HTMLInputElement) ||
      !(amountInput instanceof HTMLInputElement) ||
      !(noteInput instanceof HTMLInputElement) ||
      !(result instanceof HTMLElement) ||
      !(dialog instanceof HTMLDialogElement) ||
      !(reasonsList instanceof HTMLUListElement)) return;

  const LARGE_AMOUNT_THRESHOLD = 10000;
  const suspiciousTerms = [
    { term: "cashback", pattern: /\bcashback\b/i },
    { term: "lottery", pattern: /\blottery\b/i },
    { term: "refund", pattern: /\brefund\b/i },
    { term: "KYC", pattern: /\bkyc\b/i },
  ];

  dialog.addEventListener("keydown", (event) => {
    if (event.key === "Escape" && dialog.open) {
      event.preventDefault();
      dialog.close();
    }
  });

  const clearResult = () => {
    result.hidden = true;
    result.textContent = "";
  };

  [recipientInput, amountInput, noteInput].forEach((input) => {
    input.addEventListener("input", clearResult);
  });

  form.addEventListener("submit", (event) => {
    event.preventDefault();
    clearResult();

    if (!form.reportValidity()) return;

    const recipient = recipientInput.value.trim();
    const note = noteInput.value.trim();
    const amount = Number(amountInput.value);
    const reasons = [];

    if (!recipient) {
      recipientInput.setCustomValidity("Enter a demo recipient UPI ID or phone number.");
      recipientInput.reportValidity();
      recipientInput.setCustomValidity("");
      return;
    }

    if (!Number.isFinite(amount) || amount <= 0) return;

    const paymentDetails = `${recipient}\n${note}`;
    suspiciousTerms.forEach(({ term, pattern }) => {
      if (pattern.test(paymentDetails)) {
        reasons.push(`The recipient or note contains "${term}", a term commonly used in unsolicited payment requests.`);
      }
    });

    if (amount >= LARGE_AMOUNT_THRESHOLD) {
      const formattedAmount = new Intl.NumberFormat("en-IN", {
        style: "currency",
        currency: "INR",
        maximumFractionDigits: 2,
      }).format(amount);
      reasons.push(`The amount is ${formattedAmount}; this demo flags amounts of ₹${LARGE_AMOUNT_THRESHOLD.toLocaleString("en-IN")} or more for an extra review.`);
    }

    if (reasons.length > 0) {
      reasonsList.replaceChildren(...reasons.map((reason) => {
        const item = document.createElement("li");
        item.textContent = reason;
        return item;
      }));

      if (typeof dialog.showModal === "function") {
        dialog.showModal();
      } else {
        result.textContent = `Pause and verify: ${reasons.join(" ")} This is a simulation; no money was transferred.`;
        result.hidden = false;
      }
      return;
    }

    const formattedAmount = new Intl.NumberFormat("en-IN", {
      style: "currency",
      currency: "INR",
      maximumFractionDigits: 2,
    }).format(amount);
    result.textContent = `No demo warning signals found for ${formattedAmount}. Simulation only—no money was transferred.`;
    result.hidden = false;
  });
})();
