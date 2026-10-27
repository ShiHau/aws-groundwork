const form = document.querySelector("#ticket-form");
const submitButton = document.querySelector("#submit-button");
const readButton = document.querySelector("#read-button");
const statusMessage = document.querySelector("#status");
const ticketsContainer = document.querySelector("#tickets");

function getApiBaseUrl() {
  const configuredUrl = window.GROUNDWORK_CONFIG?.apiBaseUrl?.trim();
  if (!configuredUrl) {
    throw new Error("Set apiBaseUrl in config.js to your API Gateway URL.");
  }

  return configuredUrl.replace(/\/+$/, "");
}

async function requestJson(path, options) {
  const response = await fetch(`${getApiBaseUrl()}${path}`, options);
  const responseText = await response.text();
  let payload;

  try {
    payload = responseText ? JSON.parse(responseText) : {};
  } catch {
    throw new Error(`The API returned an unreadable response (HTTP ${response.status}).`);
  }

  if (!response.ok) {
    throw new Error(payload.error || `The API request failed (HTTP ${response.status}).`);
  }

  return payload;
}

function setBusy(isBusy) {
  submitButton.disabled = isBusy;
  readButton.disabled = isBusy;
}

function showStatus(message, kind = "info") {
  statusMessage.textContent = message;
  statusMessage.dataset.kind = kind;
}

function renderTickets(tickets) {
  ticketsContainer.replaceChildren();

  if (tickets.length === 0) {
    const emptyState = document.createElement("p");
    emptyState.className = "empty-state";
    emptyState.textContent = "No tickets found.";
    ticketsContainer.append(emptyState);
    return;
  }

  for (const ticket of tickets) {
    const card = document.createElement("article");
    card.className = "ticket";

    const header = document.createElement("div");
    header.className = "ticket-header";

    const email = document.createElement("strong");
    email.textContent = ticket.email || "Email unavailable";

    const createdAt = document.createElement("time");
    createdAt.textContent = ticket.created_at
      ? new Date(ticket.created_at).toLocaleString()
      : "";
    if (ticket.created_at) {
      createdAt.dateTime = ticket.created_at;
    }

    const message = document.createElement("p");
    message.className = "ticket-message";
    message.textContent = ticket.message || "";

    header.append(email, createdAt);
    card.append(header, message);
    ticketsContainer.append(card);
  }
}

form.addEventListener("submit", async (event) => {
  event.preventDefault();
  setBusy(true);
  showStatus("");

  const formData = new FormData(form);
  const ticket = {
    email: formData.get("email").trim(),
    message: formData.get("message").trim(),
  };

  try {
    const result = await requestJson("/ticket", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(ticket),
    });
    form.reset();
    showStatus(result.message || "Ticket submitted.");
  } catch (error) {
    showStatus(error.message, "error");
  } finally {
    setBusy(false);
  }
});

readButton.addEventListener("click", async () => {
  setBusy(true);
  showStatus("");

  try {
    const result = await requestJson("/ticket");
    renderTickets(result.tickets || []);
    showStatus(`Loaded ${result.tickets?.length || 0} ticket(s).`);
  } catch (error) {
    showStatus(error.message, "error");
  } finally {
    setBusy(false);
  }
});
