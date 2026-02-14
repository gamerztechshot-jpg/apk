// features/mantra_generator/repositories/problem_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/main_problem_model.dart';
import '../models/sub_problem_model.dart';

class ProblemRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all active main problems
  Future<List<MainProblem>> getMainProblems({bool forceRefresh = false}) async {
    try {
      final response = await _supabase
          .from('main_problems')
          .select()
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      return response
          .map<MainProblem>(
            (json) => MainProblem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch main problems: $e');
    }
  }

  /// Get sub-problems for a main problem
  Future<List<SubProblem>> getSubProblems(
    String mainProblemId, {
    bool forceRefresh = false,
  }) async {
    try {
      final response = await _supabase
          .from('sub_problems')
          .select()
          .eq('main_problem_id', mainProblemId)
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .order('created_at', ascending: false);

      return response
          .map<SubProblem>(
            (json) => SubProblem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch sub-problems: $e');
    }
  }

  /// Get main problem by ID
  Future<MainProblem?> getMainProblemById(String id) async {
    try {
      final response = await _supabase
          .from('main_problems')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return MainProblem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Get sub-problem by ID
  Future<SubProblem?> getSubProblemById(String id) async {
    try {
      final response = await _supabase
          .from('sub_problems')
          .select()
          .eq('id', id)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return SubProblem.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  /// Search problems by title (searches both main and sub-problems)
  Future<Map<String, List<dynamic>>> searchProblems(String query) async {
    try {
      // Search main problems
      final mainProblemsResponse = await _supabase
          .from('main_problems')
          .select()
          .eq('is_active', true)
          .or(
            'problem_heading_en.ilike.%$query%,problem_heading_hi.ilike.%$query%',
          )
          .order('display_order', ascending: true);

      // Search sub-problems
      final subProblemsResponse = await _supabase
          .from('sub_problems')
          .select()
          .eq('is_active', true)
          .or('title_en.ilike.%$query%,title_hi.ilike.%$query%')
          .order('display_order', ascending: true);

      final mainProblems = mainProblemsResponse
          .map<MainProblem>(
            (json) => MainProblem.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      final subProblems = subProblemsResponse
          .map<SubProblem>(
            (json) => SubProblem.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      return {'main': mainProblems, 'sub': subProblems};
    } catch (e) {
      throw Exception('Failed to search problems: $e');
    }
  }

  /// Get problem by ID (checks both main and sub-problems)
  Future<dynamic> getProblemById(String id) async {
    // Try main problems first
    final mainProblem = await getMainProblemById(id);
    if (mainProblem != null) return mainProblem;

    // Try sub-problems
    final subProblem = await getSubProblemById(id);
    if (subProblem != null) return subProblem;

    return null;
  }
}
