import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xiaojia_ledger/core/constants.dart';
import 'package:xiaojia_ledger/core/router.dart';
import 'package:xiaojia_ledger/data/api/auth_api.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLogin = true;
  bool _loading = false;
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  String get _title => _isLogin ? '欢迎回来' : '创建账号';
  String get _buttonText => _isLogin ? '登 录' : '注 册';
  String get _switchText => _isLogin ? '还没有账号？' : '已有账号？';
  String get _switchLink => _isLogin ? '去注册' : '去登录';

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _usernameCtrl.clear();
      _passwordCtrl.clear();
      _password2Ctrl.clear();
    });
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      _showToast('请填写完整');
      return;
    }

    if (username.length < 2 || username.length > 12) {
      _showToast('用户名为2-12个字符');
      return;
    }

    if (password.length < 6) {
      _showToast('密码至少6位');
      return;
    }

    if (!_isLogin) {
      final password2 = _password2Ctrl.text;
      if (password != password2) {
        _showToast('两次密码不一致');
        return;
      }
    }

    setState(() => _loading = true);

    try {
      final result =
          _isLogin ? await AuthApi.login(username, password) : await AuthApi.register(username, password);

      if (result.isSuccess && result.data != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(AppConstants.tokenKey, result.data!.token);
        await prefs.setString(AppConstants.usernameKey, result.data!.username);

        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.home);
        }
      } else {
        _showToast(result.message);
      }
    } catch (e) {
      _showToast('网络错误，请检查连接');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 4,
                    color: Color(0xFF3D362F),
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(
                    hintText: '用户名',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  maxLength: 12,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(
                    hintText: '密码',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                if (!_isLogin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password2Ctrl,
                    decoration: const InputDecoration(
                      hintText: '确认密码',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_buttonText),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _switchText,
                      style: const TextStyle(color: Color(0xFFAAA098)),
                    ),
                    GestureDetector(
                      onTap: _toggleMode,
                      child: Text(
                        _switchLink,
                        style: const TextStyle(
                          color: Color(0xFFD4794A),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
