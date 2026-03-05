<script setup>
import { ref, computed } from 'vue';

const games = ref([
  {
    name: 'Batu Gunting Kertas',
    path: '/rock-paper-scissors',
    emoji: '🤘',
    description: 'Adu pilihanmu melawan komputer.',
    category: 'action'
  },
  {
    name: 'Snake',
    path: '/SnakeGame',
    emoji: '🐍',
    description: 'Pandu ular untuk memakan makanan.',
    category: 'action'
  },
  {
    name: 'Breakout',
    path: '/BreakoutGame',
    emoji: '🧱',
    description: 'Hancurkan balok dengan bola pantul.',
    category: 'action'
  },
 
  {
    name: 'Tetris',
    path: '/tetris',
    emoji: '🕹️',
    description: 'Susun balok yang jatuh untuk membersihkan baris.',
    category: 'brain'
  },
  {
    name: 'Tic Tac Toe',
    path: '/tic-tac-toe',
    emoji: '⚔️',
    description: 'Dapatkan tiga simbol dalam satu baris.',
    category: 'brain'
  },
  {
    name: 'Tebak Angka',
    path: '/guess-the-number',
    emoji: '🤔',
    description: 'Tebak angka rahasia komputer.',
    category: 'brain'
  },
  {
    name: 'Puzzle Geser',
    path: '/SlidingPuzzle',
    emoji: '🧩',
    description: 'Susun ulang gambar yang teracak.',
    category: 'brain'
  },
 
  {
    name: 'Minesweeper',
    path: '/MinesweeperGame',
    isBeta: true,
    description: 'Cari semua bom tanpa meledakkannya.',
  },
  {
    name: '2048',
    path: '/Game2048',
    isBeta: true,
    description: 'Gabungkan ubin untuk mencapai angka 2048.',
  },
  {
    name: 'Catur',
    path: '/ChessGame',
    isBeta: true,
    description: 'Permainan catur klasik 1v1.',
  },
]);

const actionGames = computed(() => games.value.filter(game => game.category === 'action' && !game.isBeta));
const brainTeaserGames = computed(() => games.value.filter(game => game.category === 'brain' && !game.isBeta));
const betaGames = computed(() => games.value.filter(game => game.isBeta));

</script>

<template>
  <div class="home-container">
    <div class="header">
      <h1 class="title">Pilih Game 🎮</h1>
      <p class="subtitle">Mini game by sainz</p>
    </div>

    <div class="category-section">
      <h2 class="category-title">Mengasah Otak</h2>
      <div class="game-grid">
        <router-link v-for="game in brainTeaserGames" :key="game.name" :to="game.path" class="game-card-link">
          <div class="game-card">
            <div class="game-icon">{{ game.emoji }}</div>
            <h3 class="game-name">{{ game.name }}</h3>
            <p class="game-description">{{ game.description }}</p>
          </div>
        </router-link>
      </div>
    </div>
    
    <div class="category-section">
      <h2 class="category-title">Aksi & Kecepatan</h2>
      <div class="game-grid">
        <router-link v-for="game in actionGames" :key="game.name" :to="game.path" class="game-card-link">
          <div class="game-card">
            <div class="game-icon">{{ game.emoji }}</div>
            <h3 class="game-name">{{ game.name }}</h3>
            <p class="game-description">{{ game.description }}</p>
          </div>
        </router-link>
      </div>
    </div>

    <div class="category-section" v-if="betaGames.length > 0">
      <h2 class="category-title">Uji Coba (Beta)</h2>
      <div class="game-grid">
        <router-link v-for="game in betaGames" :key="game.name" :to="game.path" class="game-card-link">
          <div class="game-card beta">
            <div class="beta-badge">BETA</div>
            <h3 class="game-name">{{ game.name }}</h3>
            <p class="game-description">{{ game.description }}</p>
          </div>
        </router-link>
      </div>
    </div>

    <footer class="footer">
      <p>&copy; 2026 Sainzlab | Muhammad Fazli M</p>
    </footer>
  </div>
</template>

<style scoped>

.home-container {
  max-width: 1200px;
  margin: 0 auto;
  padding: 3rem 1.5rem;
  font-family: 'Poppins', sans-serif;
  color: var(--text-primary, #e0e0e0);
}

.header {
  text-align: center;
  margin-bottom: 4rem;
}

.title {
  font-size: 3rem;
  font-weight: 700;
  margin-bottom: 0.5rem;
  color: var(--accent-color, #e94560);
  text-shadow: 0 0 10px var(--shadow-glow, rgba(233, 69, 96, 0.5));
}

.subtitle {
  font-size: 1.25rem;
  color: var(--text-secondary, #a0a0a0);
}

.category-section {
  margin-bottom: 4rem;
}

.category-title {
  font-size: 1.8rem;
  font-weight: 600;
  padding-bottom: 0.8rem;
  border-bottom: 2px solid var(--border-color, rgba(224, 224, 224, 0.2));
  display: inline-block;
  margin-bottom: 2rem;
}

.game-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1.5rem;
}

.game-card-link {
  text-decoration: none;
  color: inherit;
}

.game-card {
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 16px;
  padding: 1.5rem;
  text-align: center;
  box-shadow: 0 8px 32px 0 rgba(0, 0, 0, 0.37);
  transition: transform 0.3s ease, box-shadow 0.3s ease;
  height: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  position: relative;
  overflow: hidden;
}

.game-card:hover {
  transform: translateY(-10px);
  box-shadow: 0 12px 40px 0 rgba(0, 0, 0, 0.5);
}

.game-icon {
  font-size: 3.5rem;
  margin-bottom: 1rem;
  line-height: 1;
}

.beta-badge {
  position: absolute;
  top: 12px;
  right: -35px;
  transform: rotate(45deg);
  background-color: var(--accent-color, #e94560);
  color: white;
  padding: 2px 40px;
  font-size: 0.75rem;
  font-weight: 700;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.2);
  letter-spacing: 1px;
}

.game-card.beta .game-name {
  margin-top: 1rem;
}

.game-name {
  font-size: 1.3rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.game-description {
  font-size: 0.9rem;
  color: var(--text-secondary, #a0a0a0);
  line-height: 1.4;
}

.footer {
  text-align: center;
  margin-top: 2rem;
  padding-top: 2rem;
  border-top: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  color: var(--text-secondary, #a0a0a0);
}
</style>