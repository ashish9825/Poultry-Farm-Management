import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'database_service.dart';
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class BackupService {
  static Future<String> exportFullExcel() async {
    final db = DatabaseService.instance;
    final farmData = await db.getFarmData();
    final deadChicks = await db.getDeadChicks();
    final customers = await db.getCustomers();
    final labours = await db.getLabours();
    final medicines = await db.getMedicines();
    final feeds = await db.getFeeds();
    
    var excel = Excel.createExcel();
    final fmt = NumberFormat('#,##0.00');

    // Farm Data
    var sFarm = excel['Farm Data'];
    sFarm.appendRow([TextCellValue('Date'), TextCellValue('Chicks Added'), TextCellValue('Chicks Cost'), TextCellValue('Medicine Cost'), TextCellValue('Grains Cost'), TextCellValue('Other Expenses')]);
    for (var f in farmData) {
      sFarm.appendRow([TextCellValue(f.date), TextCellValue('${f.numberOfChicks}'), TextCellValue(fmt.format(f.chicksAmount)), TextCellValue(fmt.format(f.medicineAmount)), TextCellValue(fmt.format(f.grainsAmount)), TextCellValue(fmt.format(f.otherExpenses))]);
    }

    // Dead Chicks
    var sDead = excel['Dead Chicks'];
    sDead.appendRow([TextCellValue('Date'), TextCellValue('Notes'), TextCellValue('Count')]);
    for (var d in deadChicks) {
      sDead.appendRow([TextCellValue(d.date), TextCellValue(d.notes), TextCellValue('${d.count}')]);
    }

    // Customers
    var sCust = excel['Customers'];
    sCust.appendRow([TextCellValue('Date'), TextCellValue('Symbol'), TextCellValue('Name'), TextCellValue('Mobile'), TextCellValue('Weight (kg)'), TextCellValue('Rate'), TextCellValue('Total Amt'), TextCellValue('Paid'), TextCellValue('Pending'), TextCellValue('Payment Mode')]);
    for (var c in customers) {
      sCust.appendRow([TextCellValue(c.date), TextCellValue(c.symbolNumber), TextCellValue(c.name), TextCellValue(c.mobileNo), TextCellValue('${c.chickenWeight}'), TextCellValue(fmt.format(c.chickenRate)), TextCellValue(fmt.format(c.totalAmount)), TextCellValue(fmt.format(c.depositAmount)), TextCellValue(fmt.format(c.remainingAmount)), TextCellValue(c.paymentMode)]);
    }

    // Labours
    var sLab = excel['Labour'];
    sLab.appendRow([TextCellValue('Name'), TextCellValue('Role'), TextCellValue('Daily Wage'), TextCellValue('Days Worked'), TextCellValue('Total Earned'), TextCellValue('Paid'), TextCellValue('Pending')]);
    for (var l in labours) {
      sLab.appendRow([TextCellValue(l.name), TextCellValue(l.role), TextCellValue(fmt.format(l.dailyWage)), TextCellValue('${l.totalDaysWorked}'), TextCellValue(fmt.format(l.totalEarned)), TextCellValue(fmt.format(l.totalPaid)), TextCellValue(fmt.format(l.remainingPayment))]);
    }

    // Medicines
    var sMed = excel['Medicines'];
    sMed.appendRow([TextCellValue('Date'), TextCellValue('Medicine Name'), TextCellValue('Cost'), TextCellValue('Notes')]);
    for (var m in medicines) {
      sMed.appendRow([TextCellValue(m.date), TextCellValue(m.name), TextCellValue(fmt.format(m.cost)), TextCellValue(m.notes)]);
    }

    // Feeds
    var sFeed = excel['Feeds'];
    sFeed.appendRow([TextCellValue('Date'), TextCellValue('Feed Type'), TextCellValue('Quantity (kg/bags)'), TextCellValue('Cost'), TextCellValue('Notes')]);
    for (var f in feeds) {
      sFeed.appendRow([TextCellValue(f.date), TextCellValue(f.type), TextCellValue('${f.quantity}'), TextCellValue(fmt.format(f.cost)), TextCellValue(f.notes)]);
    }

    excel.delete('Sheet1');
    var fileBytes = excel.save();
    
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Farm_Export_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx');
    await file.writeAsBytes(fileBytes!);
    return file.path;
  }

  static Future<String> exportFullPDF() async {
    final db = DatabaseService.instance;
    final farmData = await db.getFarmData();
    final deadChicks = await db.getDeadChicks();
    final customers = await db.getCustomers();
    final labours = await db.getLabours();
    final summary = await db.getSummary();
    
    final fmt = NumberFormat('#,##0.00');
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(level: 0, child: pw.Text('Poultry Farm Master Backup Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24))),
            pw.Paragraph(text: 'Generated on: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}'),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Financial Summary')),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Category', 'Amount (Rs.)'],
              data: [
                ['Total Income', fmt.format(summary['income'] ?? 0)],
                ['Total Expense', fmt.format(summary['expense'] ?? 0)],
                ['Net Profit', fmt.format(summary['profit'] ?? 0)],
              ],
            ),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Farm Data (Buying Chicks & Expenses)')),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Date', 'Chicks Added', 'Chicks Cost', 'Medicine Cost', 'Grains Cost'],
              data: farmData.map((f) => [f.date, '${f.numberOfChicks}', fmt.format(f.chicksAmount), fmt.format(f.medicineAmount), fmt.format(f.grainsAmount)]).toList(),
            ),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Dead Chicks Record')),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Date', 'Notes', 'Count'],
              data: deadChicks.map((d) => [d.date, d.notes, '${d.count}']).toList(),
            ),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Customer Transactions (Income)')),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Date', 'Customer', 'Rate/kg', 'Total Amt', 'Pending'],
              data: customers.map((c) => [c.date, c.name, fmt.format(c.chickenRate), fmt.format(c.totalAmount), fmt.format(c.remainingAmount)]).toList(),
            ),
            pw.SizedBox(height: 20),

            pw.Header(level: 1, child: pw.Text('Labour Records (Wages)')),
            pw.TableHelper.fromTextArray(
              context: context,
              headers: ['Name', 'Role', 'Wage', 'Paid', 'Pending'],
              data: labours.map((l) => [l.name, l.role, fmt.format(l.dailyWage), fmt.format(l.totalPaid), fmt.format(l.remainingPayment)]).toList(),
            ),
          ];
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Farm_Report_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }
}
