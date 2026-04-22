import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/core/services/app_session.dart';
import 'package:flutter_sweet_shop_app_ui/core/theme/theme.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_feedback.dart';
import 'package:flutter_sweet_shop_app_ui/core/utils/app_navigator.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/models/recommendation_models.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/recommendations_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/bloc/recommendation_chat_cubit.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/bloc/recommendation_chat_state.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/screens/product_details_screen.dart';
import 'package:flutter_sweet_shop_app_ui/features/restaurant_owner_feature/widgets/product_image_widget.dart';

Future<void> showSweetRecommendationChatSheet({
  required BuildContext parentContext,
}) async {
  if (AppSession.userId.isEmpty) {
    parentContext.showInfoMessage('Öneriler için giriş yapmalısınız.');
    return;
  }
  await showModalBottomSheet<void>(
    context: parentContext,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (final BuildContext context) {
      return BlocProvider(
        create: (_) => RecommendationChatCubit(
          service: RecommendationsService(),
        ),
        child: SweetRecommendationChatSheet(parentContext: parentContext),
      );
    },
  );
}

class SweetRecommendationChatSheet extends StatefulWidget {
  const SweetRecommendationChatSheet({super.key, required this.parentContext});

  final BuildContext parentContext;

  @override
  State<SweetRecommendationChatSheet> createState() =>
      _SweetRecommendationChatSheetState();
}

class _SweetRecommendationChatSheetState
    extends State<SweetRecommendationChatSheet> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    if (!_scroll.hasClients) {
      return;
    }
    Future<void>.delayed(const Duration(milliseconds: 80), () {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(final BuildContext context) {
    final colors = context.theme.appColors;
    final height = MediaQuery.sizeOf(context).height * 0.9;

    return BlocListener<RecommendationChatCubit, RecommendationChatState>(
      listenWhen: (final RecommendationChatState p, final RecommendationChatState c) =>
          c.pendingSnackError != null && p.pendingSnackError != c.pendingSnackError,
      listener: (final BuildContext context, final RecommendationChatState state) {
        final err = state.pendingSnackError;
        if (err != null) {
          context.showErrorMessage(err);
          context.read<RecommendationChatCubit>().clearSnackError();
        }
      },
      child: BlocConsumer<RecommendationChatCubit, RecommendationChatState>(
        listener: (final BuildContext context, final RecommendationChatState state) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
        },
        builder: (final BuildContext context, final RecommendationChatState state) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height: height,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.gray2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: colors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Tatlı asistanı',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: colors.gray2.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                        itemCount: state.messages.length,
                        itemBuilder: (final BuildContext context, final int i) {
                          return _MessageBlock(
                            message: state.messages[i],
                            sheetParentContext: widget.parentContext,
                          );
                        },
                      ),
                    ),
                    if (state.showQuickReplies && !state.awaitingResponse)
                      _QuickRepliesBar(
                        onSelect: (final String label, final String apiPreference) {
                          context.read<RecommendationChatCubit>().selectPreference(
                                label,
                                apiPreference,
                              );
                        },
                      ),
                    SizedBox(height: MediaQuery.paddingOf(context).bottom + 8),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickRepliesBar extends StatelessWidget {
  const _QuickRepliesBar({required this.onSelect});

  final void Function(String label, String apiPreference) onSelect;

  @override
  Widget build(final BuildContext context) {
    final colors = context.theme.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Hızlı seçim',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.black.withValues(alpha: 0.55),
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickChip(
                label: 'Çikolatalı',
                onTap: () => onSelect('Çikolatalı', 'chocolate'),
              ),
              _QuickChip(
                label: 'Meyveli',
                onTap: () => onSelect('Meyveli', 'fruit'),
              ),
              _QuickChip(
                label: 'Hafif',
                onTap: () => onSelect('Hafif', 'light'),
              ),
              _QuickChip(
                label: 'Fark etmez',
                onTap: () => onSelect('Fark etmez', 'any'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(final BuildContext context) {
    final colors = context.theme.appColors;
    return Material(
      color: colors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBlock extends StatelessWidget {
  const _MessageBlock({
    required this.message,
    required this.sheetParentContext,
  });

  final RecommendationChatMessage message;
  final BuildContext sheetParentContext;

  @override
  Widget build(final BuildContext context) {
    final colors = context.theme.appColors;
    if (message.loading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.gray2.withValues(alpha: 0.35),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
          ),
        ),
      );
    }

    if (message.fromUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
              ),
            ),
            child: Text(
              message.text ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
      );
    }

    final children = <Widget>[];

    if (message.text != null && message.text!.isNotEmpty) {
      children.add(
        Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: colors.gray2.withValues(alpha: 0.35),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
          ),
          child: Text(
            message.text!,
            style: TextStyle(
              color: colors.black.withValues(alpha: 0.88),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    if (message.recommendations != null && message.recommendations!.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 10));
      }
      for (final RecommendationItem item in message.recommendations!) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _RecommendationProductCard(
              item: item,
              parentContext: sheetParentContext,
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _RecommendationProductCard extends StatelessWidget {
  const _RecommendationProductCard({
    required this.item,
    required this.parentContext,
  });

  final RecommendationItem item;
  final BuildContext parentContext;

  @override
  Widget build(final BuildContext context) {
    final colors = context.theme.appColors;
    final product = item.toProductModel();

    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 76,
                child: buildProductImage(item.imagePath, 76, 76),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.shortDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.black.withValues(alpha: 0.55),
                          height: 1.25,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.tonal(
                      onPressed: () {
                        Navigator.of(context).pop();
                        appPush(
                          parentContext,
                          ProductDetailsScreen(product: product),
                        );
                      },
                      child: const Text('Sipariş Ver'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
