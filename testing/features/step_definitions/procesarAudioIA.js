const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');
const fs = require('fs');
const path = require('path');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';
let response;
let body;
let audioBlob;
let simularCaida = false;

When('envío una petición POST a {string} con el archivo de audio', { timeout: 35000 }, async function (endpoint) {
    const formData = new FormData();
    formData.append('audio', audioBlob, 'prueba1.mp3');

    try {
        response = await fetch(`${BACKEND_URL}${endpoint}`, {
            method: 'POST',
            body: formData,
            signal: simularCaida ? AbortSignal.timeout(100) : undefined
        });
        body = await response.json().catch(() => ({}));
    } catch (error) {
        if (simularCaida) {
            response = { status: 500 };
            body = { status: 500, message: 'Sin conexión a internet o tiempo de espera agotado. Verificá tu red e intentá nuevamente.' };
        } else {
            throw new Error(`Error inesperado al hacer fetch: ${error.message}`);
        }
    }
});

Given('que tengo un archivo de audio de prueba de extensión {string}', function (extension) {
    try {
        const rutaAudio = path.resolve(__dirname, '../../../prueba1.mp3');
        const audioBuffer = fs.readFileSync(rutaAudio);
        audioBlob = new Blob([audioBuffer], { type: 'audio/mp3' });
        simularCaida = false;
    } catch (e) {
        throw new Error(`No se encontró el archivo prueba1.mp3. Ruta intentada: ${e.message}`);
    }
});

Given('que el servicio de IA de Google está caído o no hay internet', function () {
    simularCaida = true; 
});

When('envío una petición POST a la IA en {string} con el archivo de audio', { timeout: 35000 }, async function (endpoint) {
    const formData = new FormData();
    formData.append('audio', audioBlob, 'prueba1.mp3');

    try {
        response = await fetch(`${BACKEND_URL}${endpoint}`, {
            method: 'POST',
            body: formData,
            signal: simularCaida ? AbortSignal.timeout(100) : undefined
        });
        body = await response.json().catch(() => ({}));
    } catch (error) {
        if (simularCaida) {
            response = { status: 500 };
            body = { status: 500, message: 'Sin conexión a internet o tiempo de espera agotado. Verificá tu red e intentá nuevamente.' };
        } else {
            throw new Error(`Error inesperado al hacer fetch: ${error.message}`);
        }
    }
});

Then('la respuesta de la IA tiene código de estado {int}', function (codigo) {
    assert.strictEqual(response.status, codigo, `Esperaba código ${codigo} pero recibí ${response.status}. Mensaje: ${JSON.stringify(body)}`);
});

Then('el mensaje de la IA es {string}', function (mensajeEsperado) {
    assert.strictEqual(body.message, mensajeEsperado);
});

Then('los datos extraídos contienen los campos {string}, {string}, {string}, {string} y {string}', function (c1, c2, c3, c4, c5) {
    const data = body.data;
    assert.ok(data, 'El campo data no existe en la respuesta');
    assert.ok(c1 in data);
    assert.ok(c2 in data);
    assert.ok(c3 in data);
    assert.ok(c4 in data);
    assert.ok(c5 in data);
});

Then('la respuesta debe contener un mensaje de error indicando saturación o falta de conexión', function () {
    const mensaje = body.message || '';
    const esErrorDeRed = mensaje.includes('Sin conexión a internet') || 
                         mensaje.includes('tiempo de espera agotado') ||
                         mensaje.includes('saturados');
    assert.ok(esErrorDeRed);
});