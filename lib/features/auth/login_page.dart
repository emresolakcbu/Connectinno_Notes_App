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
            body: SafeArea(
              child: LayoutBuilder(
                builder: (ctx, constraints) {
                  final isWide = Responsive.isTablet(ctx) || Responsive.isDesktop(ctx);

                  final form = ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: Responsive.maxContentWidth(ctx)),
                    child: Card(
                      elevation: 1,
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
                      child: isWide
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 24),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Connectinno Notes', style: Theme.of(context).textTheme.headlineMedium),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Login with your account and sync your notes.',
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Flexible(child: form),
                              ],
                            )
                          : form,
                    ),
                  );
                },
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
        Text('Login', style: Theme.of(context).textTheme.headlineSmall),
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
                child: Padding(padding: EdgeInsets.symmetric(vertical: 12), child: CircularProgressIndicator()),
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

        // Alt bilgi
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.center,
          child: Text('© ${DateTime.now().year} Connectinno', style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}
