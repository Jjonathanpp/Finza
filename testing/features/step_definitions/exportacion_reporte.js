const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';
let contador = 0;

Given('que tengo una cuenta nueva autenticada para probar la exportación', async function () {
    const unico = `${Date.now()}${contador++}`;
    const email = `exportacion.${unico}@test.com`;
    const password = 'Password123!';

    await fetch(`${BACKEND_URL}/api/auth/registro`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            email, password,
            usuario: { nombre: 'Test', apellido: 'Exportacion', dni: Number(unico.slice(-9)) }
        })
    });

    const resLogin = await fetch(`${BACKEND_URL}/api/auth/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, password })
    });

    const json = await resLogin.json();
    this.token = json.data.token;
});

When('solicito el reporte con alcance {string}, fechaDesde {string} y fechaHasta {string}', async function (alcance, fechaDesde, fechaHasta) {
    const response = await fetch(
        `${BACKEND_URL}/api/informes/reporte?alcance=${alcance}&fechaDesde=${fechaDesde}&fechaHasta=${fechaHasta}`,
        {
            method: 'GET',
            headers: { 'Authorization': `Bearer ${this.token}` }
        }
    );

    this.responseStatus = response.status;
    this.responseContentType = response.headers.get('content-type') || '';

    if (!response.ok) {
        this.responseData = await response.json().catch(() => ({}));
    } else {
        this.responseData = {};
    }
});

When('solicito el reporte sin token con alcance {string}, fechaDesde {string} y fechaHasta {string}', async function (alcance, fechaDesde, fechaHasta) {
    const response = await fetch(
        `${BACKEND_URL}/api/informes/reporte?alcance=${alcance}&fechaDesde=${fechaDesde}&fechaHasta=${fechaHasta}`,
        { method: 'GET' }
    );

    this.responseStatus = response.status;
    this.responseContentType = response.headers.get('content-type') || '';

    if (!response.ok) {
        this.responseData = await response.json().catch(() => ({}));
    } else {
        this.responseData = {};
    }
});

Then('la respuesta de exportación debe tener un codigo de estado {int}', function (codigoEsperado) {
    assert.strictEqual(
        this.responseStatus,
        codigoEsperado,
        `Se esperaba status ${codigoEsperado} pero llegó ${this.responseStatus}`
    );
});

Then('el Content-Type de la respuesta debe ser {string}', function (tipoEsperado) {
    assert.ok(
        this.responseContentType.includes(tipoEsperado),
        `Se esperaba Content-Type que contenga "${tipoEsperado}", se obtuvo: "${this.responseContentType}"`
    );
});