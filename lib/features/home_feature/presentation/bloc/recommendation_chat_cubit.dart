import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/data/services/recommendations_service.dart';
import 'package:flutter_sweet_shop_app_ui/features/home_feature/presentation/bloc/recommendation_chat_state.dart';

class RecommendationChatCubit extends Cubit<RecommendationChatState> {
  RecommendationChatCubit({RecommendationsService? service})
      : _service = service ?? RecommendationsService(),
        super(RecommendationChatState.initial());

  final RecommendationsService _service;

  void clearSnackError() {
    if (state.pendingSnackError == null) {
      return;
    }
    emit(
      RecommendationChatState(
        messages: state.messages,
        showQuickReplies: state.showQuickReplies,
        awaitingResponse: state.awaitingResponse,
        pendingSnackError: null,
      ),
    );
  }

  Future<void> selectPreference(String label, String apiPreference) async {
    if (state.awaitingResponse) {
      return;
    }

    emit(
      RecommendationChatState(
        messages: <RecommendationChatMessage>[
          ...state.messages,
          RecommendationChatMessage(fromUser: true, text: label),
          const RecommendationChatMessage(fromUser: false, loading: true),
        ],
        showQuickReplies: false,
        awaitingResponse: true,
        pendingSnackError: null,
      ),
    );

    try {
      final list = await _service.getRecommendations(preference: apiPreference);
      final withoutLoading = state.messages.sublist(0, state.messages.length - 1);

      if (list.isEmpty) {
        emit(
          RecommendationChatState(
            messages: <RecommendationChatMessage>[
              ...withoutLoading,
              const RecommendationChatMessage(
                fromUser: false,
                text:
                    'Şu an öneri listesi boş görünüyor. Menüden tatlılara göz atmayı dene 🍰',
              ),
            ],
            showQuickReplies: false,
            awaitingResponse: false,
            pendingSnackError: null,
          ),
        );
        return;
      }

      emit(
        RecommendationChatState(
          messages: <RecommendationChatMessage>[
            ...withoutLoading,
            const RecommendationChatMessage(
              fromUser: false,
              text: 'Harika seçim! Bugün için önerilerim:',
            ),
            RecommendationChatMessage(fromUser: false, recommendations: list),
          ],
          showQuickReplies: false,
          awaitingResponse: false,
          pendingSnackError: null,
        ),
      );
    } catch (e) {
      final withoutLoading = state.messages.sublist(0, state.messages.length - 1);
      emit(
        RecommendationChatState(
          messages: <RecommendationChatMessage>[
            ...withoutLoading,
            const RecommendationChatMessage(
              fromUser: false,
              text: 'Önerileri alırken bir sorun oluştu. Biraz sonra tekrar dene.',
            ),
          ],
          showQuickReplies: false,
          awaitingResponse: false,
          pendingSnackError: e,
        ),
      );
    }
  }
}
