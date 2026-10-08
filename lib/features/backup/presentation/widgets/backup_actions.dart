import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/thai_date.dart';
import '../../domain/entities/backup_summary.dart';
import '../providers/backup_providers.dart';

/// ส่งออกข้อมูลเป็นไฟล์ JSON ผ่านหน้าแชร์ของระบบ (เก็บใน Drive, LINE, Files ฯลฯ)
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final json = ref.read(backupRepositoryProvider).exportJson();
  final now = DateTime.now();
  final date =
      '${now.year}-${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
  // iPad ต้องรู้ตำแหน่งปุ่มเพื่อวางหน้าแชร์
  final box = context.findRenderObject() as RenderBox?;

  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(utf8.encode(json), mimeType: 'application/json')],
      fileNameOverrides: ['healthy-body-backup-$date.json'],
      subject: 'สำรองข้อมูล Prachaya Healthy Body',
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// เลือกไฟล์สำรอง ให้ user ยืนยัน แล้วแทนที่ข้อมูลในเครื่อง
///
/// คืนค่า true เมื่อนำเข้าสำเร็จ
Future<bool> importBackup(BuildContext context, WidgetRef ref) async {
  final file = await FilePicker.pickFile();
  if (file == null || !context.mounted) return false;

  final String json;
  final BackupSummary summary;
  try {
    json = utf8.decode(await file.readAsBytes());
    summary = ref.read(backupRepositoryProvider).inspect(json);
  } on Object catch (e) {
    if (context.mounted) {
      _showMessage(
        context,
        e is InvalidBackupException
            ? 'นำเข้าไม่ได้: ${e.detail}'
            : 'อ่านไฟล์ไม่ได้ ลองเลือกไฟล์ .json ที่ส่งออกจากแอปนี้',
      );
    }
    return false;
  }
  if (!context.mounted) return false;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => _ConfirmImportDialog(summary: summary),
  );
  if (confirmed != true || !context.mounted) return false;

  await restoreBackup(ref, json);
  if (context.mounted) {
    _showMessage(context, 'นำเข้าข้อมูลแล้ว ${summary.entryCount} รายการ');
  }
  return true;
}

void _showMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

class _ConfirmImportDialog extends StatelessWidget {
  const _ConfirmImportDialog({required this.summary});

  final BackupSummary summary;

  @override
  Widget build(BuildContext context) {
    final exportedAt = summary.exportedAt;
    return AlertDialog(
      title: const Text('นำเข้าข้อมูล?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exportedAt != null)
            Text(
              'ไฟล์สำรองเมื่อ ${ThaiDate.short(exportedAt)} '
              '${exportedAt.year + 543} ${ThaiDate.time(exportedAt)}',
            ),
          const SizedBox(height: 8),
          Text(
            '• บันทึกการกิน ${summary.entryCount} รายการ '
            '(${summary.dayCount} วัน)\n'
            '• วัตถุดิบที่เก็บไว้ ${summary.ingredientCount} รายการ\n'
            '• ข้อมูลส่วนตัว: ${summary.hasProfile ? 'มี' : 'ไม่มี'}',
          ),
          const SizedBox(height: 12),
          const Text(
            'ข้อมูลที่อยู่ในเครื่องตอนนี้จะถูกแทนที่ทั้งหมด',
            style: TextStyle(
              color: AppColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('ยกเลิก'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('นำเข้า'),
        ),
      ],
    );
  }
}

/// การ์ดปุ่มส่งออก/นำเข้า ใช้ในหน้าแก้ไขข้อมูลส่วนตัว
class BackupCard extends ConsumerWidget {
  const BackupCard({super.key, this.onImported});

  /// เรียกหลังนำเข้าสำเร็จ เช่น ปิดหน้าที่แสดงข้อมูลเก่าอยู่
  final VoidCallback? onImported;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('สำรองข้อมูล', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'ข้อมูลเก็บอยู่ในเครื่องนี้เท่านั้น ส่งออกเก็บไว้ก่อนลบแอปหรือเปลี่ยนเครื่อง',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    // ใช้ context ของปุ่มเองเป็นตำแหน่งหน้าแชร์บน iPad
                    builder: (buttonContext) => OutlinedButton.icon(
                      icon: const Icon(Icons.ios_share_rounded),
                      label: const Text('ส่งออก'),
                      onPressed: () => exportBackup(buttonContext, ref),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('นำเข้า'),
                    onPressed: () async {
                      if (await importBackup(context, ref)) onImported?.call();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
