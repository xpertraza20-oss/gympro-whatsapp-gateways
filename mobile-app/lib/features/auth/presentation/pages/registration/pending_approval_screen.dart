import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/phone_auth_bloc.dart';

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFBA5F06); // Amber/orange theme indicating pending
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 3),
              
              // Visual Icon Container
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryColor.withOpacity(0.15), width: 2),
                  ),
                  child: const Icon(
                    Icons.hourglass_empty_rounded,
                    color: primaryColor,
                    size: 72,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Headline & Tagline
              const Text(
                'Application Pending',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Your profile registration request has been submitted and is currently under review by our Admin team. We will notify you once your account is active.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ),
              
              const Spacer(flex: 2),

              // Call to Actions
              ElevatedButton.icon(
                onPressed: () {
                  // Re-trigger auth status check to refresh profile status from backend
                  context.read<PhoneAuthBloc>().add(CheckAuthStatusEvent());
                },
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Refresh Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                ),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton.icon(
                onPressed: () {
                  // Perform logout and route back to Role Selection
                  context.read<PhoneAuthBloc>().add(LogoutEvent());
                  Navigator.of(context).pushNamedAndRemoveUntil('/welcome', (_) => false);
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.black.withOpacity(0.08)),
                ),
              ),
              
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
