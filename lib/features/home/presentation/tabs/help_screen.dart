import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المساعدة'),
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        elevation: 1,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
        ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            ListTile(
              leading: const Icon(Icons.rule, color: Colors.blue),
              title: const Text('شروط الإعلان'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('شروط الإعلان'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('• يجب أن يكون محتوى الإعلان واضح وصحيح وخالي من الاحتيال.'),
                        SizedBox(height: 8),
                        Text('• يمنع نشر إعلانات تحوي على ألفاظ نابية أو محتوى مسيء.'),
                        SizedBox(height: 8),
                        Text('• يمنع نشر إعلانات عن مواد مخالفة للقانون أو الأخلاق.'),
                        SizedBox(height: 8),
                        Text('• لإدارة منصة فرصة الحق بحذف أي إعلان غير مطابق للشروط بدون الرجوع لصاحب الإعلان.'),
                      ],
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    titleTextStyle: Theme.of(context).textTheme.titleLarge,
                    contentTextStyle: Theme.of(context).textTheme.bodyMedium,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.question_answer, color: Colors.orange),
              title: const Text('الأسئلة الشائعة'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('الأسئلة الشائعة'),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('• كيف يمكنني نشر إعلان جديد؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('يمكنك نشر إعلان جديد من خلال الضغط على زر (+) في الصفحة الرئيسية واتباع التعليمات.'),
                          SizedBox(height: 12),
                          Text('• كم تستغرق عملية مراجعة الإعلان؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('عادةً تتم مراجعة الإعلان خلال ساعات قليلة، وقد تستغرق حتى 24 ساعة كحد أقصى.'),
                          SizedBox(height: 12),
                          Text('• هل يمكنني تعديل الإعلان بعد نشره؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('نعم، يمكنك تعديل بيانات إعلانك من خلال صفحة "إعلاناتي" واختيار الإعلان المطلوب.'),
                          SizedBox(height: 12),
                          Text('• كيف أتواصل مع البائع؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('يمكنك التواصل مع البائع عبر زر الاتصال أو الدردشة الموجود في صفحة الإعلان.'),
                          SizedBox(height: 12),
                          Text('• ما هي الإعلانات الممنوعة والمرفوضة؟', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('يمنع نشر أي إعلان مخالف للقانون أو الأخلاق أو يحتوي على احتيال أو إساءة. لمزيد من التفاصيل راجع شروط الإعلان.'),
                        ],
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    titleTextStyle: Theme.of(context).textTheme.titleLarge,
                    contentTextStyle: Theme.of(context).textTheme.bodyMedium,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('اتصل بنا'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('اتصل بنا'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('للتواصل عبر البريد الإلكتروني:'),
                        const SizedBox(height: 6),
                        SelectableText('support@forsa.com', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        const Text('رقم الدعم الفني:'),
                        const SizedBox(height: 6),
                        SelectableText('905510300730', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: Image.asset(
                            'assets/flags/sy.png',
                            width: 22,
                            height: 22,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(120, 40),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          label: const Text('تواصل واتساب'),
                          onPressed: () async {
                            final url = Uri.parse('https://wa.me/905510300730');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text('وسائل التواصل الاجتماعي:'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.facebook, color: Colors.blue[800]),
                            SizedBox(width: 8),
                            SelectableText('facebook.com/forsaApp'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.telegram, color: Colors.blue),
                            SizedBox(width: 8),
                            SelectableText('t.me/forsaApp'),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.camera_alt, color: Colors.purple),
                            SizedBox(width: 8),
                            SelectableText('instagram.com/forsaApp'),
                          ],
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    titleTextStyle: Theme.of(context).textTheme.titleLarge,
                    contentTextStyle: Theme.of(context).textTheme.bodyMedium,
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إغلاق'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
