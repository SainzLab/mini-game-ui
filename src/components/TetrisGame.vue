<script setup>
import { ref, onMounted, onUnmounted, computed } from 'vue';
import axios from 'axios';

const BOARD_WIDTH = 10;
const BOARD_HEIGHT = 20;

const TETROMINOES = {
  'I': { shape: [[1, 1, 1, 1]], color: 'cyan' },
  'L': { shape: [[0, 0, 1], [1, 1, 1]], color: 'orange' },
  'J': { shape: [[1, 0, 0], [1, 1, 1]], color: 'blue' },
  'O': { shape: [[1, 1], [1, 1]], color: 'yellow' },
  'S': { shape: [[0, 1, 1], [1, 1, 0]], color: 'lime' },
  'T': { shape: [[0, 1, 0], [1, 1, 1]], color: 'purple' },
  'Z': { shape: [[1, 1, 0], [0, 1, 1]], color: 'red' }
};
const TETROMINO_KEYS = Object.keys(TETROMINOES);

const board = ref([]);
const currentPiece = ref(null);
const nextPiece = ref(null);
const currentPosition = ref({ x: 0, y: 0 });
const score = ref(0);
const gameOver = ref(false);
const gameStarted = ref(false);
const gameInterval = ref(null);
const isClearingLines = ref(false);

const level = ref(1);
const linesClearedTotal = ref(0);
const gameSpeed = ref(800);

const leaderboard = ref([]);
const isLoading = ref(true);

function createEmptyBoard() {
  return Array.from({ length: BOARD_HEIGHT }, () => Array(BOARD_WIDTH).fill({ value: 0, color: null, clearing: false }));
}

function getRandomPiece() {
  const randomKey = TETROMINO_KEYS[Math.floor(Math.random() * TETROMINO_KEYS.length)];
  return TETROMINOES[randomKey];
}

function startGame() {
  board.value = createEmptyBoard();
  score.value = 0;
  level.value = 1;
  linesClearedTotal.value = 0;
  gameSpeed.value = 800;
  gameOver.value = false;
  gameStarted.value = true;
  
  nextPiece.value = getRandomPiece();
  spawnNewPiece();
  
  updateGameInterval();
}

function updateGameInterval() {
  if (gameInterval.value) clearInterval(gameInterval.value);
  gameInterval.value = setInterval(moveDown, gameSpeed.value);
}

function spawnNewPiece() {
  if (isClearingLines.value) return;
  currentPiece.value = nextPiece.value;
  nextPiece.value = getRandomPiece();

  currentPosition.value = { 
    x: Math.floor(BOARD_WIDTH / 2) - Math.floor(currentPiece.value.shape[0].length / 2),
    y: 0 
  };
  
  if (checkCollision(currentPiece.value.shape, currentPosition.value)) {
    gameOver.value = true;
    gameStarted.value = false;
    clearInterval(gameInterval.value);
    saveScore();
  }
}

function moveDown() {
  if (gameOver.value || !gameStarted.value || isClearingLines.value) return;
  const newPosition = { ...currentPosition.value, y: currentPosition.value.y + 1 };
  if (!checkCollision(currentPiece.value.shape, newPosition)) {
    currentPosition.value = newPosition;
  } else {
    mergePiece();
    clearLines();
    if (!isClearingLines.value) spawnNewPiece();
  }
}

function mergePiece() {
  currentPiece.value.shape.forEach((row, y) => {
    row.forEach((value, x) => {
      if (value !== 0) {
        const boardX = currentPosition.value.x + x;
        const boardY = currentPosition.value.y + y;
        if (board.value[boardY]) {
          board.value[boardY][boardX] = { value: 1, color: currentPiece.value.color, clearing: false };
        }
      }
    });
  });
  score.value += 5;
}

function clearLines() {
  let linesToClear = [];
  board.value.forEach((row, y) => {
    if (row.every(cell => cell.value === 1)) {
      linesToClear.push(y);
    }
  });

  if (linesToClear.length > 0) {
    isClearingLines.value = true;
    const scorePoints = [0, 40, 100, 300, 1200];
    score.value += scorePoints[linesToClear.length] * level.value;
    linesClearedTotal.value += linesToClear.length;

    linesToClear.forEach(y => {
      board.value[y].forEach(cell => cell.clearing = true);
    });

    setTimeout(() => {
      board.value = board.value.filter((_, y) => !linesToClear.includes(y));
      for (let i = 0; i < linesToClear.length; i++) {
        board.value.unshift(Array(BOARD_WIDTH).fill({ value: 0, color: null, clearing: false }));
      }
      isClearingLines.value = false;
      
      const newLevel = Math.floor(linesClearedTotal.value / 10) + 1;
      if (newLevel > level.value) {
        level.value = newLevel;
        gameSpeed.value = Math.max(100, 800 - (level.value - 1) * 50);
        updateGameInterval();
      }
      
      spawnNewPiece();
    }, 300);
  }
}

function checkCollision(pieceShape, piecePosition) {
  for (let y = 0; y < pieceShape.length; y++) {
    for (let x = 0; x < pieceShape[y].length; x++) {
      if (pieceShape[y][x] !== 0) {
        const boardX = piecePosition.x + x;
        const boardY = piecePosition.y + y;
        if (boardX < 0 || boardX >= BOARD_WIDTH || boardY >= BOARD_HEIGHT) {
          return true;
        }
        if (board.value[boardY] && board.value[boardY][boardX] && board.value[boardY][boardX].value !== 0) {
          return true;
        }
      }
    }
  }
  return false;
}

function moveHorizontal(direction) {
  if (gameOver.value || !gameStarted.value || isClearingLines.value) return;
  const newPosition = { ...currentPosition.value, x: currentPosition.value.x + direction };
  if (!checkCollision(currentPiece.value.shape, newPosition)) {
    currentPosition.value = newPosition;
  }
}

function rotate() {
  if (gameOver.value || !gameStarted.value || isClearingLines.value) return;
  const shape = currentPiece.value.shape;
  const newShape = shape[0].map((_, colIndex) => shape.map(row => row[colIndex]).reverse());
  const tempPosition = { ...currentPosition.value };
  
  let canRotate = false;
  const offsets = [0, 1, -1, 2, -2];
  for (const offset of offsets) {
    tempPosition.x = currentPosition.value.x + offset;
    if (!checkCollision(newShape, tempPosition)) {
      canRotate = true;
      break;
    }
  }

  if (canRotate) {
    currentPiece.value.shape = newShape;
    currentPosition.value = tempPosition;
  }
}

async function saveScore() {
  if (score.value === 0) return;
  try {
    const playerName = prompt("Game Over! Masukkan nama Anda untuk leaderboard:", `Player-${Date.now().toString().slice(-4)}`);
    if (!playerName) return;
    
    await axios.post('https://api.sainzlab.my.id/api/scores', {
      player_name: playerName,
      game_name: 'Tetris',
      score: score.value
    });
    fetchLeaderboard();
  } catch (error) {
    console.error("Gagal menyimpan skor:", error);
    alert("Gagal menyimpan skor. Cek koneksi ke server API.");
  }
}

async function fetchLeaderboard() {
  isLoading.value = true;
  try {
    const response = await axios.get('https://api.sainzlab.my.id/api/scores/Tetris');
    leaderboard.value = response.data;
  } catch (error) {
    console.error("Gagal mengambil leaderboard Tetris:", error);
  } finally {
    isLoading.value = false;
  }
}

function handleKeyDown(event) {
  if (event.key === 'r' || event.key === 'R') {
    startGame();
    return;
  }
  event.preventDefault(); 
  if (!gameStarted.value) return;
  switch (event.key) {
    case 'ArrowLeft': moveHorizontal(-1); break;
    case 'ArrowRight': moveHorizontal(1); break;
    case 'ArrowDown': moveDown(); break;
    case 'ArrowUp': rotate(); break;
    case ' ': moveDown(); break;
  }
}

onMounted(() => {
  board.value = createEmptyBoard();
  window.addEventListener('keydown', handleKeyDown);
  fetchLeaderboard();
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
  if (gameInterval.value) clearInterval(gameInterval.value);
});

const renderedBoard = computed(() => {
  if (!board.value.length) return [];
  const newBoard = JSON.parse(JSON.stringify(board.value));
  if (currentPiece.value && !gameOver.value) {
    currentPiece.value.shape.forEach((row, y) => {
      row.forEach((value, x) => {
        if (value !== 0) {
          const boardY = currentPosition.value.y + y;
          const boardX = currentPosition.value.x + x;
          if (newBoard[boardY] && newBoard[boardY][boardX]) {
            newBoard[boardY][boardX] = { value: 1, color: currentPiece.value.color };
          }
        }
      });
    });
  }
  return newBoard;
});

const nextPieceBoard = computed(() => {
  const grid = Array.from({ length: 4 }, () => Array(4).fill({ value: 0, color: null }));
  if (nextPiece.value) {
    const shape = nextPiece.value.shape;
    const yOffset = Math.floor((4 - shape.length) / 2);
    const xOffset = Math.floor((4 - shape[0].length) / 2);
    shape.forEach((row, y) => {
      row.forEach((cell, x) => {
        if (cell) {
          grid[y + yOffset][x + xOffset] = { value: 1, color: nextPiece.value.color };
        }
      });
    });
  }
  return grid;
});
</script>

<template>
  <div class="tetris-container">
    <router-link to="/" class="back-button">←</router-link>

    <div class="tetris-card">
      <div class="game-area">
        <h1 class="title">Tetris</h1>
        <div class="board-container">
          <div class="board">
            <div v-for="(row, y) in renderedBoard" :key="`row-${y}`" class="row">
              <div 
                v-for="(cell, x) in row" 
                :key="`cell-${y}-${x}`" 
                class="cell"
                :class="[{ 'clearing': cell.clearing }, `color-${cell.color}`]"
                :data-filled="cell.value === 1"
              ></div>
            </div>
          </div>
          <div v-if="!gameStarted" class="overlay">
            <h2 v-if="gameOver">Game Over</h2>
            <button @click="startGame" class="action-button">
              {{ gameOver ? 'Main Lagi' : 'Mulai Bermain' }}
            </button>
            <p v-if="gameOver" class="restart-hint">Atau tekan 'R' untuk restart</p>
          </div>
        </div>
      </div>
      
      <div class="info-area">
        <div class="info-box mobile-controls">
           <h3>KONTROL MOBILE</h3>
           <div class="d-pad-row">
             <button @click="moveHorizontal(-1)" class="mobile-btn">←</button>
             <button @click="moveDown()" class="mobile-btn">↓</button>
             <button @click="moveHorizontal(1)" class="mobile-btn">→</button>
           </div>
           <div class="d-pad-row">
             <button @click="rotate()" class="mobile-btn rotate-btn">↻ Rotasi</button>
           </div>
        </div>
        
        <div class="score-level-grid">
            <div class="info-box score-box">
              <h3>SKOR</h3>
              <p>{{ score }}</p>
            </div>
             <div class="info-box level-box">
              <h3>LEVEL</h3>
              <p>{{ level }}</p>
            </div>
        </div>
        
        <div class="info-box next-piece-box">
          <h3>BERIKUTNYA</h3>
          <div class="next-piece-grid">
             <div v-for="(row, y) in nextPieceBoard" :key="`next-row-${y}`" class="row">
                <div 
                  v-for="(cell, x) in row" 
                  :key="`next-cell-${y}-${x}`" 
                  class="cell"
                  :class="`color-${cell.color}`"
                  :data-filled="cell.value === 1"
                ></div>
              </div>
          </div>
        </div>

        <div class="info-box leaderboard-box">
          <h3>🏆 LEADERBOARD</h3>
          <div v-if="isLoading" class="loading-text">Memuat...</div>
          <ul v-else-if="leaderboard.length > 0">
            <li v-for="(item, index) in leaderboard" :key="item.id">
              <span>#{{ index + 1 }} {{ item.player_name }}</span>
              <strong>{{ item.score }}</strong>
            </li>
          </ul>
          <div v-else class="loading-text">Belum ada data.</div>
        </div>
        
        <div class="info-box desktop-controls">
         <h3>KONTROL DESKTOP</h3>
          <p>← Kiri | → Kanan</p>
          <p>↓ Bawah | ↑ Rotasi</p>
          <p>'R' untuk Restart</p>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@400;600;700&display=swap');

:root {
  --bg-color-deep: #10101a;
  --bg-color-main: #1a1a2e;
  --bg-card: #16213e;
  --text-primary: #e0e0e0;
  --text-secondary: #a0a0a0;
  --border-color: rgba(224, 224, 224, 0.2);
  --accent-color: #e94560;
  --accent-hover: #ff6e87;
  --shadow-glow: rgba(233, 69, 96, 0.5);
  --clearing-color: #ffffff;
}

.tetris-container {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  padding: 1rem;
  font-family: 'Poppins', sans-serif;
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
  z-index: 20; 
}

.back-button:hover {
  background-color: #2c3e50;
  color: #fff;
}

.tetris-card {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  width: 100%;
  max-width: 1200px;
}

.game-area {
  flex-grow: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.title {
  font-size: 2.5rem;
  font-weight: 700;
  color: var(--accent-color);
  text-shadow: 0 0 10px var(--shadow-glow);
  margin-bottom: 1rem;
}

.board-container {
  position: relative;
  border: 4px solid var(--border-color);
  border-radius: 8px;
  background-color: var(--bg-color-deep);
  box-shadow: inset 0 0 15px rgba(0, 0, 0, 0.5);
  width: 100%; 
  max-width: 40vh; 
}

.board {
  display: grid;
  grid-template-columns: repeat(10, 1fr);
}

.row { display: contents; }

.cell {
  aspect-ratio: 1 / 1;
  border: 1px solid rgba(255, 255, 255, 0.08); 
  background-color: transparent;
  transition: transform 0.1s ease;
}

.cell[data-filled="true"] {
  border-radius: 2px;
  border: none;
}

.cell.clearing {
  background-color: var(--clearing-color);
  animation: flash 0.3s ease-out;
}
@keyframes flash {
  0%, 100% { transform: scale(1); background-color: var(--clearing-color); }
  50% { transform: scale(1.1); background-color: white; }
}

.color-cyan { background-color: #00ffff; box-shadow: 0 0 8px #00ffff; }
.color-orange { background-color: #ff9900; box-shadow: 0 0 8px #ff9900; }
.color-blue { background-color: #0066ff; box-shadow: 0 0 8px #0066ff; }
.color-yellow { background-color: #ffff00; box-shadow: 0 0 8px #ffff00; }
.color-lime { background-color: #33ff33; box-shadow: 0 0 8px #33ff33; }
.color-purple { background-color: #cc00cc; box-shadow: 0 0 8px #cc00cc; }
.color-red { background-color: #ff3333; box-shadow: 0 0 8px #ff3333; }

.overlay {
  position: absolute;
  top: 0; left: 0;
  width: 100%; height: 100%;
  background-color: rgba(0, 0, 0, 0.75);
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  border-radius: 4px;
  z-index: 10;
  text-align: center;
}
.overlay h2 { font-size: 2rem; margin-bottom: 1.5rem; color: #fff; }
.restart-hint { font-size: 0.9rem; color: var(--text-secondary); margin-top: 1rem; }

.action-button {
  padding: 12px 24px;
  font-size: 1.2rem;
  font-weight: 600;
  color: #fff;
  background-color: var(--accent-color);
  border: none; border-radius: 8px;
  cursor: pointer;
  transition: background-color 0.2s ease, transform 0.2s ease;
  box-shadow: 0 4px 15px var(--shadow-glow);
}
.action-button:hover {
  background-color: var(--accent-hover);
  transform: translateY(-3px);
}

.info-area {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  width: 100%;
  max-width: 350px;
  margin: 0 auto;
}

.info-box {
  background-color: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: 8px;
  padding: 1rem;
  box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
}
.info-box h3 {
  font-size: 1.1rem; font-weight: 600;
  margin: 0 0 1rem 0;
  padding-bottom: 0.5rem;
  border-bottom: 1px solid var(--border-color);
  color: var(--accent-color);
  text-align: center;
}
.info-box p { text-align: center; }

.score-level-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1.5rem;
}
.score-box p, .level-box p { font-size: 2rem; font-weight: 700; margin: 0; }

.next-piece-grid { display: grid; grid-template-columns: repeat(4, 1fr); width: 100px; margin: 0 auto; }
.leaderboard-box ul { list-style: none; padding: 0; margin: 0; max-height: 200px; overflow-y: auto; }
.leaderboard-box li { display: flex; justify-content: space-between; padding: 0.5rem 0; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.leaderboard-box li:last-child { border-bottom: none; }
.leaderboard-box li span { color: var(--text-secondary); }
.leaderboard-box li strong { color: var(--text-primary); }
.loading-text { text-align: center; color: var(--text-secondary); }

.mobile-controls { display: flex; flex-direction: column; gap: 1rem; }
.desktop-controls { display: none; }
.d-pad-row { display: flex; justify-content: center; gap: 1rem; }
.mobile-btn {
  padding: 1rem; flex-grow: 1; font-size: 1.5rem; font-weight: bold;
  background-color: rgba(255,255,255,0.1); border: 1px solid var(--border-color);
  color: var(--text-primary); border-radius: 8px;
  cursor: pointer; transition: background-color 0.2s ease;
}
.mobile-btn:active { background-color: rgba(255,255,255,0.2); }
.rotate-btn { font-size: 1rem; }

@media (min-width: 992px) {
  .tetris-card { flex-direction: row; align-items: flex-start; }
  .info-area { width: 300px; flex-shrink: 0; max-width: 300px; margin: 0; }
  .mobile-controls { display: none; }
  .desktop-controls { display: block; }
  .board-container { margin-bottom: 0; }
  .back-button { top: 2rem; left: 2rem;}
}
</style>