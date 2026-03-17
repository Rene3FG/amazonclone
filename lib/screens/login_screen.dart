import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../core/theme.dart';
import '../widgets/shared_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  bool _rememberMe   = false;
  bool _hidePassword = true;
  bool _isRegister   = false;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _isRegister = _tabController.index == 1);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_isRegister) {
      context.read<AuthBloc>().add(RegisterRequested(
        email:    _emailCtrl.text.trim(),
        password: _passCtrl.text,
      ));
    } else {
      context.read<AuthBloc>().add(LoginRequested(
        email:      _emailCtrl.text.trim(),
        password:   _passCtrl.text,
        rememberMe: _rememberMe,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: BlocListener<AuthBloc, AppAuthState>(
        listener: (context, state) {
          if (state is AppAuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppColors.danger),
            );
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                
                SlideIn(
                  child: const Text('amazon',
                    style: TextStyle(
                      color:      Colors.white,
                      fontSize:   38,
                      fontWeight: FontWeight.bold,
                      fontStyle:  FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                SlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: Container(
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: const BorderRadius.all(kR8),
                      border:       Border.all(color: AppColors.line),
                    ),
                    child: Column(children: [
                      
                      TabBar(
                        controller:             _tabController,
                        labelColor:             AppColors.orange,
                        unselectedLabelColor:   AppColors.muted,
                        indicatorColor:         AppColors.orange,
                        indicatorSize:          TabBarIndicatorSize.tab,
                        dividerColor:           AppColors.line,
                        tabs: const [
                          Tab(text: 'Iniciar sesión'),
                          Tab(text: 'Registrarse'),
                        ],
                      ),

                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(children: [
                            AppTextField(
                              controller:  _emailCtrl,
                              hint:        'Correo electrónico',
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon:  const Icon(Icons.email_outlined),
                              validator:   (v) {
                                if (v == null || v.trim().isEmpty) return 'Requerido';
                                if (!v.contains('@')) return 'Correo inválido';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            AppTextField(
                              controller:  _passCtrl,
                              hint:        'Contraseña',
                              obscureText: _hidePassword,
                              prefixIcon:  const Icon(Icons.lock_outline),
                              suffixIcon:  IconButton(
                                icon: Icon(
                                  _hidePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 18,
                                ),
                                onPressed: () =>
                                    setState(() => _hidePassword = !_hidePassword),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Requerido';
                                if (v.length < 6) return 'Mínimo 6 caracteres';
                                return null;
                              },
                            ),

                            if (!_isRegister) ...[
                              const SizedBox(height: 6),
                              Row(children: [
                                Checkbox(
                                  value:      _rememberMe,
                                  onChanged:  (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                  activeColor: AppColors.orange,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                const Text('Recordar mis datos',
                                    style: TextStyle(fontSize: 13)),
                              ]),
                            ],
                            const SizedBox(height: 12),

                            BlocBuilder<AuthBloc, AppAuthState>(
                              builder: (_, state) => AppButton(
                                label:     _isRegister ? 'Crear cuenta' : 'Continuar',
                                onTap:     _submit,
                                isLoading: state is AppAuthLoading,
                              ),
                            ),

                            const SizedBox(height: 14),
                            Row(children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('o',
                                    style: TextStyle(color: AppColors.muted)),
                              ),
                              const Expanded(child: Divider()),
                            ]),
                            const SizedBox(height: 14),

                            OutlinedButton(
                              onPressed: () =>
                                  context.read<AuthBloc>().add(GoogleLoginRequested()),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 44),
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(kR8)),
                                side: const BorderSide(color: AppColors.line),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata,
                                      size: 22, color: Colors.red[400]),
                                  const SizedBox(width: 8),
                                  const Text('Continuar con Google',
                                      style: TextStyle(
                                          color: AppColors.ink, fontSize: 14)),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                ),

                const SizedBox(height: 16),
                SlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Text(
                    'Al continuar aceptas nuestras Condiciones de uso.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
