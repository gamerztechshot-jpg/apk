// features/mantra_generator/views/widgets/problem_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:karmasu/core/services/language_service.dart';
import '../../models/main_problem_model.dart';
import '../../models/sub_problem_model.dart';

class ProblemCard extends StatefulWidget {
  final MainProblem problem;
  final List<SubProblem> subProblems;
  final List<String> unlockedIds;
  final Function(MainProblem) onMainProblemTap;
  final Function(SubProblem) onSubProblemTap;

  const ProblemCard({
    super.key,
    required this.problem,
    required this.subProblems,
    required this.unlockedIds,
    required this.onMainProblemTap,
    required this.onSubProblemTap,
  });

  @override
  State<ProblemCard> createState() => _ProblemCardState();
}

class _ProblemCardState extends State<ProblemCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.orange.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Problem Header
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.subProblems.isNotEmpty) {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              }
              widget.onMainProblemTap(widget.problem);
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Problem Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade100, Colors.orange.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.psychology,
                      color: Colors.orange.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Problem Title and Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.problem.getTitle(isHindi ? 'hi' : 'en'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.problem.getDescription(
                                  isHindi ? 'hi' : 'en',
                                ) !=
                                null &&
                            widget.problem
                                .getDescription(isHindi ? 'hi' : 'en')!
                                .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.problem.getDescription(
                              isHindi ? 'hi' : 'en',
                            )!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            // Linked Content Count
                            if (widget.problem.linkedContentCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.link,
                                      size: 14,
                                      color: Colors.blue.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${widget.problem.linkedContentCount}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand/Collapse Button (if has sub-problems)
                  if (widget.subProblems.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                    ),
                  // Arrow Icon (if no sub-problems)
                  if (widget.subProblems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.orange.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Sub-Problems List (Expandable)
          if (widget.subProblems.isNotEmpty && _isExpanded)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                children: widget.subProblems.map((subProblem) {
                  final isUnlocked =
                      !subProblem.requiresCredits ||
                      widget.unlockedIds.contains(subProblem.id);

                  return SubProblemCard(
                    subProblem: subProblem,
                    isUnlocked: isUnlocked,
                    onTap: () => widget.onSubProblemTap(subProblem),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

// Sub-Problem Card Widget
class SubProblemCard extends StatelessWidget {
  final SubProblem subProblem;
  final bool isUnlocked;
  final VoidCallback onTap;

  const SubProblemCard({
    super.key,
    required this.subProblem,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: true);
    final isHindi = languageService.isHindi;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade100, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Sub-problem Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200, width: 1),
                  ),
                  child: Icon(
                    isUnlocked ? Icons.lock_open : Icons.lock_outline,
                    color: isUnlocked
                        ? Colors.green.shade600
                        : Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Sub-problem Title and Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subProblem.getTitle(isHindi ? 'hi' : 'en'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (subProblem.getDescription(isHindi ? 'hi' : 'en') !=
                              null &&
                          subProblem
                              .getDescription(isHindi ? 'hi' : 'en')!
                              .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subProblem.getDescription(isHindi ? 'hi' : 'en')!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Credit Cost Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: subProblem.requiresCredits
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: subProblem.requiresCredits
                                    ? Colors.orange.shade200
                                    : Colors.green.shade200,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  subProblem.requiresCredits
                                      ? Icons.stars
                                      : Icons.check_circle,
                                  size: 12,
                                  color: subProblem.requiresCredits
                                      ? Colors.orange.shade600
                                      : Colors.green.shade600,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  subProblem.getCreditCostDisplay(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: subProblem.requiresCredits
                                        ? Colors.orange.shade700
                                        : Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Linked Content Count
                          if (subProblem.linkedContentCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.link,
                                    size: 12,
                                    color: Colors.blue.shade600,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${subProblem.linkedContentCount}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.orange.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
