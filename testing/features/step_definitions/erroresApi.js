const { Given, When } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';
const PASSWORD = 'Password123!';

let contador = 0;

async function registrarCuenta() {
  const unico = `${Date.now()}${contador++}`;
  const email = `errores.${unico}@test.com`;
  const response = await fetch(`${BACKEND_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password: PASSWORD,
      usuario: { nombre: 'Test', apellido: 'Errores', dni: Number(unico.slice(-9)) }
    })
  });
  assert.strictEqual(response.status, 201, `No se pudo registrar la cuenta de prueba (status ${response.status})`);
  return { id: (await response.json()).id, email };
}

// El login todavía no existe (t-1.4.1). Se asume que responde con el formato común y el token en data.token.
Given('que inicié sesión con una cuenta nueva', async function () {
  const cuenta = await registrarCuenta();
  const response = await fetch(`${BACKEND_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email: cuenta.email, password: PASSWORD })
  });
  const body = await response.json().catch(() => ({}));
  assert.strictEqual(response.status, 200, `No se pudo iniciar sesión (status ${response.status}): ${JSON.stringify(body)}`);
  this.token = body.data.token;
});

Given('existe otra cuenta registrada', async function () {
  this.otraCuentaId = (await registrarCuenta()).id;
});

When('pido las categorías de la otra cuenta con mi token', async function () {
  this.response = await fetch(`${BACKEND_URL}/api/categorias?cuentaId=${this.otraCuentaId}`, {
    headers: { 'Authorization': `Bearer ${this.token}` }
  });
  this.body = await this.response.json().catch(() => ({}));
});
