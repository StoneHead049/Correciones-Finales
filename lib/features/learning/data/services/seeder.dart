import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

/// Lee un archivo local JSON y lo sube automáticamente a Firestore respetando la jerarquía (Es la semilla, por eso el nombre Seeder)
class Seeder {
  static Future<void> importarContenidoDinamico() async {
    final FirebaseFirestore db = FirebaseFirestore.instance;

    try {
      // rootBundle es la herramienta de Flutter para abrir archivos que viven dentro de la aplicación
      final String response = await rootBundle.loadString('assets/data/data_seed.json');

      // Convertimos ese bloque de texto en una l ista en idioma Dartiano
      final List<dynamic> data = json.decode(response);

      // FOR 1: Recorremos los mundos 
      for (var levelData in data) {
        String levelId = levelData['id'];

        // Creamos o actualizamos el documento del mundo en el documento de Firebase
        await db.collection('content').doc(levelId).set({

          // Ifs para evitar mandar datos erroneos a la base de datos
          if (levelData['titulo'] != null) 'titulo': levelData['titulo'],
          if (levelData['descripcion'] != null) 'descripcion': levelData['descripcion'],
          if (levelData['color_hex'] != null) 'color_hex': levelData['color_hex'],
          if (levelData['imagen_path'] != null) 'imagen_path': levelData['imagen_path'],
          if (levelData['orden'] != null) 'orden': levelData['orden'],
        }, SetOptions(merge: true)); // Esta parte es para que no vaya a borrar nada que este en la base de datos

        // FOR 2: Recorremos los subniveles del mundo (Básico, intermedio o avanzado)
        List<dynamic> sublevels = levelData['sublevels'] ?? [];
        for (var subData in sublevels) {
          String subId = subData['id'];
          
          await db.collection('content').doc(levelId)
              .collection('sublevels').doc(subId).set({
            if (subData['titulo'] != null) 'titulo': subData['titulo'],
            if (subData['descripcion'] != null) 'descripcion': subData['descripcion'],
            if (subData['orden'] != null) 'orden': subData['orden'],
            if (subData['xp_recompensa'] != null) 'xp_recompensa': subData['xp_recompensa'],
          }, SetOptions(merge: true));

          // FOR 3: Recorremos las preguntas del subnivel
          List<dynamic> questions = subData['questions'] ?? [];
          for (var qData in questions) {
            String qId = qData['id'];
            
            await db.collection('content').doc(levelId)
                .collection('sublevels').doc(subId)
                .collection('questions').doc(qId).set({
              'enunciado': qData['enunciado'],
              'tipo': qData['tipo'],
              'feedback': qData['feedback'],
              'respuesta_correcta': qData['respuesta_correcta'], 

              // Valores opcionales de las pregunts
              if (qData['opciones'] != null) 'opciones': qData['opciones'],
              if (qData['imagen_url'] != null) 'imagen_url': qData['imagen_url'],
            }, SetOptions(merge: true));
          }
        }
      }
      print("✅ El semillero tuvo exito");
    } catch (e) {
      print("❌ Semillero fallido: $e");
    }
  }
}
