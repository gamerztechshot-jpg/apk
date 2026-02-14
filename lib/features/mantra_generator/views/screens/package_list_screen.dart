// features/mantra_generator/views/screens/package_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import 'package:karmasu/core/services/auth_service.dart';
import '../../viewmodels/package_viewmodel.dart';
import '../widgets/package_card.dart';
import 'package_purchase_screen.dart';

class PackageListScreen extends StatefulWidget {
  const PackageListScreen({super.key});

  @override
  State<PackageListScreen> createState() => _PackageListScreenState();
}

class _PackageListScreenState extends State<PackageListScreen> {
  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.getCurrentUser()?.id;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isHindi ? 'पैकेज' : 'Packages',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: userId == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHindi
                        ? 'कृपया लॉगिन करें'
                        : 'Please login to view packages',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ChangeNotifierProvider(
              create: (_) {
                final viewModel = PackageViewModel();
                viewModel.initialize(userId);
                viewModel.loadPackages();
                viewModel.getUserPackage();
                return viewModel;
              },
              child: Consumer<PackageViewModel>(
                builder: (context, viewModel, child) {
                  return Column(
                    children: [
                      // Active Package Banner (if exists)
                      if (viewModel.userActivePackage != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade50,
                                Colors.green.shade100,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.shade200,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isHindi
                                          ? 'सक्रिय पैकेज'
                                          : 'Active Package',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      viewModel.userActivePackage!.packageName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      // Packages List
                      Expanded(
                        child: viewModel.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : viewModel.error != null
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          size: 64,
                                          color: Colors.grey.shade400,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          viewModel.error!,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 16,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 24),
                                        ElevatedButton.icon(
                                          onPressed: () => viewModel.refresh(),
                                          icon: const Icon(Icons.refresh),
                                          label: Text(
                                            isHindi ? 'पुनः लोड करें' : 'Retry',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange.shade600,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : viewModel.packages.isEmpty
                                    ? Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.inbox_outlined,
                                              size: 64,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              isHindi
                                                  ? 'कोई पैकेज उपलब्ध नहीं'
                                                  : 'No packages available',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: () => viewModel.refresh(),
                                        color: Colors.orange.shade600,
                                        child: ListView.builder(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: viewModel.packages.length,
                                          itemBuilder: (context, index) {
                                            final package =
                                                viewModel.packages[index];
                                            final isActive = viewModel
                                                    .userActivePackage?.id ==
                                                package.id;

                                            return PackageCard(
                                              package: package,
                                              isSelected: isActive,
                                              onTap: () {
                                                if (!isActive) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ChangeNotifierProvider.value(
                                                        value: viewModel,
                                                        child: PackagePurchaseScreen(
                                                          package: package,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                      ),
                    ],
                  );
                },
              ),
            ),
    );
  }
}
