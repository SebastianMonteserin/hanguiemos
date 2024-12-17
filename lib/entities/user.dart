class Usuario {
  String id;
  String mail;
  String nombreDeUsuario;
  List<String> intereses;
  String imagenUrl;
  String telefono;

  Usuario(
      {required this.id,
      required this.mail,
      required this.intereses,
      required this.nombreDeUsuario,
      required this.imagenUrl,
      required this.telefono});

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
        id: json['_id'],
        mail: json['mail'],
        nombreDeUsuario: json['username'],
        imagenUrl: json['imageUrl'] ?? '',
        telefono: json['telefono'] ?? '',
        intereses: List<String>.from(json['intereses']));
  }
}
