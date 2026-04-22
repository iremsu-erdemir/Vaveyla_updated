import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/models/recommendation_models.dart';

class RecommendationChatMessage {
  const RecommendationChatMessage({
    required this.fromUser,
    this.text,
    this.recommendations,
    this.loading = false,
  });

  final bool fromUser;
  final String? text;
  final List<RecommendationItem>? recommendations;
  final bool loading;
}

class RecommendationChatState {
  const RecommendationChatState({
    required this.messages,
    required this.showQuickReplies,
    required this.awaitingResponse,
    this.pendingSnackError,
  });

  static const RecommendationChatMessage initialGreeting = RecommendationChatMessage(
    fromUser: false,
    text: 'Merhaba 👋 Bugün ne tatlı yemek istersin?',
  );

  factory RecommendationChatState.initial() => RecommendationChatState(
        messages: const <RecommendationChatMessage>[initialGreeting],
        showQuickReplies: true,
        awaitingResponse: false,
      );

  final List<RecommendationChatMessage> messages;
  final bool showQuickReplies;
  final bool awaitingResponse;
  final Object? pendingSnackError;
}
