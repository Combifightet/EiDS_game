# Game Design Concept

---

## High Level Concept/Design

### Working title

> Your game’s title should communicate the gameplay and the style of the game

**EidS Game** _(maby find an acronym for "EidS")_

- **E**nter **i**n **d**isguise, **S**teal!

### Concept statement

> The game in a tweet: one or two sentences at most that say what the game is and why it’s fun.

An isometric, urban break in simulator, that keeps you on the edge of your seat.

### Genre(s)

> Single genre is clearer but often less interesting. Genre combinations can be risky. Beware of ‘tired’ genres.

- isometric
- point and click
- stealth / strategy ?
- procedural (roguelite?)

### Target audience

> Motivations and relevant interests; potentially age, gender, etc.; and the desired ESRB rating for the game.

- Students (lol)

### Unique Selling Points

> Critically important. What makes your game stand out? How is it different from all other games?

- procedural building layout generation
- game in 3d rendered to 2d pixel art

---

## Product Design

### Player Experience and Game POV

> Who is the player? What is the setting? What is the fantasy the game grants the player? What emotions do you want the player to feel? What keeps the player engaged for the duration of their play?

The player is a member of a small ounderground crime organization that focuses on theft. For the duration of a run he should be constantly weary of his souroundings and plan carefully.

### Visual and Audio Style

> What is the “look and feel” of the game? How does this support the desired player’s experience? What concept art or reference art can you show to give the feel of the game?

The whole game will be held in a pixel art asthetc to ensure visual distinction for key elements

### Game World Fiction

> Briefly describe the game world and any narrative in player-relevant terms (as presented to the player).

You play as a new member member of the `<insert gang name>` and are tasked with the teft of some valuable (or not?) object from the house of some unsuspecting citicen.

#### Gang Names

- **Phantom Troupe** — _“We perform. You won't notice.”_
  - Symbol: a half-mask and stage curtain
  - Flavor: Operatic flair, smoke and shadow entrances
- **Nightshroud Clan** — _“Darkness is our wardrobe.”_
  - Symbol: hooded silhouette.
  - Flavor: Operate after dusk
- **The Thousand Faces** — _“We are everyone.”_
  - Symbol: A fractured mirror arranged into a monstrous grin.
  - Flavor: Legends say no one’s ever seen their true faces. Each disguise adds to the “monster’s” growing count.

> **Lore Hook:** \
> The Phantom Troupe are the performers. \
> The Nightshroud Clan are the watchers. \
> Both unknowingly serve the Thousand Faces, the unseen puppeteer that trades and consumes identities. \
> Every disguise in the city — every mask, ID, alias — ultimately traces back to it.

### Monetization

> How will the game make money? Premium purchase? F2P? How do you justify this within the design?

_No monetization plans yet, but might release for purchase._

### Platform(s), Technology, and Scope (brief)

> PC or mobile? Table or phone? 2D or 3D? Unity or Javascript? How long to make, and how big a team? How long to first-playable? How long to complete the game? Major risks?

Initial support only for PC, (but keep options to add console support later down the line).

---

## Detailed & Game Systems Design

### Core Loops

> How do game objects and the player’s actions form loops? Why is this engaging? How does this support player goals? What emergent results do you expect/hope to see? If F2P, where are the monetization points?

Each robbery is independant, but progession could be handles via global unlocks.

### Objectives and Progression

> How does the player move through the game, literally and figuratively, from tutorial to end? What are their short-term and long-term goals (explicit or implicit)? How do these support the game concept, style, and player-fantasy?

0. maybe warnings for sensitive users, and calibration (black values) _only on first startup_
1. Start menu with settings and start button
2. level / difficulty selection (if unlocked)
3. complete break in (or fail the level)
4. result screen, that shows stats
5. _return to main menu_

### Game Systems

> What systems are needed to make this game? Which ones are internal (simulation, etc.) and which does the player interact with?

- tile based moovement and interactions
- procedural building generation
- character selector

### Interactivity

> How are different kinds of interactivity used? (Action/Feedback, ST Cog, LT Cog, Emotional, Social, Cultural) What is the player doing moment-by-moment? How does the player move through the world? How does physics/combat/etc. work? A clear, professional-looking sketch of the primary game UX is helpful.
