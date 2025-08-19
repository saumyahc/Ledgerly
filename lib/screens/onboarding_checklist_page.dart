import 'package:flutter/material.dart';
import '../theme.dart';
import 'home_page.dart';

class OnboardingChecklistPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String userEmail;

  const OnboardingChecklistPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.userEmail,
  });

  @override
  State<OnboardingChecklistPage> createState() =>
      _OnboardingChecklistPageState();
}

enum TaskStatus { pending, inProgress, completed, skipped }

class _OnboardingChecklistPageState extends State<OnboardingChecklistPage>
    with SingleTickerProviderStateMixin {
  // Task states
  TaskStatus walletStatus = TaskStatus.pending;
  TaskStatus paymentStatus = TaskStatus.pending;
  TaskStatus balanceStatus = TaskStatus.pending;

  bool get allDone =>
      walletStatus == TaskStatus.completed &&
      (paymentStatus == TaskStatus.completed ||
          paymentStatus == TaskStatus.skipped) &&
      (balanceStatus == TaskStatus.completed ||
          balanceStatus == TaskStatus.skipped);

  int get completedCount {
    int count = 0;
    if (walletStatus == TaskStatus.completed) count++;
    if (paymentStatus == TaskStatus.completed) count++;
    if (balanceStatus == TaskStatus.completed) count++;
    return count;
  }

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.04).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startWallet() {
    setState(() => walletStatus = TaskStatus.inProgress);
    // Simulate wallet creation
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => walletStatus = TaskStatus.completed);
    });
  }

  void _startPayment() {
    setState(() => paymentStatus = TaskStatus.inProgress);
    // Simulate payment
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => paymentStatus = TaskStatus.completed);
    });
  }

  void _skipPayment() {
    setState(() => paymentStatus = TaskStatus.skipped);
  }

  void _startBalance() {
    setState(() => balanceStatus = TaskStatus.inProgress);
    // Simulate balance check
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => balanceStatus = TaskStatus.completed);
    });
  }

  void _skipBalance() {
    setState(() => balanceStatus = TaskStatus.skipped);
  }

  @override
  void didUpdateWidget(covariant OnboardingChecklistPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkAndNavigateToHome();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndNavigateToHome();
  }

  void _checkAndNavigateToHome() {
    if (allDone) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(
              userId: widget.userId,
              userName: widget.userName,
              userEmail: widget.userEmail,
            ),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Call navigation check in build as well (safe due to Future.microtask)
    _checkAndNavigateToHome();
    return AnimatedBackground(
      child: TouchEffectOverlay(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              "Let's Get Started!",
              style: TextStyle(color: Colors.black),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Your Onboarding Checklist',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      _buildProgressBar(),
                      const SizedBox(height: 20),
                      // Task 1: Create Wallet
                      _buildTaskCard(
                        index: 1,
                        title: 'Create Your Wallet',
                        description:
                            'Your secure digital wallet is where your money lives. This is required to use Ledgerly.',
                        status: walletStatus,
                        isMandatory: true,
                        onAction: _startWallet,
                        actionLabel: 'Create Wallet',
                        locked: false,
                        isCurrent: walletStatus == TaskStatus.pending,
                      ),
                      const SizedBox(height: 16),
                      // Task 2: Make Payment
                      _buildTaskCard(
                        index: 2,
                        title: 'Make Your First Payment',
                        description:
                            'Experience the ease of sending money with your new wallet.',
                        status: paymentStatus,
                        isMandatory: false,
                        onAction: _startPayment,
                        onSkip: _skipPayment,
                        actionLabel: 'Make Payment',
                        locked: walletStatus != TaskStatus.completed,
                        isCurrent:
                            walletStatus == TaskStatus.completed &&
                            paymentStatus == TaskStatus.pending,
                      ),
                      const SizedBox(height: 16),
                      // Task 3: Check Balance
                      _buildTaskCard(
                        index: 3,
                        title: 'Check Your Balance',
                        description:
                            'See your funds and track your transactions.',
                        status: balanceStatus,
                        isMandatory: false,
                        onAction: _startBalance,
                        onSkip: _skipBalance,
                        actionLabel: 'View Balance',
                        locked: walletStatus != TaskStatus.completed,
                        isCurrent:
                            walletStatus == TaskStatus.completed &&
                            paymentStatus != TaskStatus.pending &&
                            balanceStatus == TaskStatus.pending,
                      ),
                      const SizedBox(height: 32),
                      if (allDone)
                        Column(
                          children: [
                            Text(
                              "You're all set!",
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: AppColors.primary),
                            ),
                            const SizedBox(height: 16),
                            // Removed Go to Dashboard button
                          ],
                        ),
                      if (!allDone)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            'You can revisit skipped tasks later in Settings.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.black54,
                                  fontStyle: FontStyle.italic,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: completedCount / 3,
          backgroundColor: AppColors.glass,
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 10,
        ),
        const SizedBox(height: 8),
        Text(
          '$completedCount of 3 Tasks Completed',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildTaskCard({
    required int index,
    required String title,
    required String description,
    required TaskStatus status,
    required bool isMandatory,
    required VoidCallback onAction,
    VoidCallback? onSkip,
    required String actionLabel,
    required bool locked,
    bool isCurrent = false,
  }) {
    final isLocked = locked && status == TaskStatus.pending;
    final highlightColor = isCurrent
        ? AppColors.primary.withOpacity(0.18)
        : Colors.transparent;
    final borderColor = isCurrent ? AppColors.primary : Colors.transparent;
    final shadow = isCurrent
        ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ]
        : [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ];
    Widget card = Glass3DCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('$index.', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: isMandatory ? AppColors.primary : AppColors.secondary,
                ),
              ),
              if (isMandatory)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Required',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          if (status == TaskStatus.pending && !isLocked)
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Neumorphic3DButton(
                      onTap: onAction,
                      child: Text(actionLabel),
                    ),
                  ),
                ),
                if (!isMandatory && onSkip != null)
                  TextButton(
                    onPressed: onSkip,
                    child: const Text('Skip for now'),
                  ),
              ],
            ),
          if (status == TaskStatus.inProgress)
            Row(
              children: const [
                CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
                SizedBox(width: 12),
                Text('Processing...'),
              ],
            ),
          if (status == TaskStatus.completed)
            Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Completed', style: TextStyle(color: Colors.green)),
              ],
            ),
          if (status == TaskStatus.skipped)
            Row(
              children: const [
                Icon(Icons.undo, color: Colors.orange),
                SizedBox(width: 8),
                Text('Skipped', style: TextStyle(color: Colors.orange)),
              ],
            ),
        ],
      ),
    );
    if (isCurrent) {
      card = ScaleTransition(
        scale: _pulseAnimation,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2.5),
            borderRadius: BorderRadius.circular(32),
            color: highlightColor,
            boxShadow: shadow,
          ),
          child: Container(
            constraints: BoxConstraints(minHeight: 110),
            child: card,
          ),
        ),
      );
    } else {
      card = Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 2.5),
          borderRadius: BorderRadius.circular(32),
          color: highlightColor,
          boxShadow: shadow,
        ),
        child: Container(
          constraints: BoxConstraints(minHeight: 110),
          child: card,
        ),
      );
    }
    return Opacity(opacity: isLocked ? 0.5 : 1.0, child: card);
  }
}
