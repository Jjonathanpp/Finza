const { Given, When, Then } = require('@cucumber/cucumber');

const BASE_URL = process.env.BASE_URL || 'http://app:8080';

Given('existe un usuario con email {string} y contraseña {string}', async function (email, password) {
  const res = await fetch(`${BASE_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      usuario: {
        nombre: 'Prueba',
        apellido: 'Login',
        dni: '12345678',
        telefono: '1122334455',
        fechaNacimiento: '2000-01-01',
        genero: 'MASCULINO'
      }
    })
  });
  if (!res.ok) {
    console.warn(`Registro previo respondió ${res.status} (puede que el usuario ya exista)`);
  }
});

When('envío una petición POST a {string} con email {string} y contraseña {string}',
  async function (endpoint, email, password) {
    this.response = await fetch(`${BASE_URL}${endpoint}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email, password })
    });
  });
