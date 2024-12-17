enum Categoria { deporte, recital, cine, videojuego, entrenamiento, turismo, educacion }

extension CategoriaExtension on Categoria {
  String toJson() {
    return toString().split('.').last;
  }
}
