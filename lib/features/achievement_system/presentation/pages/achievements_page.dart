import 'package:flutter/material.dart';
import '../../../../shared/models/achievement_model.dart';
import '../../../../shared/models/user_level_model.dart';
import '../../../../shared/data/achievement_definitions.dart';
import '../../../../shared/widgets/level_progress_indicator.dart';
import '../widgets/achievement_badge.dart';
import '../widgets/achievement_card.dart';
import '../widgets/achievement_statistics_widget.dart';
import '../../domain/entities/achievement_statistics.dart';
import '../../domain/entities/user_progress.dart';

class AchievementsPage extends StatefulWidget {
  final List<AchievementModel> userAchievements;
  final UserLevelModel userLevel;
  final AchievementStatistics statistics;
  final UserProgress userProgress;

  const AchievementsPage({
    super.key,
    required this.userAchievements,
    required this.userLevel,
    required this.statistics,
    required this.userProgress,
  });

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AchievementRarity? _selectedRarity;
  AchievementType? _selectedType;
  bool _showLockedAchievements = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Başarımlar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.secondary,
                    ],
                  ),
                ),
                child: _buildHeaderContent(context),
              ),
            ),
          ),

          // Tab Bar
          SliverToBoxAdapter(
            child: _buildTabBar(theme),
          ),

          // Content
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllAchievementsTab(),
                _buildUnlockedTab(),
                _buildInProgressTab(),
                _buildStatisticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Level indicator
          LevelProgressIndicator(
            userLevel: widget.userLevel,
            size: 100,
            showTitle: false,
            showExperience: false,
          ),

          const SizedBox(height: 16),

          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickStat(
                'Açılan',
                '${widget.statistics.unlockedAchievements}',
                Icons.emoji_events_rounded,
                Colors.amber,
              ),
              _buildQuickStat(
                'Toplam XP',
                '${widget.statistics.totalExperiencePoints}',
                Icons.stars_rounded,
                Colors.blue,
              ),
              _buildQuickStat(
                'Seri',
                '${widget.statistics.currentStreak}',
                Icons.local_fire_department_rounded,
                Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
        indicatorColor: theme.colorScheme.primary,
        tabs: const [
          Tab(text: 'Tümü', icon: Icon(Icons.grid_view_rounded)),
          Tab(text: 'Açılan', icon: Icon(Icons.check_circle_rounded)),
          Tab(text: 'Devam Eden', icon: Icon(Icons.hourglass_empty_rounded)),
          Tab(text: 'İstatistikler', icon: Icon(Icons.analytics_rounded)),
        ],
      ),
    );
  }

  Widget _buildAllAchievementsTab() {
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: _buildAchievementGrid(_getFilteredAchievements()),
        ),
      ],
    );
  }

  Widget _buildUnlockedTab() {
    final unlockedAchievements =
        widget.userAchievements.where((a) => a.isUnlocked).toList();

    return _buildAchievementGrid(unlockedAchievements);
  }

  Widget _buildInProgressTab() {
    final inProgressAchievements = widget.userAchievements
        .where((a) => !a.isUnlocked && a.currentProgress > 0)
        .toList();

    return _buildAchievementGrid(inProgressAchievements);
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          AchievementStatisticsWidget(
            statistics: widget.statistics,
            userProgress: widget.userProgress,
          ),
          const SizedBox(height: 24),
          LevelBenefitsShowcase(
            userLevel: widget.userLevel,
            showLocked: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Başarım ara...',
              prefixIcon: const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Show locked toggle
                FilterChip(
                  label: Text('Kilitli Göster'),
                  selected: _showLockedAchievements,
                  onSelected: (selected) {
                    setState(() {
                      _showLockedAchievements = selected;
                    });
                  },
                ),

                const SizedBox(width: 8),

                // Rarity filters
                ...AchievementRarity.values.map(
                  (rarity) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_getRarityName(rarity)),
                      selected: _selectedRarity == rarity,
                      onSelected: (selected) {
                        setState(() {
                          _selectedRarity = selected ? rarity : null;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Type filters
                ...AchievementType.values.take(3).map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getTypeName(type)),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = selected ? type : null;
                            });
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(List<AchievementModel> achievements) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz başarım yok',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Rutinlerini tamamlayarak başarımlar kazan!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return AchievementCard(
          achievement: achievement,
          userProgress: widget.userProgress,
          onTap: () => _showAchievementDetails(achievement),
        );
      },
    );
  }

  List<AchievementModel> _getFilteredAchievements() {
    var achievements =
        List<AchievementModel>.from(AchievementDefinitions.allAchievements);

    // Apply user progress
    achievements = achievements.map((definition) {
      final userAchievement = widget.userAchievements
          .firstWhere((ua) => ua.id == definition.id, orElse: () => definition);
      return userAchievement;
    }).toList();

    // Apply filters
    if (!_showLockedAchievements) {
      achievements = achievements.where((a) => a.isUnlocked).toList();
    }

    if (_selectedRarity != null) {
      achievements =
          achievements.where((a) => a.rarity == _selectedRarity).toList();
    }

    if (_selectedType != null) {
      achievements =
          achievements.where((a) => a.type == _selectedType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      achievements = achievements
          .where((a) =>
              a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              a.description.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Sort by unlock status and rarity
    achievements.sort((a, b) {
      if (a.isUnlocked != b.isUnlocked) {
        return a.isUnlocked ? -1 : 1;
      }
      return a.rarity.index.compareTo(b.rarity.index);
    });

    return achievements;
  }

  void _showAchievementDetails(AchievementModel achievement) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AchievementDetailSheet(
        achievement: achievement,
        userProgress: widget.userProgress,
      ),
    );
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Ortak';
      case AchievementRarity.uncommon:
        return 'Nadir';
      case AchievementRarity.rare:
        return 'Ender';
      case AchievementRarity.epic:
        return 'Epik';
      case AchievementRarity.legendary:
        return 'Efsane';
    }
  }

  String _getTypeName(AchievementType type) {
    switch (type) {
      case AchievementType.routine:
        return 'Rutin';
      case AchievementType.goal:
        return 'Hedef';
      case AchievementType.streak:
        return 'Seri';
      case AchievementType.category:
        return 'Kategori';
      case AchievementType.time:
        return 'Zaman';
      case AchievementType.milestone:
        return 'Mil Taşı';
      case AchievementType.special:
        return 'Özel';
    }
  }
}

// Achievement detail sheet
class _AchievementDetailSheet extends StatelessWidget {
  final AchievementModel achievement;
  final UserProgress userProgress;

  const _AchievementDetailSheet({
    required this.achievement,
    required this.userProgress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Achievement badge
                  AchievementBadge(
                    achievement: achievement,
                    size: 120,
                    showTitle: false,
                    isLocked: !achievement.isUnlocked,
                  ),

                  const SizedBox(height: 20),

                  // Title and description
                  Text(
                    achievement.title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    achievement.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Progress and conditions
                  if (!achievement.isUnlocked) ...[
                    _buildProgressSection(context),
                    const SizedBox(height: 24),
                  ],

                  // Metadata
                  _buildMetadataSection(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İlerleme',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Progress conditions
        ...achievement.unlockConditions.map(
          (condition) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildConditionProgress(context, condition),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionProgress(
      BuildContext context, UnlockCondition condition) {
    final theme = Theme.of(context);

    // Simple progress calculation
    int currentValue = 0;
    String progressText = '';

    switch (condition.type) {
      case UnlockConditionType.routineCompletion:
        currentValue = userProgress.routineCompletions;
        progressText =
            '$currentValue/${condition.targetValue} rutin tamamlandı';
        break;
      case UnlockConditionType.streakAchievement:
        currentValue = userProgress.longestStreak;
        progressText = '$currentValue/${condition.targetValue} günlük seri';
        break;
      default:
        progressText = 'İlerleme takip edilemiyor';
    }

    final progress = condition.targetValue > 0
        ? (currentValue / condition.targetValue).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          progressText,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.onSurface.withOpacity(0.1),
          valueColor: AlwaysStoppedAnimation<Color>(achievement.color),
        ),
      ],
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildMetadataRow('Nadirlik', _getRarityName(achievement.rarity)),
          _buildMetadataRow('Tür', _getTypeName(achievement.type)),
          _buildMetadataRow(
              'Deneyim Puanı', '${achievement.experiencePoints} XP'),
          if (achievement.isUnlocked && achievement.unlockedAt != null)
            _buildMetadataRow(
                'Açılma Tarihi', _formatDate(achievement.unlockedAt!)),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'Ortak';
      case AchievementRarity.uncommon:
        return 'Nadir';
      case AchievementRarity.rare:
        return 'Ender';
      case AchievementRarity.epic:
        return 'Epik';
      case AchievementRarity.legendary:
        return 'Efsane';
    }
  }

  String _getTypeName(AchievementType type) {
    switch (type) {
      case AchievementType.routine:
        return 'Rutin';
      case AchievementType.goal:
        return 'Hedef';
      case AchievementType.streak:
        return 'Seri';
      case AchievementType.category:
        return 'Kategori';
      case AchievementType.time:
        return 'Zaman';
      case AchievementType.milestone:
        return 'Mil Taşı';
      case AchievementType.special:
        return 'Özel';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
