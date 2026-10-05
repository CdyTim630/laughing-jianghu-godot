# 戰鬥角色生成記錄

工具：內建 imagegen；透明背景；參考 `assets/art/fighters.png`；輸出 `assets/art/battle-sprites.png`。圖集在 Godot 內個別取樣，保留原始 PNG 與透明度。

提示詞：

> Use case: stylized-concept. Asset type: transparent sprite atlas for a 2D comedic wuxia game. Reference image: character identity and ink illustration style only. Generate one wide image containing FOUR separate full-body chibi fighting sprites arranged in FOUR EQUAL-WIDTH columns, left to right matching reference: 1 red headband hot-blooded young swordsman red robe; 2 white-haired elderly blue-robed sword sage; 3 vain ornate gold-robed young man holding a golden fan; 4 black hooded mysterious fighter with a comical white duck face mask and orange bill. Each character faces toward the RIGHT in a readable three-quarter fighting stance, full body including feet and weapon entirely within its own equal-width column with generous transparent margins and NO overlap. Exaggerated 3-head-tall proportions, expressive face, beautiful bold ink outlines and restrained textured watercolor rendering matching source. Feet share a common baseline near the bottom. Genuine transparent background, no landscape, no floor shadows, no text, no panels, no labels, no watermark. Keep identity recognizable; these sprites will be individually sampled by equal column regions in a game renderer.

封面與肖像提示詞見同批交付提案的「素材與使用說明.md」。

## 最終版構圖

工具同上；改為 2×2 圖集，輸出 `assets/art/battle-sprites-v2.png`，以避免角色武器或衣角跨格。

> Use case: stylized-concept. Asset type: game character sprite atlas. Use reference only for exact four identities and ink watercolor style. Make a SQUARE transparent sprite sheet in a strict TWO BY TWO grid. Top left red robe hot-blooded young swordsman with red headband; top right white-haired elderly blue robe sword sage; bottom left vain gold robe young man with gold fan; bottom right black hooded duck mask martial artist. All are 3-head-tall chibi full-body fighters in neutral fighting stance, three-quarter facing RIGHT. CRITICAL: each entire figure AND weapon must be smaller than its quadrant and have at least 12% empty transparent margin on EVERY side of its quadrant; no garment, loose brushstroke or weapon may cross into another quadrant. Four standalone characters with no overlap. Entire head, arms, sword/fan, robe and feet fully visible. No floor shadows, no ground, no panels, no labels, no scenery, no words. Actual transparent alpha background. Render same polished textured ink art as source, readable silhouettes, comedic expressions.

## itch.io 橫式封面（600×300）

工具：內建 imagegen；參考 `assets/art/cover.png`，生成 1774×887 的 2:1 原圖，再以 macOS sips 等比例輸出為精確 600×300 PNG。成品：`docs/笑嗷江糊_遊戲封面_600x300.png`。

> Create a polished 2:1 horizontal cover for a comedic wuxia strategy game. Left half deep charcoal ink negative space with large cream Traditional Chinese title “笑嗷江糊”, below vermilion subtitle “不講武德大會”. Right half mischievous red-and-black-robed tournament host at an antique sound mixer holding a microphone, ring fight and cheering crowd behind. Ink watercolor, cream paper, charcoal, vermilion and muted gold. Generous safe margins, readable thumbnail typography. Only the two title lines, no logos or watermark. Reference the existing cover's personality and art style.


## v0.2.0 場地背景（2026-10-05）

使用內建 imagegen 工具生成；石台為風格基準，另兩張使用石台圖作為畫風與構圖參考。未使用 Nintendo 圖片或角色素材。原始 PNG 保留，Godot 以保持比例的全景裁切呈現。

### assets/art/arena-stone.png

```text
Use case: stylized-concept. Production background for a humorous wuxia 2D fighting game, a SUNNY STONE COURTYARD TOURNAMENT. Wide panoramic 16:9 composition, full scene with no UI, no text, no fighters. View front-facing at arena spectator eye height, a flat horizontal walkable foreground covering the lower 42% of the image with clean warm cream stone slabs, baseline for fighter feet near bottom. In the upper background: jade teal mountains, elegant Chinese ancestral temple roof, vermilion festival pennants and golden lanterns, distant tiny simplified cheerful audience behind wooden railings, banners WITHOUT writing. Hand-painted polished illustrated game art, bold expressive ink edges and gouache watercolor textures, chunky charming simplified shapes, cohesive teal, vermilion and honey gold accents. Strong layer separation: calm light floor and quiet central background, richer detail only at upper corners. Bright joyful midday lighting, blue sky, warm cinematic highlights, crisp appealing illustrated environment. Center must remain spacious, readable and uncluttered for two large chibi martial artists to be composited later. Exclude foreground people, weapons, HUDs, lettering, logos, watermarks and photo realism. Output a single wide landscape arena background.
```

### assets/art/arena-oil.png

```text
Use case: stylized-concept. Reference image is the approved art style and composition for our 2D wuxia fighting game. Generate a NEW companion arena: SLIPPERY BAMBOO NIGHT MARKET. Keep the same panoramic 16:9 front-facing spectator-height camera, polished chunky ink-edged gouache illustration, calm unobstructed floor covering lower42%, feet baseline near bottom, tiny audience behind far railings only. Replace temple courtyard with an elegant playful bamboo grove tournament market at amber dusk. Emerald and jade bamboo arches at far sides, whimsical tilted red festival lanterns, small tea stalls, golden oil jars at corners, softly lit teal hills and mist in distance. Broad smooth wooden fighting platform with subtle shiny spilled oil ribbons visible on the floor; dry central area light honey colored and readable behind chibi fighters. Strong jade teal, vermilion, honey gold palette consistent with reference; warmer orange highlights but not dark. High production quality illustrated videogame environment. Quiet spacious center for two large fighters, richer scenery uppercorners. No fighters or foreground people, no interface, no text, no letters, no logos, no watermark. Single complete wide background.
```

### assets/art/arena-echo.png

```text
Use case: stylized-concept. Reference image is the approved art style and composition for our 2D wuxia fighting game. Generate a NEW companion arena: ECHO GONG MOUNTAIN VALLEY. Keep same panoramic16:9 front-facing spectator-height camera and polished chunky ink-edged gouache illustration with calm uncluttered light floor covering lower42% and feet baseline near bottom. A beautiful mountain cliff tournament stage at luminous blue twilight, jade peaks and waterfalls, pale round moon, hanging huge ornate bronze gongs on sturdy wooden frames only at far left and far right, red ribbons and golden lanterns, tiny distant cheering audience behind stone railings. Broad pale jade stone combat platform with faint concentric echo patterns, quiet spacious central background, atmosphericcyan and indigo hills, teal+vermillion+honeygold accents, soft luminous highlights, festive and magical not ominous. Preserve charming stylized simplifiedshapes and clean silhouettes consistent withreference. Rich detail confined to uppercorners with readable clear empty stage. No fighters or foregroundpeople, no HUD, no writing, no labels, no logos, no watermark. Single complete wide arena background.
```
