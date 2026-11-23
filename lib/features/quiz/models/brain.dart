/// BRAIN walkthrough for one quiz question: Breakdown, Research, Assess, Identify, Nominate.
class OptionAssessment {
  final String option;
  final bool eliminate;
  final String reason;
  const OptionAssessment(this.option, this.eliminate, this.reason);

  factory OptionAssessment.fromJson(Map<String, dynamic> j) =>
      OptionAssessment(j['option'] as String? ?? '', j['verdict'] == 'eliminate', j['reason'] as String? ?? '');
}

class BrainWalkthrough {
  final String breakdown;
  final List<String> keywords;
  final String research;
  final List<OptionAssessment> assess;
  final String identify;
  final String nominate;
  final String why;

  const BrainWalkthrough({
    required this.breakdown,
    required this.keywords,
    required this.research,
    required this.assess,
    required this.identify,
    required this.nominate,
    required this.why,
  });

  factory BrainWalkthrough.fromJson(Map<String, dynamic> j) => BrainWalkthrough(
        breakdown: j['breakdown'] as String? ?? '',
        keywords: ((j['keywords'] as List?) ?? const []).map((e) => e.toString()).toList(),
        research: j['research'] as String? ?? '',
        assess: ((j['assess'] as List?) ?? const [])
            .map((e) => OptionAssessment.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        identify: j['identify'] as String? ?? '',
        nominate: j['nominate'] as String? ?? '',
        why: j['why'] as String? ?? '',
      );
}

/// question_id -> walkthrough
Map<String, BrainWalkthrough> parseQuizBrain(Map<String, dynamic> data) {
  final out = <String, BrainWalkthrough>{};
  for (final q in (data['questions'] as List?) ?? const []) {
    final m = (q as Map).cast<String, dynamic>();
    out[m['question_id'] as String] = BrainWalkthrough.fromJson((m['walkthrough'] as Map).cast<String, dynamic>());
  }
  return out;
}
