const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');
const axios = require('axios');

const API_URL = 'http://localhost:8080/api/movimientos';

// --- PASOS NUEVOS QUE PEDÍA CUCUMBER ---
Given('que el sistema está corriendo', async function () {
    // Como levantamos Docker, sabemos que está corriendo.
    // Solo le devolvemos true para que Cucumber siga al próximo paso.
    return true;
});

Then('la respuesta debe tener código de estado {int}', function (statusCode) {
    assert.strictEqual(this.response.status, statusCode, `Se esperaba HTTP ${statusCode} pero llegó ${this.response.status}`);
});
// ----------------------------------------

When('solicito el listado de movimientos sin filtros', async function () {
    try {
        this.response = await axios.get(API_URL);
    } catch (error) {
        this.response = error.response;
    }
});

When('solicito el listado de movimientos con el filtro {string} en {string}', async function (clave, valor) {
    try {
        this.response = await axios.get(`${API_URL}?${clave}=${valor}`);
    } catch (error) {
        this.response = error.response;
    }
});

When('solicito el listado de movimientos desde {string} hasta {string}', async function (fechaInicio, fechaFin) {
    try {
        this.response = await axios.get(`${API_URL}?fechaInicio=${fechaInicio}&fechaFin=${fechaFin}`);
    } catch (error) {
        this.response = error.response;
    }
});

Then('la respuesta debe contener una lista paginada', function () {
    assert.ok(this.response.data.content !== undefined, 'No se encontró el array paginado en la respuesta');
});

Then('el tamaño de la página debe ser como máximo {int}', function (tamanioMaximo) {
    const cantidadMovimientos = this.response.data.content.length;
    assert.ok(cantidadMovimientos <= tamanioMaximo, `La página trajo ${cantidadMovimientos} elementos, superando el máximo de ${tamanioMaximo}`);
});

Then('todos los movimientos devueltos deben tener el tipo {string}', function (tipoEsperado) {
    const movimientos = this.response.data.content;
    for (let mov of movimientos) {
        assert.strictEqual(mov.tipo, tipoEsperado, `Se encontró un movimiento que no es ${tipoEsperado}`);
    }
});

Then('la fecha de los movimientos devueltos debe estar dentro de ese rango', function () {
    const movimientos = this.response.data.content;
    const inicio = new Date("2026-09-01").getTime();
    const fin = new Date("2026-09-30").getTime();

    for (let mov of movimientos) {
        const [dia, mes, anio] = mov.fecha.split('-');
        const fechaMov = new Date(`${anio}-${mes}-${dia}`).getTime();
        
        assert.ok(fechaMov >= inicio && fechaMov <= fin, `La fecha ${mov.fecha} está fuera del rango solicitado`);
    }
});