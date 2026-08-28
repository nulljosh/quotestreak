// webmcp.js — registers Quotestreak's game state and controls as WebMCP tools
// for agents visiting the page. Read-only tools first, then reversible writes.
//
// ponytail: tools delegate to the existing handlers exported by game.js
// (quotableStartGame/quotableChoose/quotableNextQuestion/etc) rather than
// reimplementing any game logic here.
(() => {
  const mc = document.modelContext;
  if (!mc?.registerTool) return;

  const tools = [
    {
      name: 'get_high_score',
      description: 'Get the player\'s all-time high score, stored locally in this browser.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => ({ highScore: window.quotableGetHighScore() }),
    },
    {
      name: 'get_game_state',
      description: 'Get the current game state: whether a game is in progress, mode, score, streak, selected genre, and the current question (quote, type, and answer options) if any.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => window.quotableGetState(),
    },
    {
      name: 'start_game',
      description: 'Start a new game. Resets score and streak, picks a quote pool for the given genre, and shows the first question.',
      inputSchema: {
        type: 'object',
        properties: {
          genre: { type: 'string', description: 'Genre to play, e.g. "all", "action", "comedy", "drama", "scifi", "classic", "pop", "rock", "hiphop", "rnb", "country".' },
          mode: { type: 'string', enum: ['normal', 'timed'], description: 'Game mode: "normal" (no timer) or "timed" (10s speed round per question).' },
        },
        required: ['mode'],
      },
      execute: async (args) => {
        if (args?.genre) window.quotableSetGenre(args.genre);
        window.quotableStartGame(args?.mode === 'timed');
        return window.quotableGetState();
      },
    },
    {
      name: 'answer_question',
      description: 'Answer the current question by picking one of the option strings from the current question\'s options.',
      inputSchema: {
        type: 'object',
        properties: {
          choice: { type: 'string', description: 'The exact option text to choose, from the current question\'s options list.' },
        },
        required: ['choice'],
      },
      execute: async (args) => {
        window.quotableChoose(args?.choice ?? null, null);
        return window.quotableGetState();
      },
    },
    {
      name: 'next_question',
      description: 'Advance to the next question, skipping the current one.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => {
        window.quotableNextQuestion();
        return window.quotableGetState();
      },
    },
  ];

  for (const tool of tools) {
    try {
      mc.registerTool(tool);
    } catch (err) {
      console.warn(`webmcp: failed to register tool "${tool.name}"`, err);
    }
  }
})();
