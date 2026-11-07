const { Given, When, Then, setDefaultTimeout } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// Cada escenario registra 4 cuentas y manda 2 invitaciones por mail.
setDefaultTimeout(30 * 1000);

let contador = 0;

async function leerJson(res) {
  try { return await res.json(); } catch { return null; }
}

function headers(token, contentType = 'application/json') {
  return { 'Content-Type': contentType, Authorization: `Bearer ${token}` };
}

// Cuenta nueva por usuario y por escenario: el test se puede repetir sin limpiar la base.
async function crearUsuario(world, alias) {
  world.usuarios = world.usuarios || {};
  if (world.usuarios[alias]) return world.usuarios[alias];

  const unico = `${Date.now()}${contador++}`;
  const email = `${alias}.${unico}@test.com`;
  const password = 'Password123!';

  const registro = await fetch(`${BACKEND_URL}/api/auth/registro`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email,
      password,
      usuario: { nombre: alias, apellido: 'Compartida', dni: Number(unico.slice(-9)) }
    })
  });
  assert.strictEqual(registro.status, 201, `No se pudo registrar a "${alias}" (status ${registro.status})`);

  const login = await fetch(`${BACKEND_URL}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  assert.strictEqual(login.status, 200, `No se pudo loguear a "${alias}" (status ${login.status})`);

  world.usuarios[alias] = { email, token: (await leerJson(login)).data.token, perfilId: null };
  return world.usuarios[alias];
}

function usuario(world, alias) {
  const u = world.usuarios && world.usuarios[alias];
  assert.ok(u, `El usuario "${alias}" no fue creado en los Antecedentes`);
  return u;
}

function urlInvitaciones(world) {
  return `${BACKEND_URL}/api/cuentas-compartidas/${world.cuentaCompartidaId}/invitaciones`;
}

// ---------- Antecedentes ----------

Given('que {string} creó la cuenta compartida {string}', async function (alias, nombre) {
  const admin = await crearUsuario(this, alias);

  const response = await fetch(`${BACKEND_URL}/api/cuentas-compartidas`, {
    method: 'POST',
    headers: headers(admin.token),
    body: JSON.stringify({ nombre })
  });
  const json = await leerJson(response);
  assert.strictEqual(response.status, 201, `No se pudo crear la cuenta compartida: ${JSON.stringify(json)}`);

  this.cuentaCompartidaId = json.data.id;
  this.adminAlias = alias;
  admin.perfilId = json.data.perfilId;
});

Given('que {string} se unió a la cuenta compartida aceptando una invitación', async function (alias) {
  const admin = usuario(this, this.adminAlias);
  const invitado = await crearUsuario(this, alias);

  const invitacion = await fetch(urlInvitaciones(this), {
    method: 'POST',
    headers: headers(admin.token),
    body: JSON.stringify({ email: invitado.email })
  });
  const jsonInvitacion = await leerJson(invitacion);
  assert.strictEqual(invitacion.status, 201, `No se pudo invitar a "${alias}": ${JSON.stringify(jsonInvitacion)}`);

  // El endpoint recibe @RequestBody String: el token va como texto plano, sin comillas JSON.
  const aceptar = await fetch(`${urlInvitaciones(this)}/aceptar`, {
    method: 'POST',
    headers: headers(invitado.token, 'text/plain'),
    body: jsonInvitacion.data.token
  });
  assert.strictEqual(aceptar.status, 200, `"${alias}" no pudo aceptar la invitación (status ${aceptar.status})`);

  // Su perfil dentro de la cuenta compartida (no el personal).
  const misCuentas = await fetch(`${BACKEND_URL}/api/cuentas-compartidas`, { headers: headers(invitado.token) });
  const cuenta = (await leerJson(misCuentas)).data.find((c) => c.id === this.cuentaCompartidaId);
  assert.ok(cuenta, `"${alias}" no aparece en la cuenta compartida después de aceptar`);
  invitado.perfilId = cuenta.perfilId;
});

Given('que {string} tiene una cuenta pero no pertenece a la cuenta compartida', async function (alias) {
  await crearUsuario(this, alias);
});

// ---------- When ----------

When('{string} invita a {string} a la cuenta compartida', async function (aliasEmisor, aliasInvitado) {
  this.respuesta = await fetch(urlInvitaciones(this), {
    method: 'POST',
    headers: headers(usuario(this, aliasEmisor).token),
    body: JSON.stringify({ email: usuario(this, aliasInvitado).email })
  });
  this.json = await leerJson(this.respuesta);
});

When('{string} consulta las invitaciones de la cuenta compartida', async function (alias) {
  this.respuesta = await fetch(urlInvitaciones(this), { headers: headers(usuario(this, alias).token) });
  this.json = await leerJson(this.respuesta);
});

When('{string} cambia el rol de {string} a {string}', async function (aliasActor, aliasObjetivo, rol) {
  const objetivo = usuario(this, aliasObjetivo);
  this.respuesta = await fetch(`${BACKEND_URL}/api/cuentas-compartidas/perfiles/${objetivo.perfilId}/rol`, {
    method: 'PUT',
    headers: headers(usuario(this, aliasActor).token),
    body: JSON.stringify({ rol })
  });
  this.json = await leerJson(this.respuesta);
});

// ---------- Then ----------

Then('la acción se rechaza con código {int}', function (codigo) {
  assert.strictEqual(this.respuesta.status, codigo,
    `Se esperaba ${codigo} pero llegó ${this.respuesta.status}: ${JSON.stringify(this.json)}`);
});

Then('la acción se responde con código {int}', function (codigo) {
  assert.strictEqual(this.respuesta.status, codigo,
    `Se esperaba ${codigo} pero llegó ${this.respuesta.status}: ${JSON.stringify(this.json)}`);
});

Then('{string} no tiene invitaciones pendientes en la cuenta compartida', async function (alias) {
  const email = usuario(this, alias).email.toLowerCase();
  const response = await fetch(urlInvitaciones(this), { headers: headers(usuario(this, this.adminAlias).token) });
  assert.strictEqual(response.status, 200, 'El administrador debería poder listar las invitaciones');

  const pendientes = (await leerJson(response)).data
    .filter((i) => i.emailInvitado.toLowerCase() === email && i.estado === 'PENDIENTE');
  assert.strictEqual(pendientes.length, 0, `Se creó una invitación para "${alias}" aunque la pidió un miembro`);
});

Then('el rol de {string} en la cuenta compartida es {string}', async function (alias, rolEsperado) {
  const objetivo = usuario(this, alias);
  const response = await fetch(`${BACKEND_URL}/api/cuentas-compartidas/${this.cuentaCompartidaId}/perfiles`, {
    headers: headers(usuario(this, this.adminAlias).token)
  });
  assert.strictEqual(response.status, 200, 'El administrador debería poder listar los perfiles');

  const perfil = (await leerJson(response)).data.find((p) => p.perfilId === objetivo.perfilId);
  assert.ok(perfil, `No se encontró el perfil de "${alias}" en la cuenta compartida`);
  assert.strictEqual(perfil.rol, rolEsperado, `El rol de "${alias}" es ${perfil.rol}, se esperaba ${rolEsperado}`);
});
