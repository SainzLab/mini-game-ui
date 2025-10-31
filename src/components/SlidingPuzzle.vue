<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue';
import axios from 'axios';

const SIZE = 3;
const tiles = ref([]);
const emptyTile = ref({ row: 0, col: 0 });
const moves = ref(0);
const isSolved = ref(false);
const timeElapsed = ref(0);
const timer = ref(null);
const gameActive = ref(false);

const leaderboard = ref([]);
const isLoading = ref(true);
const medals = ['🥇', '🥈', '🥉']; 

function createSolvedBoard() {
  const newTiles = [];
  let count = 1;
  for (let i = 0; i < SIZE; i++) {
    newTiles[i] = [];
    for (let j = 0; j < SIZE; j++) {
      newTiles[i][j] = count++;
    }
  }
  newTiles[SIZE - 1][SIZE - 1] = null;
  return newTiles;
}

function shuffleBoard() {
  let board = createSolvedBoard();
  let empty = { row: SIZE - 1, col: SIZE - 1 };

  for (let i = 0; i < 1000; i++) {
    const neighbors = [];
    if (empty.row > 0) neighbors.push({ row: empty.row - 1, col: empty.col });
    if (empty.row < SIZE - 1) neighbors.push({ row: empty.row + 1, col: empty.col });
    if (empty.col > 0) neighbors.push({ row: empty.row, col: empty.col - 1 });
    if (empty.col < SIZE - 1) neighbors.push({ row: empty.row, col: empty.col + 1 });
    
    const randomMove = neighbors[Math.floor(Math.random() * neighbors.length)];
    
    board[empty.row][empty.col] = board[randomMove.row][randomMove.col];
    board[randomMove.row][randomMove.col] = null;
    empty = randomMove;
  }

  tiles.value = board;
  emptyTile.value = empty;
}

function startGame() {
  shuffleBoard();
  moves.value = 0;
  isSolved.value = false;
  gameActive.value = false;
  
  timeElapsed.value = 0;
  if (timer.value) clearInterval(timer.value);
  timer.value = null;
}

async function saveScore() {
  if (timeElapsed.value === 0) return;
  try {
    const playerName = prompt("Puzzle Selesai! Masukkan nama Anda:", `Pemain-${Date.now().toString().slice(-4)}`);
    if (!playerName) return;
    
    await axios.post('https://api.sainzlab.my.id/api/scores', {
      player_name: playerName,
      game_name: 'Puzzle Geser',
      score: timeElapsed.value
    });
    fetchLeaderboard();
  } catch (error) {
    console.error("Gagal menyimpan skor:", error);
  }
}

async function fetchLeaderboard() {
  isLoading.value = true;
  try {
    const response = await axios.get('https://api.sainzlab.my.id/api/scores/Puzzle Geser');
    
    leaderboard.value = response.data
      .sort((a, b) => a.score - b.score) 
      .slice(0, 5);
      
  } catch (error) {
    console.error("Gagal mengambil leaderboard:", error);
    leaderboard.value = []; 
  } finally {
    isLoading.value = false;
  }
}

function checkWin() {
  const solvedBoard = createSolvedBoard();
  for (let i = 0; i < SIZE; i++) {
    for (let j = 0; j < SIZE; j++) {
      if (tiles.value[i][j] !== solvedBoard[i][j]) {
        return false;
      }
    }
  }
  isSolved.value = true;
  gameActive.value = false;
  clearInterval(timer.value);
  saveScore();
  return true;
}

function handleTileClick(row, col) {
  if (isSolved.value) return;

  if (!gameActive.value && !isSolved.value) {
    gameActive.value = true;
    timer.value = setInterval(() => {
      timeElapsed.value++;
    }, 1000);
  }

  const dx = Math.abs(row - emptyTile.value.row);
  const dy = Math.abs(col - emptyTile.value.col);

  if ((dx === 1 && dy === 0) || (dx === 0 && dy === 1)) {
    tiles.value[emptyTile.value.row][emptyTile.value.col] = tiles.value[row][col];
    tiles.value[row][col] = null;
    emptyTile.value = { row, col };
    moves.value++;
    checkWin();
  }
}

onMounted(() => {
  startGame();
  fetchLeaderboard();
});

onUnmounted(() => {
  if (timer.value) clearInterval(timer.value);
});

const formattedTime = computed(() => {
  const minutes = Math.floor(timeElapsed.value / 60);
  const seconds = timeElapsed.value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
});
</script>

<template>
  <div class="page-container">
    <router-link to="/" class="back-button">← Kembali</router-link>

    <div class="card puzzle-card">
      <div class="puzzle-main">
        <h1>Puzzle Geser</h1>
        
        <div class="stats-container">
          <div class="stat-box">
            <span class="stat-label">Langkah</span>
            <span class="stat-value">{{ moves }}</span>
          </div>
          <div class="stat-box">
            <span class="stat-label">Waktu</span>
            <span class="stat-value">{{ formattedTime }}</span>
          </div>
        </div>
        
        <p v-if="isSolved" class="status solved">✨ Selesai! ✨</p>

        <div class="board">
          <div v-for="(row, rowIndex) in tiles" :key="rowIndex" class="puzzle-row">
            <div 
              v-for="(tile, colIndex) in row" 
              :key="colIndex"
              class="tile"
              :class="{ 'empty': tile === null, 'solved': isSolved }"
              @click="handleTileClick(rowIndex, colIndex)"
            >
              {{ tile }}
            </div>
          </div>
        </div>

        <button @click="startGame" class="reset-button">Acak Ulang</button>
      </div>

      <div class="leaderboard-section">
        <h3>🏆 Leaderboard</h3>
        <p class="leaderboard-subtitle">Waktu tercepat lebih baik!</p>
        <div v-if="isLoading" class="loading-text">Memuat...</div>
        <ul v-else-if="leaderboard.length > 0" class="leaderboard-list">
          <li v-for="(item, index) in leaderboard" :key="item.id" class="leaderboard-item">
            <div class="player-info">
              <span class="rank">{{ medals[index] || `#${index + 1}` }}</span>
              <span class="player-name">{{ item.player_name }}</span>
            </div>
            <div class="score-info">
              <span class="score-value">{{ Math.floor(item.score / 60) }}:{{ String(item.score % 60).padStart(2, '0') }}</span>
              <span class="score-label">waktu</span>
            </div>
          </li>
        </ul>
        <div v-else class="loading-text">Belum ada skor. Jadilah yang pertama!</div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-container {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: flex-start;
  min-height: 100vh;
  padding: 6rem 1.5rem 1.5rem 1.5rem;
  font-family: 'Poppins', sans-serif;
  color: var(--text-primary, #e0e0e0);
}

.back-button {
  position: absolute;
  top: 1.5rem;
  left: 1.5rem;
  padding: 0.6rem 1.2rem;
  font-size: 0.9rem;
  font-weight: 600;
  color: var(--text-secondary, #a0a0a0);
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 8px;
  text-decoration: none;
  transition: all 0.2s ease-in-out;
  z-index: 10;
}
.back-button:hover {
  background-color: #2c3e50;
  color: #fff;
}

.puzzle-card {
  display: flex;
  flex-direction: column;
  gap: 2rem;
  width: 100%;
  max-width: 900px;
}

.puzzle-main, .leaderboard-section {
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 16px;
  padding: 2rem;
  text-align: center;
}

h1, h3 {
  color: var(--accent-color, #e94560);
  margin: 0 0 1.5rem 0;
}
h1 { font-size: 2.5rem; }
h3 { font-size: 1.5rem; }

.stats-container {
  display: flex;
  justify-content: center;
  gap: 2rem;
  margin-bottom: 1.5rem;
}
.stat-box {
  background-color: var(--bg-color-deep, #10101a);
  padding: 0.8rem 1.5rem;
  border-radius: 8px;
  display: flex;
  flex-direction: column;
}
.stat-label {
  font-size: 0.9rem;
  color: var(--text-secondary, #a0a0a0);
}
.stat-value {
  font-size: 1.8rem;
  font-weight: 700;
  color: #fff;
}

.status.solved {
  color: #33ff33;
  font-weight: bold;
  margin-bottom: 1rem;
}

.board {
  display: flex;
  flex-direction: column;
  gap: 8px;
  background-color: var(--bg-color-deep, #10101a);
  border-radius: 12px;
  padding: 8px;
  margin: 0 auto 1.5rem auto;
  max-width: 400px;
}
.puzzle-row {
  display: flex;
  gap: 8px;
}
.tile {
  flex: 1;
  aspect-ratio: 1 / 1;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: #2c3e50;
  border-radius: 8px;
  font-size: 2rem;
  font-weight: 700;
  color: #fff;
  cursor: pointer;
  user-select: none;
  transition: transform 0.2s cubic-bezier(0.25, 1, 0.5, 1), background-color 0.2s;
}
.tile:hover {
  background-color: #4a5568;
  transform: scale(1.05);
}
.tile.empty {
  background-color: transparent;
  cursor: default;
  transform: none;
}
.tile.solved {
  background-color: var(--accent-color, #e94560);
  color: #fff;
}

.reset-button {
  padding: 0.8rem 2rem;
  font-size: 1.1rem;
  font-weight: 600;
  color: #fff;
  background-color: var(--accent-color, #e94560);
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s ease;
}
.reset-button:hover {
  background-color: var(--accent-hover, #ff6e87);
}

.leaderboard-subtitle {
  font-size: 0.9rem;
  margin: -1.5rem 0 1.5rem 0;
  color: var(--text-secondary, #a0a0a0);
}
.leaderboard-list {
  list-style: none;
  padding: 0;
  margin: 0;
}
.leaderboard-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.8rem 0;
  border-bottom: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
}
.leaderboard-item:last-child { border-bottom: none; }
.player-info { display: flex; align-items: center; gap: 1rem; }
.rank { font-weight: 700; font-size: 1.2rem; min-width: 35px; }
.player-name { font-weight: 600; }
.score-info { text-align: right; }
.score-value { font-weight: 700; font-size: 1.2rem; }
.score-label { display: block; font-size: 0.8rem; color: var(--text-secondary, #a0a0a0); }

@media (min-width: 992px) {
  .page-container {
    align-items: center;
    padding: 1.5rem;
  }
  .puzzle-card {
    flex-direction: row;
    align-items: flex-start;
  }
  .puzzle-main {
    flex: 2; 
  }
  .leaderboard-section {
    flex: 1; 
  }
}
</style>