import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  final String linkedInUrl = 'https://www.linkedin.com/in/matheus-lacerda96/';
  final String whatsappUrl = 'https://wa.me/98999344788';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    'Sobre',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: <Widget>[
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                      image: const DecorationImage(
                        image: NetworkImage('https://i.imgur.com/cXWK4wf.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Matheus Lacerda',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Desenvolvedor de Software',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Text(
                'Sou um desenvolvedor Full Stack, criando websites, aplicativos, servidores, e até videogames. Sempre busco novos desafios para entender o modelo de negócio e desenvolver com qualidade',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Se você tem uma idéia e quer fazer acontecer, venha falar comigo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  const FaIcon(FontAwesomeIcons.whatsapp,
                      color: Colors.green, size: 28),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final Uri whatsappUri = Uri.parse(whatsappUrl);
                      if (await canLaunchUrl(whatsappUri)) {
                        await launchUrl(whatsappUri);
                      } else {
                        throw 'Could not launch $whatsappUrl';
                      }
                    },
                    child: const Text(
                      'Chamar no WhatsApp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  const FaIcon(FontAwesomeIcons.linkedin,
                      color: Colors.blue, size: 28),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      final Uri linkedinUri = Uri.parse(linkedInUrl);
                      if (await canLaunchUrl(linkedinUri)) {
                        await launchUrl(linkedinUri);
                      } else {
                        throw 'Could not launch $linkedInUrl';
                      }
                    },
                    child: const Text(
                      'Conectar no LinkedIn',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 90),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  label: const Text(
                    'Voltar',
                    style: TextStyle(color: Colors.black, fontSize: 18),
                  ),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                      side: BorderSide(
                        color: Colors.grey[800]!,
                        width: 2.0,
                      ),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 9),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}