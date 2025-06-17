import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class HtmlToPdfService {
  static Future<void> downloadTemplateAsPdf() async {
    try {
      // Créer un PDF avec le même contenu que le template HTML
      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              // En-tête principal
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Performance du système PV couplé au réseau',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'PVGIS-5 données de production solaire énergétique estimées',
                      style: const pw.TextStyle(fontSize: 12),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Grille d'informations
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Entrées fournies
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'ENTRÉES FOURNIES',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          ..._buildInfoItems([
                            ['Latitude/Longitude', '46.500, 5.004'],
                            ['Horizon', 'Calculé'],
                            ['Base de données', 'PVGIS-SARAH3'],
                            ['Technologie PV', 'Silicium cristallin'],
                            ['PV installée', '1 kWp'],
                            ['Pertes du système', '14 %'],
                          ]),
                        ],
                      ),
                    ),
                  ),
                  
                  pw.SizedBox(width: 20),
                  
                  // Résultats de la simulation
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'RÉSULTATS DE LA SIMULATION',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10),
                          ..._buildInfoItems([
                            ['Angle d\'inclinaison', '35 °'],
                            ['Angle d\'azimut', '0 °'],
                            ['Production annuelle PV', '1229.11 kWh'],
                            ['Irradiation annuelle', '1561.4 kWh/m²'],
                            ['Variabilité interannuelle', '62.37 kWh'],
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Changements de production
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Changements de la production à cause de :',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Bullet(text: 'Angle d\'incidence : -2.86 %'),
                    pw.Bullet(text: 'Effets spectraux : +1.43 %'),
                    pw.Bullet(text: 'Température et irradiance faible : -7.1 %'),
                    pw.Bullet(text: 'Pertes totales : -21.28 %'),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Titre du tableau
              pw.Text(
                'Production énergétique mensuelle du système PV fixe : Irradiation mensuelle sur plan fixe',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              
              pw.SizedBox(height: 20),
              
              // Graphiques côte à côte
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Graphique de production
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Production énergétique mensuelle (E_m)',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 15),
                          _buildProductionChart(),
                        ],
                      ),
                    ),
                  ),
                  
                  pw.SizedBox(width: 20),
                  
                  // Graphique d'irradiation
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(15),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey400),
                        color: PdfColors.grey50,
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Irradiation mensuelle sur plan fixe (H(i)_m)',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.SizedBox(height: 15),
                          _buildIrradiationChart(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Tableau des données mensuelles
              _buildMonthlyDataTable(),
              
              pw.SizedBox(height: 30),
              
              // Légende
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  border: pw.Border.all(color: PdfColors.grey400),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'LÉGENDE',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'E_m : Production électrique moyenne mensuelle du système défini [kWh]',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'H(i)_m : Montant total mensuel moyen de l\'irradiation globale reçue par mètre carré sur les panneaux du système défini [kWh/m²]',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      'SD_m : Déviation standard de la production électrique mensuelle à cause de la variation interannuelle [kWh]',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 20),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    top: pw.BorderSide(color: PdfColors.grey400),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PVGIS ©Union Européenne, 2001-2025',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Reproduction is authorised, provided the source is acknowledged, save where otherwise stated.',
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                    pw.SizedBox(height: 20),
                    pw.Align(
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(
                        'Rapport généré le ${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      );
      
      // Sauvegarder le PDF et le partager
      final Uint8List pdfBytes = await pdf.save();
      
      // Obtenir le répertoire de téléchargement
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/rapport_pvgis_template.pdf');
      await file.writeAsBytes(pdfBytes);
      
      // Partager le fichier
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Rapport PVGIS Template',
      );
      
    } catch (e) {
      throw Exception('Erreur lors de la génération du PDF : $e');
    }
  }
  
  static List<pw.Widget> _buildInfoItems(List<List<String>> items) {
    return items.map((item) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey200),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            item[0],
            style: const pw.TextStyle(fontSize: 11),
          ),
          pw.Text(
            item[1],
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    )).toList();
  }
  
  static pw.Widget _buildMonthlyDataTable() {
    final data = [
      ['Mois', 'E_m (kWh)', 'H(i)_m (kWh/m²)', 'SD_m (kWh)'],
      ['Janvier', '48.1', '56.6', '8.6'],
      ['Février', '73.8', '87.8', '16.9'],
      ['Mars', '113.6', '139.3', '19.0'],
      ['Avril', '131.3', '165.6', '20.4'],
      ['Mai', '134.2', '171.1', '18.3'],
      ['Juin', '140.7', '185.4', '13.4'],
      ['Juillet', '146.8', '195.8', '15.4'],
      ['Août', '136.7', '181.2', '8.8'],
      ['Septembre', '121.6', '156.3', '11.4'],
      ['Octobre', '87.4', '108.1', '12.2'],
      ['Novembre', '52.8', '63.7', '7.8'],
      ['Décembre', '42.2', '50.5', '9.5'],
    ];
    
    return pw.Table.fromTextArray(
      context: null,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey400),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 10,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.center,
      headerDecoration: const pw.BoxDecoration(
        color: PdfColors.grey200,
      ),
    );
  }
  
  // Graphique de production énergétique
  static pw.Widget _buildProductionChart() {
    final production = [48.1, 73.8, 113.6, 131.3, 134.2, 140.7, 146.8, 136.7, 121.6, 87.4, 52.8, 42.2];
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final maxValue = 160.0;
    
    return pw.Container(
      height: 150,
      child: pw.Column(
        children: [
          // Axe Y avec valeurs
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Labels Y
                pw.Container(
                  width: 25,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('160', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('120', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('80', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('40', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('0', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 5),
                // Barres
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: production.map((value) {
                      final barHeight = (value / maxValue) * 120;
                      return pw.Container(
                        width: 12,
                        height: barHeight,
                        color: PdfColors.grey800,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          // Labels X
          pw.Row(
            children: [
              pw.SizedBox(width: 30),
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: months.map((month) => 
                    pw.Text(month, style: const pw.TextStyle(fontSize: 8))
                  ).toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text('kWh', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
  
  // Graphique d'irradiation
  static pw.Widget _buildIrradiationChart() {
    final irradiation = [56.6, 87.8, 139.3, 165.6, 171.1, 185.4, 195.8, 181.2, 156.3, 108.1, 63.7, 50.5];
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    final maxValue = 210.0;
    
    return pw.Container(
      height: 150,
      child: pw.Column(
        children: [
          // Axe Y avec valeurs
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                // Labels Y
                pw.Container(
                  width: 25,
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('210', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('160', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('105', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('50', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text('0', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ),
                pw.SizedBox(width: 5),
                // Barres
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                    children: irradiation.map((value) {
                      final barHeight = (value / maxValue) * 120;
                      return pw.Container(
                        width: 12,
                        height: barHeight,
                        color: PdfColors.grey600,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          // Labels X
          pw.Row(
            children: [
              pw.SizedBox(width: 30),
              pw.Expanded(
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: months.map((month) => 
                    pw.Text(month, style: const pw.TextStyle(fontSize: 8))
                  ).toList(),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text('kWh/m²', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }
}

