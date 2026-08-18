import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

void main() => runApp(const HitungKasApp());

const teal = Color(0xFF1D4D56);
const tealDark = Color(0xFF153D45);
const lime = Color(0xFFC6FF3F);
const lavender = Color(0xFFD8C7FF);
const mint = Color(0xFFBFE8C9);
const cream = Color(0xFFF4F2EB);
const textColor = Color(0xFF173F47);
const muted = Color(0xFF78898D);

String rupiah(num value) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0)
        .format(value);

class MoneyItem {
  final int value;
  final Color bg;
  const MoneyItem(this.value, this.bg);
}

const notes = [
  MoneyItem(100000, lavender),
  MoneyItem(50000, Color(0xFFF5EADB)),
  MoneyItem(20000, mint),
  MoneyItem(10000, lavender),
  MoneyItem(5000, Color(0xFFF5EADB)),
  MoneyItem(2000, mint),
  MoneyItem(1000, Colors.white),
];

class HitungKasApp extends StatelessWidget {
  const HitungKasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hitung Kas',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans',
        scaffoldBackgroundColor: cream,
        colorScheme: ColorScheme.fromSeed(seedColor: teal),
      ),
      home: const HitungKasPage(),
    );
  }
}

class HitungKasPage extends StatefulWidget {
  const HitungKasPage({super.key});

  @override
  State<HitungKasPage> createState() => _HitungKasPageState();
}

class _HitungKasPageState extends State<HitungKasPage> {
  final Map<int, int> noteCount = {for (final n in notes) n.value: 0};
  final Map<int, int> coinCount = {1000: 0, 500: 0, 200: 0, 100: 0};

  int? activeNote = 100000;
  int? activeCoin;
  String inputValue = '';
  final receiptKey = GlobalKey();

  int get denomination => activeNote ?? activeCoin ?? 0;
  int get amount => int.tryParse(inputValue) ?? 0;

  int get total {
    var t = 0;
    for (final n in notes) {
      t += n.value * (noteCount[n.value] ?? 0);
    }
    for (final c in coinCount.keys) {
      t += c * (coinCount[c] ?? 0);
    }
    return t;
  }

  void selectNote(int value) {
    setState(() {
      activeNote = value;
      activeCoin = null;
      inputValue = '${noteCount[value] ?? 0}';
      if (inputValue == '0') inputValue = '';
    });
  }

  void selectCoin(int value) {
    setState(() {
      activeCoin = value;
      activeNote = null;
      inputValue = '${coinCount[value] ?? 0}';
      if (inputValue == '0') inputValue = '';
    });
  }

  void pressNumber(int number) {
    if (inputValue == '0') inputValue = '';
    if (inputValue.length >= 5) return;
    setState(() {
      inputValue += '$number';
      final v = int.tryParse(inputValue) ?? 0;
      if (activeNote != null) noteCount[activeNote!] = v;
      if (activeCoin != null) coinCount[activeCoin!] = v;
    });
  }

  void backspace() {
    setState(() {
      if (inputValue.isNotEmpty) {
        inputValue = inputValue.substring(0, inputValue.length - 1);
      }
      final v = int.tryParse(inputValue) ?? 0;
      if (activeNote != null) noteCount[activeNote!] = v;
      if (activeCoin != null) coinCount[activeCoin!] = v;
    });
  }

  Future<void> resetAll() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset hitungan?'),
        content: const Text('Semua jumlah uang akan dikembalikan ke nol.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
        ],
      ),
    );
    if (yes != true) return;
    setState(() {
      for (final n in notes) noteCount[n.value] = 0;
      for (final c in coinCount.keys) coinCount[c] = 0;
      activeNote = 100000;
      activeCoin = null;
      inputValue = '';
    });
  }

  String receiptText() {
    final now = DateTime.now();
    final date = DateFormat('dd/MM/yyyy').format(now);
    final time = DateFormat('HH:mm:ss').format(now);
    final no = 'STRUK-${DateFormat('yyyyMMdd').format(now)}-${1000 + now.millisecond}';

    final b = StringBuffer();
    b.writeln('CASH CONTROL');
    b.writeln('LAPORAN PERHITUNGAN KAS');
    b.writeln();
    b.writeln('TGL : $date     $time');
    b.writeln('NO  : $no');
    b.writeln('--------------------------------');
    var physical = 0;

    b.writeln('UANG KERTAS');
    for (final n in notes) {
      final q = noteCount[n.value] ?? 0;
      if (q > 0) {
        physical += q;
        b.writeln('${rupiah(n.value)} x $q lbr = ${rupiah(n.value * q)}');
      }
    }
    b.writeln('--------------------------------');
    b.writeln('UANG LOGAM');
    for (final c in [1000, 500, 200, 100]) {
      final q = coinCount[c] ?? 0;
      if (q > 0) {
        physical += q;
        b.writeln('${rupiah(c)} x $q kpg = ${rupiah(c * q)}');
      }
    }
    b.writeln('--------------------------------');
    b.writeln('TOTAL FISIK : $physical item');
    b.writeln('TOTAL KAS   : ${rupiah(total)}');
    b.writeln('--------------------------------');
    b.writeln('--- BUKTI FISIK SALDO KAS ---');
    b.writeln('TERIMA KASIH');
    return b.toString();
  }

  Future<Uint8List?> captureReceipt() async {
    final boundary =
        receiptKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> downloadJpgLike() async {
    final data = await captureReceipt();
    if (data == null || !mounted) return;
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/Struk_Kas_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(data);
    await Share.shareXFiles([XFile(file.path)], text: 'Struk perhitungan kas ${rupiah(total)}');
  }

  Future<void> shareReceipt() async {
    final data = await captureReceipt();
    if (data == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/Struk_Kas_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(data);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: 'LAPORAN KAS FISIK\nTotal: ${rupiah(total)}',
      subject: 'Struk Perhitungan Kas',
    );
  }

  void openReceipt() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReceiptSheet(
        receiptKey: receiptKey,
        notes: notes,
        noteCount: noteCount,
        coinCount: coinCount,
        total: total,
        receiptText: receiptText(),
        onSave: downloadJpgLike,
        onShare: shareReceipt,
      ),
    );
  }

  Widget moneyCard(MoneyItem item) {
    final value = item.value;
    final active = activeNote == value;
    final count = noteCount[value] ?? 0;
    return GestureDetector(
      onTap: () => selectNote(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: item.bg,
          borderRadius: BorderRadius.circular(16),
          border: active ? Border.all(color: lime, width: 3) : null,
          boxShadow: const [BoxShadow(color: Color(0x12203C46), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 115,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Rp${NumberFormat('#,###', 'id_ID').format(value)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: teal),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(rupiah(value), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(rupiah(value * count), style: const TextStyle(fontSize: 9, color: muted, fontWeight: FontWeight.w700)),
              ],
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 28),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                height: 25,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.88), borderRadius: BorderRadius.circular(8)),
                child: Text('$count', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget coinCard(int value) {
    final active = activeCoin == value;
    return GestureDetector(
      onTap: () => selectCoin(value),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: active ? Border.all(color: lime, width: 3) : null,
          boxShadow: const [BoxShadow(color: Color(0x0D143C46), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(rupiah(value), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text('${coinCount[value]} keping', style: const TextStyle(fontSize: 8, color: muted, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cream,
                borderRadius: BorderRadius.circular(27),
                boxShadow: const [BoxShadow(color: Color(0x16203C46), blurRadius: 30, offset: Offset(0, 12))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CASH CONTROL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 2, color: muted)),
                          SizedBox(height: 2),
                          Text('Hitung Kas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                        ],
                      ),
                      IconButton(
                        onPressed: resetAll,
                        icon: const Icon(Icons.refresh_rounded, size: 25),
                        style: IconButton.styleFrom(backgroundColor: Colors.white, foregroundColor: teal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: notes.length,
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 7,
                              mainAxisSpacing: 7,
                              childAspectRatio: .70,
                            ),
                            itemBuilder: (_, i) => moneyCard(notes[i]),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            children: [
                              Expanded(
                                flex: 9,
                                child: Container(
                                  height: 59,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: teal, borderRadius: BorderRadius.circular(15)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('NOMINAL AKTIF', style: TextStyle(fontSize: 8, color: Color(0xFFA9C2C5), fontWeight: FontWeight.w800, letterSpacing: 1)),
                                      const SizedBox(height: 3),
                                      Text(rupiah(denomination), style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                flex: 12,
                                child: Container(
                                  height: 59,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('HASIL', style: TextStyle(fontSize: 8, color: muted, fontWeight: FontWeight.w800, letterSpacing: 1)),
                                      const SizedBox(height: 3),
                                      Text(rupiah(denomination * amount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                            decoration: BoxDecoration(color: lime, borderRadius: BorderRadius.circular(15)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL UANG', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                Text(rupiah(total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: openReceipt,
                              icon: const Icon(Icons.receipt_long_rounded, size: 18),
                              label: const Text('Lihat / Buat Struk Gambar'),
                              style: FilledButton.styleFrom(
                                backgroundColor: teal,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Uang Logam', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
                              const Text('JUMLAH KEPING', style: TextStyle(fontSize: 8, color: muted, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(child: coinCard(1000)),
                              const SizedBox(width: 6),
                              Expanded(child: coinCard(500)),
                              const SizedBox(width: 6),
                              Expanded(child: coinCard(200)),
                              const SizedBox(width: 6),
                              Expanded(child: coinCard(100)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 3,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                            childAspectRatio: 1.45,
                            children: [
                              for (final n in [1,2,3,4,5,6,7,8,9])
                                keyButton('$n', () => pressNumber(n)),
                              const SizedBox.shrink(),
                              keyButton('0', () => pressNumber(0)),
                              keyButton('←', backspace, dark: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget keyButton(String label, VoidCallback onTap, {bool dark = false}) {
    return Material(
      color: dark ? teal : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark ? Colors.white : teal)),
        ),
      ),
    );
  }
}

class ReceiptSheet extends StatelessWidget {
  final GlobalKey receiptKey;
  final List<MoneyItem> notes;
  final Map<int,int> noteCount;
  final Map<int,int> coinCount;
  final int total;
  final String receiptText;
  final VoidCallback onSave;
  final VoidCallback onShare;

  const ReceiptSheet({
    super.key,
    required this.receiptKey,
    required this.notes,
    required this.noteCount,
    required this.coinCount,
    required this.total,
    required this.receiptText,
    required this.onSave,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    var physical = 0;
    return Container(
      height: MediaQuery.of(context).size.height * .88,
      decoration: const BoxDecoration(
        color: Color(0xFFEEF2F3),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 9),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(9))),
          const SizedBox(height: 9),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(15),
              child: RepaintBoundary(
                key: receiptKey,
                child: Container(
                  width: 290,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                  color: Colors.white,
                  child: DefaultTextStyle(
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.black, fontSize: 11, height: 1.35),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('CASH CONTROL', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                        const Text('LAPORAN PERHITUNGAN KAS', textAlign: TextAlign.center, style: TextStyle(fontSize: 9, color: Colors.black54)),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('TGL : ${DateFormat('dd/MM/yyyy').format(now)}'),
                          Text(DateFormat('HH:mm:ss').format(now)),
                        ]),
                        const Text('NO  : STRUK-${DateFormat('yyyyMMdd').format(now)}'),
                        const Divider(height: 16),
                        const Text('UANG KERTAS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
                        for (final n in notes)
                          if ((noteCount[n.value] ?? 0) > 0)
                            Builder(builder: (_) {
                              final q = noteCount[n.value]!;
                              physical += q;
                              return Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${rupiah(n.value)} x $q lbr'),
                                    Text(rupiah(n.value * q)),
                                  ],
                                ),
                              );
                            }),
                        const Divider(height: 16),
                        const Text('UANG LOGAM', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
                        for (final c in [1000,500,200,100])
                          if ((coinCount[c] ?? 0) > 0)
                            Builder(builder: (_) {
                              final q = coinCount[c]!;
                              physical += q;
                              return Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [Text('${rupiah(c)} x $q kpg'), Text(rupiah(c*q))],
                                ),
                              );
                            }),
                        const Divider(height: 16),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('TOTAL FISIK'), Text('$physical item')]),
                        const SizedBox(height: 4),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('TOTAL KAS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                          Text(rupiah(total), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                        ]),
                        const Divider(height: 16),
                        const Text('--- BUKTI FISIK SALDO KAS ---', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, color: Colors.black54)),
                        const SizedBox(height: 3),
                        const Text('TERIMA KASIH', textAlign: TextAlign.center, style: TextStyle(fontSize: 8.5, color: Colors.black54)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: FilledButton.icon(onPressed: onSave, icon: const Icon(Icons.save_alt_rounded), label: const Text('Simpan Gambar'))),
                    const SizedBox(width: 6),
                    Expanded(child: FilledButton.icon(onPressed: onShare, icon: const Icon(Icons.share_rounded), label: const Text('Kirim WA'))),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
