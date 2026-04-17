// ignore_for_file: unused_element, unnecessary_overrides, annotate_overrides

part of '../../analysis/screens/chess_analysis_page.dart';

mixin _StoreState on _ChessAnalysisPageStateCore {
  String _depthTierLabel() => super._depthTierLabel();

  Future<void> _purchaseDepthTier(int targetTier) =>
      super._purchaseDepthTier(targetTier);

  Future<void> _purchaseExtraSuggestion() => super._purchaseExtraSuggestion();

  Future<void> _purchaseThemePack() => super._purchaseThemePack();

  Future<void> _purchasePiecePack() => super._purchasePiecePack();

  Future<void> _purchaseSpectral() => super._purchaseSpectral();

  Future<void> _purchaseTuttiFrutti() => super._purchaseTuttiFrutti();

  Future<void> _purchaseSakuraBoard() => super._purchaseSakuraBoard();

  Future<void> _purchaseTropicalBoard() => super._purchaseTropicalBoard();

  @override
  Future<void> _performResetWithSponsoredBreak() =>
      super._performResetWithSponsoredBreak();

  Future<void> _watchRewardAdFromStore() => super._watchRewardAdFromStore();

  Future<void> _buyCoinPack(int amount, String label) =>
      super._buyCoinPack(amount, label);

  Future<void> _buyAdFree() => super._buyAdFree();

  Future<void> _buyAcademyTuitionPass() => super._buyAcademyTuitionPass();

  Future<void> _resetPurchases() => super._resetPurchases();

  String _storeRewardAdCountdownLabel(Duration remaining) =>
      super._storeRewardAdCountdownLabel(remaining);

  @override
  Future<void> _openStore({
    StoreSection initialSection = StoreSection.general,
  }) => super._openStore(initialSection: initialSection);

  Widget _storeSectionHeader(String title, String subtitle) =>
      super._storeSectionHeader(title, subtitle);

  Widget _buildStoreRewardCooldownPreview(
    Duration remaining, {
    required bool lockedUntilTomorrow,
    required bool useMonochrome,
  }) => super._buildStoreRewardCooldownPreview(
    remaining,
    lockedUntilTomorrow: lockedUntilTomorrow,
    useMonochrome: useMonochrome,
  );

  Widget _buildThemeVaultCard(
    Function setL, {
    Future<void> Function()? onBoardThemeUnlockTap,
    Future<void> Function()? onPieceThemeUnlockTap,
  }) => super._buildThemeVaultCard(
    setL,
    onBoardThemeUnlockTap: onBoardThemeUnlockTap,
    onPieceThemeUnlockTap: onPieceThemeUnlockTap,
  );

  Widget _storeThemeCategoryHeader(String label) =>
      super._storeThemeCategoryHeader(label);

  Widget _buildStoreBoardThemeCard(
    BoardThemeMode mode,
    Function setL, {
    Future<void> Function()? onLockedTap,
  }) => super._buildStoreBoardThemeCard(
    mode,
    setL,
    onLockedTap: onLockedTap,
  );

  Widget _buildStorePieceThemeCard(
    PieceThemeMode mode,
    Function setL, {
    Future<void> Function()? onLockedTap,
  }) => super._buildStorePieceThemeCard(
    mode,
    setL,
    onLockedTap: onLockedTap,
  );

  Widget _buildStoreUiThemeCard(AppThemeStyle style, Function setL) =>
      super._buildStoreUiThemeCard(style, setL);

  Widget _storeThemeChoiceCard({
    required String label,
    required Widget preview,
    required bool selected,
    required bool locked,
    required String actionLabel,
    required Future<void> Function()? onTap,
  }) => super._storeThemeChoiceCard(
    label: label,
    preview: preview,
    selected: selected,
    locked: locked,
    actionLabel: actionLabel,
    onTap: onTap,
  );

  Widget _themeVaultChip({
    required String label,
    required bool selected,
    required Widget leading,
    VoidCallback? onTap,
  }) => super._themeVaultChip(
    label: label,
    selected: selected,
    leading: leading,
    onTap: onTap,
  );

  Widget _storeItemCard({
    Key? itemKey,
    required IconData icon,
    required String title,
    required String subtitle,
    required String priceLabel,
    required bool enabled,
    required String actionLabel,
    Color? actionColor,
    Widget? preview,
    VoidCallback? onTap,
  }) => super._storeItemCard(
    itemKey: itemKey,
    icon: icon,
    title: title,
    subtitle: subtitle,
    priceLabel: priceLabel,
    enabled: enabled,
    actionLabel: actionLabel,
    actionColor: actionColor,
    preview: preview,
    onTap: onTap,
  );

  Widget _perspectiveOption(String label, BoardPerspective p, Function setL) =>
      super._perspectiveOption(label, p, setL);

  Widget _boardThemeOption(BoardThemeMode mode, Function setL) =>
      super._boardThemeOption(mode, setL);

  Widget _pieceThemeOption(PieceThemeMode mode, Function setL) =>
      super._pieceThemeOption(mode, setL);

  Widget _boardThemeSwatch(BoardThemeMode mode) =>
      super._boardThemeSwatch(mode);

  Widget _pieceThemePreview(PieceThemeMode mode, {double pieceSize = 18}) =>
      super._pieceThemePreview(mode, pieceSize: pieceSize);

  Widget _themePackPreview() => super._themePackPreview();

  Widget _piecePackPreview() => super._piecePackPreview();
}