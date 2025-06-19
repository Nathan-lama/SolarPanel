import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/roof_pan.dart';

class HtmlToPdfService {
  static Future<void> downloadTemplateAsPdf({
    RoofPan? roofPan,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? analysisResults,
  }) async {
    try {
      // Utiliser les données fournies ou des valeurs par défaut
      final lat = latitude ?? 46.500;
      final lng = longitude ?? 5.004;
      final orientation = roofPan?.orientation ?? 0.0;
      final inclination = roofPan?.inclination ?? 35.0;
      final peakPower = roofPan?.peakPower ?? 1.0;
      
      // Données d'analyse dynamiques ou valeurs par défaut
      final monthlyProduction = analysisResults?['monthlyProduction'] ?? 
          [48.1, 73.8, 113.6, 131.3, 134.2, 140.7, 146.8, 136.7, 121.6, 87.4, 52.8, 42.2];
      final monthlyIrradiation = analysisResults?['monthlyIrradiation'] ?? 
          [56.6, 87.8, 139.3, 165.6, 171.1, 185.4, 195.8, 181.2, 156.3, 108.1, 63.7, 50.5];
      final monthlyStdDev = analysisResults?['monthlyStdDev'] ?? 
          [8.6, 16.9, 19.0, 20.4, 18.3, 13.4, 15.4, 8.8, 11.4, 12.2, 7.8, 9.5];
      final annualProduction = analysisResults?['annualProduction'] ?? 1229.11;
      final annualIrradiation = analysisResults?['annualIrradiation'] ?? 1561.4;
      final interannualVariability = analysisResults?['interannualVariability'] ?? 62.37;
      final systemLosses = analysisResults?['systemLosses'] ?? 14.0;
      
      // Créer un PDF avec les données dynamiques
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
              
              // Grille d'informations avec données dynamiques
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
                            ['Latitude/Longitude', '${lat.toStringAsFixed(3)}, ${lng.toStringAsFixed(3)}'],
                            ['Horizon', 'Calculé'],
                            ['Base de données', 'PVGIS-SARAH3'],
                            ['Technologie PV', 'Silicium cristallin'],
                            ['PV installée', '${peakPower.toStringAsFixed(1)} kWp'],
                            ['Pertes du système', '${systemLosses.toStringAsFixed(0)} %'],
                          ]),
                        ],
                      ),
                    ),
                  ),
                  
                  pw.SizedBox(width: 20),
                  
                  // Résultats de la simulation avec données dynamiques
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
                            ['Angle d\'inclinaison', '${inclination.toStringAsFixed(0)} °'],
                            ['Angle d\'azimut', '${orientation.toStringAsFixed(0)} °'],
                            ['Production annuelle PV', '${annualProduction.toStringAsFixed(2)} kWh'],
                            ['Irradiation annuelle', '${annualIrradiation.toStringAsFixed(1)} kWh/m²'],
                            ['Variabilité interannuelle', '${interannualVariability.toStringAsFixed(2)} kWh'],
                          ]),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Changements de production avec données dynamiques
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
                    pw.Bullet(text: 'Angle d\'incidence : ${(analysisResults?['incidenceAngleLoss'] ?? -2.86).toStringAsFixed(2)} %'),
                    pw.Bullet(text: 'Effets spectraux : +${(analysisResults?['spectralLoss'] ?? 1.43).toStringAsFixed(2)} %'),
                    pw.Bullet(text: 'Température et irradiance faible : ${(analysisResults?['temperatureLoss'] ?? -7.1).toStringAsFixed(1)} %'),
                    pw.Bullet(text: 'Pertes totales : ${(analysisResults?['totalLosses'] ?? -21.28).toStringAsFixed(2)} %'),
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
              
              // Graphiques côte à côte avec données dynamiques
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
                          _buildProductionChart(monthlyProduction),
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
                          _buildIrradiationChart(monthlyIrradiation),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Tableau des données mensuelles avec données dynamiques
              _buildMonthlyDataTable(monthlyProduction, monthlyIrradiation, monthlyStdDev),
              
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
  
  // Graphique de production énergétique avec données dynamiques
  static pw.Widget _buildProductionChart(List<dynamic> production) {
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    
    // Convertir les valeurs en double de manière sécurisée
    final productionDoubles = production.map((value) => _toDouble(value)).toList();
    final maxValue = productionDoubles.reduce((a, b) => a > b ? a : b) * 1.1; // 10% de marge
    
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
                      pw.Text(maxValue.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                      pw.Text((maxValue * 0.75).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                      pw.Text((maxValue * 0.5).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                      pw.Text((maxValue * 0.25).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
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
                    children: productionDoubles.map<pw.Widget>((value) {
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
  
  // Graphique d'irradiation avec données dynamiques
  static pw.Widget _buildIrradiationChart(List<dynamic> irradiation) {
    final months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    
    // Convertir les valeurs en double de manière sécurisée
    final irradiationDoubles = irradiation.map((value) => _toDouble(value)).toList();
    final maxValue = irradiationDoubles.reduce((a, b) => a > b ? a : b) * 1.1; // 10% de marge
    
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
                      pw.Text(maxValue.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                      pw.Text((maxValue * 0.75).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                      pw.Text((maxValue * 0.5).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
                      pw.Text((maxValue * 0.25).toStringAsFixed(0), style: const pw.TextStyle(fontSize: 8)),
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
                    children: irradiationDoubles.map<pw.Widget>((value) {
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
  
  static pw.Widget _buildMonthlyDataTable(List<dynamic> production, List<dynamic> irradiation, List<dynamic> stdDev) {
    final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                   'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    
    List<List<String>> data = [
      ['Mois', 'E_m (kWh)', 'H(i)_m (kWh/m²)', 'SD_m (kWh)']
    ];
    
    for (int i = 0; i < 12; i++) {
      data.add([
        months[i],
        _toDouble(production[i]).toStringAsFixed(1),
        _toDouble(irradiation[i]).toStringAsFixed(1),
        _toDouble(stdDev[i]).toStringAsFixed(1),
      ]);
    }
    
    return pw.TableHelper.fromTextArray(
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
  
  // Fonction utilitaire pour convertir de manière sécurisée en double
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      return parsed ?? 0.0;
    }
    return 0.0;
  }
}

