1. **Reduce Padding in `ReaderPage`**:
   - In `lib/main.dart` around line `2057` and `2060`, there is `padding: const EdgeInsets.all(24)`. I will reduce this to `padding: const EdgeInsets.all(10.0)` for safe UI expansion.
2. **Reduce Margin/Padding in List Cards**:
   - For `_HomeSmallCard` and other list items, find `padding`/`margin` and reduce to `8.0` or `10.0`.
   - Find margin in Surah cards (e.g., around line `1723`: `margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)`) and list cards (e.g., around line `1829`: `margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)`). I'll change these horizontal margins to `8.0` or `10.0`.
3. **Reduce `lineHeight` in `ReaderPage`**:
   - In `lib/main.dart` around line `2166` and `2191`, `height: 2.2` needs to be changed to `height: 1.6`. Find all instances of `height: 2.2` inside `TextStyle`/`GoogleFonts` and change to `1.6`. Also check `1.8` at `2186` to align it.
4. **Fix Title Colors**:
   - In `lib/main.dart` at line `2168`, `color: widget.titleColor != null ? _parseColor(widget.titleColor!) ?? Theme.of(context).colorScheme.primary : dynamicTextColor`. We will enforce a single consistent color for the title hierarchy (no mixed red/blue) as requested. We can just use `Theme.of(context).colorScheme.primary`.
5. **Fault-tolerant Text Cleaning**:
   - In `lib/utils/string_extensions.dart`, rewrite `cleanSnippet` with a `try-catch` block, simple `startsWith('html')` matching, and simple `.replaceAll` for ligatures, returning `this` on failure.
6. **Pre-commit Checks**: Run pre commit check.
7. **Submit Changes**: Submit the branch.
