// features/profile/profile.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/l10n/app_localizations.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/language_service.dart';
import '../../core/services/profile_service.dart';
import '../../core/services/in_app_update_service.dart';
import '../../core/models/user_profile_model.dart';
import '../auth/login.dart';
import '../dharma_store/screens/user_orders_screen.dart';
import '../teacher/views/acharya_screen.dart';
import '../puja_booking/bookings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final ProfileService _profileService = ProfileService();
  UserProfile? _userProfile;
  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.getCurrentUser();

    if (user != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Try to get profile from database first
        UserProfile? profile;
        try {
          // Test database access first
          final dbAccessible = await _profileService.testDatabaseAccess();
          if (!dbAccessible) {
            throw Exception('Database not accessible');
          }

          final profileExists = await _profileService.profileExists(user.id);
          if (profileExists) {
            profile = await _profileService.getUserProfile(user.id);
          } else {
            // Try to create initial profile
            profile = await _profileService.createInitialProfile(
              userId: user.id,
              email: user.email ?? '',
              displayName: user.userMetadata?['name'],
              phone: user.userMetadata?['phone'],
            );
          }
        } catch (e) {
          // If database access fails, create a profile from auth data

          profile = UserProfile(
            userId: user.id,
            displayName: user.userMetadata?['name'] ?? 'User',
            email: user.email ?? '',
            phone: user.userMetadata?['phone'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }

        if (mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
            _loadControllers();
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          final isHindi =
              Provider.of<LanguageService>(context, listen: false).isHindi;
          _showSnackBar(
            isHindi
                ? 'प्रोफाइल लोड करने में त्रुटि: $e'
                : 'Error loading profile: $e',
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _loadControllers() {
    if (_userProfile != null) {
      _nameController.text = _userProfile!.displayName;
      _emailController.text = _userProfile!.email;
      _phoneController.text = _userProfile!.phone ?? '';
      _bioController.text = _userProfile!.bio ?? '';
      _locationController.text = _userProfile!.location ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    if (_userProfile == null) return;

    try {
      // Try to save to database first
      try {
        final updatedProfile = await _profileService.updateProfileFields(
          userId: _userProfile!.userId,
          displayName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          bio: _bioController.text.trim().isEmpty
              ? null
              : _bioController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        );

        if (updatedProfile != null) {
          // Also update AuthService metadata
          final authService = Provider.of<AuthService>(context, listen: false);
          await authService.updateUserMetadata(
            name: updatedProfile.displayName,
            phone: updatedProfile.phone,
          );

          setState(() {
            _userProfile = updatedProfile;
            _isEditing = false;
          });
          final isHindi =
              Provider.of<LanguageService>(context, listen: false).isHindi;
          _showSnackBar(
            isHindi
                ? 'प्रोफाइल सफलतापूर्वक अपडेट हो गया!'
                : 'Profile updated successfully!',
          );
          return;
        }
      } catch (e) {}

      // If database save fails, update local profile
      final updatedProfile = UserProfile(
        userId: _userProfile!.userId,
        displayName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        bio: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        avatarUrl: _userProfile!.avatarUrl,
        dateOfBirth: _userProfile!.dateOfBirth,
        preferredLanguage: _userProfile!.preferredLanguage,
        timezone: _userProfile!.timezone,
        isActive: _userProfile!.isActive,
        lastLogin: _userProfile!.lastLogin,
        createdAt: _userProfile!.createdAt,
        updatedAt: DateTime.now(),
      );

      // Also update AuthService metadata for local profile
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateUserMetadata(
        name: updatedProfile.displayName,
        phone: updatedProfile.phone,
      );

      setState(() {
        _userProfile = updatedProfile;
        _isEditing = false;
      });
      final isHindi =
          Provider.of<LanguageService>(context, listen: false).isHindi;
      _showSnackBar(
        isHindi
            ? 'प्रोफाइल स्थानीय रूप से अपडेट हुआ (डेटाबेस उपलब्ध नहीं)'
            : 'Profile updated locally (database access unavailable)',
      );
    } catch (e) {
      final isHindi =
          Provider.of<LanguageService>(context, listen: false).isHindi;
      _showSnackBar(
        isHindi
            ? 'प्रोफाइल अपडेट करने में त्रुटि: $e'
            : 'Error updating profile: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isHindi =
        Provider.of<LanguageService>(context, listen: false).isHindi;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.profile),
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [],
        ),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (_userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.profile),
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                isHindi ? 'प्रोफाइल लोड नहीं हो पा रहा है' : 'Unable to load profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isHindi ? 'कृपया बाद में पुनः प्रयास करें' : 'Please try again later',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                ),
                child: Text(isHindi ? 'पुनः प्रयास करें' : 'Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange.shade400,
              Colors.orange.shade500,
              Colors.orange.shade600,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Profile Header
                Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.orange.shade50],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Row(
                            children: [
                              // Profile Image Section
                              GestureDetector(
                                onTap: () {
                                  _showSnackBar(
                                    isHindi
                                        ? 'प्रोफाइल फोटो अपलोड सुविधा जल्द उपलब्ध होगी!'
                                        : 'Profile picture upload feature will be implemented soon!',
                                  );
                                },
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.orange.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Icon(
                                          Icons.person,
                                          size: 40,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade600,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // User Info Section
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Name Field
                                    _buildProfileField(
                                      context: context,
                                      label: l10n.name,
                                      controller: _nameController,
                                      isEditing: _isEditing,
                                      isRequired: true,
                                      icon: Icons.person_outline,
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .titleLarge!
                                          .copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange.shade700,
                                          ),
                                      placeholder: l10n.enterName,
                                    ),
                                    const SizedBox(height: 12),

                                    // Email Field
                                    _buildProfileField(
                                      context: context,
                                      label: l10n.email,
                                      controller: _emailController,
                                      isEditing: _isEditing,
                                      isRequired: true,
                                      icon: Icons.email_outlined,
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                      placeholder: l10n.enterEmail,
                                    ),
                                    const SizedBox(height: 12),

                                    // Phone Field
                                    _buildProfileField(
                                      context: context,
                                      label: l10n.phoneNumber,
                                      controller: _phoneController,
                                      isEditing: _isEditing,
                                      isRequired: false,
                                      icon: Icons.phone_outlined,
                                      textStyle: Theme.of(context)
                                          .textTheme
                                          .bodyMedium!
                                          .copyWith(
                                            color: Colors.grey.shade600,
                                          ),
                                      placeholder: l10n.enterPhone,
                                    ),
                                    if (_isEditing) ...[
                                      const SizedBox(height: 12),

                                      // Bio Field
                                      _buildProfileField(
                                        context: context,
                                        label: l10n.bio,
                                        controller: _bioController,
                                        isEditing: _isEditing,
                                        isRequired: false,
                                        icon: Icons.info_outline,
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                        maxLines: 2,
                                        placeholder: l10n.enterBio,
                                      ),
                                      const SizedBox(height: 12),

                                      // Location Field
                                      _buildProfileField(
                                        context: context,
                                        label: l10n.location,
                                        controller: _locationController,
                                        isEditing: _isEditing,
                                        isRequired: false,
                                        icon: Icons.location_on_outlined,
                                        textStyle: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                              color: Colors.grey.shade600,
                                            ),
                                        placeholder: l10n.enterLocation,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit Icon
                        Positioned(
                          top: 12,
                          right: 12,
                          child: GestureDetector(
                            onTap: () async {
                              if (_isEditing) {
                                // Save changes
                                await _saveProfileChanges();
                              } else {
                                // Enter edit mode
                                setState(() {
                                  _isEditing = true;
                                });
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _isEditing
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isEditing ? Icons.check : Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Options
                Column(
                  children: [
                    // My Courses and My Bookings Section
                    _buildGroupedCard(context, l10n.learningActivities, [
                      _buildGroupedOption(
                        context,
                        l10n.myCourses,
                        Icons.school,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AcharyaScreen(),
                            ),
                          );
                        },
                      ),
                      _buildGroupedOption(
                        context,
                        l10n.myBookings,
                        Icons.book_online,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookingsScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Orders Section
                    _buildGroupedCard(
                      context,
                      isHindi ? 'खरीदारी' : 'Shopping',
                      [
                      _buildGroupedOption(
                        context,
                        isHindi ? 'मेरे ऑर्डर' : 'My Orders',
                        Icons.shopping_bag,
                        () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UserOrdersScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                    ),
                    const SizedBox(height: 12),
                    // Jaap History and Karmic Score Section
                    _buildGroupedCard(context, l10n.spiritualJourney, [
                      _buildGroupedOption(
                        context,
                        l10n.jaapHistory,
                        Icons.history,
                        () {
                          _showSnackBar(
                            isHindi
                                ? 'जाप इतिहास सुविधा जल्द उपलब्ध होगी!'
                                : 'Jaap History feature will be implemented soon!',
                          );
                        },
                      ),
                      _buildGroupedOption(
                        context,
                        l10n.karmicScore,
                        Icons.star,
                        () {
                          _showSnackBar(
                            isHindi
                                ? 'कर्मिक स्कोर सुविधा जल्द उपलब्ध होगी!'
                                : 'Karmic Score feature will be implemented soon!',
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 12),
                    // Language Option
                    _buildLanguageOption(context, l10n),
                    const SizedBox(height: 12),
                    // Settings and Support Section
                    _buildGroupedCard(
                      context,
                      isHindi ? 'ऐप सेटिंग्स' : 'App Settings',
                      [
                      _buildGroupedOption(
                        context,
                        isHindi ? 'अपडेट जांचें' : 'Check for Updates',
                        Icons.system_update,
                        () {
                          InAppUpdateService.forceCheckForUpdate(context);
                        },
                      ),
                      _buildGroupedOption(
                        context,
                        l10n.settings,
                        Icons.settings,
                        () {
                          _showSnackBar(
                            isHindi
                                ? 'सेटिंग्स सुविधा जल्द उपलब्ध होगी!'
                                : 'Settings feature will be implemented soon!',
                          );
                        },
                      ),
                      _buildGroupedOption(
                        context,
                        l10n.support,
                        Icons.help,
                        () {
                          _showSnackBar(
                            isHindi
                                ? 'सहायता सुविधा जल्द उपलब्ध होगी!'
                                : 'Support feature will be implemented soon!',
                          );
                        },
                      ),
                    ],
                    ),
                    const SizedBox(height: 24),
                    // Logout Button
                    _buildLogoutButton(context, l10n),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(BuildContext context, AppLocalizations l10n) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.orange.shade50],
              ),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.language,
                  color: Colors.orange.shade600,
                  size: 20,
                ),
              ),
              title: Text(
                l10n.language,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
              subtitle: Text(
                languageService.getLanguageName(),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              trailing: Switch(
                value: languageService.isHindi,
                onChanged: (value) async {
                  await languageService.toggleLanguage();
                },
                activeColor: Colors.orange.shade600,
                activeTrackColor: Colors.orange.shade200,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedCard(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.orange.shade50],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedOption(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.orange.shade600, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.orange.shade600,
      ),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n) {
    final isHindi =
        Provider.of<LanguageService>(context, listen: false).isHindi;
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: ElevatedButton.icon(
          onPressed: () => _showLogoutDialog(context, l10n),
          icon: const Icon(Icons.logout, color: Colors.white),
          label: Text(
            isHindi ? 'लॉग आउट' : 'Logout',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            elevation: 4,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppLocalizations l10n) {
    final isHindi =
        Provider.of<LanguageService>(context, listen: false).isHindi;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red.shade600, size: 24),
              const SizedBox(width: 8),
              Text(isHindi ? 'लॉग आउट' : 'Logout'),
            ],
          ),
          content: Text(
            isHindi
                ? 'क्या आप वाकई लॉग आउट करना चाहते हैं?'
                : 'Are you sure you want to logout?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isHindi ? 'रद्द करें' : 'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authService = Provider.of<AuthService>(
                  context,
                  listen: false,
                );
                await authService.signOut();
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isHindi ? 'लॉग आउट' : 'Logout',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required bool isRequired,
    required IconData icon,
    required TextStyle textStyle,
    String? placeholder,
    int maxLines = 1,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Label
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.orange.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(fontSize: 12, color: Colors.red.shade600),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Field Content
        if (isEditing)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade100,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: textStyle,
              decoration: InputDecoration(
                hintText: placeholder ?? 'Enter ${label.toLowerCase()}',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20,
                      )
                    : null,
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Text(
              controller.text.isEmpty
                  ? (placeholder ?? l10n.notProvided)
                  : controller.text,
              style: textStyle.copyWith(
                color: controller.text.isEmpty
                    ? Colors.grey.shade500
                    : textStyle.color,
              ),
            ),
          ),
      ],
    );
  }
}
