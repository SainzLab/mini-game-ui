<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue';
import axios from 'axios';

const GRID_SIZE = 4;
const board = ref([]);
const score = ref(0);
const isGameOver = ref(false);
const gameWon = ref(false);
const leaderboard = ref([]);
const isLoading = ref(true);
const medals = ['🥇', '🥈', '🥉'];

function createEmptyBoard() {
  return Array.from({ length: GRID_SIZE }, () => Array(GRID_SIZE).fill(0));
}

function startGame() {
  board.value = createEmptyBoard();
  score.value = 0;
  isGameOver.value = false;
  gameWon.value = false;
  addRandomTile();
  addRandomTile();
  fetchLeaderboard();
}

function addRandomTile() {
  const emptyTiles = [];
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      if (board.value[r][c] === 0) {
        emptyTiles.push({ r, c });
      }
    }
  }
  if (emptyTiles.length > 0) {
    const { r, c } = emptyTiles[Math.floor(Math.random() * emptyTiles.length)];
    board.value[r][c] = Math.random() < 0.9 ? 2 : 4;
  }
}

function slideAndCombine(row) {
  let filteredRow = row.filter(tile => tile !== 0);
  for (let i = 0; i < filteredRow.length - 1; i++) {
    if (filteredRow[i] === filteredRow[i + 1]) {
      filteredRow[i] *= 2;
      score.value += filteredRow[i];
      if (filteredRow[i] === 2048) gameWon.value = true;
      filteredRow[i + 1] = 0;
    }
  }
  let newRow = filteredRow.filter(tile => tile !== 0);
  while (newRow.length < GRID_SIZE) {
    newRow.push(0);
  }
  return newRow;
}

function rotateBoard(boardToRotate) {
  const newBoard = createEmptyBoard();
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      newBoard[r][c] = boardToRotate[GRID_SIZE - 1 - c][r];
    }
  }
  return newBoard;
}

function move(direction) {
  if (isGameOver.value) return;
  const originalBoard = JSON.stringify(board.value);
  let currentBoard = JSON.parse(JSON.stringify(board.value));

  if (direction === 'up') currentBoard = rotateBoard(currentBoard);
  if (direction === 'right') {
    currentBoard = rotateBoard(currentBoard);
    currentBoard = rotateBoard(currentBoard);
  }
  if (direction === 'down') {
    currentBoard = rotateBoard(currentBoard);
    currentBoard = rotateBoard(currentBoard);
    currentBoard = rotateBoard(currentBoard);
  }

  for (let r = 0; r < GRID_SIZE; r++) {
    currentBoard[r] = slideAndCombine(currentBoard[r]);
  }

  if (direction === 'up') {
    currentBoard = rotateBoard(currentBoard);
    currentBoard = rotateBoard(currentBoard);
    currentBoard = rotateBoard(currentBoard);
  }
  if (direction === 'right') {
    currentBoard = rotateBoard(currentBoard);
    currentBoard = rotateBoard(currentBoard);
  }
  if (direction === 'down') currentBoard = rotateBoard(currentBoard);
  
  board.value = currentBoard;

  if (JSON.stringify(board.value) !== originalBoard) {
    addRandomTile();
    checkGameOver();
  }
}

function checkGameOver() {
  for (let r = 0; r < GRID_SIZE; r++) {
    for (let c = 0; c < GRID_SIZE; c++) {
      if (board.value[r][c] === 0) return;
      if (r < GRID_SIZE - 1 && board.value[r][c] === board.value[r + 1][c]) return;
      if (c < GRID_SIZE - 1 && board.value[r][c] === board.value[r][c + 1]) return;
    }
  }
  isGameOver.value = true;
  saveScore();
}

async function saveScore() {
  if (score.value === 0) return;
  try {
    const playerName = prompt("Game Over! Masukkan nama Anda:", `Pemain-${Date.now().toString().slice(-4)}`);
    if (!playerName) return;
    
    await axios.post('https://api.sainzlab.my.id/api/scores', {
      player_name: playerName,
      game_name: '2048',
      score: score.value
    });
    fetchLeaderboard();
  } catch (error) { console.error("Gagal menyimpan skor:", error); }
}

async function fetchLeaderboard() {
  isLoading.value = true;
  try {
    const response = await axios.get('https://api.sainzlab.my.id/api/scores/2048');
    leaderboard.value = response.data;
  } catch (error) { console.error("Gagal mengambil leaderboard:", error); }
  finally { isLoading.value = false; }
}

function handleKeyDown(event) {
  if (isGameOver.value) return;
  if (['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(event.key)) {
    event.preventDefault();
  }
  switch (event.key) {
    case 'ArrowUp': move('up'); break;
    case 'ArrowDown': move('down'); break;
    case 'ArrowLeft': move('left'); break;
    case 'ArrowRight': move('right'); break;
  }
}

onMounted(() => {
  startGame();
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
});

const tileColorClass = (value) => {
  if (value === 0) return 'tile-0';
  return `tile-${value > 2048 ? 'super' : value}`;
};
</script>

<template>
  <div class="page-container">
    <router-link to="/" class="back-button">← Kembali</router-link>

    <div class="game-2048-card">
      <div class="game-main">
        <div class="header">
          <h1>2048</h1>
          <div class="score-container">
            <div class="score-box">
              <span class="label">SKOR</span>
              <span class="value">{{ score }}</span>
            </div>
          </div>
        </div>
        
        <div class="board-container">
          <div class="board">
            <div v-for="(row, r) in board" :key="r" class="board-row">
              <div v-for="(tile, c) in row" :key="c" class="tile-container">
                <div class="tile" :class="tileColorClass(tile)">
                  {{ tile > 0 ? tile : '' }}
                </div>
              </div>
            </div>
          </div>
          <div v-if="isGameOver || gameWon" class="overlay">
            <h2>{{ gameWon ? 'Anda Menang!' : 'Game Over!' }}</h2>
            <button @click="startGame" class="reset-button">Main Lagi</button>
          </div>
        </div>

        <div class="controls-info">Gunakan tombol panah untuk bermain.</div>

        <div class="mobile-controls">
          <div class="d-pad">
            <div class="d-pad-cell"></div>
            <button @click="move('up')" class="control-btn">↑</button>
            <div class="d-pad-cell"></div>
            <button @click="move('left')" class="control-btn">←</button>
            <div class="d-pad-cell center"></div>
            <button @click="move('right')" class="control-btn">→</button>
            <div class="d-pad-cell"></div>
            <button @click="move('down')" class="control-btn">↓</button>
            <div class="d-pad-cell"></div>
          </div>
        </div>
      </div>
      
      <div class="leaderboard-section">
        <h3>🏆 Leaderboard</h3>
        <div v-if="isLoading" class="loading-text">Memuat...</div>
        <ul v-else-if="leaderboard.length > 0" class="leaderboard-list">
          <li v-for="(item, index) in leaderboard" :key="item.id" class="leaderboard-item">
            <div class="player-info">
              <span class="rank">{{ medals[index] || `#${index + 1}` }}</span>
              <span class="player-name">{{ item.player_name }}</span>
            </div>
            <strong class="score-value">{{ item.score }}</strong>
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

.game-2048-card {
  display: flex; flex-direction: column; gap: 2rem;
  width: 100%; max-width: 1000px;
}
.game-main {
  flex: 2;
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 16px; padding: 2rem;
}
.leaderboard-section {
  flex: 1;
  background-color: var(--bg-card, #16213e);
  border: 1px solid var(--border-color, rgba(224, 224, 224, 0.2));
  border-radius: 16px; padding: 2rem;
}

.header {
  display: flex; justify-content: space-between; align-items: center; margin-bottom: 2rem;
}
h1 { font-size: 3rem; font-weight: 700; color: #fff; margin: 0;}
.score-box {
  background-color: var(--bg-color-deep, #10101a);
  padding: 0.8rem 1.5rem; border-radius: 8px;
  display: flex; flex-direction: column; text-align: center;
}
.score-box .label { font-size: 0.9rem; color: var(--text-secondary, #a0a0a0); }
.score-box .value { font-size: 1.8rem; font-weight: 700; color: #fff; }

.board-container { position: relative; }
.board {
  background-color: #3d3a50;
  border-radius: 8px;
  padding: 10px;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  aspect-ratio: 1/1;
  max-width: 500px;
  margin: 0 auto;
}
.tile-container {
  background-color: rgba(255, 255, 255, 0.1);
  border-radius: 6px;
}
.tile {
  width: 100%; height: 100%;
  display: flex; justify-content: center; align-items: center;
  font-weight: bold;
  border-radius: 6px;
  transition: all 0.2s ease;
}

.tile-0 { background: transparent; }
.tile-2 { background-color: #eee4da; color: #776e65; font-size: 2.5em; }
.tile-4 { background-color: #ede0c8; color: #776e65; font-size: 2.5em; }
.tile-8 { background-color: #f2b179; color: #f9f6f2; font-size: 2.5em; }
.tile-16 { background-color: #f59563; color: #f9f6f2; font-size: 2.2em; }
.tile-32 { background-color: #f67c5f; color: #f9f6f2; font-size: 2.2em; }
.tile-64 { background-color: #f65e3b; color: #f9f6f2; font-size: 2.2em; }
.tile-128 { background-color: #edcf72; color: #f9f6f2; font-size: 1.8em; box-shadow: 0 0 10px #edcf72; }
.tile-256 { background-color: #edcc61; color: #f9f6f2; font-size: 1.8em; box-shadow: 0 0 10px #edcc61; }
.tile-512 { background-color: #edc850; color: #f9f6f2; font-size: 1.8em; box-shadow: 0 0 10px #edc850; }
.tile-1024 { background-color: #edc53f; color: #f9f6f2; font-size: 1.4em; box-shadow: 0 0 15px #edc53f; }
.tile-2048 { background-color: #edc22e; color: #f9f6f2; font-size: 1.4em; box-shadow: 0 0 20px #edc22e; }
.tile-super { background-color: #3c3a32; color: #f9f6f2; font-size: 1.4em; box-shadow: 0 0 20px #ff1744; }


.overlay {
  position: absolute; top: 0; left: 0;
  width: 100%; height: 100%;
  background-color: rgba(15, 23, 42, 0.8);
  display: flex; flex-direction: column; justify-content: center; align-items: center;
  border-radius: 8px;
}
.overlay h2 { font-size: 3rem; color: #fff; }
.reset-button {
  padding: 0.8rem 2rem; font-size: 1.1rem; font-weight: 600;
  color: #fff; background-color: var(--accent-color, #e94560);
  border: none; border-radius: 8px; cursor: pointer;
  transition: background-color 0.2s ease; margin-top: 1rem;
}
.reset-button:hover { background-color: var(--accent-hover, #ff6e87); }

.controls-info { text-align: center; margin-top: 1.5rem; color: var(--text-secondary); }
.mobile-controls { margin-top: 1rem; }
.d-pad { display: grid; grid-template-columns: repeat(3, 1fr); gap: 0.5rem; max-width: 200px; margin: 0 auto; }
.control-btn { aspect-ratio: 1 / 1; font-size: 1.5rem; font-weight: bold; background-color: rgba(255,255,255,0.1); border: 1px solid var(--border-color); color: var(--text-primary); border-radius: 8px; cursor: pointer; }
.control-btn:active { background-color: rgba(255,255,255,0.2); }
.d-pad-cell { background: transparent; }

h3 { font-size: 1.5rem; }
.leaderboard-list { list-style: none; padding: 0; margin-top: 1rem; }
.leaderboard-item { display: flex; justify-content: space-between; align-items: center; padding: 0.8rem 0; border-bottom: 1px solid var(--border-color); }
.leaderboard-item:last-child { border-bottom: none; }
.player-info { display: flex; align-items: center; gap: 1rem; }
.rank { font-weight: 700; font-size: 1.2rem; min-width: 35px; }
.player-name { font-weight: 600; }
.score-value { font-weight: 700; font-size: 1.2rem; }
.loading-text { color: var(--text-secondary); }


@media (min-width: 992px) {
  .page-container { align-items: center; padding: 1.5rem; }
  .game-2048-card { flex-direction: row; align-items: flex-start; }
  .mobile-controls { display: none; }
}

@media (max-width: 480px) {
  h1 { font-size: 2.5rem; }
  .tile { font-size: 1.5em; }
  .tile-16, .tile-32, .tile-64 { font-size: 1.4em; }
  .tile-128, .tile-256, .tile-512 { font-size: 1.2em; }
  .tile-1024, .tile-2048, .tile-super { font-size: 1em; }
}
</style>