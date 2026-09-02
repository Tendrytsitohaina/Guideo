import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'favorites_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _displayName = 'Utilisateur';
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    try {
      final user = AuthService.instance.currentUser;
      _displayName = user?.displayName?.trim().isNotEmpty == true
          ? user!.displayName!
          : user?.email?.split('@').first ?? 'Utilisateur';
      _loadNotificationPreference();
    } catch (_) {
      // Permet d'afficher le profil dans un test ou avant Firebase.
    }
  }

  Future<void> _loadNotificationPreference() async {
    try {
      final enabled = await AuthService.instance.notificationsEnabled();
      if (!mounted) return;
      setState(() {
        _notificationsEnabled = enabled;
      });
    } catch (_) {
      // Le réglage local par défaut reste activé si Firestore est indisponible.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // titre
              const Text(
                'Mon profil',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              //carte profil
              _buildProfileCard(context),

              const SizedBox(height: 28),

              //mon activité
              const Text(
                'Mon activité',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: Icons.favorite_rounded,
                iconColor: AppColors.accent,
                title: 'Mes favoris',
                subtitle: 'Retrouvez vos lieux préférés',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              //application
              const SizedBox(height: 18),

              const Text(
                'Application',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: Icons.settings_outlined,
                iconColor: AppColors.primary,
                title: 'Paramètres',
                subtitle: 'Personnalisez votre expérience',
                onTap: () {
                  _showSettingsSheet(context);
                },
              ),

              const SizedBox(height: 10),

              _ProfileMenuItem(
                icon: Icons.notifications_none_rounded,
                iconColor: AppColors.primary,
                title: 'Notifications',
                subtitle: 'Gérez vos notifications',
                onTap: () {
                  _showNotificationsSheet(context);
                },
              ),

              const SizedBox(height: 28),

              //info
              const Text(
                'Informations',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              _ProfileMenuItem(
                icon: Icons.info_outline_rounded,
                iconColor: AppColors.primary,
                title: 'À propos de MadaGuide',
                subtitle: 'Découvrez l’application',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),

              const SizedBox(height: 28),

              //deconnexion
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  //carte profil

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),

      child: Row(
        children: [
          // Avatar temporaire
          Container(
            width: 72,
            height: 72,

            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
                width: 2,
              ),
            ),

            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 38,
            ),
          ),

          const SizedBox(width: 16),

          //info temporaires
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Bienvenue sur MadaGuide',
                  style: TextStyle(color: AppColors.grey, fontSize: 13),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => _showEditProfileDialog(context),
            tooltip: 'Modifier le profil',
            icon: const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  //btn deconnexion
  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,

      child: OutlinedButton.icon(
        onPressed: () {
          _confirmLogout(context);
        },

        icon: const Icon(Icons.logout_rounded, color: AppColors.error),

        label: const Text(
          'Se déconnecter',
          style: TextStyle(
            color: AppColors.error,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),

        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.35)),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    final controller = TextEditingController(text: _displayName);

    final name = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Modifier le profil'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Nom',
              hintText: 'Entrez votre nom',
            ),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    setState(() {
      _displayName = name.trim();
    });

    try {
      await AuthService.instance.updateProfile(name: _displayName);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Le profil n’a pas pu être enregistré.')),
      );
    }
  }

  void _showSettingsSheet(BuildContext context) {
    var useLocation = true;
    var useAnimations = true;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    leading: Icon(Icons.settings_outlined),
                    title: Text('Paramètres'),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on_outlined),
                    title: const Text('Utiliser ma position'),
                    subtitle: const Text('Afficher les lieux proches de vous'),
                    value: useLocation,
                    onChanged: (value) {
                      setSheetState(() {
                        useLocation = value;
                      });
                    },
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.animation_outlined),
                    title: const Text('Animations'),
                    subtitle: const Text('Activer les transitions de l’application'),
                    value: useAnimations,
                    onChanged: (value) {
                      setSheetState(() {
                        useAnimations = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    var notificationsEnabled = _notificationsEnabled;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ListTile(
                    leading: Icon(Icons.notifications_none_rounded),
                    title: Text('Notifications'),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Recevoir les notifications'),
                    subtitle: const Text('Conseils et nouveautés touristiques'),
                    value: notificationsEnabled,
                    onChanged: (value) {
                      setSheetState(() {
                        notificationsEnabled = value;
                      });
                      _notificationsEnabled = value;
                      AuthService.instance.updateNotifications(value).catchError(
                        (_) {},
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Se déconnecter ?'),
          content: const Text('Votre session Firebase sera fermée.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Se déconnecter'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    try {
      await AuthService.instance.signOut();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous êtes déconnecté.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La déconnexion a échoué.')),
      );
    }
  }

  //about
  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'MadaGuide',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.explore_rounded,
        color: AppColors.primary,
        size: 36,
      ),
      children: const [
        Text(
          'MadaGuide est une application mobile '
          'destinée à faciliter la découverte des '
          'lieux touristiques de Madagascar.',
        ),
      ],
    );
  }
}

//élément menu profil
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(14),

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),

            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),

          child: Row(
            children: [
              // Icône
              Container(
                width: 46,
                height: 46,

                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),

                child: Icon(icon, color: iconColor, size: 22),
              ),

              const SizedBox(width: 14),

              //texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.grey,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
