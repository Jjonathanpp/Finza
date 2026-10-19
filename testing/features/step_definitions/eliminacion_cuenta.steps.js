const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BASE_URL = process.env.API_URL || 'http://app:8080';

async function leerJson(res) {
    try { return await res.json(); } catch { return null; }
}

async function registrar(email, password) {
    // Ajustá el body a tu CuentaRegistroDTO real
    return fetch(`${BASE_URL}/api/auth/registro`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email,
            password,
            usuario: {
                nombre: 'Juan',
                apellido: 'Perez',
                dni: ' 13579246',
                telefono: '3415550000',
                fechaNacimiento: '1999-01-01',
                genero: 'MASCULINO'
            }
        })
    });
}

async function login(email, password) {
    return fetch(`${BASE_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
    });
}

// ---------- Antecedentes ----------

Given('que el usuario {string} con contraseña {string} se encuentra registrado en el sistema',
    async function (email, password) {
        this.email = email;
        this.password = password;
        // Si ya existe de un escenario anterior, el registro falla y no pasa nada
        await registrar(email, password);
    });

Given('el usuario ha iniciado sesión y cuenta con un token de autenticación válido',
    async function () {
        const res = await login(this.email, this.password);
        assert.strictEqual(res.status, 200, 'El login previo debería ser exitoso');
        const json = await leerJson(res);
        this.token = json.data.token;
    });

// ---------- Given ----------

Given('que el usuario se encuentra en la pantalla de configuración de su perfil', function () {
    // Paso de contexto de UI: no hay acción contra la API
});

Given('que un usuario no autenticado intenta enviar una solicitud de eliminación de cuenta', function () {
    this.token = null;
});

// ---------- When ----------

When('solicita eliminar su cuenta ingresando su contraseña actual {string}', function (password) {
    this.passwordIngresada = password;
});

When('solicita eliminar su cuenta ingresando una contraseña incorrecta {string}', function (password) {
    this.passwordIngresada = password;
});

When('confirma la acción de eliminación definitiva', async function () {
    this.respuesta = await fetch(`${BASE_URL}/api/auth/me`, {
        method: 'DELETE',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.token}`
        },
        body: JSON.stringify({ password: this.passwordIngresada })
    });
    this.json = await leerJson(this.respuesta);
});

When('envía la petición al endpoint de eliminación con la contraseña {string}', async function (password) {
    this.respuesta = await fetch(`${BASE_URL}/api/auth/me`, {
        method: 'DELETE',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ password })
    });
    this.json = await leerJson(this.respuesta);
});

// ---------- Then ----------

Then('el sistema valida que la contraseña es correcta', function () {
    assert.strictEqual(this.respuesta.status, 200);
});

Then('el sistema detecta que la contraseña no coincide con el registro', function () {
    assert.strictEqual(this.respuesta.status, 401);
});

Then('elimina la cuenta del usuario de la base de datos', async function () {
    const res = await login(this.email, this.password);
    assert.notStrictEqual(res.status, 200, 'La cuenta eliminada no debería poder iniciar sesión');
});

Then('la cuenta del usuario no es eliminada de la base de datos', async function () {
    const res = await login(this.email, this.password);
    assert.strictEqual(res.status, 200, 'La cuenta debería seguir existiendo');
});

Then('la cuenta del usuario permanece activa en el sistema', async function () {
    const res = await login(this.email, this.password);
    assert.strictEqual(res.status, 200, 'La cuenta debería seguir activa');
});

Then('el sistema responde con un estado HTTP {int} y un mensaje de éxito', function (status) {
    assert.strictEqual(this.respuesta.status, status);
    assert.ok(this.json && this.json.message, 'Debería haber un mensaje en la respuesta');
});

Then('el sistema responde con un estado HTTP {int} y un mensaje de error de credenciales', function (status) {
    assert.strictEqual(this.respuesta.status, status);
    assert.ok(this.json && this.json.message, 'Debería haber un mensaje de error');
});

Then('el sistema rechaza la solicitud respondiendo con un estado HTTP {int} o {int}', function (a, b) {
    assert.ok([a, b].includes(this.respuesta.status),
        `Se esperaba ${a} o ${b} pero fue ${this.respuesta.status}`);
});

Then('la sesión del usuario queda invalidada', async function () {
    const res = await fetch(`${BASE_URL}/api/auth/me`, {
        method: 'DELETE',
        headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${this.token}`
        },
        body: JSON.stringify({ password: this.password })
    });
    assert.strictEqual(res.status, 401, 'Reusar el token tras borrar la cuenta debería fallar');
});