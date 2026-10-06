import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({this.register = false, super.key});
  final bool register;

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final repo = AuthRepository();
  late bool register;
  bool loading = false;
  bool obscure = true;

  @override
  void initState() { super.initState(); register = widget.register; }

  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      final response = register
          ? await repo.signUp(email: email.text, password: password.text, name: name.text)
          : await repo.signIn(email: email.text, password: password.text);
      if (!mounted) return;
      if (register && response.session == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء الحساب. تحقق من بريدك الإلكتروني لتفعيله.')));
        setState(() => register = false);
      } else {
        context.go('/');
      }
    } on AuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ غير متوقع، حاول مرة أخرى.')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Form(
              key: formKey,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                CircleAvatar(radius: 36, backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: .1), child: Icon(LucideIcons.home, color: Theme.of(context).colorScheme.primary, size: 34)),
                const SizedBox(height: 22),
                Text(register ? 'حياك في حيّنا' : 'حياك الله في حيّنا', textAlign: TextAlign.center, style: const TextStyle(fontSize: 29, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(register ? 'أنشئ حسابك وابدأ اكتشاف حيّك' : 'سجّل دخولك وكمل تجربتك', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 30),
                if (register) ...[
                  TextFormField(controller: name, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'الاسم', prefixIcon: Icon(LucideIcons.userRound)), validator: (v) => v == null || v.trim().length < 2 ? 'اكتب اسمك' : null),
                  const SizedBox(height: 14),
                ],
                TextFormField(controller: email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(LucideIcons.mail)), validator: (v) => v == null || !v.contains('@') ? 'أدخل بريدًا إلكترونيًا صحيحًا' : null),
                const SizedBox(height: 14),
                TextFormField(
                  controller: password, obscureText: obscure, onFieldSubmitted: (_) => submit(),
                  decoration: InputDecoration(labelText: 'كلمة المرور', prefixIcon: const Icon(LucideIcons.lockKeyhole), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? LucideIcons.eye : LucideIcons.eyeOff))),
                  validator: (v) => v == null || v.length < 6 ? 'كلمة المرور 6 أحرف على الأقل' : null,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: loading ? null : submit,
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(register ? 'إنشاء الحساب' : 'تسجيل الدخول', style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 10),
                TextButton(onPressed: loading ? null : () => setState(() => register = !register), child: Text(register ? 'عندي حساب — تسجيل الدخول' : 'ليس لدي حساب — إنشاء حساب')),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}
