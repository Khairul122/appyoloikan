class FishModel {
  final String name;
  final String scientificName;
  final String description;
  final String habitat;
  final List<String> characteristics;

  FishModel({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.habitat,
    required this.characteristics,
  });

  factory FishModel.fromClassName(String className) {
    switch (className.toLowerCase()) {
      case 'ikan_baramundi':
        return FishModel(
          name: 'Ikan Baramundi',
          scientificName: 'Lates calcarifer',
          description: 'Ikan predator air tawar dan payau yang besar',
          habitat: 'Perairan payau, muara sungai, dan laut dangkal',
          characteristics: ['Tubuh memanjang', 'Mulut besar', 'Sisik besar'],
        );
      case 'ikan_belanak_merah':
        return FishModel(
          name: 'Ikan Belanak Merah',
          scientificName: 'Mugil cephalus',
          description: 'Ikan yang hidup di perairan dangkal',
          habitat: 'Perairan pantai dan muara sungai',
          characteristics: ['Tubuh torpedo', 'Warna kemerahan', 'Mulut kecil'],
        );
      case 'ikan_cakalang':
        return FishModel(
          name: 'Ikan Cakalang',
          scientificName: 'Katsuwonus pelamis',
          description: 'Ikan pelagis yang aktif berenang dalam kelompok',
          habitat: 'Perairan laut tropis dan subtropis',
          characteristics: ['Garis-garis gelap horizontal', 'Tubuh fusiform', 'Sirip punggung tinggi'],
        );
      case 'ikan_kakap_putih':
        return FishModel(
          name: 'Ikan Kakap Putih',
          scientificName: 'Lates calcarifer',
          description: 'Ikan predator bernilai ekonomi tinggi',
          habitat: 'Perairan laut dan payau',
          characteristics: ['Tubuh memanjang', 'Warna putih keperakan', 'Mulut besar'],
        );
      case 'ikan_kembung':
        return FishModel(
          name: 'Ikan Kembung',
          scientificName: 'Rastrelliger spp.',
          description: 'Ikan pelagis kecil yang hidup bergerombol',
          habitat: 'Perairan laut tropis',
          characteristics: ['Tubuh memanjang', 'Sisik halus', 'Warna kebiruan'],
        );
      case 'ikan_sarden':
        return FishModel(
          name: 'Ikan Sarden',
          scientificName: 'Sardinella spp.',
          description: 'Ikan kecil yang hidup dalam kelompok besar',
          habitat: 'Perairan laut dangkal',
          characteristics: ['Tubuh kecil memanjang', 'Sisik mudah lepas', 'Warna keperakan'],
        );
      default:
        return FishModel(
          name: className,
          scientificName: 'Unknown',
          description: 'Spesies ikan tidak diketahui',
          habitat: 'Perairan laut',
          characteristics: ['Tidak ada data'],
        );
    }
  }
}