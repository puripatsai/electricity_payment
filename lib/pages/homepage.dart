import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/billing_record_model.dart';
import '../services/database_helper.dart';
import 'billing_entry.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<BillingRecordModel> billingItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(widget.title, style: TextStyle(fontSize: 18)),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder(
        stream: DatabaseHelper().getStreamBillingRecords(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No billing records found.'));
          }
          return _buildListView(snapshot);
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: Padding(padding: const EdgeInsets.all(12.0)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        shape: CircleBorder(),
        tooltip: 'Add Electricity Payment Entry',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BillingEntry(
                action: 'add',
                billingRecord: BillingRecordModel(
                  userId: 'U001',
                  month: DateFormat('MMMM yyyy').format(DateTime.now()),
                  units: 0,
                  amount: 0.0,
                  paidStatus: 'Paid',
                ),
              ),
            ),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // แสดง dialog ยืนยันก่อนลบทุกครั้ง (Yes/No) ตามที่โจทย์การบ้าน #6 กำหนด
  Future<bool> _confirmDelete(BillingRecordModel record) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('ยืนยันการลบข้อมูล'),
          content: Text(
            'ต้องการลบรายการเดือน ${record.month} ของ ${record.userId} ใช่หรือไม่?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  // ไปหน้าฟอร์มแก้ไข พร้อมส่งค่าเดิมของรายการที่เลือกไปแสดงในฟอร์ม
  void _goToEditForm(BillingRecordModel record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BillingEntry(action: 'edit', billingRecord: record),
      ),
    );
  }

  // Build the ListView for displaying billing records
  Widget _buildListView(AsyncSnapshot snapshot) {
    billingItems.clear();
    for (var doc in snapshot.data!.docs) {
      billingItems.add(
        BillingRecordModel(
          userId: doc.get('userId'),
          month: doc.get('month'),
          units: doc.get('units') as int,
          amount: doc.get('amount') is int
              ? (doc.get('amount') as int).toDouble()
              : doc.get('amount') as double,
          paidStatus: doc.get('paidStatus'),
          referenceId: doc.id,
        ),
      ); // Update the snapshot data with the model
    }
    // Sort the billing items by month
    billingItems.sort((a, b) {
      // ใช้ DateFormat จากแพ็กเกจ intl เพื่อแปลง String เป็น DateTime
      DateFormat format = DateFormat("MMMM yyyy");

      DateTime dateA = format.parse(a.month);
      DateTime dateB = format.parse(b.month);

      return dateA.compareTo(dateB);
    });

    return ListView.separated(
      itemCount: billingItems.length,
      itemBuilder: (BuildContext context, int index) {
        final record = billingItems[index];
        String titleDate = record.month;
        String paidStatusText = record.paidStatus == 'Paid'
            ? 'ชำระแล้ว'
            : 'ยังไม่ชำระ';
        String subtitle =
            "หน่วยที่ใช้ ${record.units} หน่วย, ${record.amount} บาท\n$paidStatusText";

        return Slidable(
          key: ValueKey(record.referenceId),

          // ---- Swipe จากซ้ายไปขวา -> โผล่ไอคอนแก้ไข ----
          startActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) => _goToEditForm(record),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                icon: Icons.edit,
                label: 'แก้ไข',
              ),
            ],
          ),

          // ---- Swipe จากขวาไปซ้าย -> โผล่ไอคอนลบ ----
          endActionPane: ActionPane(
            motion: const DrawerMotion(),
            extentRatio: 0.25,
            children: [
              SlidableAction(
                onPressed: (_) async {
                  final confirmed = await _confirmDelete(record);
                  if (confirmed && record.referenceId != null) {
                    await DatabaseHelper().deleteBillingRecord(
                      record.referenceId!,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ลบรายการเรียบร้อยแล้ว')),
                      );
                    }
                  }
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                icon: Icons.delete,
                label: 'ลบ',
              ),
            ],
          ),

          child: ListTile(
            title: Text(
              titleDate,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle, style: TextStyle(fontSize: 14)),
            // แตะที่รายการ (จากหน้าไปหลัง) ก็เปิดฟอร์มแก้ไขได้เช่นกัน ตามที่โจทย์ระบุ
            onTap: () => _goToEditForm(record),
          ),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return Divider(color: Colors.grey);
      },
    );
  }
}
