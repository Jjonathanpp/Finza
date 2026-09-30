const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

// La respuesta se guarda en el World (this) para que otros archivos de pasos la puedan leer.
Given('que el backend está corriendo', function () {
    this.response = null;
    this.body = null;
});

When('envío una petición GET a {string}', async function (path) {
    this.response = await fetch(`http://app:8080${path}`);
    this.body = await this.response.json().catch(() => ({}));
});

Then('recibo una respuesta con código {int}', function (codigo) {
    assert.strictEqual(this.response.status, codigo, `Se esperaba ${codigo} pero llegó ${this.response.status}: ${JSON.stringify(this.body)}`);
});

Then('el body tiene los campos status, message y data', function () {
    assert.ok('status' in this.body);
    assert.ok('message' in this.body);
    assert.ok('data' in this.body);
});

Then('el campo status es {int}', function (status) {
    assert.strictEqual(this.body.status, status);
});
