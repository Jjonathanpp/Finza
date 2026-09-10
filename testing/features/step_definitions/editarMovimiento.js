const { Given, When, Then } = require('@cucumber/cucumber');
const assert = require('assert');

const BACKEND_URL = process.env.BACKEND_URL || 'http://app:8080';

// ------------------------------------------------------------------
// ANTECEDENTES Y PRE-CONDICIONES (GIVEN)
// ------------------------------------------------------------------

Given('que un usuario no autenticado intenta modificar un movimiento', function () {
    this.usuarioAutenticado = null;
});

// ------------------------------------------------------------------
// ACCIONES (WHEN)
// ------------------------------------------------------------------

When('envio una solicitud PUT a {string} para ese movimiento con los siguientes datos:', async function (endpointBase, dataTable) {
    assert.ok(
        this.movimientoIdCreado,
        'No existe un ID de movimiento pre-cargado para ejecutar la modificacion'
    );

    const datosNuevos = dataTable.hashes()[0];
    this.datosActualizadosEsperados = datosNuevos;

    try {
        const response = await fetch(`${BACKEND_URL}${endpointBase}/${this.movimientoIdCreado}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            },
            body: JSON.stringify(datosNuevos)
        });

        this.responseStatus = response.status;

        try {
            this.responseData = await response.json();
        } catch (e) {
            this.responseData = {};
        }
    } catch (error) {
        throw new Error(`Error de conexion al enviar la peticion PUT a ${endpointBase}: ${error.message}`);
    }
});

When('envio una solicitud PUT a {string} para ese movimiento con los siguientes datos invalidos:', async function (endpointBase, dataTable) {
    assert.ok(
        this.movimientoIdCreado,
        'No existe un ID de movimiento pre-cargado para ejecutar la modificacion'
    );

    const datosInvalidos = dataTable.hashes()[0];

    try {
        const response = await fetch(`${BACKEND_URL}${endpointBase}/${this.movimientoIdCreado}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            },
            body: JSON.stringify(datosInvalidos)
        });

        this.responseStatus = response.status;

        try {
            this.responseData = await response.json();
        } catch (e) {
            this.responseData = {};
        }
    } catch (error) {
        throw new Error(`Error de conexion al enviar la peticion PUT con datos invalidos: ${error.message}`);
    }
});

When('envio una solicitud PUT a {string} con los siguientes datos:', async function (endpointCompleto, dataTable) {
    const datosModificacion = dataTable.hashes()[0];

    try {
        const response = await fetch(`${BACKEND_URL}${endpointCompleto}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            },
            body: JSON.stringify(datosModificacion)
        });

        this.responseStatus = response.status;

        try {
            this.responseData = await response.json();
        } catch (e) {
            this.responseData = {};
        }
    } catch (error) {
        throw new Error(`Error de conexion al enviar la peticion PUT a ${endpointCompleto}: ${error.message}`);
    }
});

When('envio una solicitud PUT a {string} sin token de autenticacion con los siguientes datos:', async function (endpointCompleto, dataTable) {
    const datosModificacion = dataTable.hashes()[0];

    try {
        const response = await fetch(`${BACKEND_URL}${endpointCompleto}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(datosModificacion)
        });

        this.responseStatus = response.status;

        try {
            this.responseData = await response.json();
        } catch (e) {
            this.responseData = {};
        }
    } catch (error) {
        throw new Error(`Error de conexion al enviar la peticion PUT sin autorizacion: ${error.message}`);
    }
});

// ------------------------------------------------------------------
// ASERCIONES Y VALIDACIONES (THEN)
// ------------------------------------------------------------------

Then('el movimiento editado debe reflejar los nuevos datos en la base de datos', async function () {
    try {
        const response = await fetch(`${BACKEND_URL}/api/movimientos/${this.movimientoIdCreado}`, {
            method: 'GET',
            headers: {
                'Authorization': `Bearer ${this.usuarioAutenticado?.token || ''}`
            }
        });

        const movimientoActualizado = await response.json();

        assert.strictEqual(
            parseFloat(movimientoActualizado.monto),
            parseFloat(this.datosActualizadosEsperados.monto),
            'El monto del movimiento en la base de datos no coincide con el valor editado'
        );

        assert.strictEqual(
            movimientoActualizado.descripcion,
            this.datosActualizadosEsperados.descripcion,
            'La descripcion del movimiento en la base de datos no coincide con la editada'
        );
    } catch (error) {
        throw new Error(`Error al validar los datos editados en la base de datos: ${error.message}`);
    }
});