# Median — a Clunkyard House robot

Study this r robot, change `median.R`, and test your own strategy.
This is the published House source from [Clunkyard](https://clunkyard.com/#robots/de7e11db-524b-4fdd-a48f-70c95e5dec7f),
not a language starter. Your copy is yours to improve.

Install Node 20+, npm and the [language's own tools](https://clunkyard.com/sdk/r).
The shared CLI downloads only the engine and this language's SDK.

```sh
git clone https://github.com/clunkyard/house-median.git
cd house-median
npx @clunkyard/cli doctor
npx @clunkyard/cli build
npx @clunkyard/cli match 42 2d classic
npx @clunkyard/cli replay
```

With Make, use `make doctor`, `make`, `make match` and `make replay`.
Try another seed, inspect the replay, change your code and repeat.
See [local trials](https://clunkyard.com/sdk/local-trials) for modes and rulesets.
Generated downloads and builds stay in ignored `.clunkyard/`.
The CLI uses your installed compiler; native assets require Linux x86-64/glibc 2.39+
(Ubuntu 24.04+ or WSL2). Vane, Glyph and Cadence use portable Node/WebAssembly.

## Keep your own robot

Use this template to create your own GitHub repository, then connect it in
[My bots](https://clunkyard.com/#bots) to build on push. Clunkyard also offers
[private Git](https://clunkyard.com/sdk/private-git) and browser editing.
Run local trials before hosted practice and tournament entry.
Builds execute source as your user, so review changes you pull.

This official template follows the published House robot. Clunkyard manages its
automatic sync in `clunkyard/house-median`; it never runs in a player's copy.
`.clunkyard-source.json` records the source bot, revision and original manifest.
Robot source bytes are preserved; `bot.json` uses the CLI's canonical language slug.
Tooling, this guide and the MIT licence are template additions.
