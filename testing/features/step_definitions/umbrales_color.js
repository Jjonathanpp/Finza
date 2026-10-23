const { Then } = require('@cucumber/cucumber');
const assert = require('assert');

Then('el estado del umbral debe ser {string}', function (estadoEsperado) {
    const categorias = this.responseData.data?.categorias || [];
    const cat = categorias.find(c => c.categoriaNombre === 'Comida');

    assert.ok(cat, 'Categoría "Comida" no encontrada en la respuesta');
    assert.strictEqual(
        cat.estado,
        estadoEsperado,
        `Estado: esperado ${estadoEsperado}, obtenido ${cat.estado}`
    );
});

Then('el porcentaje del umbral debe ser {float}', function (porcentajeEsperado) {
    const categorias = this.responseData.data?.categorias || [];
    const cat = categorias.find(c => c.categoriaNombre === 'Comida');

    assert.ok(cat, 'Categoría "Comida" no encontrada en la respuesta');
    assert.strictEqual(
        parseFloat(cat.porcentajeConsumo),
        porcentajeEsperado,
        `Porcentaje: esperado ${porcentajeEsperado}%, obtenido ${cat.porcentajeConsumo}%`
    );
});