const { Given, When, Then } = require('@cucumber/cucumber');

const BASE_URL = process.env.BASE_URL || 'https://finza-backend-9c6t.onrender.com';

let invitadoToken = '';
let cuentaCompartidaId = '';
let invitacionToken = '';
let lastResponse = null;
let invitadoEmail = '';

async function register(email, password, nombre, apellido, dni, telefono) {
  const res = await fetch(`${BASE_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      usuario: { nombre, apellido, dni, telefono, fechaNacimiento: '1990-01-01', genero: 'OTRO' }
    })
  });
  return res;
}

async function login(email, password) {
  const res = await fetch(`${BASE_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  return res;
}

Given('existe un usuario registrado con email único para invitación', async function () {
  const ts = Date.now();
  invitadoEmail = `inv${ts}@ejemplo.com`;
  const dni = String(Math.floor(Math.random() * 90000000) + 10000000);
  const telefono = '11' + String(Math.floor(Math.random() * 9000000000 + 1000000000));

  const res = await register(invitadoEmail, 'Test1234!', 'Invitado', 'Test', dni, telefono);
  if (res.status !== 200 && res.status !== 201 && res.status !== 400) {
    throw new Error(`Registro falló con ${res.status}`);
  }
});

Given('existe una cuenta compartida llamada {string}', async function (nombre) {
  const loginRes = await login(invitadoEmail, 'Test1234!');
  const loginData = await loginRes.json();
  const token = loginData.token || loginData.accessToken || loginData.data?.token;
  invitadoToken = token;

  if (!token) {
    throw new Error(`Login no devolvió token. Respuesta: ${JSON.stringify(loginData)}`);
  }

  const ccRes = await fetch(`${BASE_URL}/api/cuentas-compartidas`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({ nombre })
  });
  if (!ccRes.ok) {
    const body = await ccRes.text();
    throw new Error(`No se pudo crear cuenta compartida: ${ccRes.status} ${body}`);
  }
  const ccData = await ccRes.json();
  cuentaCompartidaId = ccData.data || ccData.id;
});

Given('existe una invitación pendiente para el email del usuario en la cuenta compartida {string}', async function (nombreCC) {
  const invRes = await fetch(`${BASE_URL}/api/cuentas-compartidas/${cuentaCompartidaId}/invitaciones`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${invitadoToken}` },
    body: JSON.stringify({ email: invitadoEmail })
  });
  if (!invRes.ok) {
    const body = await invRes.text();
    throw new Error(`No se pudo crear invitación: ${invRes.status} ${body}`);
  }
  const invData = await invRes.json();
  invitacionToken = invData.token;
});

When('el usuario acepta la invitación enviando su token en el body', async function () {
  lastResponse = await fetch(`${BASE_URL}/api/cuentas-compartidas/invitaciones/aceptar`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${invitadoToken}` },
    body: JSON.stringify(invitacionToken)
  });
});

When('envío una petición POST a {string} con token {string}', async function (endpoint, token) {
  lastResponse = await fetch(`${BASE_URL}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(token)
  });
});

Then('recibo una respuesta de invitación con código {int}', async function (codigo) {
  const actual = lastResponse.status;
  if (actual !== codigo) {
    throw new Error(`Esperaba ${codigo} pero recibí ${actual}`);
  }
});

Then('el usuario es miembro de la cuenta compartida {string}', async function (nombreCC) {
  const res = await fetch(`${BASE_URL}/api/cuentas-compartidas`, {
    method: 'GET',
    headers: { 'Authorization': `Bearer ${invitadoToken}` }
  });
  if (!res.ok) {
    throw new Error(`No se pudo listar cuentas compartidas: ${res.status}`);
  }
  const data = await res.json();
  const cuentas = data.data || data;
  const encontrado = cuentas.some(c => c.nombre === nombreCC);
  if (!encontrado) {
    throw new Error(`El usuario no es miembro de la cuenta compartida "${nombreCC}"`);
  }
});