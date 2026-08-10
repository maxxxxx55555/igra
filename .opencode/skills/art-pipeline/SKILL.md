---
name: art-pipeline
description: External art generation pipeline
---
Art is generated outside the repo: Meshy (3D), Mixamo (anim), image gen (textures).
Write prompts to docs/ART_PROMPTS.md, docs/TEXTURE_PROMPTS.md, docs/ANIMATION_GUIDE.md.
Code must work with placeholders; wire real .glb via scripts/tools/_replace_placeholders.gd
when the user drops files into assets/models/.
