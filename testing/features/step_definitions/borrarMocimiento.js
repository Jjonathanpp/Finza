const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

// En la red interna de Docker, la URL del backend se resuelve mediante el nombre del servicio ('app')
const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// ------------------------------------------------------------------
// ANTECEDENTES Y PASOS PREVIOS (GIVEN)
// ------------------------------------------------------------------

Given('que la API del backend esta activa y lista para recibir peticiones', async function () {
    try {
        await fetch(`${BACKEND_URL}/actuator/health`);
    } catch (error) {
        // Si la API no responde de inmediato, fallara durante las peticiones HTTP
    }
});

Given('que el usuario autenticado tiene un movimiento registrado con los siguientes datos:', async function (dataTable) {
    const datosMovimiento = dataTable.hashes()[0];

    try {
        // 1. Pre-creamos el movimiento en la BD
        const response = await fetch(`${BACKEND_URL}/api/movimientos`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            },
            body: JSON.stringify([datosMovimiento])
        });

        const responseData = await response.json();

        const elementoCreado = Array.isArray(responseData) ? responseData[0] : responseData;
        this.movimientoIdCreado = elementoCreado?.id || '1';
    } catch (error) {
        throw new Error(`Error al pre-cargar el movimiento de prueba: ${error.message}`);
    }
});

Given('que el usuario autenticado intenta eliminar un movimiento inexistente', function () {
    assert.ok(
        this.usuarioAutenticado,
        'Se requiere un usuario autenticado para realizar esta operacion'
    );
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('envio una solicitud DELETE a {string} para ese movimiento', async function (endpointBase) {
    assert.ok(
        this.movimientoIdCreado,
        'No existe un ID de movimiento pre-cargado para ejecutar la eliminacion'
    );

    try {
        const response = await fetch(`${BACKEND_URL}${endpointBase}/${this.movimientoIdCreado}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            }
        });

        this.responseStatus = response.status;

        try {
            this.responseData = await response.json();
        } catch (e) {
            this.responseData = {};
        }
    } catch (error) {
        throw new Error(`Error de conexion al enviar la peticion DELETE a ${endpointBase}: ${error.message}`);
    }
});

When('envio una solicitud DELETE a {string}', async function (endpointCompleto) {
    try {
        const response = await fetch(`${BACKEND_URL}${endpointCompleto}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            }
        });

        this.responseStatus = response.status;

        try {
            this.responseData = await response.json();
        } catch (e) {
            this.responseData = {};
        }
    } catch (error) {
        throw new Error(`Error de conexion al enviar la peticion DELETE a ${endpointCompleto}: ${error.message}`);
    }
});

// ------------------------------------------------------------------
// ASERCIONES Y VALIDACIONES DE RESPUESTA (THEN)
// ------------------------------------------------------------------

Then('la respuesta debe tener un codigo de estado {int}', function (expectedStatus) {
    assert.strictEqual(
        this.responseStatus,
        expectedStatus,
        `Se esperaba el codigo HTTP ${expectedStatus} pero el backend retorno ${this.responseStatus}`
    );
});

Then('la respuesta debe contener el mensaje {string}', function (mensajeEsperado) {
    const mensajeObtenido =
        this.responseData.mensaje ||
        this.responseData.message ||
        this.responseData.error;

    assert.strictEqual(
        mensajeObtenido,
        mensajeEsperado,
        `Se esperaba el mensaje "${mensajeEsperado}", pero el backend devolvio "${mensajeObtenido}"`
    );
});
