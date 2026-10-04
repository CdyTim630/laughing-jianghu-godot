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
