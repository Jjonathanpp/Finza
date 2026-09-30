class UsuarioData {
  final String nombre;
  final String apellido;
  final int dni;
  final String telefono;
  final String fechaNacimiento; // formato yyyy-MM-dd
  final String genero;

  UsuarioData({
    required this.nombre,
    required this.apellido,
    required this.dni,
    required this.telefono,
    required this.fechaNacimiento,
    required this.genero,
  });

  Map<String, dynamic> toJson() => {
    'nombre': nombre,
    'apellido': apellido,
    'dni': dni,
    'telefono': telefono,
    'fechaNacimiento': fechaNacimiento,
    'genero': genero,
  };
}

class RegistroRequest {
  final String email;
  final String password;
  final UsuarioData usuario;

  RegistroRequest({
    required this.email,
    required this.password,
    required this.usuario,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'usuario': usuario.toJson(),
  };
}
