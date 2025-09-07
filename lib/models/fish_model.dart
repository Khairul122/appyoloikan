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
    final normalizedClassName = className.toLowerCase().trim();
    print('FishModel.fromClassName called with: "$className" -> normalized: "$normalizedClassName"');
    
    switch (normalizedClassName) {
      case 'ikan_baramundi':
        return FishModel(
          name: 'Ikan Baramundi',
          scientificName: 'Lates calcarifer',
          description: 'Ikan predator air tawar dan payau yang dapat tumbuh besar hingga 1,5 meter. Sangat populer untuk budidaya karena pertumbuhannya yang cepat dan rasanya yang lezat.',
          habitat: 'Perairan payau, muara sungai, dan laut dangkal',
          characteristics: ['Tubuh memanjang dan kokoh', 'Mulut besar dengan gigi tajam', 'Sisik besar berwarna perak kehijauan'],
        );
      case 'ikan_belanak_merah':
        return FishModel(
          name: 'Ikan Belanak Merah',
          scientificName: 'Valamugil buchanani',
          description: 'Ikan herbivora yang memiliki warna kemerah-merahan khas. Sering ditemukan di perairan dangkal dan menjadi target tangkapan nelayan tradisional.',
          habitat: 'Perairan pantai, estuari, dan muara sungai',
          characteristics: ['Tubuh torpedo dengan warna kemerahan', 'Mulut kecil terminal', 'Sirip ekor bercagak dalam'],
        );
      case 'ikan_cakalang':
        return FishModel(
          name: 'Ikan Cakalang',
          scientificName: 'Katsuwonus pelamis',
          description: 'Ikan tuna kecil yang sangat penting secara ekonomi. Memiliki daging yang kaya protein dan menjadi bahan baku utama industri pengalengan ikan.',
          habitat: 'Perairan laut terbuka, tropis dan subtropis',
          characteristics: ['Garis-garis gelap horizontal di punggung', 'Tubuh fusiform hidrodinamis', 'Sirip punggung tinggi dan kuat'],
        );
      case 'ikan_kakap_putih':
        return FishModel(
          name: 'Ikan Kakap Putih',
          scientificName: 'Lates niloticus',
          description: 'Ikan predator bernilai ekonomi tinggi dengan daging putih yang lezat. Sering menjadi target utama dalam perikanan komersial.',
          habitat: 'Perairan laut tropis, terumbu karang, dan perairan dalam',
          characteristics: ['Tubuh oval memanjang berwarna putih keperakan', 'Mulut besar dengan rahang kuat', 'Mata besar dan tajam'],
        );
      case 'ikan_kembung':
        return FishModel(
          name: 'Ikan Kembung',
          scientificName: 'Rastrelliger kanagurta',
          description: 'Ikan pelagis kecil yang hidup bergerombol dalam jumlah besar. Merupakan sumber protein penting dan mudah diolah menjadi berbagai masakan.',
          habitat: 'Perairan laut tropis di zona neritik',
          characteristics: ['Tubuh streamlined berwarna biru kehijauan', 'Sisik halus dan mudah lepas', 'Pola gelombang di sisi tubuh'],
        );
      case 'ikan_sarden':
        return FishModel(
          name: 'Ikan Sarden',
          scientificName: 'Sardinella longiceps',
          description: 'Ikan kecil yang hidup dalam kelompok besar dan menjadi basis industri pengalengan. Kaya akan omega-3 dan nutrisi penting lainnya.',
          habitat: 'Perairan laut dangkal dan zona pesisir',
          characteristics: ['Tubuh kecil memanjang berwarna keperakan', 'Sisik mudah lepas saat ditangani', 'Perut mengkilap seperti perak'],
        );
      default:
        print('No match found for: "$normalizedClassName". Using default.');
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