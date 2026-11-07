const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';
const URL_CONSOLIDADO = `${BACKEND_URL}/api/movimientos/consolidado`;

let contador = 0;

async function leerJson(res) {
  try { return await res.json(); } catch { return null; }
}

function headers(token, perfilId) {
  const h = { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` };
  // Con X-Perfil-Id el backend trabaja sobre ese perfil (por ejemplo, el de una cuenta compartida).
  if (perfilId) h['X-Perfil-Id'] = String(perfilId);
  return h;
}

// Cuenta nueva por escenario: el test se puede repetir sin limpiar la base.
async function crearCuenta(prefijo) {
  const unico = `${Date.now()}${contador++}`;
  const email = `${prefijo}.${unico}@test.com`;
  const password = 'Password123!';

  const registro = await fetch(`${BACKEND_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      usuario: { nombre: 'Test', apellido: 'Consolidado', dni: Number(unico.slice(-9)) }
    })
  });
  const jsonRegistro = await leerJson(registro);
  assert.strictEqual(registro.status, 201, `No se pudo registrar la cuenta de prueba: ${JSON.stringify(jsonRegistro)}`);

  const login = await fetch(`${BACKEND_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  assert.strictEqual(login.status, 200, `No se pudo loguear la cuenta de prueba (status ${login.status})`);

  return {
    token: (await leerJson(login)).data.token,
    cuentaId: jsonRegistro?.data?.id ?? jsonRegistro?.id
  };
}

async function registrarMovimientos(token, perfilId, filas) {
  const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
    method: 'POST',
    headers: headers(token, perfilId),
    body: JSON.stringify({ movimientos: filas })
  });
  const json = await leerJson(response);
  assert.strictEqual(response.status, 201, `No se pudieron precargar los movimientos: ${JSON.stringify(json)}`);
}

async function consultar(world, query = '', perfilId = null) {
  world.respuesta = await fetch(`${URL_CONSOLIDADO}${query ? `?${query}` : ''}`, {
    headers: headers(world.token, perfilId)
  });
  world.json = await leerJson(world.respuesta);
}

// La página de Spring viene en "data". Según la versión, el total está en la raíz
// de la página o dentro de "page" (serialización VIA_DTO): se aceptan las dos.
function pagina(world) {
  assert.ok(world.json && world.json.data, `La respuesta no trae la página en "data": ${JSON.stringify(world.json)}`);
  return world.json.data;
}
const contenido = (world) => pagina(world).content;
const totalElementos = (world) => pagina(world).totalElements ?? pagina(world).page?.totalElements;
const totalPaginas = (world) => pagina(world).totalPages ?? pagina(world).page?.totalPages;

function buscarPorDescripcion(world, descripcion) {
  return contenido(world).find((m) => m.descripcion === descripcion);
}

// ---------- Antecedentes ----------

Given('que tengo una cuenta nueva para probar el consolidado', async function () {
  const cuenta = await crearCuenta('consolidado');
  this.token = cuenta.token;
  this.cuentaId = cuenta.cuentaId;
  this.compartidas = {};
});

Given('que creé la cuenta compartida {string}', async function (nombre) {
  const response = await fetch(`${BACKEND_URL}/api/cuentas-compartidas`, {
    method: 'POST',
    headers: headers(this.token),
    body: JSON.stringify({ nombre })
  });
  const json = await leerJson(response);
  assert.strictEqual(response.status, 201, `No se pudo crear la cuenta compartida: ${JSON.stringify(json)}`);
  // Al crearla, el backend me da un perfil ADMIN en ella.
  this.compartidas[nombre] = { id: json.data.id, perfilId: json.data.perfilId };
});

// ---------- Given ----------

Given('que registré en mi perfil personal los movimientos:', async function (dataTable) {
  await registrarMovimientos(this.token, null, dataTable.hashes());
});

Given('que registré en la cuenta compartida {string} los movimientos:', async function (nombre, dataTable) {
  const compartida = this.compartidas[nombre];
  assert.ok(compartida, `La cuenta compartida "${nombre}" no fue creada en los Antecedentes`);
  await registrarMovimientos(this.token, compartida.perfilId, dataTable.hashes());
});

Given('que otro usuario registró el movimiento {string} en su perfil personal', async function (descripcion) {
  this.otro = await crearCuenta('consolidado.otro');
  await registrarMovimientos(this.otro.token, null, [
    { tipo: 'egreso', monto: '999', categoria: 'Comida', descripcion, fecha: '03-11-2026' }
  ]);
});

// ---------- When ----------

When('consulto mis movimientos consolidados', async function () {
  await consultar(this);
});

When('consulto mis movimientos consolidados con {string}', async function (query) {
  await consultar(this, query);
});

When('consulto mis movimientos consolidados indicando la cuenta del otro usuario en la URL', async function () {
  await consultar(this, `cuentaId=${this.otro.cuentaId}`);
});

When('consulto mis movimientos consolidados parado en la cuenta compartida {string}', async function (nombre) {
  await consultar(this, '', this.compartidas[nombre].perfilId);
});

When('consulto los movimientos consolidados sin token', async function () {
  this.respuesta = await fetch(URL_CONSOLIDADO);
  this.json = await leerJson(this.respuesta);
});

// ---------- Then ----------

Then('el consolidado responde con código {int}', function (codigo) {
  assert.strictEqual(this.respuesta.status, codigo,
    `Se esperaba ${codigo} pero llegó ${this.respuesta.status}: ${JSON.stringify(this.json)}`);
});

Then('el mensaje del consolidado es {string}', function (mensaje) {
  assert.strictEqual(this.json && this.json.message, mensaje);
});

Then('el consolidado tiene en total {int} movimiento(s)', function (cantidad) {
  assert.strictEqual(totalElementos(this), cantidad,
    `Descripciones recibidas: ${contenido(this).map((m) => m.descripcion).join(', ')}`);
});

Then('el consolidado tiene en total {int} movimiento(s) en {int} página(s)', function (cantidad, paginas) {
  assert.strictEqual(totalElementos(this), cantidad);
  assert.strictEqual(totalPaginas(this), paginas);
});

Then('la página trae {int} movimiento(s)', function (cantidad) {
  assert.strictEqual(contenido(this).length, cantidad);
});

Then('el movimiento {string} figura como del perfil personal', function (descripcion) {
  const movimiento = buscarPorDescripcion(this, descripcion);
  assert.ok(movimiento, `El movimiento "${descripcion}" no está en el consolidado`);
  assert.ok(movimiento.perfilId, 'El movimiento no trae el perfilId');
  assert.ok(movimiento.cuentaCompartidaId == null, 'Un movimiento personal no debería traer cuenta compartida');
  assert.ok(movimiento.cuentaCompartidaNombre == null);
});

Then('el movimiento {string} figura como de la cuenta compartida {string}', function (descripcion, nombre) {
  const movimiento = buscarPorDescripcion(this, descripcion);
  assert.ok(movimiento, `El movimiento "${descripcion}" no está en el consolidado`);
  assert.strictEqual(movimiento.perfilId, this.compartidas[nombre].perfilId);
  assert.strictEqual(movimiento.cuentaCompartidaId, this.compartidas[nombre].id);
  assert.strictEqual(movimiento.cuentaCompartidaNombre, nombre);
});

Then('el movimiento {string} no figura en el consolidado', function (descripcion) {
  assert.strictEqual(buscarPorDescripcion(this, descripcion), undefined,
    `"${descripcion}" es de otra cuenta y no debería aparecer`);
});

Then('los movimientos vienen en este orden:', function (dataTable) {
  const esperado = dataTable.raw().map((fila) => fila[0]);
  assert.deepStrictEqual(contenido(this).map((m) => m.descripcion), esperado);
});
