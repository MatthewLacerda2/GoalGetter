// Resources screen
import 'package:flutter/material.dart';
import '../widgets/screens/resource/resource_tab.dart';
import '../l10n/app_localizations.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});

  @override
  State<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends State<ResourcesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> books = [
    {'title': 'Apostila de Violão – Allan Sales', 'description': 'Dicas musicais para iniciantes', 'link': 'https://www.viamusical.com.br/Apostila%20Violao%20(versao%201).pdf'},
    {'title': 'Curso Prático De Violão Básico', 'description': 'Para ajudar os verdadeiros interessados em seu aprendizado', 'link': 'https://musicaeadoracao.com.br/recursos/arquivos/tecnicos/instrumentos/violao.pdf'},
    {'title': 'Curso Básico de Violão Popular', 'description': 'Curso básico de violão, extremamente prático', 'link': 'https://www.ibel.org.br/download/ApostilaDeViolao.pdf'},
  ];

  final List<Map<String, String>> youtube = [
    {'title': 'Hebert Freire', 'description': 'O papo aqui é violão!', 'link': 'https://www.youtube.com/@HebertFreire', 'image': 'https://yt3.googleusercontent.com/A_eM8MM0vMyXG3diHg697BZ9aXRHMbaxrsyzViiXnkNn7tuTDM6zvJdhr9Cc9DCKtHlS2V2f3g=s160-c-k-c0x00ffffff-no-rj'},
    {'title': 'Heitor Castro', 'description': 'Para dominar o violão!', 'link': 'https://www.youtube.com/@heitorcastro', 'image': 'https://yt3.googleusercontent.com/ytc/AIdro_nlaREsV8Qc26FFmZYfiA0u8ueftvg9tbKrQZz54hUHUnQ=s160-c-k-c0x00ffffff-no-rj'},
    {'title': 'Sidimar Antunes', 'description': 'O papo aqui é violão!', 'link': 'https://www.youtube.com/@SidimarAntunes', 'image': 'https://yt3.googleusercontent.com/CD29-HW1jyA4sq7oK3AYRmPkuAVf3JDWng1kFxVwECXt8nm99Yw_i1y8mOAXQSb65I9hvDIL=s160-c-k-c0x00ffffff-no-rj'},
  ];

  final List<Map<String, String>> sites = [
    {'title': 'Aprenda a tocar violão do zero (para iniciantes)', 'description': 'Guia inicial para aprender violão. Aqui tem o básico para você começar, é só ficar vendo repetidamente e praticar', 'link': 'https://www.descomplicandoamusica.com/aprenda-como-tocar-violao-aula-iniciantes/'},
    {'title': 'Cifra Club', 'description': 'Aqui você pega as cifras de qualquer som, e vai vendo elas enquanto a música passa', 'link': 'https://www.cifraclub.com.br/david-quinlan/abraca-me/', 'image': 'https://play-lh.googleusercontent.com/7-ERikbkh50hRSox2GDbUHDXykqI8G9TH_Tc4--HCqyHBnfFdlym1w-l0SilD3MAEA=w240-h480-rw'},
    {'title': 'Chordu', 'description': 'Outro site para ver a cifra enquanto a música passa', 'link': 'https://chordu.com/'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[800],
            dividerHeight: 4,
            tabs: [
              Tab(icon: Icon(Icons.book, size: 24), text: AppLocalizations.of(context)!.book),
              Tab(icon: Icon(Icons.play_circle, size: 28), text: AppLocalizations.of(context)!.youtube),
              Tab(icon: Icon(Icons.language, size: 28), text: AppLocalizations.of(context)!.sites),
            ],
          ),
        ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ResourceTab(
            resources: books,
          ),
          ResourceTab(
            resources: youtube,
          ),
          ResourceTab(
            resources: sites,
          ),
        ],
      ),
    );
  }
}