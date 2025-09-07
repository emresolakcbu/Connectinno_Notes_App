import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'auth_cubit.dart';
import '../../ui/responsive/responsive.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.of(context).textScaler.clamp(maxScaleFactor: 1.2);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: BlocProvider(
        create: (_) => AuthCubit(FirebaseAuth.instance),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (!state.loading && state.error == null && FirebaseAuth.instance.currentUser != null) {
              context.go('/notes');
            }
            if (state.error != null) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
            }
          },
          child: Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xfff7f7f7), Color(0xffe3f2fd)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    final isWide = Responsive.isTablet(ctx) || Responsive.isDesktop(ctx);

                    final form = ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(ctx)),
                      child: Card(
                        elevation: 4,
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: Responsive.pagePadding(ctx),
                          child: _LoginForm(emailCtrl: emailCtrl, passCtrl: passCtrl),
                        ),
                      ),
                    );

                    return Center(
                      child: SingleChildScrollView(
                        padding: Responsive.pagePadding(ctx),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Üst kısım logo + başlık
                            Column(
                              children: [
                                Icon(Icons.note_alt_outlined, size: 72, color: Colors.blue.shade700),
                                const SizedBox(height: 12),
                                Text('Connectinno Notes',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey.shade800,
                                    )),
                                const SizedBox(height: 6),
                                Text(
                                  'Take notes, organize ideas, and sync anywhere.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                              ],
                            ),

                            // Form
                            isWide ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(child: form),
                                const SizedBox(width: 24),
                                Flexible(
                                  child: Image.asset(
                                    "assets/images/login_illustration.png",
                                    height: 220,
                                  ),
                                ),
                              ],
                            ) : form,

                            const SizedBox(height: 32),

                            // Alt kısım info
                            Align(
                              alignment: Alignment.center,
                              child: Text(
                                '© ${DateTime.now().year} Connectinno',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({required this.emailCtrl, required this.passCtrl});

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: Text('Login', style: Theme.of(context).textTheme.headlineSmall)),
        const SizedBox(height: 16),

        TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email'),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: passCtrl,
          decoration: const InputDecoration(labelText: 'Password'),
          obscureText: true,
        ),

        const SizedBox(height: 16),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(state.error!, style: const TextStyle(color: Colors.red)),
          ),

        state.loading
            ? const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CircularProgressIndicator(),
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => context.read<AuthCubit>().login(emailCtrl.text.trim(), passCtrl.text.trim()),
              child: const Text('Login'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.read<AuthCubit>().register(emailCtrl.text.trim(), passCtrl.text.trim()),
              child: const Text('Register'),
            ),
          ],
        ),
      ],
    );
  }
}
