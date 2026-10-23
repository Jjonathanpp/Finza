// features/step_definitions/cambio_contrasena.steps.js
const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('node:assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';
const REGISTRO_PATH = process.env.REGISTRO_PATH || '/api/auth/registro'; // AJUSTAR
const LOGIN_PATH = process.env.LOGIN_PATH || '/api/auth/login';          // AJUSTAR

// Reemplazar la función armarDatosUsuario en features/step_definitions/cambio_contrasena.steps.js
let contador = 0;

// DNI y email no se pueden duplicar, así que se generan únicos en cada escenario
function armarDatosUsuario(password) {
  contador += 1;
  const unico = `${Date.now()}${contador}`;      // distinto por escenario y por ejecución
  const dni = unico.slice(-8);                   // 8 dígitos, como el de tu ejemplo
  const telefono = `28${unico.slice(-7)}`;       // 9 dígitos, mismo largo que tu ejemplo

  return {
    email: `test_${unico}@test.com`,
    password,
    usuario: {
      nombre: 'Test',
      apellido: 'Cucumber',
      dni,
      telefono,
      fechaNacimiento: '2000-01-01',
      genero: 'MASCULINO',
    },
  };
}

async function postJson(ruta, body, token) {
  const headers = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  return fetch(`${BACKEND_URL}${ruta}`, {
    method: 'POST',
    headers,
    body: typeof body === 'string' ? body : JSON.stringify(body),
  });
}

async function iniciarSesion(email, password) {
  return postJson(LOGIN_PATH, { email, password });
}

// Dado: crea el usuario, hace login y guarda el JWT en el contexto del escenario
Given(
  'que hay un usuario registrado y autenticado con la contraseña {string}',
  async function (password) {
    const datos = armarDatosUsuario(password);

    const registro = await postJson(REGISTRO_PATH, datos);
    assert.ok(
      registro.status === 200 || registro.status === 201,
      `Registro falló (status ${registro.status}): ${await registro.text()}`
    );

    const login = await iniciarSesion(datos.email, password);
    assert.strictEqual(login.status, 200, `Login falló (status ${login.status})`);

    const json = await login.json();
    this.token = json.data?.token ?? json.token;
    assert.ok(this.token, 'El login no devolvió un token');
    this.email = datos.email;
  }
);

When(
  'envío una petición POST a {string} con el body:',
  async function (ruta, docString) {
    this.response = await postJson(ruta, docString, this.token);
    this.body = await this.response.json();
  }
);

Then('recibo una respuesta con código {int}', function (codigo) {
  assert.strictEqual(this.response.status, codigo);
});

Then('el body tiene los campos status, message y data', function () {
  assert.ok('status' in this.body, 'Falta el campo status');
  assert.ok('message' in this.body, 'Falta el campo message');
  assert.ok('data' in this.body, 'Falta el campo data');
});

Then('el campo status es {int}', function (status) {
  assert.strictEqual(this.body.status, status);
});

Then('el mensaje indica que la contraseña ha sido cambiada exitosamente', function () {
  assert.match(this.body.message, /contraseña.*cambiada.*exitosamente/i);
});

Then('el mensaje indica que la contraseña actual es incorrecta', function () {
  assert.match(this.body.message, /contraseña actual.*incorrecta/i);
});

// El error de validación viene en data: { nuevaContrasena: "..." }
Then('el detalle indica que la contraseña debe tener al menos 8 caracteres', function () {
  assert.match(JSON.stringify(this.body.data), /al menos 8 caracteres/i);
});

Then('puedo iniciar sesión con la contraseña {string}', async function (password) {
  const res = await iniciarSesion(this.email, password);
  assert.strictEqual(res.status, 200, `Se esperaba login exitoso (status ${res.status})`);
});

Then('no puedo iniciar sesión con la contraseña {string}', async function (password) {
  const res = await iniciarSesion(this.email, password);
  assert.strictEqual(res.status, 401, `Se esperaba 401 (status ${res.status})`);
});