const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

let response;
let body;

Given('que el backend está corriendo', function () {
    response = null;
    body = null;
});

When('envío una petición GET a {string}', async function (path) {
    response = await fetch(`http://app:8080${path}`);
    body = await response.json();
});

Then('recibo una respuesta con código {int}', function (codigo) {
    assert.strictEqual(response.status, codigo);
});

Then('el body tiene los campos status, message y data', function () {
    assert.ok('status' in body);
    assert.ok('message' in body);
    assert.ok('data' in body);
});

Then('el campo status es {int}', function (status) {
    assert.strictEqual(body.status, status);
});