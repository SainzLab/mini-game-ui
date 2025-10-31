<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue';
import axios from 'axios';

const ROWS = 10;
const COLS = 10;
const MINES = 15;

const board = ref([]);
const isGameOver = ref(false);
const gameWon = ref(false);
const gameActive = ref(false);
const minesFlagged = ref(0);
const timer = ref(null);
const timeElapsed = ref(0);

const leaderboard = ref([]);
const isLoading = ref(true);
const medals = ['🥇', '🥈', '🥉'];

function createBoard() {
  const newBoard = Array.from({ length: ROWS }, (_, r) => 
    Array.from({ length: COLS }, (_, c) => ({
      isMine: false,
      isRevealed: false,
      isFlagged: false,
      adjacentMines: 0,
      row: r,
      col: c
    }))
  );
  board.value = newBoard;
}

function placeMines(firstClickRow, firstClickCol) {
  let minesPlaced = 0;
  while (minesPlaced < MINES) {
    const row = Math.floor(Math.random() * ROWS);
    const col = Math.floor(Math.random() * COLS);
    if (!board.value[row][col].isMine && !(row === firstClickRow && col === firstClickCol)) {
      board.value[row][col].isMine = true;
      minesPlaced++;
    }
  }
}

function calculateAdjacentMines() {
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      if (!board.value[r][c].isMine) {
        let count = 0;
        for (let dr = -1; dr <= 1; dr++) {
          for (let dc = -1; dc <= 1; dc++) {
            if (dr === 0 && dc === 0) continue;
            const nr = r + dr;
            const nc = c + dc;
            if (nr >= 0 && nr < ROWS && nc >= 0 && nc < COLS && board.value[nr][nc].isMine) {
              count++;
            }
          }
        }
        board.value[r][c].adjacentMines = count;
      }
    }
  }
}

function startGame() {
  createBoard();
  isGameOver.value = false;
  gameWon.value = false;
  gameActive.value = false;
  minesFlagged.value = 0;
  timeElapsed.value = 0;
  if (timer.value) clearInterval(timer.value);
  timer.value = null;
  fetchLeaderboard();
}

function handleLeftClick(cell) {
  if (isGameOver.value || cell.isRevealed || cell.isFlagged) return;

  if (!gameActive.value) {
    gameActive.value = true;
    placeMines(cell.row, cell.col);
    calculateAdjacentMines();
    timer.value = setInterval(() => timeElapsed.value++, 1000);
  }

  if (cell.isMine) {
    endGame(false);
    return;
  }

  revealCell(cell.row, cell.col);
  checkWinCondition();
}

function revealCell(r, c) {
  if (r < 0 || r >= ROWS || c < 0 || c >= COLS || board.value[r][c].isRevealed) {
    return;
  }
  const cell = board.value[r][c];
  cell.isRevealed = true;

  if (cell.adjacentMines === 0 && !cell.isMine) {
    for (let dr = -1; dr <= 1; dr++) {
      for (let dc = -1; dc <= 1; dc++) {
        if (dr === 0 && dc === 0) continue;
        revealCell(r + dr, c + dc);
      }
    }
  }
}

function handleRightClick(cell) {
  if (isGameOver.value || cell.isRevealed) return;
  if (!gameActive.value && !isGameOver.value) { 
    gameActive.value = true;
    timer.value = setInterval(() => timeElapsed.value++, 1000);
  }
  cell.isFlagged = !cell.isFlagged;
  minesFlagged.value += cell.isFlagged ? 1 : -1;
}

function checkWinCondition() {
  const revealedCount = board.value.flat().filter(cell => cell.isRevealed).length;
  if (revealedCount === ROWS * COLS - MINES) {
    endGame(true);
  }
}

function endGame(won) {
  isGameOver.value = true;
  gameActive.value = false;
  gameWon.value = won;
  clearInterval(timer.value);

  if (won) {
    saveScore();
  } else {
    board.value.flat().forEach(cell => {
      if (cell.isMine) cell.isRevealed = true;
    });
  }
}

async function saveScore() {
  if (timeElapsed.value === 0) return;
  try {
    const playerName = prompt("Selamat! Masukkan nama Anda:", `Pemain-${Date.now().toString().slice(-4)}`);
    if (!playerName) return;
    await axios.post('https://api.sainzlab.my.id/api/scores', {
      player_name: playerName,
      game_name: 'Minesweeper',
      score: timeElapsed.value
    });
    fetchLeaderboard();
  } catch (error) { console.error("Gagal menyimpan skor:", error); }
}

async function fetchLeaderboard() {
  isLoading.value = true;
  try {
    const response = await axios.get('https://api.sainzlab.my.id/api/scores/Minesweeper');
    leaderboard.value = response.data; 
  } catch (error) { console.error("Gagal mengambil leaderboard:", error); }
  finally { isLoading.value = false; }
}

onMounted(startGame);
onUnmounted(() => { if (timer.value) clearInterval(timer.value); });

const formattedTime = computed(() => {
  const minutes = Math.floor(timeElapsed.value / 60);
  const seconds = timeElapsed.value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
});

const adjacentMinesClass = (cell) => {
  return cell.adjacentMines > 0 ? `color-${cell.adjacentMines}` : '';
};
</script>

<template>
  <div class="page-container">
    <router-link to="/" class="back-button">← Kembali</router-link>

    <div class="minesweeper-card">
      <div class="game-main">
        <h1>Minesweeper</h1>
        
        <div class="stats-container">
          <div class="stat-box">
            <span class="stat-label">Ranjau</span>
            <span class="stat-value">💣 {{ MINES - minesFlagged }}</span>
          </div>
          <div class="stat-box">
            <span class="stat-label">Waktu</span>
            <span class="stat-value">⏱️ {{ formattedTime }}</span>
          </div>
        </div>

        <div class="board-container">
          <div class="board">
            <div 
              v-for="(cell, index) in board.flat()" 
              :key="index"
              class="cell"
              :class="{ 
                revealed: cell.isRevealed, 
                flagged: cell.isFlagged,
                mine: cell.isRevealed && cell.isMine 
              }"
              @click="handleLeftClick(cell)"
              @contextmenu.prevent="handleRightClick(cell)"
            >
              <span v-if="cell.isRevealed && !cell.isMine && cell.adjacentMines > 0" :class="adjacentMinesClass(cell)">
                {{ cell.adjacentMines }}
              </span>
              <span v-if="cell.isRevealed && cell.isMine">💥</span>
              <span v-if="cell.isFlagged && !cell.isRevealed">🚩</span>
            </div>
          </div>
        </div>

        <div class="status-message-container">
          <div class="status-message" :class="{ 'win': gameWon, 'loss': !gameWon, 'visible': isGameOver }">
            {{ gameWon ? 'Selamat, Anda Menang!' : 'Anda Kalah!' }}
          </div>
        </div>

        <button @click="startGame" class="reset-button">Mulai Ulang</button>
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
        <div v-else class="loading-text">Belum ada skor.</div>
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
  position: absolute; top: 1.5rem; left: 1.5rem;
  padding: 0.6rem 1.2rem; font-size: 0.9rem; font-weight: 600;
  color: var(--text-secondary, #a0a0a0);
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 8px; text-decoration: none;
  transition: all 0.2s ease-in-out; z-index: 10;
}
.back-button:hover { background-color: #2c3e50; color: #fff; }

.minesweeper-card {
  display: flex; flex-direction: column; gap: 2rem;
  width: 100%; max-width: 900px;
}
.game-main, .leaderboard-section {
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 16px; padding: 2rem; text-align: center;
}

h1, h3 { color: var(--accent-color, #e94560); margin: 0 0 1.5rem 0; }
h1 { font-size: 2.5rem; }
h3 { font-size: 1.5rem; }

.stats-container {
  display: flex; justify-content: space-around; gap: 1rem;
  background-color: var(--bg-color-deep, #10101a);
  padding: 1rem; border-radius: 12px; margin-bottom: 1.5rem;
}
.stat-box { display: flex; flex-direction: column; }
.stat-label { font-size: 0.9rem; color: var(--text-secondary, #a0a0a0); }
.stat-value { font-size: 1.8rem; font-weight: 700; color: #fff; }

.board-container {
  padding: 8px;
  background-color: var(--bg-color-deep, #10101a);
  border-radius: 8px;
  margin-bottom: 1rem;
}
.board {
  display: grid;
  grid-template-columns: repeat(10, 1fr);
  grid-template-rows: repeat(10, 1fr); 
  gap: 4px;
  max-width: 500px; 
  margin: 0 auto;
  aspect-ratio: 1/1;
}
.cell {
  background-color: #2c3e50;
  border-radius: 4px;
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 1.2rem;
  font-weight: bold;
  cursor: pointer;
  user-select: none;
  transition: all 0.2s ease;
  border-top: 3px solid #4a5568;
  border-left: 3px solid #4a5568;
  border-bottom: 3px solid #1a202c;
  border-right: 3px solid #1a202c;
  line-height: 1;
  overflow: hidden;
}
.cell:not(.revealed):active {
  transform: scale(0.95);
  border-top: 3px solid #1a202c;
  border-left: 3px solid #1a202c;
  border-bottom: 3px solid #4a5568;
  border-right: 3px solid #4a5568;
}

.cell.revealed {
  background-color: var(--bg-color-deep, #10101a);
  border: 1px solid #2c3e50;
  cursor: default;
}
.cell.flagged { font-size: 1.5rem; }
.cell.mine { background-color: #ff3333; animation: explode 0.5s forwards; }
@keyframes explode {
  from { transform: scale(0.5); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

.status-message-container { height: 2em; margin-bottom: 1rem; }
.status-message {
  font-size: 1.3rem; font-weight: bold;
  opacity: 0; transform: translateY(-10px);
  transition: opacity 0.3s ease, transform 0.3s ease;
}
.status-message.visible { opacity: 1; transform: translateY(0); }
.status-message.win { color: #33ff33; }
.status-message.loss { color: #ff3333; }

.reset-button {
  padding: 0.8rem 2rem; font-size: 1.1rem; font-weight: 600;
  color: #fff; background-color: var(--accent-color, #e94560);
  border: none; border-radius: 8px; cursor: pointer;
  transition: background-color 0.2s ease;
}
.reset-button:hover { background-color: var(--accent-hover, #ff6e87); }

.leaderboard-subtitle {
  font-size: 0.9rem; margin: -1.5rem 0 1.5rem 0;
  color: var(--text-secondary, #a0a0a0);
}
.leaderboard-list { list-style: none; padding: 0; margin: 0; }
.leaderboard-item { display: flex; justify-content: space-between; align-items: center; padding: 0.8rem 0; border-bottom: 1px solid var(--border-color, rgba(224, 224, 224, 0.2)); }
.leaderboard-item:last-child { border-bottom: none; }
.player-info { display: flex; align-items: center; gap: 1rem; }
.rank { font-weight: 700; font-size: 1.2rem; min-width: 35px; }
.player-name { font-weight: 600; }
.score-info { text-align: right; }
.score-value { font-weight: 700; font-size: 1.2rem; }
.score-label { display: block; font-size: 0.8rem; color: var(--text-secondary, #a0a0a0); }
.loading-text { color: var(--text-secondary, #a0a0a0); }

.color-1 { color: #00e676; }
.color-2 { color: #00b0ff; }
.color-3 { color: #ffea00; }
.color-4 { color: #ff9100; }
.color-5 { color: #ff1744; }
.color-6 { color: #d500f9; }
.color-7 { color: #6200ea; }
.color-8 { color: #3e2723; }

@media (min-width: 992px) {
  .page-container { align-items: center; padding: 1.5rem; }
  .minesweeper-card { flex-direction: row; align-items: flex-start; }
  .game-main { flex: 1.5; }
  .leaderboard-section { flex: 1; }
}
</style>