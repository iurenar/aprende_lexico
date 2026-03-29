import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String profession;
  final String level;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.profession,
    required this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14), // ✅ menos padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14), // ✅ radio más suave
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // ✅ sombra más sutil
            blurRadius: 6, // ✅ menos difuminado
            offset: const Offset(0, 2), // ✅ sombra hacia abajo, no centrada
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hola, $userName 👋",
                  style: const TextStyle(
                    fontSize: 16, // ✅ texto más pequeño
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3), // ✅ menos espacio
                Text(
                  "Perfil: $profession",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13, // ✅ tamaño más adecuado
                  ),
                ),
                const SizedBox(height: 6), // ✅ menos espacio
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), // ✅ menos padding
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.12), // ✅ opacidad más suave
                    borderRadius: BorderRadius.circular(12), // ✅ radio más pequeño
                  ),
                  child: Text(
                    level,
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 11, // ✅ tamaño más modesto
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40, // ✅ más compacto
            height: 40, // ✅ más compacto
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.indigo,
              size: 20, // ✅ ícono proporcional
            ),
          ),
        ],
      ),
    );

  }
}
