# rfw_ui: the documents behind the answers

Each of these answers one question asked of the kit, with what was measured
or tested to answer it. Where a claim has a test behind it, the test is named.

| Question | Document |
|---|---|
| Is it as fast as Flutter? What are the drawbacks, and what has been fixed? | [performance.md](performance.md): profile-mode numbers for plain Flutter, rfw and the kit, side by side; the benchmark is in [`../benchmark`](../benchmark) |
| Why is it slower than Flutter? | [why-slower.md](why-slower.md): a CPU profile of the same screen built three ways, the place in rfw's source behind each cost, and a patch to rfw measured against it |
| What is UiRuntime, and how is it held to rfw's behaviour? | [runtime.md](runtime.md): the kit's own runtime, what it does differently, the measured numbers, and the `.builder` widgets it runs |
| How does a screen animate, and what does a running animation cost? | [motion.md](motion.md): the one rule every animated widget follows, the effects, reduced motion, and what owns each controller |
| What is a widget's lifecycle, and does anything leak? | [lifecycle-and-memory.md](lifecycle-and-memory.md): every test runs under Flutter's leak tracker |
| Can the focus move to a particular input, or on when one is done? Do widgets take keys? | [focus-and-keys.md](focus-and-keys.md) |
| Can a studio file import another? | [studio-imports.md](studio-imports.md) |
| What can the kit not build yet? | [limits.md](limits.md) |
| How is a theme made, and how does the console edit all of ThemeData? | [theme.md](theme.md) |

And a skill for building screens with all of it from a design image:
[`skills/rfw-ui-from-image`](../../../skills/rfw-ui-from-image/SKILL.md).
