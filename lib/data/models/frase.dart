class Frase {
  final int? id;
  final String texto;
  final String hash;
  String? pathAudio;
  int usoCount;
  int? lastUsed; // (epoch millis)

  Frase({
    this.id,
    required this.texto,
    required this.hash,
    this.pathAudio,
    this.usoCount = 0,
    this.lastUsed,
  });

  // Convierte un mapa (de la base de datos) a un objeto Frase
  factory Frase.fromMap(Map<String, dynamic> map) {
    return Frase(
      id: map['id'] as int?,
      texto: map['texto'] as String,
      hash: map['hash'] as String,
      pathAudio: map['path_audio'] as String?,
      usoCount: map['uso_count'] as int? ?? 0,
      lastUsed: map['last_used'] as int?,
    );
  }

  // Convierte un objeto Frase a un mapa para la base de datos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'texto': texto,
      'hash': hash,
      'path_audio': pathAudio,
      'uso_count': usoCount,
      'last_used': lastUsed,
    };
  }

  // Crea una copia del objeto con valores opcionales actualizados
  Frase copyWith({
    int? id,
    String? texto,
    String? hash,
    String? pathAudio,
    int? usoCount,
    int? lastUsed,
  }) {
    return Frase(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      hash: hash ?? this.hash,
      pathAudio: pathAudio ?? this.pathAudio,
      usoCount: usoCount ?? this.usoCount,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }
}
