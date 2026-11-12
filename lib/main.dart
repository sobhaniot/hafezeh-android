import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/vocab_repository.dart';
import 'models/vocab_word.dart';
import 'theme/app_theme.dart';

void main() => runApp(const HafezehApp());

class HafezehApp extends StatelessWidget {
  const HafezehApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'حافظه',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('fa', 'IR'),
    supportedLocales: const [Locale('fa', 'IR')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const AppShell(),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _repository = VocabRepository();
  List<VocabWord> _words = [];
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    try {
      final words = await _repository.load();
      if (mounted) setState(() => _words = words);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خواندن واژه‌ها ممکن نشد. دوباره تلاش کن.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() => _repository.save(_words);

  Future<void> _addWord() async {
    final word = await showModalBottomSheet<VocabWord>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddWordSheet(),
    );
    if (word == null || !mounted) return;
    setState(() => _words = [word, ..._words]);
    await _save();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('واژه به فهرستت اضافه شد')));
    }
  }

  Future<void> _review() async {
    final due = _words.where((word) => word.isDue).toList()
      ..sort((a, b) => a.nextReview.compareTo(b.nextReview));
    if (due.isEmpty) {
      await _addWord();
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ReviewPage(
          words: due,
          onRated: (updated) {
            setState(() {
              _words = _words
                  .map((word) => word.id == updated.id ? updated : word)
                  .toList();
            });
            _save();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        words: _words,
        loading: _loading,
        onAdd: _addWord,
        onReview: _review,
        onShowWords: () => setState(() => _selectedTab = 1),
      ),
      WordsPage(words: _words, loading: _loading, onAdd: _addWord),
      ProgressPage(words: _words, loading: _loading),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_selectedTab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: 'واژه‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'روند من',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({
    required this.words,
    required this.loading,
    required this.onAdd,
    required this.onReview,
    required this.onShowWords,
    super.key,
  });

  final List<VocabWord> words;
  final bool loading;
  final VoidCallback onAdd;
  final VoidCallback onReview;
  final VoidCallback onShowWords;

  @override
  Widget build(BuildContext context) {
    final due = words.where((word) => word.isDue).length;
    final learned = words.where((word) => word.repetitions >= 3).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.mint,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.green,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حافظه',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                Text(
                  'یادگیری واژه‌ها با مرور هوشمند',
                  style: TextStyle(color: AppTheme.muted, fontSize: 12),
                ),
              ],
            ),
            const Spacer(),
            IconButton.filledTonal(
              onPressed: onAdd,
              tooltip: 'افزودن واژه',
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 30),
        Text(_greeting(), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          due == 0
              ? 'چند واژه اضافه کن تا مسیر یادگیری‌ات شروع شود.'
              : '${faNum(due)} واژه برای مرور امروز آماده است.',
          style: const TextStyle(color: AppTheme.muted, height: 1.6),
        ),
        const SizedBox(height: 22),
        _ReviewHero(due: due, loading: loading, onPressed: onReview),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.style_outlined,
                value: faNum(words.length),
                label: 'همهٔ واژه‌ها',
                tint: AppTheme.mint,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.check_circle_outline_rounded,
                value: faNum(learned),
                label: 'واژه‌های جاافتاده',
                tint: const Color(0xFFFFF1D8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              'دستهٔ واژه‌ها',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            TextButton(onPressed: onShowWords, child: const Text('دیدن همه')),
          ],
        ),
        const SizedBox(height: 8),
        _DeckCard(count: words.length, onTap: onShowWords),
        if (words.isEmpty) ...[
          const SizedBox(height: 18),
          _FirstWordHint(onAdd: onAdd),
        ],
      ],
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'صبح بخیر!';
    if (hour < 17) return 'روزت بخیر!';
    return 'عصر بخیر!';
  }
}

class _ReviewHero extends StatelessWidget {
  const _ReviewHero({
    required this.due,
    required this.loading,
    required this.onPressed,
  });
  final int due;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppTheme.green, Color(0xFF0A574B)],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      borderRadius: BorderRadius.circular(27),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24135B4F),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'مرور امروز',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                loading ? '…' : '${faNum(due)} واژه',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          due == 0 ? 'یک شروع کوچک؟' : 'حافظه‌ات را تازه کن',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          due == 0
              ? 'یک واژه اضافه کن و اولین کارتت را بساز.'
              : 'چند دقیقه مرور، ماندگاری بیشتری می‌سازد.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: loading ? null : onPressed,
          icon: Icon(
            due == 0 ? Icons.add_rounded : Icons.arrow_back_rounded,
            size: 20,
          ),
          label: Text(due == 0 ? 'افزودن اولین واژه' : 'شروع مرور'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.green,
            minimumSize: const Size(160, 50),
          ),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.tint,
  });
  final IconData icon;
  final String value;
  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppTheme.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 20, color: AppTheme.green),
        ),
        const SizedBox(height: 14),
        Text(
          value,
          style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: AppTheme.muted, fontSize: 11.5),
        ),
      ],
    ),
  );
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.peach,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.translate_rounded,
                color: Color(0xFFB66B37),
              ),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'واژه‌های من',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'دستهٔ عمومی',
                    style: TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              '${faNum(count)} کارت',
              style: const TextStyle(color: AppTheme.muted, fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left_rounded, color: AppTheme.muted),
          ],
        ),
      ),
    ),
  );
}

class _FirstWordHint extends StatelessWidget {
  const _FirstWordHint({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFEAF3EF),
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(20),
      child: const Padding(
        padding: EdgeInsets.all(17),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded, color: AppTheme.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'واژه‌ای که امروز یاد گرفتی را همین‌جا ثبت کن.',
                style: TextStyle(height: 1.5, fontSize: 13),
              ),
            ),
            Icon(Icons.add_circle_outline_rounded, color: AppTheme.green),
          ],
        ),
      ),
    ),
  );
}

class WordsPage extends StatefulWidget {
  const WordsPage({
    required this.words,
    required this.loading,
    required this.onAdd,
    super.key,
  });
  final List<VocabWord> words;
  final bool loading;
  final VoidCallback onAdd;

  @override
  State<WordsPage> createState() => _WordsPageState();
}

class _WordsPageState extends State<WordsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.words
        .where(
          (word) => '${word.term} ${word.meaning}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'واژه‌های من',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${faNum(widget.words.length)} واژه در فهرستت',
                      style: const TextStyle(color: AppTheme.muted),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: widget.onAdd,
                tooltip: 'افزودن واژه',
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: TextField(
            textDirection: TextDirection.rtl,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              hintText: 'جست‌وجو بین واژه‌ها',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: widget.loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
              ? _EmptyWords(onAdd: widget.onAdd, searching: _query.isNotEmpty)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(22, 2, 22, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _WordTile(word: filtered[index]),
                ),
        ),
      ],
    );
  }
}

class _WordTile extends StatelessWidget {
  const _WordTile({required this.word});
  final VocabWord word;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppTheme.line),
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: word.isDue ? AppTheme.peach : AppTheme.mint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            word.isDue ? Icons.schedule_rounded : Icons.check_rounded,
            color: AppTheme.green,
            size: 20,
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  word.term,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                word.meaning,
                style: const TextStyle(color: AppTheme.muted, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: word.isDue
                ? const Color(0xFFFFF1E8)
                : const Color(0xFFEAF3EF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            word.isDue ? 'مرور' : 'بعداً',
            style: TextStyle(
              color: word.isDue ? const Color(0xFF9C5828) : AppTheme.green,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyWords extends StatelessWidget {
  const _EmptyWords({required this.onAdd, required this.searching});
  final VoidCallback onAdd;
  final bool searching;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.mint,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              searching ? Icons.search_off_rounded : Icons.style_outlined,
              color: AppTheme.green,
              size: 34,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            searching ? 'واژه‌ای پیدا نشد' : 'هنوز واژه‌ای نداری',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 7),
          Text(
            searching
                ? 'عبارت دیگری را جست‌وجو کن.'
                : 'اولین واژه را اضافه کن تا مرورش را شروع کنیم.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, height: 1.5),
          ),
          if (!searching) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('افزودن واژه'),
            ),
          ],
        ],
      ),
    ),
  );
}

class ProgressPage extends StatelessWidget {
  const ProgressPage({required this.words, required this.loading, super.key});
  final List<VocabWord> words;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final learned = words.where((word) => word.repetitions >= 3).length;
    final learning = words.length - learned;
    final percent = words.isEmpty ? 0.0 : learned / words.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
      children: [
        Text('روند من', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        const Text(
          'نگاهی به مسیر یادگیری‌ات',
          style: TextStyle(color: AppTheme.muted),
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'مجموع واژه‌ها',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 8),
              Text(
                loading ? '…' : faNum(words.length),
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 10,
                  backgroundColor: AppTheme.mint,
                  color: AppTheme.green,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                words.isEmpty
                    ? 'با اضافه کردن واژه، پیشرفتت را اینجا می‌بینی.'
                    : '${faNum((percent * 100).round())}٪ از واژه‌ها در حافظهٔ بلندمدت جا افتاده‌اند.',
                style: const TextStyle(
                  color: AppTheme.muted,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.bolt_rounded,
                value: faNum(learning),
                label: 'در حال یادگیری',
                tint: const Color(0xFFFFF1D8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.check_circle_outline_rounded,
                value: faNum(learned),
                label: 'جاافتاده',
                tint: AppTheme.mint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3EF),
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_outlined, color: AppTheme.green),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'پیشنهاد حافظه',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Text(
            'مرورهای کوتاه و منظم کمک می‌کنند واژه‌ها را بهتر به خاطر بسپاری.',
            style: TextStyle(color: AppTheme.muted, height: 1.6),
          ),
        ),
      ],
    );
  }
}

class AddWordSheet extends StatefulWidget {
  const AddWordSheet({super.key});

  @override
  State<AddWordSheet> createState() => _AddWordSheetState();
}

class _AddWordSheetState extends State<AddWordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _termController = TextEditingController();
  final _meaningController = TextEditingController();
  final _exampleController = TextEditingController();

  @override
  void dispose() {
    _termController.dispose();
    _meaningController.dispose();
    _exampleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: const BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'واژهٔ تازه',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              const Text(
                'واژه و معنی‌اش را وارد کن؛ مثال اختیاری است.',
                style: TextStyle(color: AppTheme.muted),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('واژه'),
              TextFormField(
                controller: _termController,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'مثلاً: remember'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'واژه را وارد کن'
                    : null,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('معنی'),
              TextFormField(
                controller: _meaningController,
                decoration: const InputDecoration(
                  hintText: 'معنی واژه به فارسی',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'معنی را وارد کن'
                    : null,
              ),
              const SizedBox(height: 14),
              const _FieldLabel('مثال (اختیاری)'),
              TextFormField(
                controller: _exampleController,
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'A sentence with this word',
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('ذخیرهٔ واژه'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      VocabWord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        term: _termController.text.trim(),
        meaning: _meaningController.text.trim(),
        example: _exampleController.text.trim(),
        nextReview: DateTime.now(),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
    ),
  );
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({required this.words, required this.onRated, super.key});
  final List<VocabWord> words;
  final ValueChanged<VocabWord> onRated;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _index = 0;
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final complete = _index >= widget.words.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('مرور واژه‌ها'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'بازگشت',
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: complete
            ? _ReviewComplete(
                total: widget.words.length,
                onDone: () => Navigator.of(context).pop(),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 22),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _index / widget.words.length,
                              minHeight: 8,
                              color: AppTheme.green,
                              backgroundColor: AppTheme.mint,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${faNum(_index + 1)} از ${faNum(widget.words.length)}',
                          style: const TextStyle(
                            color: AppTheme.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Expanded(
                      child: _FlashCard(
                        word: widget.words[_index],
                        revealed: _revealed,
                        onReveal: () => setState(() => _revealed = true),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (_revealed)
                      Row(
                        children: [
                          Expanded(
                            child: _RatingButton(
                              label: 'دوباره',
                              hint: '۱۰ دقیقه',
                              color: const Color(0xFFB94E3D),
                              onPressed: () => _rate(ReviewRating.again),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RatingButton(
                              label: 'سخت',
                              hint: '۱ روز',
                              color: const Color(0xFFB47727),
                              onPressed: () => _rate(ReviewRating.hard),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RatingButton(
                              label: 'خوب',
                              hint: 'چند روز',
                              color: AppTheme.green,
                              onPressed: () => _rate(ReviewRating.good),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RatingButton(
                              label: 'آسان',
                              hint: 'بیشتر',
                              color: const Color(0xFF4373A1),
                              onPressed: () => _rate(ReviewRating.easy),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => setState(() => _revealed = true),
                          child: const Text('نمایش معنی'),
                        ),
                      ),
                    const SizedBox(height: 10),
                    const Text(
                      'اول جواب را در ذهنت بگو، بعد کارت را برگردان.',
                      style: TextStyle(color: AppTheme.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _rate(ReviewRating rating) {
    final current = widget.words[_index];
    widget.onRated(current.withReview(rating));
    setState(() {
      _index++;
      _revealed = false;
    });
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({
    required this.word,
    required this.revealed,
    required this.onReveal,
  });
  final VocabWord word;
  final bool revealed;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 220),
    child: Container(
      key: ValueKey(revealed),
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A18342D),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.mint,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              revealed ? 'معنی واژه' : 'واژهٔ انگلیسی',
              style: const TextStyle(
                color: AppTheme.green,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 30),
          if (!revealed) ...[
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                word.term,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
            ),
            const SizedBox(height: 26),
            TextButton.icon(
              onPressed: onReveal,
              icon: const Icon(Icons.flip_rounded),
              label: const Text('برای دیدن معنی لمس کن'),
            ),
          ] else ...[
            Text(
              word.meaning,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
                height: 1.5,
              ),
            ),
            if (word.example.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 14),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  word.example,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.muted, height: 1.6),
                ),
              ),
            ],
          ],
        ],
      ),
    ),
  );
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.hint,
    required this.color,
    required this.onPressed,
  });
  final String label;
  final String hint;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: .45)),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      minimumSize: const Size(48, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(hint, style: const TextStyle(fontSize: 9)),
      ],
    ),
  );
}

class _ReviewComplete extends StatelessWidget {
  const _ReviewComplete({required this.total, required this.onDone});
  final int total;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: AppTheme.mint,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 48,
              color: AppTheme.green,
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'مرور امروز تمام شد!',
            style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            '${faNum(total)} واژه را مرور کردی. آفرین به این استمرار.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.muted, height: 1.6),
          ),
          const SizedBox(height: 22),
          FilledButton(onPressed: onDone, child: const Text('بازگشت به خانه')),
        ],
      ),
    ),
  );
}
