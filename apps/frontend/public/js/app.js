// App initialization and UI logic
const App = (() => {
  // Simple cart in memory
  let cart = [];

  function showToast(message, type = 'success') {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const id = 'toast-' + Date.now();
    const bgClass = type === 'error' ? 'bg-danger' : type === 'warning' ? 'bg-warning text-dark' : 'bg-success';
    container.innerHTML += `
      <div id="${id}" class="toast align-items-center text-white ${bgClass} border-0" role="alert">
        <div class="d-flex">
          <div class="toast-body">${message}</div>
          <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
      </div>`;
    const el = document.getElementById(id);
    const toast = new bootstrap.Toast(el, { delay: 3000 });
    toast.show();
    el.addEventListener('hidden.bs.toast', () => el.remove());
  }

  function updateNav() {
    const loggedIn = API.isLoggedIn();
    const user = API.getUser();

    document.querySelectorAll('.nav-logged-in').forEach(el => {
      el.style.display = loggedIn ? '' : 'none';
    });
    document.querySelectorAll('.nav-logged-out').forEach(el => {
      el.style.display = loggedIn ? 'none' : '';
    });

    const nameEl = document.getElementById('nav-user-name');
    if (nameEl && user) nameEl.textContent = user.name;

    const cartBadge = document.getElementById('cart-count');
    if (cartBadge) cartBadge.textContent = cart.length;
  }

  function addToCart(productId, productName, price) {
    const existing = cart.find(i => i.product_id === productId);
    if (existing) {
      existing.quantity++;
    } else {
      cart.push({ product_id: productId, product_name: productName, price, quantity: 1 });
    }
    updateNav();
    showToast(`${productName} added to cart`);
  }

  function getCart() {
    return cart;
  }

  function clearCart() {
    cart = [];
    updateNav();
  }

  // ---- Page renderers ----

  async function renderProducts(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    container.innerHTML = '<div class="text-center py-5"><div class="spinner-border" role="status"></div></div>';

    try {
      const products = await API.getProducts();
      if (products.length === 0) {
        container.innerHTML = '<div class="text-center py-5"><p class="text-muted">No products available yet.</p></div>';
        return;
      }

      container.innerHTML = products.map(p => `
        <div class="col-md-4 col-sm-6 mb-4">
          <div class="card product-card h-100 shadow-sm">
            <div class="product-img-placeholder">
              <i class="bi bi-box-seam"></i>
            </div>
            <div class="card-body d-flex flex-column">
              <h5 class="card-title">${escapeHtml(p.name)}</h5>
              <p class="card-text text-muted flex-grow-1">${escapeHtml(p.description || 'No description')}</p>
              <div class="d-flex justify-content-between align-items-center mt-2">
                <span class="h5 mb-0 text-primary">$${parseFloat(p.price).toFixed(2)}</span>
                <span class="badge bg-secondary">${p.stock} in stock</span>
              </div>
              <button class="btn btn-primary mt-3 btn-add-cart"
                data-id="${p.id}" data-name="${escapeHtml(p.name)}" data-price="${p.price}"
                ${p.stock <= 0 ? 'disabled' : ''}>
                ${p.stock <= 0 ? 'Out of Stock' : '<i class="bi bi-cart-plus"></i> Add to Cart'}
              </button>
            </div>
          </div>
        </div>
      `).join('');

      container.querySelectorAll('.btn-add-cart').forEach(btn => {
        btn.addEventListener('click', () => {
          if (!API.isLoggedIn()) {
            showToast('Please log in to add items to cart', 'warning');
            return;
          }
          addToCart(btn.dataset.id, btn.dataset.name, parseFloat(btn.dataset.price));
        });
      });
    } catch (err) {
      container.innerHTML = `<div class="alert alert-danger">Failed to load products: ${escapeHtml(err.message)}</div>`;
    }
  }

  async function renderOrders(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (!API.isLoggedIn()) {
      container.innerHTML = '<div class="alert alert-warning">Please log in to view your orders.</div>';
      return;
    }

    container.innerHTML = '<div class="text-center py-5"><div class="spinner-border" role="status"></div></div>';

    try {
      const orders = await API.getOrders();
      if (orders.length === 0) {
        container.innerHTML = '<div class="text-center py-5"><p class="text-muted">No orders yet.</p></div>';
        return;
      }

      container.innerHTML = `
        <div class="table-responsive">
          <table class="table table-hover">
            <thead class="table-dark">
              <tr>
                <th>Order ID</th>
                <th>Date</th>
                <th>Total</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              ${orders.map(o => `
                <tr>
                  <td><code>${o.id.slice(0, 8)}...</code></td>
                  <td>${new Date(o.created_at).toLocaleDateString()}</td>
                  <td>$${parseFloat(o.total_amount).toFixed(2)}</td>
                  <td><span class="badge badge-status-${o.status}">${o.status}</span></td>
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>`;
    } catch (err) {
      container.innerHTML = `<div class="alert alert-danger">Failed to load orders: ${escapeHtml(err.message)}</div>`;
    }
  }

  function renderCart(containerId) {
    const container = document.getElementById(containerId);
    if (!container) return;

    if (cart.length === 0) {
      container.innerHTML = '<div class="text-center py-4"><p class="text-muted">Your cart is empty.</p></div>';
      return;
    }

    const total = cart.reduce((sum, i) => sum + i.price * i.quantity, 0);

    container.innerHTML = `
      <div class="table-responsive">
        <table class="table">
          <thead><tr><th>Product</th><th>Price</th><th>Qty</th><th>Subtotal</th><th></th></tr></thead>
          <tbody>
            ${cart.map((item, idx) => `
              <tr>
                <td>${escapeHtml(item.product_name)}</td>
                <td>$${item.price.toFixed(2)}</td>
                <td>${item.quantity}</td>
                <td>$${(item.price * item.quantity).toFixed(2)}</td>
                <td><button class="btn btn-sm btn-outline-danger btn-remove-cart" data-idx="${idx}"><i class="bi bi-trash"></i></button></td>
              </tr>
            `).join('')}
          </tbody>
          <tfoot>
            <tr><td colspan="3" class="text-end fw-bold">Total:</td><td class="fw-bold">$${total.toFixed(2)}</td><td></td></tr>
          </tfoot>
        </table>
      </div>
      <div class="text-end">
        <button id="btn-checkout" class="btn btn-success btn-lg"><i class="bi bi-credit-card"></i> Checkout</button>
      </div>`;

    container.querySelectorAll('.btn-remove-cart').forEach(btn => {
      btn.addEventListener('click', () => {
        cart.splice(parseInt(btn.dataset.idx), 1);
        renderCart(containerId);
        updateNav();
      });
    });

    document.getElementById('btn-checkout')?.addEventListener('click', async () => {
      try {
        const items = cart.map(i => ({ product_id: i.product_id, quantity: i.quantity }));
        const order = await API.createOrder(items);
        clearCart();
        showToast(`Order placed! Status: ${order.status}`);
        renderCart(containerId);
      } catch (err) {
        showToast(err.message, 'error');
      }
    });
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  function init() {
    updateNav();

    // Login form
    document.getElementById('login-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const email = document.getElementById('login-email').value;
      const password = document.getElementById('login-password').value;
      try {
        await API.login(email, password);
        showToast('Login successful!');
        updateNav();
        const modal = bootstrap.Modal.getInstance(document.getElementById('authModal'));
        modal?.hide();
        if (typeof onAuthChange === 'function') onAuthChange();
      } catch (err) {
        showToast(err.message, 'error');
      }
    });

    // Register form
    document.getElementById('register-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = document.getElementById('register-name').value;
      const email = document.getElementById('register-email').value;
      const password = document.getElementById('register-password').value;
      try {
        await API.register(name, email, password);
        showToast('Registration successful!');
        updateNav();
        const modal = bootstrap.Modal.getInstance(document.getElementById('authModal'));
        modal?.hide();
        if (typeof onAuthChange === 'function') onAuthChange();
      } catch (err) {
        showToast(err.message, 'error');
      }
    });

    // Logout
    document.getElementById('btn-logout')?.addEventListener('click', () => {
      API.logout();
      updateNav();
      showToast('Logged out');
      if (typeof onAuthChange === 'function') onAuthChange();
    });
  }

  return { init, renderProducts, renderOrders, renderCart, showToast, updateNav, addToCart, getCart, clearCart };
})();

document.addEventListener('DOMContentLoaded', () => App.init());
