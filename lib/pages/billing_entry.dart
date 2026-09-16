import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/billing_record_model.dart';
import '../services/database_helper.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';

class BillingEntry extends StatefulWidget {
  final BillingRecordModel billingRecord;
  final String action;
  const BillingEntry({
    super.key,
    required this.action,
    required this.billingRecord,
  });

  @override
  State<BillingEntry> createState() => _BillingEntryState();
}

class _BillingEntryState extends State<BillingEntry> {
  late BillingRecordModel newBillingRecord;
  late String title, buttonText;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _monthController = TextEditingController();

  @override
  void initState() {
    super.initState();
    title = widget.action == 'add'
        ? 'Billing Entry (ADD)'
        : 'Billing Entry (EDIT)';
    buttonText = widget.action == 'add' ? 'Add' : 'Update';
    newBillingRecord = widget.billingRecord;
  }

  @override
  void dispose() {
    _monthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // User ID
              TextFormField(
                initialValue: newBillingRecord.userId,
                decoration: InputDecoration(
                  labelText: 'รหัสผู้ใช้ไฟฟ้า (User ID)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'กรุณากรอก User ID' : null,
                onSaved: (value) => newBillingRecord.userId = value!,
              ),
              SizedBox(height: 15),

              // Month (with month picker)
              TextFormField(
                controller: _monthController,
                decoration: InputDecoration(
                  labelText: 'เดือน/ปี',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: () async {
                      String pickerDate = await selectMonth();
                      setState(() {
                        newBillingRecord.month = pickerDate;
                        // 2. อัปเดตค่าใน Controller เพื่อให้ตัวหนังสือเปลี่ยนบนหน้าจอ
                        _monthController.text = pickerDate;
                      });
                    },
                  ),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'กรุณากรอกเดือน/ปี' : null,
                onSaved: (value) => newBillingRecord.month = value!,
              ),
              SizedBox(height: 15),

              // Units (เลขจำนวนเต็ม)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'จำนวนหน่วย (Units)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'กรุณากรอกจำนวนหน่วย';
                  if (int.tryParse(value) == null)
                    return 'กรุณากรอกเป็นตัวเลขจำนวนเต็ม';
                  return null;
                },
                onSaved: (value) => newBillingRecord.units = int.parse(value!),
              ),
              SizedBox(height: 15),

              // Amount (เลขทศนิยม)
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'ยอดเงิน (Amount)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value!.isEmpty) return 'กรุณากรอกยอดเงิน';
                  if (double.tryParse(value) == null)
                    return 'กรุณากรอกเป็นตัวเลขทศนิยม';
                  return null;
                },
                onSaved: (value) =>
                    newBillingRecord.amount = double.parse(value!),
              ),
              SizedBox(height: 20),

              // Paid Status (Radio Buttons)
              Text(
                'สถานะการชำระเงิน:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              RadioGroup<String>(
                // กำหนดค่าที่เลือกในปัจจุบันไว้ที่นี่ที่เดียว
                groupValue: newBillingRecord.paidStatus,

                // เมื่อมีการเปลี่ยนค่าในกลุ่มนี้
                onChanged: (value) {
                  if (value != null) {
                    setState(() => newBillingRecord.paidStatus = value);
                  }
                },

                // ใส่ปุ่ม Radio ต่างๆ ลงใน child
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('ยังไม่ได้ชำระ (Unpaid)'),
                      value: 'Unpaid',
                      // ไม่ต้องใส่ groupValue หรือ selectionValue แล้ว
                    ),
                    RadioListTile<String>(
                      title: const Text('ชำระแล้ว (Paid)'),
                      value: 'Paid',
                      // ไม่ต้องใส่ groupValue หรือ selectionValue แล้ว
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Submit Button
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text('บันทึกข้อมูล', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save(); // บันทึกข้อมูลจากฟอร์มลงใน newBillingRecord
      processBillingEntry(newBillingRecord); // เรียกฟังก์ชันเพื่อบันทึกข้อมูลลงฐานข้อมูล      
    }
  }

  Future<void> processBillingEntry(dynamic billingRecord) async {
    if (widget.action == 'add') {
      try {
        await DatabaseHelper().addBillingRecord(billingRecord);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Billing record added successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add billing record: $error'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (widget.action == 'edit') {
      try {
        await DatabaseHelper().updateBillingRecord(
          widget.billingRecord.referenceId!,
          billingRecord,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Billing record updated successfully!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update billing record: $error'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<String> selectMonth() async {
    final selected = await showMonthPicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2080),
    );
    if (selected != null) {
      return DateFormat('MMMM yyyy').format(selected);
    }
    return DateFormat('MMMM yyyy').format(DateTime.now());
  }
}
