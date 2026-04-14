// API client module
const API = (() => {
  let config = null;

  async function loadConfig() {
    if (config) return config;
    const res = await fetch('/api/config');
    config = await res.json();
    return config;
  }

  function getToken() {
    return localStorage.getItem('token');
  }

  function setToken(token) {
    localStorage.setItem('token', token);
  }

  function clearToken() {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
  }

  function getUser() {
    const user = localStorage.getItem('user');
    return user ? JSON.parse(user) : null;
  }

  function setUser(user) {
    localStorage.setItem('user', JSON.stringify(user));
  }

  function isLoggedIn() {
    return !!getToken();
  }

  function authHeaders() {
    const token = getToken();
    const headers = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    return headers;
  }

  async function register(name, email, password) {
    const cfg = await loadConfig();
    const res = await fetch(`${cfg.authServiceUrl}/api/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name, email, password })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Registration failed');
    setToken(data.token);
    setUser(data.user);
    return data;
  }

  async function login(email, password) {
    const cfg = await loadConfig();
    const res = await fetch(`${cfg.authServiceUrl}/api/auth/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Login failed');
    setToken(data.token);
    setUser(data.user);
    return data;
  }

  function logout() {
    clearToken();
  }

  async function getProducts() {
    const cfg = await loadConfig();
    const res = await fetch(`${cfg.productServiceUrl}/api/products`);
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to fetch products');
    return data.products;
  }

  async function getProduct(id) {
    const cfg = await loadConfig();
    const res = await fetch(`${cfg.productServiceUrl}/api/products/${id}`);
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to fetch product');
    return data.product;
  }

  async function createProduct(product) {
    const cfg = await loadConfig();
    const res = await fetch(`${cfg.productServiceUrl}/api/products`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify(product)
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to create product');
    return data.product;
  }

  async function createOrder(items) {
    const cfg = await loadConfig();
    const res = await fetch(`${cfg.orderServiceUrl}/api/orders`, {
      method: 'POST',
      headers: authHeaders(),
      body: JSON.stringify({ items })
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to create order');
    return data.order;
  }

  async function getOrders() {
    const cfg = await loadConfig();
    const res = await fetch(`${cfg.orderServiceUrl}/api/orders`, {
      headers: authHeaders()
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Failed to fetch orders');
    return data.orders;
  }

  return {
    loadConfig, getToken, getUser, isLoggedIn,
    register, login, logout,
    getProducts, getProduct, createProduct,
    createOrder, getOrders
  };
})();
