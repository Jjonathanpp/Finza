// Los colores que se pueden elegir para una categoría propia (HU-4.2), los de la maqueta.
// Es una paleta cerrada: así dos categorías no quedan con tonos casi iguales en los gráficos.
// Van como texto porque así los guarda el backend; en pantalla se pasan con colorDesdeHex.
// Solo vale para las categorías nuevas: las que ya existen conservan el color que tienen guardado.
const paletaCategorias = [
  '#15784F', // verde
  '#2F5D9E', // azul
  '#8A3A66', // ciruela
  '#8F5600', // ámbar
  '#B23A2A', // coral
  '#0E7490', // turquesa
  '#6D28D9', // violeta
  '#56625C', // gris
];

// El nombre de cada color, para el lector de pantalla.
const nombresColoresCategorias = {
  '#15784F': 'Verde',
  '#2F5D9E': 'Azul',
  '#8A3A66': 'Ciruela',
  '#8F5600': 'Ámbar',
  '#B23A2A': 'Coral',
  '#0E7490': 'Turquesa',
  '#6D28D9': 'Violeta',
  '#56625C': 'Gris',
};
